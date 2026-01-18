$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

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
  EnsureDir 'tools/_patch_backup'
  $ts = Get-Date -Format 'yyyyMMdd-HHmmss'
  $safe = ($path -replace '[\\/:*?"<>|]', '_')
  $dst = ('tools/_patch_backup/{0}-{1}' -f $ts, $safe)
  Copy-Item -Force -LiteralPath $path $dst
  return $dst
}
function NewReport([string]$name){
  EnsureDir 'reports'
  $ts = Get-Date -Format 'yyyyMMdd-HHmmss'
  return ('reports/{0}-{1}.md' -f $ts, $name)
}

$rep = NewReport 'eco-step-51-doctor-and-new-tijolo'
$log = @()
$log += '# ECO — STEP 51 — Doctor + New Tijolo'
$log += ''
$log += ('Data: {0}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
$log += ('PWD : {0}' -f (Get-Location).Path)
$log += ''

try {
  # 0) Guard repo
  if(!(Test-Path -LiteralPath 'package.json')){ throw 'GUARD: rode na raiz do repo (package.json não encontrado).' }
  if(!(Test-Path -LiteralPath 'src')){ throw 'GUARD: pasta src não encontrada; confirme o repo.' }

  # 1) Garantir bootstrap (se já existir, não mexe)
  $boot = 'tools/_bootstrap.ps1'
  if(!(Test-Path -LiteralPath $boot)){
    EnsureDir 'tools'
    $bootLines = @(
      '$ErrorActionPreference = ''Stop'''
      'Set-StrictMode -Version Latest'
      ''
      'function EnsureDir([string]$p){'
      '  if($p -and !(Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null }'
      '}'
      'function WriteUtf8NoBom([string]$path, [string]$content){'
      '  $dir = Split-Path -Parent $path'
      '  if($dir){ EnsureDir $dir }'
      '  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)'
      '  [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)'
      '}'
      'function BackupFile([string]$path){'
      '  if(!(Test-Path -LiteralPath $path)){ return $null }'
      '  EnsureDir ''tools/_patch_backup'''
      '  $ts = Get-Date -Format ''yyyyMMdd-HHmmss'''
      '  $safe = ($path -replace ''[\\/:*?"<>|]'', ''_'')'
      '  $dst = (''tools/_patch_backup/{0}-{1}'' -f $ts, $safe)'
      '  Copy-Item -Force -LiteralPath $path $dst'
      '  return $dst'
      '}'
      'function NewReport([string]$name){'
      '  EnsureDir ''reports'''
      '  $ts = Get-Date -Format ''yyyyMMdd-HHmmss'''
      '  return (''reports/{0}-{1}.md'' -f $ts, $name)'
      '}'
    )
    WriteUtf8NoBom $boot ($bootLines -join "`n")
    $log += '## PATCH — bootstrap'
    $log += ('Criado: {0}' -f $boot)
    $log += ''
  } else {
    $log += '## OK — bootstrap já existe'
    $log += ('Arquivo: {0}' -f $boot)
    $log += ''
  }

  # 2) Criar DOCTOR
  $doctor = 'tools/eco-doctor.ps1'
  $bkD = BackupFile $doctor
  $doctorLines = @(
    '$ErrorActionPreference = ''Stop'''
    'Set-StrictMode -Version Latest'
    'if(-not $PSCommandPath){ throw ''Rode este script com: pwsh -NoProfile -ExecutionPolicy Bypass -File tools\eco-doctor.ps1'' }'
    '$repo = (Resolve-Path (Join-Path $PSScriptRoot ''..'')).Path'
    'Write-Host ''== ECO DOCTOR =='' -ForegroundColor Cyan'
    'Write-Host (''Repo: {0}'' -f $repo) -ForegroundColor DarkGray'
    'Push-Location $repo'
    'try {'
    '  $ok = $true'
    '  if(!(Test-Path -LiteralPath ''package.json'')){ Write-Host ''FAIL: package.json ausente'' -ForegroundColor Red; $ok=$false }'
    '  if(!(Test-Path -LiteralPath ''prisma/schema.prisma'')){ Write-Host ''WARN: prisma/schema.prisma ausente'' -ForegroundColor Yellow }'
    '  if(!(Test-Path -LiteralPath ''tools/_bootstrap.ps1'')){ Write-Host ''WARN: tools/_bootstrap.ps1 ausente'' -ForegroundColor Yellow }'
    '  $prismaCmd = ''.\node_modules\.bin\prisma.cmd'''
    '  if(!(Test-Path -LiteralPath $prismaCmd)){ Write-Host ''WARN: prisma.cmd não encontrado (instale prisma/@prisma-client)'' -ForegroundColor Yellow }'
    '  $route = ''src/app/api/share/route-day-card/route.ts'''
    '  if(Test-Path -LiteralPath $route){'
    '    $txt = Get-Content -LiteralPath $route -Raw'
    '    if($txt -match ''<div''){ Write-Host ''WARN: route.ts contém JSX (<div). Em route.ts use React.createElement.'' -ForegroundColor Yellow }'
    '    if($txt -notmatch ''ImageResponse''){ Write-Host ''WARN: route-day-card sem ImageResponse?'' -ForegroundColor Yellow }'
    '  } else { Write-Host ''WARN: route-day-card não encontrado'' -ForegroundColor Yellow }'
    '  if($ok){ Write-Host ''OK: checks básicos passaram.'' -ForegroundColor Green }'
    '} finally { Pop-Location }'
  )
  WriteUtf8NoBom $doctor ($doctorLines -join "`n")

  $log += '## PATCH — eco-doctor'
  $log += ('Backup: {0}' -f ($(if($bkD){$bkD}else{'(novo)'})))
  $log += ('Criado: {0}' -f $doctor)
  $log += ''

  # 3) Criar gerador new-tijolo
  $newT = 'tools/new-tijolo.ps1'
  $bkN = BackupFile $newT
  $newLines = @(
    'param([Parameter(Mandatory=$true)][string]$Name)'
    '$ErrorActionPreference = ''Stop'''
    'Set-StrictMode -Version Latest'
    'if(-not $PSCommandPath){ throw ''Rode este script com: pwsh -File tools\new-tijolo.ps1 -Name <nome>'' }'
    '. (Join-Path $PSScriptRoot ''_bootstrap.ps1'')'
    '$file = Join-Path $PSScriptRoot (''eco-step-'' + $Name + ''.ps1'')'
    'if(Test-Path -LiteralPath $file){ throw (''Já existe: {0}'' -f $file) }'
    '$lines = @('
    '  ''$ErrorActionPreference = ''''Stop'''''''
    '  ''Set-StrictMode -Version Latest'''
    '  ''if(-not $PSCommandPath){ throw ''''Rode este script com pwsh -File (não cole no prompt)'''' }'''
    '  ''. (Join-Path $PSScriptRoot ''''_bootstrap.ps1'''')'''
    '  '''''
    '  ''$rep = NewReport ''''eco-step-XXXX'''''''
    '  ''$log = @()'''
    '  ''$log += ''''# ECO — STEP XXXX'''''''
    '  ''$log += '''''''''
    '  ''try {'''
    '  ''  # DIAG'''
    '  ''  # PATCH'''
    '  ''  # VERIFY (no report)'''
    '  ''} catch {'''
    '  ''  try { WriteUtf8NoBom $rep ($log -join "``n") } catch {}'''
    '  ''  throw'''
    '  ''}'''
    '  ''WriteUtf8NoBom $rep ($log -join "``n")'''
    '  ''Write-Host ("✅ OK. Report -> {0}" -f $rep) -ForegroundColor Green'''
    ')'
    'WriteUtf8NoBom $file ($lines -join "`n")'
    'Write-Host (''Criado: {0}'' -f $file) -ForegroundColor Green'
  )
  WriteUtf8NoBom $newT ($newLines -join "`n")

  $log += '## PATCH — new-tijolo'
  $log += ('Backup: {0}' -f ($(if($bkN){$bkN}else{'(novo)'})))
  $log += ('Criado: {0}' -f $newT)
  $log += ''

  WriteUtf8NoBom $rep ($log -join "`n")
  Write-Host ('✅ STEP 51 aplicado. Report -> {0}' -f $rep) -ForegroundColor Green
  Write-Host 'VERIFY:' -ForegroundColor Yellow
  Write-Host '1) pwsh -NoProfile -ExecutionPolicy Bypass -File tools\eco-doctor.ps1' -ForegroundColor Yellow
  Write-Host '2) pwsh -NoProfile -ExecutionPolicy Bypass -File tools\new-tijolo.ps1 -Name 52-minha-proxima-feature' -ForegroundColor Yellow
} catch {
  try { WriteUtf8NoBom $rep ($log -join "`n") } catch {}
  throw
}