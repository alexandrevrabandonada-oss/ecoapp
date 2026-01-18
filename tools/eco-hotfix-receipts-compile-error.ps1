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

EnsureDir "reports"
$ts = Get-Date -Format "yyyyMMdd-HHmmss"
$rep = "reports/$ts-eco-hotfix-receipts-compile-error.md"
$log = @()
$log += "# ECO — Hotfix receipts compile error"
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

$f = "src/app/api/receipts/route.ts"
if(!(Test-Path -LiteralPath $f)){ throw "Não achei $f" }

$bak = BackupFile $f
$raw = Get-Content -LiteralPath $f -Raw

$log += "## Backup"
$log += ("- {0}" -f $bak)
$log += ""

$log += "## DIAG (antes)"
$log += ("- tem `${modelName}`? " + ($raw -match '\$\{modelName\}'))
$log += ""

# Corrige exatamente o padrão quebrado: tried.push(${modelName} -> );
$fixed = $raw

# 1) replace robusto (com espaços variáveis)
$fixed = $fixed -replace 'tried\.push\(\s*\$\{modelName\}\s*-\s*>\s*\)\s*;', 'tried.push(modelName + " -> " + (key ?? "null"));'

# 2) fallback: se por algum motivo estiver sem espaços, tenta exato
$fixed = $fixed -replace 'tried\.push\(\$\{modelName\}\s*-\>\s*\)\s*;', 'tried.push(modelName + " -> " + (key ?? "null"));'

if($fixed -eq $raw){
  $log += "## PATCH"
  $log += "- Nenhuma mudança aplicada (padrão não encontrado)."
} else {
  WriteUtf8NoBom $f $fixed
  $log += "## PATCH"
  $log += "- Linha inválida substituída por concatenação segura."
}

$after = Get-Content -LiteralPath $f -Raw
$log += ""
$log += "## DIAG (depois)"
$log += ("- tem `${modelName}`? " + ($after -match '\$\{modelName\}'))
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")
Write-Host ("✅ HOTFIX aplicado. Report -> {0}" -f $rep) -ForegroundColor Green

Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) Teste manual: irm http://localhost:3000/api/receipts -SkipHttpErrorCheck | select -Expand Content" -ForegroundColor Yellow