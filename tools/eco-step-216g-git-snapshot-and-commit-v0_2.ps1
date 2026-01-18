param(
  [switch]$OpenReport,
  [string]$Message = "ECO: fix build blockers + zero lint warnings (route params/catch vars)"
)

$ErrorActionPreference = "Stop"
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"

function EnsureDir([string]$p){
  if([string]::IsNullOrWhiteSpace($p)){ return }
  if(-not (Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null }
}
function WriteUtf8NoBom([string]$p,[string]$s){
  EnsureDir (Split-Path -Parent $p)
  [IO.File]::WriteAllText($p, $s, [Text.UTF8Encoding]::new($false))
}
function GitLines([string[]]$args){
  $cmd = "cd /d `"$Root`" && git " + ($args -join " ")
  $out = cmd.exe /c ($cmd + " 2^>^&1")
  if($out -is [string]){ return @($out) }
  return @($out)
}
function RunGit([string[]]$args){
  $cmd = "cd /d `"$Root`" && git " + ($args -join " ")
  cmd.exe /c ($cmd + " 2^>^&1") | Out-Host
  return $LASTEXITCODE
}

$reportsDir = Join-Path $Root "reports"
EnsureDir $reportsDir
$reportPath = Join-Path $reportsDir ("eco-step-216g-git-snapshot-" + $stamp + ".md")

$r = New-Object System.Collections.Generic.List[string]
$r.Add("# ECO STEP 216g — git snapshot + commit — $stamp")
$r.Add("")
$r.Add("Root: $Root")
$r.Add("Message: $Message")
$r.Add("")

$r.Add("## git status (before)")
$r.Add("```")
foreach($ln in (GitLines @("status","--porcelain"))){ $r.Add($ln) }
$r.Add("```")
$r.Add("")

$r.Add("## git diff --stat")
$r.Add("```")
foreach($ln in (GitLines @("diff","--stat"))){ $r.Add($ln) }
$r.Add("```")
$r.Add("")

$status = GitLines @("status","--porcelain")
if(-not $status -or $status.Count -eq 0){
  $r.Add("No changes to commit.")
  WriteUtf8NoBom $reportPath ($r -join "`n")
  Write-Host ("[REPORT] " + $reportPath)
  if($OpenReport){ try { ii $reportPath } catch {} }
  exit 0
}

$r.Add("## git add -A")
$null = RunGit @("add","-A")
$r.Add("")

$r.Add("## git commit")
$r.Add("```")
# safe message quoting for cmd
$msg = $Message.Replace('"','\"')
foreach($ln in (GitLines @("commit","-m",('"' + $msg + '"')))){ $r.Add($ln) }
$r.Add("```")
$r.Add("")

$r.Add("## git status (after)")
$r.Add("```")
foreach($ln in (GitLines @("status"))){ $r.Add($ln) }
$r.Add("```")
$r.Add("")

WriteUtf8NoBom $reportPath ($r -join "`n")
Write-Host ("[REPORT] " + $reportPath)
if($OpenReport){ try { ii $reportPath } catch {} }