param(
  [string[]]$Tasks = @('lint','build'),
  [switch]$OpenReport
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function NowStamp { Get-Date -Format "yyyyMMdd-HHmmss" }
function EnsureDir([string]$p){ if(-not (Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function WriteUtf8NoBom([string]$path, [string]$content){ [IO.File]::WriteAllText($path, $content, [Text.UTF8Encoding]::new($false)) }
function FindCmd([string]$name){ $c = Get-Command $name -ErrorAction SilentlyContinue; if($c){ return $c.Source }; return $null }

function RunProc([string]$exe, [string[]]$argv, [string]$workdir){
  $psi = [System.Diagnostics.ProcessStartInfo]::new()
  $psi.FileName = $exe
  $psi.WorkingDirectory = $workdir
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError  = $true
  $psi.UseShellExecute = $false
  foreach($a in $argv){ if($null -ne $a){ [void]$psi.ArgumentList.Add([string]$a) } }
  $p = [System.Diagnostics.Process]::new()
  $p.StartInfo = $psi
  [void]$p.Start()
  $stdout = $p.StandardOutput.ReadToEnd()
  $stderr = $p.StandardError.ReadToEnd()
  $p.WaitForExit()
  return @{ ExitCode = $p.ExitCode; Text = (($stdout + $stderr).TrimEnd()) }
}

$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$reports = Join-Path $root "reports"
EnsureDir $reports
$stamp = NowStamp
$reportPath = Join-Path $reports ("eco-runner-" + $stamp + ".md")
$r = @()
$r += ("# eco-runner - " + $stamp)
$r += ""
$r += ("Root: " + $root)
$r += ""
$r += "## RUN"
$r += ""

# normalize tasks (accept: -Tasks lint build smoke OR -Tasks "lint,build,smoke")
$norm = New-Object System.Collections.Generic.List[string]
foreach($t in $Tasks){
  if([string]::IsNullOrWhiteSpace($t)){ continue }
  $parts = $t.Split(",", [System.StringSplitOptions]::RemoveEmptyEntries)
  foreach($p in $parts){
    $v = $p.Trim().ToLowerInvariant()
    if($v){ $norm.Add($v) }
  }
}
if($norm.Count -eq 0){ $norm.Add("lint"); $norm.Add("build") }

$npm = FindCmd "npm.cmd"
if(-not $npm){ $npm = FindCmd "npm" }
if(-not $npm){ throw "npm not found (need npm.cmd on PATH)" }
$pwsh = FindCmd "pwsh"
if(-not $pwsh){ $pwsh = FindCmd "powershell" }
if(-not $pwsh){ throw "pwsh/powershell not found" }

function Fail([int]$code, [string]$msg){
  $script:r += "## FAIL"
  $script:r += $msg
  $script:r += ""
  WriteUtf8NoBom $script:reportPath ($script:r -join "`n")
  Write-Host ("[REPORT] " + $script:reportPath)
  if($OpenReport){ Start-Process $script:reportPath | Out-Null }
  exit $code
}

function RunStep([string]$title, [string]$exe, [string[]]$argv){
  $script:r += ("### " + $title)
  $script:r += "~~~"
  $script:r += ("exe: " + $exe)
  $script:r += ("args: " + ($argv -join " "))
  $script:r += ""
  $res = RunProc $exe $argv $script:root
  if($res.Text){ $script:r += $res.Text }
  $script:r += "~~~"
  $script:r += ("exit: " + $res.ExitCode)
  $script:r += ""
  return $res.ExitCode
}

foreach($task in $norm){
  if($task -eq "lint"){
    $ec = RunStep "npm run lint" $npm @("run","lint")
    if($ec -ne 0){ Fail $ec ("command failed: npm run lint (exit " + $ec + ")") }
    continue
  }
  if($task -eq "build"){
    $ec = RunStep "npm run build" $npm @("run","build")
    if($ec -ne 0){ Fail $ec ("command failed: npm run build (exit " + $ec + ")") }
    continue
  }
  if($task -eq "smoke"){
    $tools = Join-Path $root "tools"
    $cand = @(Get-ChildItem -LiteralPath $tools -File -Filter "*.ps1" -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "^eco-step-148b.*smoke.*\.ps1$" } | Sort-Object LastWriteTime -Descending)
    if($cand.Count -eq 0){ Fail 2 "smoke script not found in tools/ (expected eco-step-148b*smoke*.ps1)" }
    $smokePath = $cand[0].FullName
    $ec = RunStep ("smoke: " + $cand[0].Name) $pwsh @("-NoProfile","-ExecutionPolicy","Bypass","-File",$smokePath)
    if($ec -ne 0){ Fail $ec ("command failed: smoke (exit " + $ec + ")") }
    continue
  }
  $script:r += ("### unknown task: " + $task)
  $script:r += "~~~"
  $script:r += "WARN: task ignorada (use: lint, build, smoke)"
  $script:r += "~~~"
  $script:r += ""
}

WriteUtf8NoBom $reportPath ($r -join "`n")
Write-Host ("[REPORT] " + $reportPath)
if($OpenReport){ Start-Process $reportPath | Out-Null }
exit 0