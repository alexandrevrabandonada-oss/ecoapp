$ErrorActionPreference = "Stop"

function EnsureDir([string]$p){
  if($p -and !(Test-Path $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null }
}

function WriteUtf8NoBom([string]$path, [string]$content){
  $dir = Split-Path -Parent $path
  if($dir){ EnsureDir $dir }
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
}

function BackupFile([string]$path){
  if(!(Test-Path $path)){ return $null }
  EnsureDir "tools/_patch_backup"
  $ts = Get-Date -Format "yyyyMMdd-HHmmss"
  $safe = ($path -replace '[\\/:*?"<>|]', '_')
  $dst = "tools/_patch_backup/$ts-$safe"
  Copy-Item -Force $path $dst
  return $dst
}

function NewReport([string]$name){
  EnsureDir "reports"
  $ts = Get-Date -Format "yyyyMMdd-HHmmss"
  return "reports/$ts-$name.md"
}

function PatchFile([string]$path, [scriptblock]$patch){
  if(!(Test-Path $path)){
    $script:log += ("SKIP missing: {0}" -f $path)
    return
  }
  $orig = Get-Content $path -Raw
  $new  = & $patch $orig
  if($new -ne $orig){
    $bak = BackupFile $path
    if($bak){ $script:log += ("Backup: {0}" -f $bak) }
    WriteUtf8NoBom $path $new
    $script:log += ("OK patched: {0}" -f $path)
  } else {
    $script:log += ("NOCHANGE: {0}" -f $path)
  }
}

$rep = NewReport "eco-fix-duplicate-receipt-and-align-code"
$log = @()
$log += "# ECO — FIX — Prisma duplicate receipt + code align (ecoReceipt)"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ("Node: {0}" -f (node -v 2>$null))
$log += ("npm : {0}" -f (npm -v 2>$null))
$log += ""

# =========================
# PATCH 1 — prisma/schema.prisma
# =========================
$schemaPath = "prisma/schema.prisma"
if(!(Test-Path $schemaPath)){ throw "Não achei prisma/schema.prisma" }

$schemaRaw = Get-Content $schemaPath -Raw

$rx = [regex]'model\s+PickupRequest\s*\{([\s\S]*?)\r?\n\}'
$m = $rx.Match($schemaRaw)
if(!$m.Success){ throw "Não achei model PickupRequest no schema" }

$block = $m.Value

# conta quantas linhas 'receipt X?'
$receiptLineMatches = [regex]::Matches($block, '^\s*receipt\s+\w+\?\s*$', 'Multiline')
$receiptLineCount = $receiptLineMatches.Count

$hasReceiptReceipt = ($block -match '^\s*receipt\s+Receipt\?\s*$' )
$hasReceiptEco     = ($block -match '^\s*receipt\s+EcoReceipt\?\s*$' )
$hasEcoReceiptLine = ($block -match '^\s*ecoReceipt\s+EcoReceipt\?\s*$' )

$log += "## DIAG"
$log += ("PickupRequest receipt lines: {0}" -f $receiptLineCount)
$log += ("Has 'receipt Receipt?'   : {0}" -f $hasReceiptReceipt)
$log += ("Has 'receipt EcoReceipt?': {0}" -f $hasReceiptEco)
$log += ("Has 'ecoReceipt EcoReceipt?': {0}" -f $hasEcoReceiptLine)
$log += ""

if($hasReceiptReceipt -and $hasReceiptEco){
  $schemaBak = BackupFile $schemaPath
  if($schemaBak){ $log += ("Backup: {0}" -f $schemaBak) }

  if($hasEcoReceiptLine){
    # já existe ecoReceipt -> remove a linha duplicada receipt EcoReceipt?
    $block2 = [regex]::Replace($block, '^\s*receipt\s+EcoReceipt\?\s*\r?\n', '', 'Multiline')
    $log += "PATCH schema: removida linha duplicada 'receipt EcoReceipt?' (ecoReceipt já existia)"
  } else {
    # renomeia receipt EcoReceipt? -> ecoReceipt EcoReceipt?
    $block2 = [regex]::Replace($block, '^\s*receipt\s+EcoReceipt\?\s*$', '  ecoReceipt EcoReceipt?', 'Multiline')
    $log += "PATCH schema: renomeado 'receipt EcoReceipt?' -> 'ecoReceipt EcoReceipt?'"
  }

  $schemaFixed = $schemaRaw.Replace($block, $block2)
  WriteUtf8NoBom $schemaPath $schemaFixed
  $log += "OK: prisma/schema.prisma atualizado"
} else {
  $log += "SKIP schema: não encontrei o padrão exato 'receipt Receipt?' + 'receipt EcoReceipt?'"
}

$log += ""
$log += "## VERIFY Prisma"
npx prisma validate --schema=prisma/schema.prisma | Out-Host
npx prisma generate --schema=prisma/schema.prisma | Out-Host
npx prisma db push --schema=prisma/schema.prisma | Out-Host
$log += "OK: prisma validate/generate/db push"

# =========================
# PATCH 2 — ajustar API/UI para ecoReceipt
# =========================
$log += ""
$log += "## PATCH code (ecoReceipt)"

# pickup-requests list
PatchFile "src/app/api/pickup-requests/route.ts" {
  param($t)
  # inclui both se possível
  $t = $t -replace 'include:\s*\{\s*receipt:\s*true\s*\}', 'include: { receipt: true, ecoReceipt: true }'
  return $t
}

# pickup-requests by id
PatchFile "src/app/api/pickup-requests/\[id\]/route.ts" {
  param($t)
  $t = $t -replace 'include:\s*\{\s*receipt:\s*true\s*\}', 'include: { receipt: true, ecoReceipt: true }'
  return $t
}

# chamar-coleta UI: trocar receipt -> ecoReceipt nas partes que usam shareCode
PatchFile "src/app/chamar-coleta/page.tsx" {
  param($t)
  $t = $t -replace 'receipt\?:\s*Receipt;', 'ecoReceipt?: Receipt;'
  $t = $t -replace 'it\.receipt\?\.', 'it.ecoReceipt?.'
  $t = $t -replace 'it\.receipt\.', 'it.ecoReceipt.'
  return $t
}

# Se teu UI estiver lendo "receipt" no type Item, isso garante
PatchFile "src/app/chamar-coleta/page.tsx" {
  param($t)
  if($t -match 'receipt\?:\s*Receipt;' -and $t -notmatch 'ecoReceipt\?:\s*Receipt;'){
    $t = $t -replace 'receipt\?:\s*Receipt;', 'ecoReceipt?: Receipt;'
  }
  return $t
}

# (opcional) se algum outro arquivo usar a mesma ideia de shareCode:
PatchFile "src/app/chamar-coleta/page.tsx" {
  param($t)
  # link do recibo
  $t = $t -replace 'href=\{\"\/recibo\/\"\s*\+\s*it\.receipt\.shareCode\}', 'href={"/recibo/" + it.ecoReceipt!.shareCode}'
  return $t
}

$log += "OK: patches aplicados (onde existiam)"

WriteUtf8NoBom $rep ($log -join "`n")
Write-Host ("✅ FIX aplicado. Report -> {0}" -f $rep) -ForegroundColor Green

Write-Host ""
Write-Host "AGORA (importante):" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C e rode de novo): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow