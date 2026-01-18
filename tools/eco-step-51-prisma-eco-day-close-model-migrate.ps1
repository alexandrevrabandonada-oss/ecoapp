$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# ---- bootstrap (preferencial) ----
$bootstrap = Join-Path (Split-Path -Parent $PSCommandPath) "_bootstrap.ps1"
if(Test-Path -LiteralPath $bootstrap){
  . $bootstrap
} else {
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
}

function ResolvePrismaCmd(){
  $cmd = ".\node_modules\.bin\prisma.cmd"
  if(Test-Path -LiteralPath $cmd){ return $cmd }
  return $null
}

function EnsurePrismaDeps([ref]$log){
  $pr = ResolvePrismaCmd
  if($pr){ return }

  $log.Value += "## DIAG — Prisma CLI ausente"
  $log.Value += "- Instalando prisma + @prisma/client..."
  $log.Value += ""

  & npm i -D prisma | Out-Null
  & npm i @prisma/client | Out-Null
}

function RunPrisma([string[]]$args, [ref]$outLines){
  $cmd = ResolvePrismaCmd
  if(-not $cmd){ throw "Prisma CLI não encontrado em .\node_modules\.bin\prisma.cmd" }
  $out = & $cmd @args 2>&1
  $outLines.Value = @($out)
  return $LASTEXITCODE
}

$rep = NewReport "eco-step-51-prisma-eco-day-close-model-migrate"
$log = @()
$log += "# ECO — STEP 51 — Prisma EcoDayClose (model + migrate)"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

try {
  # -------------------------
  # DIAG
  # -------------------------
  if(!(Test-Path -LiteralPath "prisma/schema.prisma")){
    throw "GUARD: não achei prisma/schema.prisma"
  }

  EnsurePrismaDeps ([ref]$log)

  $schemaPath = "prisma/schema.prisma"
  $schemaRaw  = Get-Content -Raw -LiteralPath $schemaPath

  $log += "## DIAG — schema.prisma"
  $log += ("- Tamanho: {0} chars" -f $schemaRaw.Length)
  $log += ""

  # -------------------------
  # PATCH — adicionar model EcoDayClose se faltar
  # -------------------------
  if($schemaRaw -match "model\s+EcoDayClose"){
    $log += "## PATCH — model EcoDayClose"
    $log += "- OK: já existe (nenhuma alteração)."
    $log += ""
  } else {
    $bk = BackupFile $schemaPath
    $log += "## PATCH — model EcoDayClose"
    $log += ("Backup: {0}" -f $bk)
    $log += "- Inserindo model EcoDayClose no final do schema."
    $log += ""

    $model = @"
model EcoDayClose {
  day       String   @id
  summary   Json
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}
"@

    $schemaNew = ($schemaRaw.TrimEnd() + "`n`n" + $model + "`n")
    WriteUtf8NoBom $schemaPath $schemaNew
  }

  # -------------------------
  # PRISMA: format + migrate dev + generate
  # -------------------------
  $log += "## PRISMA — format"
  $out = @()
  $exit = RunPrisma @("format") ([ref]$out)
  $log += ($out | Select-Object -First 30)
  $log += ("- ExitCode: {0}" -f $exit)
  $log += ""

  $log += "## PRISMA — migrate dev (eco_day_close)"
  $out2 = @()
  $exit2 = RunPrisma @("migrate","dev","--name","eco_day_close") ([ref]$out2)
  $text2 = ($out2 -join "`n")
  $log += ($out2 | Select-Object -First 80)
  $log += ("- ExitCode: {0}" -f $exit2)
  $log += ""

  $needReset = $false
  if($exit2 -ne 0){ $needReset = $true }
  if($text2.ToLower().Contains("drift detected")){ $needReset = $true }
  if($text2.ToLower().Contains("we need to reset")){ $needReset = $true }

  if($needReset){
    $log += "## PRISMA — drift/reset detectado (auto-fix)"
    $db1 = "prisma/dev.db"
    $db2 = "dev.db"
    if(Test-Path -LiteralPath $db1){
      $bkdb = BackupFile $db1
      $log += ("- Backup dev.db: {0}" -f $bkdb)
    } elseif(Test-Path -LiteralPath $db2){
      $bkdb = BackupFile $db2
      $log += ("- Backup dev.db: {0}" -f $bkdb)
    } else {
      $log += "- dev.db não encontrado para backup (ok)."
    }

    $outR = @()
    $exitR = RunPrisma @("migrate","reset","--force") ([ref]$outR)
    $log += "- migrate reset --force:"
    $log += ($outR | Select-Object -First 80)
    $log += ("- ExitCode: {0}" -f $exitR)
    $log += ""

    $outM = @()
    $exitM = RunPrisma @("migrate","dev","--name","eco_day_close") ([ref]$outM)
    $log += "- migrate dev (depois do reset):"
    $log += ($outM | Select-Object -First 80)
    $log += ("- ExitCode: {0}" -f $exitM)
    $log += ""
  }

  $log += "## PRISMA — generate"
  $out3 = @()
  $exit3 = RunPrisma @("generate") ([ref]$out3)
  $log += ($out3 | Select-Object -First 60)
  $log += ("- ExitCode: {0}" -f $exit3)
  $log += ""

  WriteUtf8NoBom $rep ($log -join "`n")
  Write-Host ("✅ STEP 51 aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
  Write-Host "VERIFY:" -ForegroundColor Yellow
  Write-Host "1) CTRL+C (se dev rodando) e npm run dev" -ForegroundColor Yellow
  Write-Host "2) GET /api/eco/day-close?day=2025-12-26 (esperado 404 ou 200, NÃO 503)" -ForegroundColor Yellow
  Write-Host "3) (Opcional) POST /api/eco/day-close com JSON { day: '2025-12-26', summary: {...} }" -ForegroundColor Yellow

} catch {
  try { WriteUtf8NoBom $rep ($log -join "`n") } catch {}
  throw
}