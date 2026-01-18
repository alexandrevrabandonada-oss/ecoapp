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

$target = "tools\eco-step-07-pedidos-fechar-ui.ps1"
if(!(Test-Path -LiteralPath $target)){
  throw "Não achei $target (o STEP 07 precisa existir pra eu corrigir)."
}

$bak = BackupFile $target
Write-Host ("Backup do step07 -> {0}" -f $bak) -ForegroundColor DarkGray

$txt = Get-Content -LiteralPath $target -Raw

# Corrige qualquer linha do tipo: $log += "```"  -> $log += '```'
$fixed = [regex]::Replace(
  $txt,
  '(?m)^(\s*)\$log\s*\+=\s*"```"\s*$',
  { param($m) $m.Groups[1].Value + "`$log += '```'" }
)

if($fixed -eq $txt){
  Write-Host "Nada pra corrigir (não achei `$log += ""```""). Mesmo assim vou tentar rodar o step07." -ForegroundColor Yellow
} else {
  WriteUtf8NoBom $target $fixed
  Write-Host "✅ Corrigido: backticks no log (parser)." -ForegroundColor Green
}

Write-Host "== Rodando STEP 07 novamente ==" -ForegroundColor Cyan
pwsh -NoProfile -ExecutionPolicy Bypass -File $target

Write-Host "== Smoke ==" -ForegroundColor Cyan
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1