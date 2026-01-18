param(
  [switch]$OpenReport,
  [string]$Message = "ECO: build ok + lint 0 warnings (pickup id + catch vars)"
)

$ErrorActionPreference = "Stop"
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"

function EnsureDir([string]$p){
  if([string]::IsNullOrWhiteSpace($p)){ return }
  if(-not (Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null }
}
function WriteUtf8NoBom([string]$p,[string[]]$lines){
  EnsureDir (Split-Path -Parent $p)
  [IO.File]::WriteAllText($p, ($lines -join "`n"), [Text.UTF8Encoding]::new($false))
}

$reportsDir = Join-Path $Root "reports"
EnsureDir $reportsDir
$reportPath = Join-Path $reportsDir ("eco-step-216g-git-snapshot-" + $stamp + ".md")

Set-Location -LiteralPath $Root

$r = @()
$r += "# ECO STEP 216g - git snapshot + commit - $stamp"
$r += ""
$r += "Root: $Root"
$r += "Message: $Message"
$r += ""

$statusBefore = @(git status --porcelain)
$diffStat = @(git diff --stat)

$r += "## git status (before)"
$r += "```"
if($statusBefore.Count -eq 0){
  $r += "clean"
} else {
  foreach($ln in $statusBefore){ $r += $ln }
}
$r += "```"
$r += ""

$r += "## git diff --stat"
$r += "```"
if($diffStat.Count -eq 0){
  $r += "no diff"
} else {
  foreach($ln in $diffStat){ $r += $ln }
}
$r += "```"
$r += ""

if($statusBefore.Count -eq 0){
  $r += "No changes to commit."
  WriteUtf8NoBom $reportPath $r
  Write-Host ("[REPORT] " + $reportPath)
  if($OpenReport){ try { ii $reportPath } catch {} }
  exit 0
}

$r += "## git add -A"
git add -A | Out-Null
$r += "OK"
$r += ""

$r += "## git commit"
$r += "```"
$commitOut = @(git commit -m $Message 2>&1)
foreach($ln in $commitOut){ $r += $ln }
$r += "```"
$r += ""

if($LASTEXITCODE -ne 0){
  WriteUtf8NoBom $reportPath $r
  Write-Host ("[REPORT] " + $reportPath)
  if($OpenReport){ try { ii $reportPath } catch {} }
  throw "git commit falhou (veja o report)."
}

$r += "## git status (after)"
$r += "```"
$statusAfter = @(git status 2>&1)
foreach($ln in $statusAfter){ $r += $ln }
$r += "```"
$r += ""

WriteUtf8NoBom $reportPath $r
Write-Host ("[REPORT] " + $reportPath)
if($OpenReport){ try { ii $reportPath } catch {} }