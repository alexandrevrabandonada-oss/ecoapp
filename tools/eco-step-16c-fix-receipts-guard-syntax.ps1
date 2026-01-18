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
  $f = Get-ChildItem -Recurse -File -Path $root -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -match $pattern } |
    Select-Object -First 1
  if($f){ return $f.FullName }
  return $null
}

$rep = NewReport "eco-step-16c-fix-receipts-guard-syntax"
$log = @()
$log += "# ECO — STEP 16c — Fix syntax do guard de recibo (route.ts)"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

# =========
# DIAG
# =========
$apiReceipts = "src/app/api/receipts/route.ts"
if(!(Test-Path -LiteralPath $apiReceipts)){
  $apiReceipts = FindFirst "src/app" "\\api\\receipts\\route\.ts$"
}
if(-not $apiReceipts){ throw "Não achei /api/receipts/route.ts" }

$txt = Get-Content -LiteralPath $apiReceipts -Raw

$log += "## DIAG"
$log += ("API receipts: {0}" -f $apiReceipts)
$log += ("Has guard marker? {0}" -f ($txt -match "ECO_RECEIPTS_PUBLIC_GUARD_V1"))
$log += ""

# =========
# PATCH
# =========
$log += "## PATCH"
$log += ("Backup API: {0}" -f (BackupFile $apiReceipts))
$log += ""

if($txt -notmatch "ECO_RECEIPTS_PUBLIC_GUARD_V1"){
  throw "Não encontrei o marker ECO_RECEIPTS_PUBLIC_GUARD_V1 no /api/receipts. Não sei onde corrigir."
}

$marker = "// ECO_RECEIPTS_PUBLIC_GUARD_V1"
$idxMarker = $txt.IndexOf($marker)
if($idxMarker -lt 0){ throw "Marker não encontrado (index)." }

# começa no início da linha do marker
$idxLineStart = $txt.LastIndexOf("`n", $idxMarker)
if($idxLineStart -lt 0){ $idxLineStart = 0 } else { $idxLineStart = $idxLineStart + 1 }

# termina antes do return ok do ramo code
$needleReturnOk = "return NextResponse.json({ ok: true"
$idxReturnOk = $txt.IndexOf($needleReturnOk, $idxMarker)
if($idxReturnOk -lt 0){
  throw "Não achei o '$needleReturnOk' depois do marker para delimitar o bloco."
}

$fixedBlock = @"
      // ECO_RECEIPTS_PUBLIC_GUARD_V1
      // Se ECO_OPERATOR_TOKEN estiver setado:
      // - recibo público => retorna normal
      // - recibo privado => só retorna se token bater (header x-eco-token ou query ?token=)
      const isPublic = !!((receipt as any).public ?? (receipt as any).isPublic);
      const required = process.env.ECO_OPERATOR_TOKEN;

      if (!isPublic && required) {
        const u = new URL(req.url);
        const token =
          req.headers.get("x-eco-token") ||
          u.searchParams.get("token") ||
          u.searchParams.get("operatorToken") ||
          "";

        if (!token || token !== required) {
          // 404 para não revelar existência
          return NextResponse.json({ error: "receipt_not_found", code }, { status: 404 });
        }
      }

"@

# substitui bloco inteiro do marker até antes do return ok
$txt2 = $txt.Substring(0, $idxLineStart) + $fixedBlock + $txt.Substring($idxReturnOk)

WriteUtf8NoBom $apiReceipts $txt2
$log += "- OK: Bloco ECO_RECEIPTS_PUBLIC_GUARD_V1 reescrito com TypeScript válido."
$log += ""

# =========
# REGISTRO
# =========
$log += "## Próximos passos"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1"
$log += "3) /api/services deve voltar 200 (compile OK)"
$log += "4) Teste recibo privado com ECO_OPERATOR_TOKEN: em aba anônima deve dar 404"
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")
Write-Host ("✅ STEP 16c aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) /api/services deve voltar 200" -ForegroundColor Yellow