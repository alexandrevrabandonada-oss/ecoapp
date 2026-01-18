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
      $val = $Matches[1].Trim().Trim('"').Trim("'")
      return $val
    }
  }
  return $null
}
function FindPrismaCmd(){
  foreach($c in @("node_modules\.bin\prisma.cmd","node_modules\.bin\prisma")){
    if(Test-Path -LiteralPath $c){ return (Resolve-Path -LiteralPath $c).Path }
  }
  return $null
}
function Run([string]$title, [scriptblock]$sb){
  Write-Host $title -ForegroundColor Cyan
  $out = & $sb 2>&1 | Out-String
  $code = $LASTEXITCODE
  return @{ out = $out; code = $code }
}

$rep = NewReport "eco-step-10h2-ensure-prisma-cli-and-push-safe"
$log = @()
$log += "# ECO — STEP 10h2 — Ensure Prisma CLI + db push (corrigir drift status)"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

$schema = "prisma/schema.prisma"
if(!(Test-Path -LiteralPath $schema)){ throw "Não achei $schema" }

# DATABASE_URL
$dbUrl = $env:DATABASE_URL
if(-not $dbUrl){
  foreach($f in @(".env",".env.local",".env.development","prisma/.env")){
    $v = ReadEnvValue $f "DATABASE_URL"
    if($v){ $dbUrl = $v; break }
  }
}
if(-not $dbUrl){ $dbUrl = "file:./prisma/dev.db" }
$env:DATABASE_URL = $dbUrl

# db path (sqlite)
$dbPath = $null
if($dbUrl -match "^file:(.+)$"){
  $p = $Matches[1].Trim()
  $p = $p.TrimStart("/")
  if($p.StartsWith("./")){ $p = $p.Substring(2) }
  $dbPath = Join-Path (Get-Location).Path $p
}

$log += "## DIAG"
$log += ("Schema: {0}" -f $schema)
$log += ("DATABASE_URL: {0}" -f $dbUrl)
$log += ("SQLite path: {0}" -f ($dbPath ?? "(não-file:)"))
$log += ""

# Prisma CLI local (sem npx)
$prismaCmd = FindPrismaCmd
$log += "## PRISMA CLI"
$log += ("Prisma local: {0}" -f ($prismaCmd ?? "NÃO ENCONTRADO"))
$log += ""

if(-not $prismaCmd){
  $r = Run "== npm i -D prisma ==" { npm i -D prisma }
  $log += "### npm i -D prisma"
  $log += "~~~"
  $log += $r.out.TrimEnd()
  $log += "~~~"
  if($r.code -ne 0){
    WriteUtf8NoBom $rep ($log -join "`n")
    throw "Falhou instalar prisma CLI. Veja: $rep"
  }
  $prismaCmd = FindPrismaCmd
  $log += ("Prisma local (depois): {0}" -f ($prismaCmd ?? "ainda não encontrado"))
  $log += ""
  if(-not $prismaCmd){
    WriteUtf8NoBom $rep ($log -join "`n")
    throw "Instalei prisma mas não encontrei node_modules\.bin\prisma(.cmd). Veja: $rep"
  }
}

# backup DB
$log += "## BACKUP"
if($dbPath -and (Test-Path -LiteralPath $dbPath)){
  $bak = BackupFile $dbPath
  $log += ("DB backup: {0}" -f $bak)
} else {
  $log += "DB não encontrado (ainda) — seguindo."
}
$log += ""

# db push
$log += "## DB PUSH"
$r1 = Run "== prisma db push --accept-data-loss ==" { & $prismaCmd db push --accept-data-loss }
$log += "~~~"
$log += $r1.out.TrimEnd()
$log += "~~~"
$log += ("ExitCode: {0}" -f $r1.code)
$log += ""

if($r1.code -ne 0){
  $log += "## FORCE RESET (fallback)"
  $r2 = Run "== prisma db push --force-reset --accept-data-loss ==" { & $prismaCmd db push --force-reset --accept-data-loss }
  $log += "~~~"
  $log += $r2.out.TrimEnd()
  $log += "~~~"
  $log += ("ExitCode(force-reset): {0}" -f $r2.code)
  $log += ""
  if($r2.code -ne 0){
    WriteUtf8NoBom $rep ($log -join "`n")
    throw "Prisma db push falhou mesmo com --force-reset. Veja o report: $rep"
  }
}

# generate
$log += "## GENERATE"
$rg = Run "== prisma generate ==" { & $prismaCmd generate }
$log += "~~~"
$log += $rg.out.TrimEnd()
$log += "~~~"
$log += ("ExitCode(generate): {0}" -f $rg.code)
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 10h2 aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) npm run dev" -ForegroundColor Yellow
Write-Host "2) pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) /api/pickup-requests deve voltar 200 (sem erro do status)" -ForegroundColor Yellow