$ErrorActionPreference = "Stop"

function EnsureDir([string]$p){
  if($p -and !(Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null }
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

function ReadText([string]$p){
  if(!(Test-Path -LiteralPath $p)){ return "" }
  return (Get-Content -LiteralPath $p -Raw)
}

function Run([string]$cmd, [string[]]$args){
  & $cmd @args
  if($LASTEXITCODE -ne 0){
    throw ("Command failed: {0} {1}" -f $cmd, ($args -join " "))
  }
}

function PatchTsPickupInclude([string]$file){
  if(!(Test-Path -LiteralPath $file)){
    $script:log += ("SKIP missing: {0}" -f $file)
    return
  }

  $txt  = ReadText $file
  $orig = $txt

  # 1) garantir import Prisma + PrismaClient
  if($txt -match 'import\s+\{\s*PrismaClient\s*\}\s+from\s+"@prisma/client"'){
    $txt = $txt -replace 'import\s+\{\s*PrismaClient\s*\}\s+from\s+"@prisma/client"', 'import { Prisma, PrismaClient } from "@prisma/client"'
  } elseif($txt -match 'import\s+\{[^}]*PrismaClient[^}]*\}\s+from\s+"@prisma/client"' -and $txt -notmatch 'import\s+\{[^}]*\bPrisma\b[^}]*\}\s+from\s+"@prisma/client"'){
    # injeta Prisma no mesmo import
    $txt = [regex]::Replace($txt, '(import\s+\{)([^}]*PrismaClient[^}]*)(\}\s+from\s+"@prisma/client")', '$1 Prisma, $2$3')
  }

  # 2) inserir helper pickupInclude() (se não existir)
  if($txt -notmatch 'function\s+pickupInclude\s*\('){
    $marker = 'if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = prisma;'
    $idx = $txt.IndexOf($marker)
    if($idx -ge 0){
      $helperLines = @(
        "",
        "function pickupInclude() {",
        "  const model = Prisma.dmmf.datamodel.models.find((m) => m.name === ""PickupRequest"");",
        "  const fieldNames = (model?.fields ?? []).map((f) => f.name);",
        "  const include: any = {};",
        "  if (fieldNames.includes(""receipt"")) include.receipt = true;",
        "  if (fieldNames.includes(""ecoReceipt"")) include.ecoReceipt = true;",
        "  return include;",
        "}",
        ""
      )
      $helper = ($helperLines -join "`r`n")

      $txt = $txt.Replace($marker, ($marker + $helper))
    } else {
      $script:log += ("WARN: marker prisma init não encontrado em {0} (não injetei pickupInclude)" -f $file)
    }
  }

  # 3) trocar include fixo por include dinâmico (vários formatos)
  # include: { receipt: true }
  $txt = [regex]::Replace($txt, 'include\s*:\s*\{\s*receipt\s*:\s*true\s*\}', 'include: pickupInclude()', 'IgnoreCase')
  $txt = [regex]::Replace($txt, 'include\s*:\s*\{\s*ecoReceipt\s*:\s*true\s*\}', 'include: pickupInclude()', 'IgnoreCase')

  # include: { receipt: true, ... }
  $txt = [regex]::Replace($txt, 'include\s*:\s*\{\s*receipt\s*:\s*true\s*,', 'include: { ...pickupInclude(),', 'IgnoreCase')
  $txt = [regex]::Replace($txt, 'include\s*:\s*\{\s*ecoReceipt\s*:\s*true\s*,', 'include: { ...pickupInclude(),', 'IgnoreCase')

  if($txt -ne $orig){
    $bak = BackupFile $file
    if($bak){ $script:log += ("Backup: {0}" -f $bak) }
    WriteUtf8NoBom $file $txt
    $script:log += ("OK patched: {0}" -f $file)
  } else {
    $script:log += ("NOCHANGE: {0}" -f $file)
  }
}

$rep = NewReport "eco-fix-v4e-duplicate-receipt-and-pickup-include"
$script:log = @()
$script:log += "# ECO — FIX v4e — Duplicate receipt + pickup include"
$script:log += ""
$script:log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$script:log += ("PWD : {0}" -f (Get-Location).Path)
$script:log += ("Node: {0}" -f (node -v 2>$null))
$script:log += ("npm : {0}" -f (npm -v 2>$null))
$script:log += ""

# =========================
# PATCH 1 — prisma/schema.prisma (remover duplicidade do campo receipt)
# =========================
$schemaPath = "prisma/schema.prisma"
if(!(Test-Path -LiteralPath $schemaPath)){ throw "Não achei prisma/schema.prisma" }
$schemaRaw = Get-Content -LiteralPath $schemaPath -Raw

$rx = [regex]::new('(?ms)model\s+PickupRequest\s*\{.*?\r?\n\}')
$m = $rx.Match($schemaRaw)
if(!$m.Success){ throw "Não achei model PickupRequest no schema" }

$block = $m.Value
$lines = $block -split "`r?`n"

$script:log += "## DIAG schema (antes) — linhas receipt/ecoReceipt"
$script:log += '```'
foreach($ln in $lines){
  if($ln -match '^\s*(receipt|ecoReceipt)\b'){ $script:log += $ln }
}
$script:log += '```'
$script:log += ""

# detecta se já existe ecoReceipt EcoReceipt?
$hasEcoReceiptField = $false
foreach($ln in $lines){
  if($ln -match '^\s*ecoReceipt\s+EcoReceipt\?\s*$'){ $hasEcoReceiptField = $true }
}

$new = New-Object System.Collections.Generic.List[string]
$changed = $false

foreach($ln in $lines){
  # se existir receipt EcoReceipt? => renomeia pra ecoReceipt OU remove se já existir
  if($ln -match '^\s*receipt\s+EcoReceipt\?\s*$'){
    if($hasEcoReceiptField){
      $changed = $true
      continue
    } else {
      $new.Add("  ecoReceipt EcoReceipt?")
      $hasEcoReceiptField = $true
      $changed = $true
      continue
    }
  }
  $new.Add($ln)
}

if($changed){
  $bak = BackupFile $schemaPath
  if($bak){ $script:log += ("Backup: {0}" -f $bak) }

  $block2 = ($new -join "`r`n")
  $schemaFixed = $schemaRaw.Replace($block, $block2)
  WriteUtf8NoBom $schemaPath $schemaFixed
  $script:log += "OK: schema corrigido (receipt EcoReceipt? -> ecoReceipt OU removido se duplicado)"
} else {
  $script:log += "NOCHANGE: não achei 'receipt EcoReceipt?' no PickupRequest"
}

$script:log += ""
$script:log += "## VERIFY Prisma"
Run "npx" @("prisma","validate","--schema=prisma/schema.prisma")
Run "npx" @("prisma","generate","--schema=prisma/schema.prisma")
Run "npx" @("prisma","db","push","--schema=prisma/schema.prisma")
$script:log += "OK: prisma validate/generate/db push"

# =========================
# PATCH 2 — pickup-requests API include dinâmico
# =========================
$script:log += ""
$script:log += "## PATCH pickup-requests API"
PatchTsPickupInclude "src/app/api/pickup-requests/route.ts"
PatchTsPickupInclude "src/app/api/pickup-requests/[id]/route.ts"

WriteUtf8NoBom $rep ($script:log -join "`n")

Write-Host ("✅ FIX v4e aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host ""
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow