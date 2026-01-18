param(
  [switch]$OpenReport
)

$ErrorActionPreference = "Stop"

function EnsureDir([string]$p){
  if([string]::IsNullOrWhiteSpace($p)){ return }
  if(-not (Test-Path $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null }
}

function Stamp(){
  return (Get-Date).ToString("yyyyMMdd-HHmmss")
}

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$reportsDir = Join-Path $root "reports"
$backupDir  = Join-Path $root "tools\_patch_backup"
EnsureDir $reportsDir
EnsureDir $backupDir

$stamp = Stamp
$reportPath = Join-Path $reportsDir ("eco-step-216b-fix-build-catch-e-" + $stamp + ".md")

$r = New-Object System.Collections.Generic.List[string]
$r.Add("# ECO STEP 216b — fix build blocker (catch param e) — $stamp")
$r.Add("")
$r.Add("Root: $root")
$r.Add("")

$ecoApiDir = Join-Path $root "src\app\api\eco"
if(-not (Test-Path $ecoApiDir)){
  $r.Add("ERR: eco api dir not found: $ecoApiDir")
  [IO.File]::WriteAllLines($reportPath, $r, [Text.UTF8Encoding]::new($false))
  throw ("eco api dir not found. See report: " + $reportPath)
}

# Targets: any file under src/app/api/eco that contains asMsg(e)
$targets = @()
$matches = Select-String -Path (Join-Path $ecoApiDir "*") -Recurse -File -Pattern "asMsg\(\s*e\s*\)" -List -ErrorAction SilentlyContinue
if($matches){ $targets = $matches | Select-Object -ExpandProperty Path }

# Fallback to the known failing file path if none found
if(-not $targets -or $targets.Count -eq 0){
  $fallback = Join-Path $root "src\app\api\eco\points\react\route.ts"
  if(Test-Path $fallback){ $targets = @($fallback) }
}

$r.Add("## DIAG")
$r.Add("- targets found: " + ($targets.Count))
foreach($t in $targets){ $r.Add("  - " + $t) }
$r.Add("")

if(-not $targets -or $targets.Count -eq 0){
  $r.Add("ERR: no targets to patch (no asMsg(e) found).")
  [IO.File]::WriteAllLines($reportPath, $r, [Text.UTF8Encoding]::new($false))
  throw ("No targets to patch. See report: " + $reportPath)
}

# Patch: only when pattern is catch { <newline> const msg = asMsg(e);
$pattern = '(?s)\bcatch\s*\{\s*(\r?\n\s*const\s+msg\s*=\s*asMsg\(\s*e\s*\)\s*;)'
$repl    = 'catch (e) {$1'

$r.Add("## PATCH")
$changed = 0

foreach($file in $targets){
  if(-not (Test-Path $file)){
    $r.Add("- skip (not found): $file")
    continue
  }

  $raw = Get-Content -Raw -LiteralPath $file
  $new = [regex]::Replace($raw, $pattern, $repl)

  if($new -ne $raw){
    $backupName = ([IO.Path]::GetFileName($file)) + ".bak-" + $stamp
    $backupPath = Join-Path $backupDir $backupName
    Copy-Item -LiteralPath $file -Destination $backupPath -Force
    [IO.File]::WriteAllText($file, $new, [Text.UTF8Encoding]::new($false))
    $changed++
    $r.Add("- patched: $file")
    $r.Add("  - backup: $backupPath")
  } else {
    $r.Add("- ok (no change needed): $file")
  }
}

$r.Add("")
$r.Add("Patched files: $changed")
$r.Add("")

# VERIFY: lint + build
$npm = (Get-Command npm -ErrorAction Stop).Source

function RunLogged([string]$label, [string[]]$args, [string]$logPath){
  Write-Host ("[" + $label + "] " + ($args -join " ") + " ...")
  & $npm @args 2>&1 | Tee-Object -FilePath $logPath | Out-Host
  return $LASTEXITCODE
}

$r.Add("## VERIFY")

$lintLog  = Join-Path $reportsDir ("eco-step-216b-lint-"  + $stamp + ".log")
$buildLog = Join-Path $reportsDir ("eco-step-216b-build-" + $stamp + ".log")

$lintExit = RunLogged "216b" @("run","lint")  $lintLog
$r.Add("- lint exit: $lintExit")
$r.Add("- lint log:  $lintLog")

$buildExit = RunLogged "216b" @("run","build") $buildLog
$r.Add("- build exit: $buildExit")
$r.Add("- build log:  $buildLog")

$r.Add("")
$r.Add("## RESULT")
if($buildExit -eq 0){
  $r.Add("- OK: build passou ✅")
} else {
  $r.Add("- FAIL: build ainda falhou ❌")
}

[IO.File]::WriteAllLines($reportPath, $r, [Text.UTF8Encoding]::new($false))
Write-Host ("[REPORT] " + $reportPath)

if($OpenReport){ ii $reportPath }

if($lintExit -ne 0){ throw ("LINT failed. See: " + $lintLog) }
if($buildExit -ne 0){ throw ("BUILD failed. See: " + $buildLog) }