$ErrorActionPreference = "Stop"

function Ensure-Dir([string]$p){
  if($p -and !(Test-Path $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null }
}

function WriteUtf8NoBom([string]$path, [string]$content){
  $dir = Split-Path -Parent $path
  if($dir){ Ensure-Dir $dir }
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
}

function Backup-File([string]$path){
  if(!(Test-Path $path)){ return $null }
  Ensure-Dir "tools/_patch_backup"
  $ts = Get-Date -Format "yyyyMMdd-HHmmss"
  $safe = ($path -replace '[\\/:*?"<>|]', '_')
  $dst = "tools/_patch_backup/$ts-$safe"
  Copy-Item -Force $path $dst
  return $dst
}

function New-Report([string]$name){
  Ensure-Dir "reports"
  $ts = Get-Date -Format "yyyyMMdd-HHmmss"
  return "reports/$ts-$name.md"
}

function Run-Exe([string]$cmd, [string[]]$args){
  & $cmd @args
  if($LASTEXITCODE -ne 0){
    throw "Falhou: $cmd $($args -join ' ') (exit=$LASTEXITCODE)"
  }
}

$rep = New-Report "eco-fix-prisma-duplicate-receipt-field"
$log = @()
$log += "# ECO — FIX — Prisma duplicate field (PickupRequest.receipt)"
$log += ""
$log += "- Data: " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
$log += "- PWD : " + (Get-Location).Path
$log += "- Node: " + (node -v 2>$null)
$log += "- npm : " + (npm -v 2>$null)
$log += ""

# =========================
# DIAG
# =========================
$schemaPath = "prisma/schema.prisma"
if(!(Test-Path $schemaPath)){ throw "Não achei $schemaPath" }

$raw = Get-Content $schemaPath -Raw
$log += "## DIAG"
$log += "- schema path: $schemaPath"
$log += ""

# Extrair bloco PickupRequest
$rx = [regex]'model\s+PickupRequest\s*\{([\s\S]*?)\r?\n\}'
$m = $rx.Match($raw)
if(!$m.Success){
  $log += "- ❌ Não achei model PickupRequest no schema."
  WriteUtf8NoBom $rep ($log -join "`n")
  throw "Não achei model PickupRequest no schema."
}

$block = $m.Value

# Contar quantas linhas "receipt ..." existem
$receiptLines = [regex]::Matches($block, '^\s*receipt\s+\w+\?\s*$', 'Multiline').Count
$log += "- linhas receipt? (count): **$receiptLines**"
$log += ""
$log += "### Trecho atual (PickupRequest)"
$log += "```prisma"
$log += ($block.Trim())
$log += "```"
$log += ""

# =========================
# PATCH
# =========================
$bak = Backup-File $schemaPath
if($bak){ $log += "- Backup: $bak" }

# Caso clássico: tem receipt Receipt? e receipt EcoReceipt? -> renomeia o EcoReceipt p/ ecoReceipt
$hasReceiptReceipt = ($block -match '^\s*receipt\s+Receipt\?\s*$' -and $block -match '^\s*receipt\s+EcoReceipt\?\s*$')
if($hasReceiptReceipt){
  $block2 = [regex]::Replace($block, '^\s*receipt\s+EcoReceipt\?\s*$', '  ecoReceipt EcoReceipt?', 'Multiline')
  $log += "- PATCH: renomeado 'receipt EcoReceipt?' -> 'ecoReceipt EcoReceipt?' (mantendo receipt Receipt?)"
} else {
  # Se houver duplicate receipt de qualquer tipo, tenta dedupe mantendo a 1ª e renomeando a 2ª se for EcoReceipt
  if($receiptLines -ge 2 -and ($block -match '^\s*receipt\s+EcoReceipt\?\s*$')){
    $block2 = [regex]::Replace($block, '^\s*receipt\s+EcoReceipt\?\s*$', '  ecoReceipt EcoReceipt?', 'Multiline')
    $log += "- PATCH: havia duplicidade; renomeado receipt EcoReceipt? -> ecoReceipt EcoReceipt?"
  } else {
    $block2 = $block
    $log += "- PATCH: nada a fazer (não detectei o padrão de duplicidade com EcoReceipt)."
  }
}

# Aplicar bloco no schema
if($block2 -ne $block){
  $fixed = $raw.Replace($block, $block2)
  WriteUtf8NoBom $schemaPath $fixed
  $log += "- OK: schema atualizado"
} else {
  $log += "- OK: schema mantido (sem mudanças)"
}

$log += ""
$log += "## VERIFY — Prisma"
Run-Exe "npx" @("prisma","validate","--schema=prisma/schema.prisma")
Run-Exe "npx" @("prisma","generate","--schema=prisma/schema.prisma")
Run-Exe "npx" @("prisma","db","push","--schema=prisma/schema.prisma")
$log += "- OK: prisma validate/generate/db push"

WriteUtf8NoBom $rep ($log -join "`n")
Write-Host "✅ Prisma FIX aplicado e verificado. Report -> $rep" -ForegroundColor Green

Write-Host ""
Write-Host "AGORA:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C no terminal do dev e rode de novo): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow

Write-Host ""
Write-Host "Checagem rápida do trecho do schema:" -ForegroundColor DarkGray
Write-Host "  Select-String -Path prisma/schema.prisma -Pattern 'model PickupRequest' -Context 0,60" -ForegroundColor DarkGray