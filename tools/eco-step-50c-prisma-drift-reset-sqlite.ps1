$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function EnsureDir([string]$p){
  if($p -and !(Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null }
}
function NewReport([string]$name){
  EnsureDir "reports"
  $ts = Get-Date -Format "yyyyMMdd-HHmmss"
  return "reports/$ts-$name.md"
}

$rep = NewReport "eco-step-50c-prisma-drift-reset-sqlite"
$log = @()
$log += "# ECO — STEP 50C — Prisma drift (SQLite) reset seguro"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

try {
  if(!(Test-Path -LiteralPath "prisma/schema.prisma")){ throw "Não achei prisma/schema.prisma (rode no repo certo)." }

  # Prisma bin local (Windows)
  $prisma = ".\node_modules\.bin\prisma.cmd"
  if(!(Test-Path -LiteralPath $prisma)){
    throw "Não achei $prisma. Rode: npm i -D prisma ; npm i @prisma/client"
  }

  $db = "prisma/dev.db"
  if(Test-Path -LiteralPath $db){
    EnsureDir "tools/_db_backup"
    $ts = Get-Date -Format "yyyyMMdd-HHmmss"
    $bk = "tools/_db_backup/$ts-dev.db"
    Copy-Item -Force -LiteralPath $db $bk
    $log += "## BACKUP"
    $log += ("Backup dev.db -> {0}" -f $bk)
    $log += ""
  } else {
    $log += "## BACKUP"
    $log += "dev.db não existe (ok)"
    $log += ""
  }

  $log += "## RESET + MIGRATE"
  $log += "- Rodando: prisma migrate reset --force"
  & $prisma migrate reset --force | ForEach-Object { $log += $_ }
  $log += ""

  $log += "- Rodando: prisma migrate dev (aplica migrations)"
  & $prisma migrate dev | ForEach-Object { $log += $_ }
  $log += ""

  $log += "- Rodando: prisma generate"
  & $prisma generate | ForEach-Object { $log += $_ }
  $log += ""

  $log += "✅ OK: reset + migrate + generate concluídos."
  $log -join "`n" | Set-Content -LiteralPath $rep -Encoding utf8
  Write-Host hookup
  Write-Host ("✅ STEP 50C aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
  Write-Host "VERIFY:" -ForegroundColor Yellow
  Write-Host "1) npm run dev" -ForegroundColor Yellow
  Write-Host "2) GET /api/eco/day-close?day=2025-12-26 (esperado 404 not_found OU 200 se já salvou)" -ForegroundColor Yellow
  Write-Host "3) Abra /s/dia/2025-12-26 e tente 'Auto preencher (triagem)' + salvar" -ForegroundColor Yellow

} catch {
  try { $log -join "`n" | Set-Content -LiteralPath $rep -Encoding utf8 } catch {}
  throw
}