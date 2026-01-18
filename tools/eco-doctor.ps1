$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if(-not $PSCommandPath){ throw 'Rode este script com: pwsh -NoProfile -ExecutionPolicy Bypass -File tools\eco-doctor.ps1' }
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Write-Host '== ECO DOCTOR ==' -ForegroundColor Cyan
Write-Host ('Repo: {0}' -f $repo) -ForegroundColor DarkGray
Push-Location $repo
try {
  $ok = $true
  if(!(Test-Path -LiteralPath 'package.json')){ Write-Host 'FAIL: package.json ausente' -ForegroundColor Red; $ok=$false }
  if(!(Test-Path -LiteralPath 'prisma/schema.prisma')){ Write-Host 'WARN: prisma/schema.prisma ausente' -ForegroundColor Yellow }
  if(!(Test-Path -LiteralPath 'tools/_bootstrap.ps1')){ Write-Host 'WARN: tools/_bootstrap.ps1 ausente' -ForegroundColor Yellow }
  $prismaCmd = '.\node_modules\.bin\prisma.cmd'
  if(!(Test-Path -LiteralPath $prismaCmd)){ Write-Host 'WARN: prisma.cmd não encontrado (instale prisma/@prisma-client)' -ForegroundColor Yellow }
  $route = 'src/app/api/share/route-day-card/route.ts'
  if(Test-Path -LiteralPath $route){
    $txt = Get-Content -LiteralPath $route -Raw
    if($txt -match '<div'){ Write-Host 'WARN: route.ts contém JSX (<div). Em route.ts use React.createElement.' -ForegroundColor Yellow }
    if($txt -notmatch 'ImageResponse'){ Write-Host 'WARN: route-day-card sem ImageResponse?' -ForegroundColor Yellow }
  } else { Write-Host 'WARN: route-day-card não encontrado' -ForegroundColor Yellow }
  if($ok){ Write-Host 'OK: checks básicos passaram.' -ForegroundColor Green }
} finally { Pop-Location }