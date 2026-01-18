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

function ReadEnvValue([string]$file, [string]$key){
  if(!(Test-Path -LiteralPath $file)){ return $null }
  foreach($line in Get-Content -LiteralPath $file -ErrorAction SilentlyContinue){
    if($line -match "^\s*$key\s*=\s*(.+)\s*$"){
      $val = $Matches[1].Trim()
      $val = $val.Trim('"').Trim("'")
      return $val
    }
  }
  return $null
}

function FindPrismaCli(){
  $candidates = @(
    "node_modules\.bin\prisma.cmd",
    "node_modules\.bin\prisma"
  )
  foreach($c in $candidates){
    if(Test-Path -LiteralPath $c){
      return (Resolve-Path -LiteralPath $c).Path
    }
  }
  return $null
}

function RunPrisma([string[]]$args){
  if($script:PrismaCli){
    & $script:PrismaCli @args
    return $LASTEXITCODE
  }

  # Fallback (se não tiver bin local): npm exec
  & npm exec -- prisma -- @args
  return $LASTEXITCODE
}

$rep = NewReport "eco-step-10g-fix-db-pickup-status-column"
$log = @()
$log += "# ECO — STEP 10g — Fix DB drift (PickupRequest.status missing)"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

$schema = "prisma/schema.prisma"
if(!(Test-Path -LiteralPath $schema)){ throw "Não achei $schema" }

# tenta pegar DATABASE_URL do ambiente / .env
$dbUrl = $env:DATABASE_URL
if(-not $dbUrl){
  foreach($f in @(".env",".env.local",".env.development","prisma/.env")){
    $v = ReadEnvValue $f "DATABASE_URL"
    if($v){ $dbUrl = $v; break }
  }
}
if(-not $dbUrl){ $dbUrl = "file:./prisma/dev.db" }

# fixa env para o Prisma (evita apontar pro DB errado)
$env:DATABASE_URL = $dbUrl

# resolve caminho do sqlite (se for file:)
$dbPath = $null
if($dbUrl -match "^file:(.+)$"){
  $p = $Matches[1].Trim()
  $p = $p.TrimStart("/")
  if($p.StartsWith("./")){ $p = $p.Substring(2) }
  $dbPath = Join-Path (Get-Location).Path $p
}

$script:PrismaCli = FindPrismaCli

$log += "## DIAG"
$log += ("Schema: {0}" -f $schema)
$log += ("DATABASE_URL: {0}" -f $dbUrl)
$log += ("SQLite path: {0}" -f ($dbPath ?? "(não-file:)"))
$log += ("Prisma CLI: {0}" -f ($script:PrismaCli ?? "npm exec fallback"))
$log += ""

# backup do DB se existir
if($dbPath -and (Test-Path -LiteralPath $dbPath)){
  $bak = BackupFile $dbPath
  $log += "## BACKUP"
  $log += ("DB backup: {0}" -f $bak)
  $log += ""
} else {
  $log += "## BACKUP"
  $log += "DB não encontrado (ainda) — seguindo assim mesmo."
  $log += ""
}

$log += "## PATCH"
$log += "- Rodando: prisma db push"
$exit = RunPrisma @("db","push")
$log += ("ExitCode: {0}" -f $exit)
$log += ""

if($exit -ne 0){
  $log += "## PATCH (fallback)"
  $log += "- db push falhou. Rodando: prisma db push --force-reset (APAGA o dev.db; backup já foi feito acima se existia)"
  $exit2 = RunPrisma @("db","push","--force-reset")
  $log += ("ExitCode(force-reset): {0}" -f $exit2)
  $log += ""
  if($exit2 -ne 0){
    WriteUtf8NoBom $rep ($log -join "`n")
    throw "Prisma db push falhou mesmo com --force-reset. Veja o report: $rep"
  }
}

$log += "## VERIFY"
$log += "- Rodando: prisma generate"
$exitG = RunPrisma @("generate")
$log += ("ExitCode(generate): {0}" -f $exitG)
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 10g aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) Confirme /api/pickup-requests = 200 (sem erro do status)" -ForegroundColor Yellow