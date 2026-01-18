param([switch]$OpenReport)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# --- bootstrap (fallback) ---
function EnsureDir([string]$p){ if(!(Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function WriteUtf8NoBom([string]$p,[string]$t){ [IO.File]::WriteAllText($p,$t,[Text.UTF8Encoding]::new($false)) }
function BackupFile([string]$file,[string]$dir){
  EnsureDir $dir
  $safe = ($file -replace '[\\/:*?""<>|]','_')
  $stamp = (Get-Date -Format "yyyyMMdd-HHmmss")
  $dest = Join-Path $dir ($stamp + "-" + $safe)
  Copy-Item -LiteralPath $file -Destination $dest -Force
  return $dest
}
function ReadRaw([string]$p){ return (Get-Content -LiteralPath $p -Raw -ErrorAction Stop) }
function WriteRaw([string]$p,[string]$t){ [IO.File]::WriteAllText($p,$t,[Text.UTF8Encoding]::new($false)) }

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$stamp = (Get-Date -Format "yyyyMMdd-HHmmss")
$reportDir = Join-Path $root "reports"
EnsureDir $reportDir
$reportPath = Join-Path $reportDir ("eco-step-164-fix-pickuprequest-receipt-link-" + $stamp + ".md")

$routePath  = Join-Path $root "src\app\api\pickup-requests\[id]\receipt\route.ts"
$schemaPath = Join-Path $root "prisma\schema.prisma"

$patchLog = ""

if(!(Test-Path -LiteralPath $routePath)){ throw ("missing: " + $routePath) }
if(!(Test-Path -LiteralPath $schemaPath)){ throw ("missing: " + $schemaPath) }

# --- DIAG: achar relacao do Receipt -> PickupRequest no schema ---
$schema = ReadRaw $schemaPath
$mBlock = [regex]::Match($schema, '(?s)model\s+Receipt\s*\{.*?\n\}' )
if(!$mBlock.Success){ throw "model Receipt { ... } nao encontrado em prisma/schema.prisma" }
$block = $mBlock.Value

$relField = $null
$fkField  = $null
$relType  = $null

$candidateTypes = @("PickupRequest","Request","EcoPickupRequest","EcoRequest")
foreach($t in $candidateTypes){
  $rx = '(?m)^\s*(\w+)\s+' + [regex]::Escape($t) + '\b[^\n]*@relation\(([^)]*)\)'
  $mm = [regex]::Match($block, $rx)
  if($mm.Success){
    $relField = $mm.Groups[1].Value
    $relType  = $t
    $args = $mm.Groups[2].Value
    $ff = [regex]::Match($args, 'fields\s*:\s*\[\s*(\w+)\s*\]')
    if($ff.Success){ $fkField = $ff.Groups[1].Value }
    break
  }
}

$patchLog += ("[DIAG] Receipt relation type: " + ($relType ?? "<nao achou>") + "`n")
$patchLog += ("[DIAG] Receipt relation field: " + ($relField ?? "<nao achou>") + "`n")
$patchLog += ("[DIAG] Receipt fk scalar (fields:[..]): " + ($fkField ?? "<nao achou>") + "`n")

# --- PATCH: substituir requestId:"MVP" por connect via relacao (ou remover) ---
$raw = ReadRaw $routePath
$bk = BackupFile $routePath (Join-Path $root "tools\_patch_backup\eco-step-164")
$patchLog += ("[OK] backup: " + $bk + "`n")

$rxBad = '(?m)^\s*requestId\s*:\s*"MVP"\s*,\s*\r?\n'
$repLine = ""
if($relField){
  $repLine = ("    " + $relField + ": { connect: { id } },")
} else {
  # sem relacao encontrada: melhor so remover a linha invalida e deixar o resto compilar
  $repLine = ""
}

if([regex]::IsMatch($raw, $rxBad)){
  if($repLine){
    $raw2 = [regex]::Replace($raw, $rxBad, ($repLine + "`n"))
    $patchLog += ("[OK] replace requestId:\"MVP\" -> " + $repLine + "`n")
  } else {
    $raw2 = [regex]::Replace($raw, $rxBad, "")
    $patchLog += "[OK] removed invalid requestId:\"MVP\" (no relation found in schema)`n"
  }
} else {
  $raw2 = $raw
  $patchLog += "[SKIP] linha requestId:\"MVP\" nao encontrada (nada a fazer)`n"
}

WriteRaw $routePath $raw2

# --- VERIFY ---
$verify = @()
function RunCmd([string]$label,[scriptblock]$sb){
  $verify += ""
  $verify += ("### " + $label)
  try { $o = (& $sb 2>&1 | Out-String).TrimEnd(); $verify += "~~~"; $verify += $o; $verify += "~~~" }
  catch { $verify += ("(erro: " + $_.Exception.Message + ")") }
}
RunCmd "npm run build" { npm run build }

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