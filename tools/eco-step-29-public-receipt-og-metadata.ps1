$ErrorActionPreference = "Stop"

function EnsureDir([string]$p){
  if($p -and !(Test-Path -LiteralPath $p)){
    New-Item -ItemType Directory -Force -Path $p | Out-Null
  }
}
function WriteUtf8NoBom([string]$path, [string]$content){
  $dir = Split-Path -Parent $path
  if($dir){ EnsureDir $dir }
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
}
function BackupFile([string]$path){
  if(!(Test-Path -LiteralPath $path)){ return $null }
  EnsureDir "tools/_patch_backup"
  $ts = Get-Date -Format "yyyyMMdd-HHmmss"
  $safe = ($path -replace '[\\/:*?"<>|]', '_')
  $dst = "tools/_patch_backup/$ts-$safe"
  Copy-Item -Force -LiteralPath $path $dst
  return $dst
}
function NewReport([string]$name){
  EnsureDir "reports"
  $ts = Get-Date -Format "yyyyMMdd-HHmmss"
  return "reports/$ts-$name.md"
}
function FindFirst([string]$root, [string]$pattern){
  if(!(Test-Path -LiteralPath $root)){ return $null }
  $f = Get-ChildItem -Recurse -File -Path $root -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -match $pattern } |
    Select-Object -First 1
  if($f){ return $f.FullName }
  return $null
}

$rep = NewReport "eco-step-29-public-receipt-og-metadata"
$log = @()
$log += "# ECO — STEP 29 — OpenGraph/Twitter metadata em /r/[code]"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

# localizar page.tsx de /r/[code]
$page = "src/app/r/[code]/page.tsx"
if(!(Test-Path -LiteralPath $page)){
  # tenta achar qualquer variação dentro de src/app/r/[...]/page.tsx
  $page = FindFirst "." "\\src\\app\\r\\\[[^\]]+\]\\page\.tsx$"
}
if(!(Test-Path -LiteralPath $page)){
  $log += "## ERRO"
  $log += "Não achei a página pública do recibo. Esperado: src/app/r/[code]/page.tsx"
  WriteUtf8NoBom $rep ($log -join "`n")
  throw "Não achei src/app/r/[code]/page.tsx (nem variações em src/app/r/[...]/page.tsx)"
}

$txt = Get-Content -LiteralPath $page -Raw

$log += "## DIAG"
$log += ("Arquivo alvo: {0}" -f $page)
$log += ""

$log += "## PATCH"
$bk = BackupFile $page
$log += ("Backup: {0}" -f $bk)

if($txt -match "ECO_STEP29_METADATA_START"){
  $log += "- INFO: já existe ECO_STEP29_METADATA (skip)."
} elseif($txt -match "generateMetadata\s*\("){
  $log += "- WARN: já existe generateMetadata no arquivo; não injetei outra (skip)."
  $log += "  -> Se quiser, me manda esse trecho e eu ajusto pra incluir OG."
} else {
  # garantir import de headers
  $needHeadersImport = $true
  if($txt -match "from\s+['""]next\/headers['""]"){ $needHeadersImport = $false }

  # achar ponto de inserção (após último import)
  $mImp = [regex]::Matches($txt, '^\s*import\s+.*?;\s*$', 'Multiline')
  $insAt = 0
  if($mImp -and $mImp.Count -gt 0){
    $last = $mImp[$mImp.Count-1]
    $insAt = $last.Index + $last.Length
  }

  $block = @"
$([string]::Empty)

// ECO_STEP29_METADATA_START
$([string]::Empty)
"@

  if($needHeadersImport){
    $block += "import { headers } from 'next/headers';`n`n"
  }

  $block += @"
function ecoOriginFromHeaders(): string {
  const h = headers();
  const proto = h.get('x-forwarded-proto') ?? 'http';
  const host = h.get('x-forwarded-host') ?? h.get('host') ?? 'localhost:3000';
  return proto + '://' + host;
}

export async function generateMetadata({ params }: { params: { code: string } }) {
  const code = params?.code ?? '';
  const origin = ecoOriginFromHeaders();
  const base = new URL(origin);

  const c = encodeURIComponent(String(code));
  const img34 = '/api/share/receipt-card?code=' + c + '&format=3x4';
  const img11 = '/api/share/receipt-card?code=' + c + '&format=1x1';

  return {
    metadataBase: base,
    title: 'Recibo ECO #' + String(code),
    description: 'Recibo ECO público — código ' + String(code),
    alternates: { canonical: '/r/' + String(code) },
    openGraph: {
      title: 'Recibo ECO #' + String(code),
      description: 'Recibo ECO público — código ' + String(code),
      url: '/r/' + String(code),
      type: 'article',
      images: [
        { url: img34, width: 1080, height: 1350, alt: 'Recibo ECO 3:4' },
        { url: img11, width: 1080, height: 1080, alt: 'Recibo ECO 1:1' }
      ]
    },
    twitter: {
      card: 'summary_large_image',
      title: 'Recibo ECO #' + String(code),
      description: 'Recibo ECO público — código ' + String(code),
      images: [img34]
    }
  } as any;
}
// ECO_STEP29_METADATA_END

"@

  $txt = $txt.Insert($insAt, $block)
  $log += "- OK: inseri generateMetadata + OpenGraph/Twitter (com metadataBase via headers)."
}

WriteUtf8NoBom $page $txt

$log += ""
$log += "## VERIFY"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1"
$log += "3) Teste preview: cole um link /r/[code] no WhatsApp e veja se puxa imagem/título"
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")
Write-Host ("✅ STEP 29 aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) Cole um link /r/[code] no WhatsApp (preview OG/Twitter)" -ForegroundColor Yellow