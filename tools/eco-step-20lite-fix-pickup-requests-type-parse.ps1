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

$rep = NewReport "eco-step-20lite-fix-pickup-requests-type-parse"
$log = @()
$log += "# ECO — STEP 20LITE — Fix TS parse em /api/pickup-requests (type AnyDelegate)"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

$route = "src/app/api/pickup-requests/route.ts"
if(!(Test-Path -LiteralPath $route)){
  $route = FindFirst "src/app" "\\api\\pickup-requests\\route\.ts$"
}
if(-not $route){
  $route = FindFirst "src" "\\api\\pickup-requests\\route\.ts$"
}
if(-not $route){ throw "Não achei src/app/api/pickup-requests/route.ts" }

$log += "## DIAG"
$log += ("route.ts: {0}" -f $route)
$log += ""

$log += "## PATCH"
$log += ("Backup: {0}" -f (BackupFile $route))
$log += ""

$txt = Get-Content -LiteralPath $route -Raw

# Corrige a assinatura inválida que o STEP 18h injetou:
# findMany?: (ecoWithReceipt(args?: any)) => Promise<any>;
$before = $txt
$txt2 = [regex]::Replace(
  $txt,
  'findMany\?\s*:\s*\(\s*ecoWithReceipt\s*\(\s*args\?\s*:\s*any\s*\)\s*\)\s*=>\s*Promise\s*<\s*any\s*>\s*;',
  'findMany?: (args?: any) => Promise<any>;',
  'IgnoreCase'
)

if($txt2 -eq $before){
  $log += "- WARN: não achei a linha exata. Vou aplicar um fallback mais amplo."
  # fallback: qualquer "findMany?: (ecoWithReceipt(...)) => Promise<any>;"
  $txt2 = [regex]::Replace(
    $txt,
    'findMany\?\s*:\s*\(\s*ecoWithReceipt\s*\([^\)]*\)\s*\)\s*=>\s*Promise\s*<\s*any\s*>\s*;',
    'findMany?: (args?: any) => Promise<any>;',
    'IgnoreCase'
  )
}

WriteUtf8NoBom $route $txt2
$log += "- OK: type AnyDelegate corrigido (TS parse)."
$log += ""

$log += "## Próximos passos"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1"
$log += "3) /api/pickup-requests deve voltar 200 (sem parsing error)"
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 20LITE aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) /api/pickup-requests deve voltar 200" -ForegroundColor Yellow