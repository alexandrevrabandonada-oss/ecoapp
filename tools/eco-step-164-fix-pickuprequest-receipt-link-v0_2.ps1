param([switch]$OpenReport)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function EnsureDir([string]$p){
  if([string]::IsNullOrWhiteSpace($p)){ return }
  if(!(Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null }
}
function WriteUtf8NoBom([string]$p,[string]$t){
  [IO.File]::WriteAllText($p,$t,[Text.UTF8Encoding]::new($false))
}
function BackupFile([string]$file,[string]$dir){
  if(!(Test-Path -LiteralPath $file)){ return $null }
  EnsureDir $dir
  $safe = ($file -replace '[:\\\/\[\]\s]','_')
  $stamp = (Get-Date -Format 'yyyyMMdd-HHmmss')
  $dest = Join-Path $dir ($stamp + '-' + $safe)
  Copy-Item -LiteralPath $file -Destination $dest -Force
  return $dest
}
function ReadRaw([string]$p){ return (Get-Content -LiteralPath $p -Raw -ErrorAction Stop) }
function WriteRaw([string]$p,[string]$t){ [IO.File]::WriteAllText($p,$t,[Text.UTF8Encoding]::new($false)) }

function RunCmd([string]$label,[scriptblock]$sb,[ref]$out){
  $out.Value += ("### " + $label + "`n~~~`n")
  try {
    $o = (& $sb 2>&1 | Out-String).TrimEnd()
    $out.Value += ($o + "`n")
  } catch {
    $out.Value += ("[ERR] " + $_.Exception.Message + "`n")
  }
  $out.Value += "~~~`n`n"
}

if(!(Test-Path -LiteralPath "package.json")){ throw "Rode na raiz do repo (onde tem package.json)." }

$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
$stamp = (Get-Date -Format 'yyyyMMdd-HHmmss')

$reportDir = Join-Path $root "reports"
EnsureDir $reportDir
$reportPath = Join-Path $reportDir ("eco-step-164-fix-pickuprequest-receipt-link-" + $stamp + ".md")

$bakDir = Join-Path $root "tools\_patch_backup\eco-step-164"
EnsureDir $bakDir

$routePath  = Join-Path $root "src\app\api\pickup-requests\[id]\receipt\route.ts"
$schemaPath = Join-Path $root "prisma\schema.prisma"

$patchLog = ""
$verify = ""

if(!(Test-Path -LiteralPath $routePath)){ throw ("missing: " + $routePath) }
if(!(Test-Path -LiteralPath $schemaPath)){ throw ("missing: " + $schemaPath) }

# --- DIAG: achar relacao do Receipt -> PickupRequest no schema ---
$schema = ReadRaw $schemaPath
$mBlock = [regex]::Match($schema, '(?s)model\s+Receipt\s*\{.*?\n\}')
if(!$mBlock.Success){ throw "model Receipt { ... } nao encontrado em prisma/schema.prisma" }
$block = $mBlock.Value

$relField = $null
$relType  = $null
$fkField  = $null

# tenta pegar uma linha com tipo PickupRequest + @relation(...)
$mm = [regex]::Match($block, '(?m)^\s*(\w+)\s+(PickupRequest)\b[^\n]*@relation\(([^)]*)\)')
if($mm.Success){
  $relField = $mm.Groups[1].Value
  $relType  = $mm.Groups[2].Value
  $args = $mm.Groups[3].Value
  $ff = [regex]::Match($args, 'fields\s*:\s*\[\s*(\w+)\s*\]')
  if($ff.Success){ $fkField = $ff.Groups[1].Value }
}

$patchLog += ('[DIAG] Receipt relation type: ' + ($(if($relType){$relType}else{'<nao achou>'})) + "`n")
$patchLog += ('[DIAG] Receipt relation field: ' + ($(if($relField){$relField}else{'<nao achou>'})) + "`n")
$patchLog += ('[DIAG] Receipt fk scalar (fields:[..]): ' + ($(if($fkField){$fkField}else{'<nao achou>'})) + "`n")

# --- PATCH: substituir requestId:"MVP" ---
$raw = ReadRaw $routePath
$bk = BackupFile $routePath $bakDir
if($bk){ $patchLog += ("[OK] backup: " + $bk + "`n") }

$rxBad = '(?m)^\s*requestId\s*:\s*"MVP"\s*,\s*\r?\n'

$repLine = ""
if($relField){
  $repLine = ("    " + $relField + ": { connect: { id } },")
}

if([regex]::IsMatch($raw, $rxBad)){
  if($repLine){
    $raw2 = [regex]::Replace($raw, $rxBad, ($repLine + "`n"))
    $patchLog += ('[OK] replace requestId:"MVP" -> ' + $repLine + "`n")
  } else {
    $raw2 = [regex]::Replace($raw, $rxBad, "")
    $patchLog += '[OK] removed invalid requestId:"MVP" (no relation found in schema)' + "`n"
  }
} else {
  $raw2 = $raw
  $patchLog += '[SKIP] linha requestId:"MVP" nao encontrada (nada a fazer)' + "`n"
}

WriteRaw $routePath $raw2

# --- VERIFY ---
RunCmd "npm run build" { npm run build } ([ref]$verify)

# --- REPORT ---
$r = @()
$r += ("# eco-step-164 — fix pickup-requests/[id]/receipt link — " + $stamp)
$r += ""
$r += "## Patch log"
$r += "~~~"
$r += $patchLog.TrimEnd()
$r += "~~~"
$r += ""
$r += "## VERIFY"
$r += $verify

WriteUtf8NoBom $reportPath ($r -join "`n")
Write-Host ("[REPORT] " + $reportPath)
if($OpenReport){ try { Start-Process $reportPath | Out-Null } catch {} }

Write-Host ""
Write-Host "[NEXT] se o build passar, rode o smoke:"
Write-Host "  pwsh -NoProfile -ExecutionPolicy Bypass -File tools\eco-step-148b-verify-smoke-autodev-v0_1.ps1 -OpenReport"