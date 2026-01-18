param([switch]$OpenReport)

$ErrorActionPreference = "Stop"
$ToolsDir = $PSScriptRoot
$Root = (Resolve-Path (Join-Path $ToolsDir "..")).Path
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"

function EnsureDir([string]$p){
  if([string]::IsNullOrWhiteSpace($p)){ return }
  if(-not (Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null }
}

function RunCmdToLog([string]$cmd, [string]$logFile){
  EnsureDir (Split-Path -Parent $logFile)
  $full = "cd /d `"$Root`" && $cmd 2^>^&1"
  $p = Start-Process -FilePath "cmd.exe" -ArgumentList @("/c", $full) -NoNewWindow -PassThru -RedirectStandardOutput $logFile
  $p.WaitForExit()
  return $p.ExitCode
}

$reportDir = Join-Path $Root "reports"
EnsureDir $reportDir

$reportPath = Join-Path $reportDir ("eco-step-216-verify-build-" + $stamp + ".md")
$lintLog    = Join-Path $reportDir ("eco-step-216-lint-" + $stamp + ".log")
$buildLog   = Join-Path $reportDir ("eco-step-216-build-" + $stamp + ".log")

$lines = @()
$lines += "# ECO STEP 216 — VERIFY build + git snapshot — $stamp"
$lines += ""
$lines += "Root: $Root"
$lines += ""

Write-Host "[216] npm run lint..."
$lintExit = RunCmdToLog "npm run lint" $lintLog
Write-Host ("[216] lint exit=" + $lintExit)
$lines += "## LINT"
$lines += "- exit: $lintExit"
$lines += "- log: $lintLog"
$lines += ""

Write-Host "[216] npm run build..."
$buildExit = RunCmdToLog "npm run build" $buildLog
Write-Host ("[216] build exit=" + $buildExit)
$lines += "## BUILD"
$lines += "- exit: $buildExit"
$lines += "- log: $buildLog"
$lines += ""

$lines += "## GIT"
try {
  $branch = (& git -C $Root rev-parse --abbrev-ref HEAD) 2>$null
  $last   = (& git -C $Root log -1 --oneline) 2>$null
  $status = (& git -C $Root status --porcelain) 2>$null
  $stat   = (& git -C $Root diff --stat) 2>$null
} catch {
  $branch = ""
  $last = ""
  $status = ""
  $stat = ""
}

$lines += "- branch: $branch"
$lines += "- last commit: $last"
$lines += ""
$lines += "### git status --porcelain"
if([string]::IsNullOrWhiteSpace($status)){ $lines += "(clean)" } else { $lines += $status }
$lines += ""
$lines += "### git diff --stat"
if([string]::IsNullOrWhiteSpace($stat)){ $lines += "(no diff)" } else { $lines += $stat }
$lines += ""

[IO.File]::WriteAllText($reportPath, ($lines -join "`n"), [Text.UTF8Encoding]::new($false))
Write-Host ("[REPORT] " + $reportPath)

if($OpenReport){
  try { ii $reportPath } catch {}
}

if($lintExit -ne 0){ throw ("Lint failed. See: " + $lintLog) }
if($buildExit -ne 0){ throw ("Build failed. See: " + $buildLog) }

Write-Host "[216] OK — lint+build passaram."