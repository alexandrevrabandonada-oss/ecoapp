$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# --- bootstrap (se existir) ---
$boot = Join-Path $PSScriptRoot '_bootstrap.ps1'
if(Test-Path -LiteralPath $boot){
  . $boot
} else {
  function EnsureDir([string]$p){ if($p -and !(Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
  function WriteUtf8NoBom([string]$p,[string]$c){ $d=Split-Path -Parent $p; if($d){EnsureDir $d}; $e=New-Object System.Text.UTF8Encoding($false); [System.IO.File]::WriteAllText($p,$c,$e) }
  function BackupFile([string]$p){ if(!(Test-Path -LiteralPath $p)){ return $null }; EnsureDir 'tools/_patch_backup'; $ts=Get-Date -Format 'yyyyMMdd-HHmmss'; $safe=($p -replace '[\\/:*?""<>|]','_'); $dst='tools/_patch_backup/'+$ts+'-'+$safe; Copy-Item -Force -LiteralPath $p $dst; return $dst }
  function NewReport([string]$n){ EnsureDir 'reports'; $ts=Get-Date -Format 'yyyyMMdd-HHmmss'; return 'reports/'+$ts+'-'+$n+'.md' }
}

$rep = NewReport 'eco-step-50b-fix-prisma-exec-and-run-migrate'
$log = @()
$log += '# ECO — STEP 50B — Fix Prisma exec (no npx) + migrate'
$log += ''
$log += ('Data: {0}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
$log += ('PWD : {0}' -f (Get-Location).Path)
$log += ''

try {
  # GUARDS
  if(!(Test-Path -LiteralPath 'package.json')){ throw 'GUARD: package.json não encontrado (rode no repo certo).' }
  if(!(Test-Path -LiteralPath 'prisma/schema.prisma')){ throw 'GUARD: prisma/schema.prisma não encontrado.' }

  $pkg = Get-Content -LiteralPath 'package.json' -Raw
  $hasPrismaDev = ($pkg -match '\"prisma\"\\s*:\\s*\"')
  $hasPrismaClient = ($pkg -match '\"@prisma/client\"\\s*:\\s*\"')

  $log += '## DIAG'
  $log += ('hasPrisma(devDep): {0}' -f $hasPrismaDev)
  $log += ('has@prisma/client : {0}' -f $hasPrismaClient)
  $log += ''

  # Ensure deps (best-effort)
  if(-not $hasPrismaDev){
    $log += '## PATCH — npm i -D prisma'
    npm i -D prisma
    $log += '- OK: prisma instalado (devDependency).'
    $log += ''
  }
  if(-not $hasPrismaClient){
    $log += '## PATCH — npm i @prisma/client'
    npm i @prisma/client
    $log += '- OK: @prisma/client instalado.'
    $log += ''
  }

  # Find prisma.cmd
  $prismaCmd = Join-Path (Get-Location).Path 'node_modules\.bin\prisma.cmd'
  if(!(Test-Path -LiteralPath $prismaCmd)){
    # fallback attempt: npm exec (sem npx)
    $log += '## WARN'
    $log += 'Não achei node_modules\.bin\prisma.cmd. Tentando via npm exec -- prisma ...'
    $log += ''
    npm exec -- prisma -v | Out-Null
  }

  # Re-check
  if(!(Test-Path -LiteralPath $prismaCmd)){
    throw 'Não consegui resolver prisma.cmd em node_modules\.bin. Rode: npm i -D prisma && npm i @prisma/client e tente de novo.'
  }

  $log += '## RUN — prisma format'
  & $prismaCmd format
  $log += '- OK: format'
  $log += ''

  $log += '## RUN — prisma migrate dev'
  # nome fixo (idempotente: se já existir, ele só aplica o que falta)
  & $prismaCmd migrate dev --name eco_day_close
  $log += '- OK: migrate dev'
  $log += ''

  $log += '## RUN — prisma generate'
  & $prismaCmd generate
  $log += '- OK: generate'
  $log += ''

  WriteUtf8NoBom $rep ($log -join "
")
  Write-Host ("✅ STEP 50B aplicado. Report -> {0}" -f $rep) -ForegroundColor Green

  Write-Host "VERIFY:" -ForegroundColor Yellow
  Write-Host "1) npm run dev" -ForegroundColor Yellow
  Write-Host "2) GET /api/eco/day-close?day=2025-12-26 (agora deve 404 not_found, não 503)" -ForegroundColor Yellow
  Write-Host "3) /s/dia/2025-12-26 -> Auto preencher (triagem) e Salvar fechamento" -ForegroundColor Yellow
} catch {
  try { WriteUtf8NoBom $rep ($log -join "
") } catch {}
  throw
}