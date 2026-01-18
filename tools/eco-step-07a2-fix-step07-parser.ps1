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

$rep = NewReport "eco-step-07a2-fix-step07-parser"
$log = @()
$log += "# ECO — STEP 07a2 — Fix parser (``` em strings do PowerShell)"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

$targetStep = "tools\eco-step-07-pedidos-fechar-ui.ps1"
if(!(Test-Path -LiteralPath $targetStep)){
  throw "Não achei $targetStep"
}

$bak = BackupFile $targetStep
$log += ("Backup: {0}" -f $bak)

$txt = Get-Content -LiteralPath $targetStep -Raw
$lines = $txt -split "`r?`n"

$changed = 0
$newLines = New-Object System.Collections.Generic.List[string]

foreach($ln in $lines){
  # troca SOMENTE linhas: $log += "```..."  ->  $log += '```...'
  if($ln -match '^(\s*\$log\s*\+=\s*)"(```[^"]*)"\s*$'){
    $pre = $Matches[1]
    $val = $Matches[2]
    $newLines.Add($pre + "'" + $val + "'")
    $changed++
  } else {
    $newLines.Add($ln)
  }
}

if($changed -gt 0){
  WriteUtf8NoBom $targetStep ($newLines -join "`r`n")
  $log += ("OK: corrigi {0} linha(s) com ``` em aspas duplas" -f $changed)
} else {
  $log += "NOCHANGE: não achei linhas `$log += ""```..."""
}

$log += ""
$log += "## Executando STEP 07 novamente"
WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ Parser fix aplicado. Linhas corrigidas: {0}" -f $changed) -ForegroundColor Green
Write-Host ("Report -> {0}" -f $rep) -ForegroundColor DarkGray
Write-Host ""

pwsh -NoProfile -ExecutionPolicy Bypass -File $targetStep

Write-Host ""
Write-Host "== SMOKE ==" -ForegroundColor Cyan
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1

Write-Host ""
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Abra /pedidos" -ForegroundColor Yellow
Write-Host "2) Clique Fechar/Emitir recibo em um pedido" -ForegroundColor Yellow
Write-Host "3) Verifique se existe /pedidos/fechar/[id] e se gera /recibo/[code]" -ForegroundColor Yellow