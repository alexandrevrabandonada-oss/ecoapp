param([switch]$OpenReport)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function NowStamp(){ (Get-Date).ToString("yyyyMMdd-HHmmss") }
function EnsureDir([string]$p){
  if([string]::IsNullOrWhiteSpace($p)){ return }
  if(!(Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null }
}
function WriteUtf8NoBom([string]$path, [string]$text){
  [IO.File]::WriteAllText($path, $text, [Text.UTF8Encoding]::new($false))
}
function BackupFile([string]$file, [string]$bakRoot){
  if(!(Test-Path -LiteralPath $file)){ return $null }
  EnsureDir $bakRoot
  $safe = ($file -replace "[:\\\/\[\]\s]", "_")
  $dst = Join-Path $bakRoot ((NowStamp) + "-" + $safe)
  Copy-Item -LiteralPath $file -Destination $dst -Force
  return $dst
}
function RunCmd([string]$label, [scriptblock]$sb, [ref]$out){
  $out.Value += ("### " + $label + "`n~~~`n")
  try {
    $o = (& $sb 2>&1 | Out-String).TrimEnd()
    if($o){ $out.Value += ($o + "`n") }
  } catch {
    $out.Value += ("[ERR] " + $_.Exception.Message + "`n")
  }
  $out.Value += "~~~`n`n"
}

if(!(Test-Path -LiteralPath "package.json")){ throw "Rode na raiz do repo (onde tem package.json)." }

$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path

EnsureDir (Join-Path $repoRoot "reports")
EnsureDir (Join-Path $repoRoot "tools\_patch_backup\eco-step-171")

$stamp = NowStamp
$reportPath = Join-Path $repoRoot ("reports\eco-step-171-fix-pickuprequests-ecoIsOperator-param-" + $stamp + ".md")

$targetRel  = "src\app\api\pickup-requests\route.ts"
$targetFull = Join-Path $repoRoot $targetRel
if(!(Test-Path -LiteralPath $targetFull)){ throw ("missing: " + $targetRel) }

$raw = Get-Content -LiteralPath $targetFull -Raw

# --- Detect param name from GET handler (function or const)
$param = $null
$patterns = @(
  '(?s)export\s+async\s+function\s+GET\s*\(\s*(\w+)',
  '(?s)export\s+function\s+GET\s*\(\s*(\w+)',
  '(?s)export\s+const\s+GET\s*=\s*async\s*\(\s*(\w+)',
  '(?s)export\s+const\s+GET\s*=\s*\(\s*(\w+)',
  '(?s)export\s+const\s+GET\s*=\s*async\s*function\s*\(\s*(\w+)',
  '(?s)export\s+const\s+GET\s*=\s*function\s*\(\s*(\w+)'
)

foreach($p in $patterns){
  $m = [regex]::Match($raw, $p)
  if($m.Success){
    $param = $m.Groups[1].Value
    break
  }
}
if([string]::IsNullOrWhiteSpace($param)){ $param = "req" }

# --- DIAG counts
$diag = @()
$diag += ("# eco-step-171 — normalize ecoIsOperator(param) — " + $stamp)
$diag += ""
$diag += "## DIAG"
$diag += ("alvo: " + $targetRel)
$diag += ("GET param detectado: " + $param)

$hits = 0
try {
  $ms = [regex]::Matches($raw, 'ecoIsOperator\(\s*\w+\s*\)')
  if($ms){ $hits = $ms.Count }
} catch {}
$diag += ("calls ecoIsOperator(...): " + $hits)
$diag += ""

# --- PATCH
$patchLog = ""

# Normaliza ecoIsOperator(qualquerIdentificador) -> ecoIsOperator(<param>)
$before = $raw
$raw2 = [regex]::Replace($raw, 'ecoIsOperator\(\s*\w+\s*\)', ('ecoIsOperator(' + $param + ')'))

if($raw2 -ne $before){
  $bk = BackupFile $targetFull (Join-Path $repoRoot "tools\_patch_backup\eco-step-171")
  WriteUtf8NoBom $targetFull $raw2
  $patchLog += ("[OK]   normalized ecoIsOperator(...) -> ecoIsOperator(" + $param + ")`n")
  if($bk){ $patchLog += ("       backup: " + $bk + "`n") }
} else {
  $patchLog += "[SKIP] no change (ecoIsOperator already normalized or not present)`n"
}

$diag += "## PATCH LOG"
$diag += "~~~"
$diag += $patchLog.TrimEnd()
$diag += "~~~"
$diag += ""

# --- VERIFY
$verify = ""
RunCmd "npm run build" { npm run build } ([ref]$verify)

$diag += "## VERIFY"
$diag += $verify

WriteUtf8NoBom $reportPath ($diag -join "`n")
Write-Host ("[REPORT] " + $reportPath)
if($OpenReport){ try { Start-Process $reportPath | Out-Null } catch {} }

Write-Host ""
Write-Host "[NEXT] Se o build passar, rode o smoke:"
Write-Host "  pwsh -NoProfile -ExecutionPolicy Bypass -File tools\eco-step-148b-verify-smoke-autodev-v0_1.ps1 -OpenReport"