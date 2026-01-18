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

function DetectReceiptFkField([string]$schemaPath){
  # tenta achar no model Receipt: @relation(fields: [X], references: [id])
  if(!(Test-Path -LiteralPath $schemaPath)){ return "requestId" }
  $lines = Get-Content -LiteralPath $schemaPath
  $start = -1
  for($i=0; $i -lt $lines.Count; $i++){
    if($lines[$i] -match "^\s*model\s+Receipt\s*\{"){ $start = $i; break }
  }
  if($start -lt 0){ return "requestId" }

  $end = -1
  for($j=$start+1; $j -lt $lines.Count; $j++){
    if($lines[$j] -match "^\s*\}\s*$"){ $end = $j; break }
  }
  if($end -lt 0){ return "requestId" }

  for($k=$start; $k -le $end; $k++){
    $line = $lines[$k]
    if($line -match "@relation\(\s*fields:\s*\[(\w+)\]\s*,\s*references:\s*\[id\]\s*\)"){
      return $Matches[1]
    }
  }
  return "requestId"
}

$rep = NewReport "eco-step-18g-attach-receipts-in-pickup-list-postprocess-safe"
$log = @()
$log += "# ECO — STEP 18g — Anexar receipt na lista de pickup-requests (post-process robusto)"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

# localizar rota
$api = "src/app/api/pickup-requests/route.ts"
if(!(Test-Path -LiteralPath $api)){ $api = FindFirst "src/app" "\\api\\pickup-requests\\route\.ts$" }
if(!(Test-Path -LiteralPath $api)){ $api = FindFirst "src" "\\api\\pickup-requests\\route\.ts$" }
if(!(Test-Path -LiteralPath $api)){ $api = FindFirst "." "\\api\\pickup-requests\\route\.ts$" }
if(-not $api){
  WriteUtf8NoBom $rep ($log -join "`n")
  throw "Não achei /api/pickup-requests/route.ts"
}

$schema = "prisma/schema.prisma"
if(!(Test-Path -LiteralPath $schema)){ $schema = FindFirst "." "\\prisma\\schema\.prisma$" }
$fk = DetectReceiptFkField $schema

$txt = Get-Content -LiteralPath $api -Raw
if($txt -match "ECO_STEP18G_ATTACH_RECEIPTS"){
  $log += "## INFO"
  $log += "- Marker já existe. Nada a fazer."
  WriteUtf8NoBom $rep ($log -join "`n")
  Write-Host ("✅ STEP 18g (skip) — já aplicado. Report -> {0}" -f $rep) -ForegroundColor Yellow
  exit 0
}

# descobrir nome do client (prisma/db)
$dbVar = $null
if($txt.Contains("prisma.")){ $dbVar = "prisma" }
elseif($txt.Contains("db.")){ $dbVar = "db" }
else { $dbVar = "prisma" } # fallback

# achar bloco de items e return de sucesso
$idxItems = $txt.IndexOf("const items")
if($idxItems -lt 0){ $idxItems = $txt.IndexOf("let items") }
if($idxItems -lt 0){
  WriteUtf8NoBom $rep ($log -join "`n")
  throw "Não achei 'const items' ou 'let items' em /api/pickup-requests para anexar receipt."
}

$idxReturn = $txt.IndexOf("return NextResponse.json", $idxItems)
if($idxReturn -lt 0){
  WriteUtf8NoBom $rep ($log -join "`n")
  throw "Não achei 'return NextResponse.json' após items em /api/pickup-requests."
}

$log += "## DIAG"
$log += ("API: {0}" -f $api)
$log += ("DB var: {0}" -f $dbVar)
$log += ("Receipt FK: {0}" -f $fk)
$log += ""

$log += "## PATCH"
$log += ("Backup: {0}" -f (BackupFile $api))

# snippet (sem here-string aninhada @' dentro do $code!)
$snippet = @"
`n// ECO_STEP18G_ATTACH_RECEIPTS
let __items = items;
try {
  const __ids = Array.isArray(items) ? items.map((x:any)=>x?.id).filter(Boolean) : [];
  if (__ids.length) {
    const __receipts = await $dbVar.receipt.findMany({
      where: { $fk: { in: __ids } },
      select: { $fk: true, code: true, shareCode: true, public: true, isPublic: true, createdAt: true },
    });
    const __byReq: Record<string, any> = {};
    for (const r of __receipts as any[]) {
      const k = (r as any).$fk;
      if (k) __byReq[k] = r;
    }
    __items = (items as any[]).map((it:any) => {
      const rid = it?.id;
      const rec = rid ? __byReq[rid] : null;
      if (!rec) return it;
      return { ...it, receipt: rec };
    });
  }
} catch {
  // ignore: não quebra list se receipt falhar
}
"@

# inserir snippet antes do return
$txt2 = $txt.Insert($idxReturn, $snippet)

# ajustar return para usar __items quando possível (janela local)
$winLen = [Math]::Min(900, $txt2.Length - $idxReturn)
$win = $txt2.Substring($idxReturn, $winLen)

if($win.Contains("NextResponse.json(items")){
  $win2 = $win.Replace("NextResponse.json(items", "NextResponse.json(__items")
  $txt2 = $txt2.Substring(0, $idxReturn) + $win2 + $txt2.Substring($idxReturn + $winLen)
  $log += "- OK: return NextResponse.json(items...) -> __items"
} else {
  $w2 = $win
  $w2 = $w2.Replace("{ items,", "{ items: __items,")
  $w2 = $w2.Replace("{ items }", "{ items: __items }")
  $w2 = $w2.Replace(", items,", ", items: __items,")
  $w2 = $w2.Replace(", items }", ", items: __items }")
  $txt2 = $txt2.Substring(0, $idxReturn) + $w2 + $txt2.Substring($idxReturn + $winLen)
  $log += "- OK: tentativa de trocar shorthand 'items' por 'items: __items' no return (quando existir)."
}

WriteUtf8NoBom $api $txt2

$log += ""
$log += "## Próximos passos"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1"
$log += "3) Abra /pedidos -> quando houver recibo, deve aparecer 'Ver recibo'."
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 18g aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) /pedidos -> deve aparecer 'Ver recibo' quando houver receipt" -ForegroundColor Yellow