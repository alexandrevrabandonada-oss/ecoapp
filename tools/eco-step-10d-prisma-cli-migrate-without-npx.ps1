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
function GetSchemaPath(){
  $cands = @("prisma/schema.prisma","src/prisma/schema.prisma","schema.prisma")
  foreach($c in $cands){ if(Test-Path -LiteralPath $c){ return $c } }
  return $null
}

$rep = NewReport "eco-step-10d-prisma-cli-migrate-without-npx"
$log = @()
$log += "# ECO — STEP 10d — Prisma CLI + migrate/generate (sem npx)"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

$schema = GetSchemaPath
if(-not $schema){ throw "Não achei schema.prisma." }

$log += "## DIAG"
$log += ("Schema: {0}" -f $schema)

$schemaTxt = Get-Content -LiteralPath $schema -Raw
$hasPublicField = ($schemaTxt -match '(?ms)model\s+\w*(Receipt|Recibo)\w*\s*\{.*?^\s*public\s+Boolean\b')
$log += ("Receipt/Recibo tem field public? {0}" -f $hasPublicField)

$prismaCmd = Join-Path (Get-Location).Path "node_modules\.bin\prisma.cmd"
$prismaSh  = Join-Path (Get-Location).Path "node_modules\.bin\prisma"
$prismaBin = $null

if(Test-Path -LiteralPath $prismaCmd){ $prismaBin = $prismaCmd }
elseif(Test-Path -LiteralPath $prismaSh){ $prismaBin = $prismaSh }

$log += ("Prisma bin exists? {0}" -f ([bool]$prismaBin))
$log += ""

if(-not $prismaBin){
  $log += "## INSTALL"
  $log += "- Instalando prisma (devDependency) porque não achei node_modules/.bin/prisma*"
  $log += ""
  WriteUtf8NoBom $rep ($log -join "`n")

  & npm i -D prisma

  if(Test-Path -LiteralPath $prismaCmd){ $prismaBin = $prismaCmd }
  elseif(Test-Path -LiteralPath $prismaSh){ $prismaBin = $prismaSh }

  if(-not $prismaBin){
    $log = Get-Content -LiteralPath $rep -Raw -ErrorAction SilentlyContinue
    throw "Instalei prisma mas ainda não encontrei node_modules/.bin/prisma(.cmd)."
  }
}

$log += "## RUN"
$log += ("Usando bin: {0}" -f $prismaBin)
$log += ""

# prisma format
$log += "### prisma format"
& $prismaBin format | ForEach-Object { $log += $_ }

# migrate dev
$log += ""
$log += "### prisma migrate dev --name eco_receipt_public"
& $prismaBin migrate dev --name eco_receipt_public | ForEach-Object { $log += $_ }

# generate
$log += ""
$log += "### prisma generate"
& $prismaBin generate | ForEach-Object { $log += $_ }

$log += ""
$log += "## Próximos passos"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1"
$log += "3) Abra /recibo/[code] (STEP 10: toggle público/privado vem já já)"
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 10d aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) Reabra /recibos e /recibo/[code]" -ForegroundColor Yellow