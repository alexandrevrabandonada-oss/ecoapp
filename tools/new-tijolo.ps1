param([Parameter(Mandatory=$true)][string]$Name)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if(-not $PSCommandPath){ throw 'Rode este script com: pwsh -File tools\new-tijolo.ps1 -Name <nome>' }
. (Join-Path $PSScriptRoot '_bootstrap.ps1')
$file = Join-Path $PSScriptRoot ('eco-step-' + $Name + '.ps1')
if(Test-Path -LiteralPath $file){ throw ('Já existe: {0}' -f $file) }
$lines = @(
  '$ErrorActionPreference = ''Stop'''
  'Set-StrictMode -Version Latest'
  'if(-not $PSCommandPath){ throw ''Rode este script com pwsh -File (não cole no prompt)'' }'
  '. (Join-Path $PSScriptRoot ''_bootstrap.ps1'')'
  ''
  '$rep = NewReport ''eco-step-XXXX'''
  '$log = @()'
  '$log += ''# ECO — STEP XXXX'''
  '$log += ''''
  'try {'
  '  # DIAG'
  '  # PATCH'
  '  # VERIFY (no report)'
  '} catch {'
  '  try { WriteUtf8NoBom $rep ($log -join "``n") } catch {}'
  '  throw'
  '}'
  'WriteUtf8NoBom $rep ($log -join "``n")'
  'Write-Host ("✅ OK. Report -> {0}" -f $rep) -ForegroundColor Green'
)
WriteUtf8NoBom $file ($lines -join "`n")
Write-Host ('Criado: {0}' -f $file) -ForegroundColor Green