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
function RunCmd([string]$title, [string[]]$args){
  Write-Host ("== {0} ==" -f $title) -ForegroundColor Cyan
  Write-Host ("npx {0}" -f ($args -join " ")) -ForegroundColor DarkGray
  & npx @args
}

$rep = NewReport "eco-step-10f-fix-db-drift-pickup-status"
$log = @()
$log += "# ECO — STEP 10f — Fix drift DB (PickupRequest.status missing)"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

# =========
# DIAG: achar schema
# =========
$schema = $null
if(Test-Path -LiteralPath "prisma/schema.prisma"){ $schema = "prisma/schema.prisma" }
elseif(Test-Path -LiteralPath "schema.prisma"){ $schema = "schema.prisma" }
else{
  $found = Get-ChildItem -Recurse -File -Filter "schema.prisma" -ErrorAction SilentlyContinue | Select-Object -First 1
  if($found){ $schema = $found.FullName }
}
if(-not $schema){ throw "Não achei schema.prisma (procurei em prisma/schema.prisma e recursivo)." }

$log += "## DIAG"
$log += ("Schema: {0}" -f $schema)

# =========
# DIAG: tentar achar DB para backup
# =========
$dbPick = $null
$dbCandidates = @()
if(Test-Path -LiteralPath "prisma"){
  $dbCandidates += Get-ChildItem -File -Path "prisma" -Filter "*.db" -ErrorAction SilentlyContinue
}
if(-not $dbCandidates){
  $dbCandidates += Get-ChildItem -File -Path "." -Filter "*.db" -ErrorAction SilentlyContinue
}
if($dbCandidates){
  $dbPick = $dbCandidates | Sort-Object LastWriteTime -Descending | Select-Object -First 1
}

if($dbPick){
  $bakDb = BackupFile $dbPick.FullName
  $log += ("DB (backup): {0}" -f $bakDb)
}else{
  $log += "DB (backup): não encontrei *.db (ok, pode estar fora do repo)."
}
$log += ""

# =========
# PATCH: db push (sincroniza schema -> DB)
# =========
$log += "## PATCH"
$log += "- Tentando: npx prisma db push (sync schema->DB)"
$log += ""

$pushOk = $false
try {
  RunCmd "PRISMA DB PUSH" @("prisma","db","push","--schema",$schema)
  $pushOk = $true
} catch {
  $pushOk = $false
  $log += ("- db push falhou: {0}" -f $_.Exception.Message)
}

# =========
# Fallback: adiciona só a coluna status via db execute (SQLite)
# =========
if(-not $pushOk){
  $log += ""
  $log += "## FALLBACK"
  $log += "- Tentando adicionar coluna status manualmente via prisma db execute (sem reset)."

  EnsureDir "tools/_tmp"
  $sqlFile = "tools/_tmp/eco-add-pickup-status.sql"

  # Nota: se já existir, SQLite pode dar "duplicate column name", vamos aceitar como OK.
  $sql = @"
ALTER TABLE "PickupRequest" ADD COLUMN "status" TEXT;
"@

  WriteUtf8NoBom $sqlFile $sql

  try {
    RunCmd "PRISMA DB EXECUTE" @("prisma","db","execute","--schema",$schema,"--file",$sqlFile)
    $pushOk = $true
    $log += "- OK: coluna status adicionada via SQL."
  } catch {
    # Se for duplicate column, tratamos como ok
    $msg = $_.Exception.Message
    if($msg -match "duplicate column name" -or $msg -match "already exists"){
      $pushOk = $true
      $log += "- OK: status já existia (duplicate column)."
    } else {
      $log += ("- FAIL fallback db execute: {0}" -f $msg)
      throw
    }
  }
}

# =========
# VERIFY: generate (cliente)
# =========
$log += ""
$log += "## VERIFY"
$log += "- Rodando: npx prisma generate"
RunCmd "PRISMA GENERATE" @("prisma","generate","--schema",$schema)

$log += ""
$log += "## Próximos passos"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1"
$log += "3) Confirme /api/pickup-requests = 200"
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")
Write-Host ("✅ STEP 10f aplicado. Report -> {0}" -f $rep) -ForegroundColor Green