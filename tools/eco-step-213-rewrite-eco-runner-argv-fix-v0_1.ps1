param([switch]$OpenReport)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function NowStamp { Get-Date -Format "yyyyMMdd-HHmmss" }
function EnsureDir([string]$p){
  if([string]::IsNullOrWhiteSpace($p)){ return }
  if(-not (Test-Path -LiteralPath $p)){
    New-Item -ItemType Directory -Force -Path $p | Out-Null
  }
}
function WriteUtf8NoBom([string]$path, [string]$content){
  $enc = [Text.UTF8Encoding]::new($false)
  [IO.File]::WriteAllText($path, $content, $enc)
}
function BackupFile([string]$root, [string]$stamp, [string]$targetPath, [ref]$log){
  if([string]::IsNullOrWhiteSpace($targetPath)){ return }
  if(-not (Test-Path -LiteralPath $targetPath)){ return }
  $bkDir = Join-Path $root "tools\_patch_backup"
  EnsureDir $bkDir
  $name = Split-Path -Leaf $targetPath
  $bk = Join-Path $bkDir ($name + ".bak-" + $stamp)
  Copy-Item -LiteralPath $targetPath -Destination $bk -Force
  $log.Value += ("- backup: " + $bk)
}

function FindCmd([string]$name){
  $c = Get-Command $name -ErrorAction SilentlyContinue
  if($c){ return $c.Source }
  return $null
}

function RunProc([string]$exe, [string[]]$argv, [string]$workdir){
  $psi = [System.Diagnostics.ProcessStartInfo]::new()
  $psi.FileName = $exe
  $psi.WorkingDirectory = $workdir
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError  = $true
  $psi.UseShellExecute = $false
  foreach($a in $argv){
    if($null -ne $a){ [void]$psi.ArgumentList.Add([string]$a) }
  }
  $p = [System.Diagnostics.Process]::new()
  $p.StartInfo = $psi
  [void]$p.Start()
  $stdout = $p.StandardOutput.ReadToEnd()
  $stderr = $p.StandardError.ReadToEnd()
  $p.WaitForExit()
  return @{ ExitCode = $p.ExitCode; Text = (($stdout + $stderr).TrimEnd()) }
}

# --- paths
$here = $PSScriptRoot
if([string]::IsNullOrWhiteSpace($here)){ $here = (Get-Location).Path }
$root = (Resolve-Path (Join-Path $here "..")).Path
$tools = Join-Path $root "tools"
$reports = Join-Path $root "reports"
EnsureDir $tools
EnsureDir $reports

$stamp = NowStamp
$reportPath = Join-Path $reports ("eco-step-213-rewrite-eco-runner-" + $stamp + ".md")
$log = @()
$log += ("# ECO STEP 213 — rewrite tools/eco-runner.ps1 (argv OK) — " + $stamp)
$log += ""
$log += ("Root: " + $root)
$log += ""

$runnerPath = Join-Path $tools "eco-runner.ps1"

$log += "## DIAG"
$log += ("- runner target: " + $runnerPath)
$log += ""

$log += "## BACKUP"
BackupFile $root $stamp $runnerPath ([ref]$log)
$log += ""

# --- write tools\eco-runner.ps1 (IMPORTANT: single quotes so no $ expansion while generating)
$rl = New-Object System.Collections.Generic.List[string]

$rl.Add('param(')
$rl.Add('  [string[]]$Tasks = @(''lint'',''build''),')
$rl.Add('  [switch]$OpenReport')
$rl.Add(')')
$rl.Add('')
$rl.Add('Set-StrictMode -Version Latest')
$rl.Add('$ErrorActionPreference = "Stop"')
$rl.Add('')
$rl.Add('function NowStamp { Get-Date -Format "yyyyMMdd-HHmmss" }')
$rl.Add('function EnsureDir([string]$p){ if(-not (Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }')
$rl.Add('function WriteUtf8NoBom([string]$path, [string]$content){ [IO.File]::WriteAllText($path, $content, [Text.UTF8Encoding]::new($false)) }')
$rl.Add('function FindCmd([string]$name){ $c = Get-Command $name -ErrorAction SilentlyContinue; if($c){ return $c.Source }; return $null }')
$rl.Add('')
$rl.Add('function RunProc([string]$exe, [string[]]$argv, [string]$workdir){')
$rl.Add('  $psi = [System.Diagnostics.ProcessStartInfo]::new()')
$rl.Add('  $psi.FileName = $exe')
$rl.Add('  $psi.WorkingDirectory = $workdir')
$rl.Add('  $psi.RedirectStandardOutput = $true')
$rl.Add('  $psi.RedirectStandardError  = $true')
$rl.Add('  $psi.UseShellExecute = $false')
$rl.Add('  foreach($a in $argv){ if($null -ne $a){ [void]$psi.ArgumentList.Add([string]$a) } }')
$rl.Add('  $p = [System.Diagnostics.Process]::new()')
$rl.Add('  $p.StartInfo = $psi')
$rl.Add('  [void]$p.Start()')
$rl.Add('  $stdout = $p.StandardOutput.ReadToEnd()')
$rl.Add('  $stderr = $p.StandardError.ReadToEnd()')
$rl.Add('  $p.WaitForExit()')
$rl.Add('  return @{ ExitCode = $p.ExitCode; Text = (($stdout + $stderr).TrimEnd()) }')
$rl.Add('}')
$rl.Add('')
$rl.Add('$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path')
$rl.Add('$reports = Join-Path $root "reports"')
$rl.Add('EnsureDir $reports')
$rl.Add('$stamp = NowStamp')
$rl.Add('$reportPath = Join-Path $reports ("eco-runner-" + $stamp + ".md")')
$rl.Add('$r = @()')
$rl.Add('$r += ("# eco-runner - " + $stamp)')
$rl.Add('$r += ""')
$rl.Add('$r += ("Root: " + $root)')
$rl.Add('$r += ""')
$rl.Add('$r += "## RUN"')
$rl.Add('$r += ""')
$rl.Add('')
$rl.Add('# normalize tasks (accept: -Tasks lint build smoke OR -Tasks "lint,build,smoke")')
$rl.Add('$norm = New-Object System.Collections.Generic.List[string]')
$rl.Add('foreach($t in $Tasks){')
$rl.Add('  if([string]::IsNullOrWhiteSpace($t)){ continue }')
$rl.Add('  $parts = $t.Split(",", [System.StringSplitOptions]::RemoveEmptyEntries)')
$rl.Add('  foreach($p in $parts){')
$rl.Add('    $v = $p.Trim().ToLowerInvariant()')
$rl.Add('    if($v){ $norm.Add($v) }')
$rl.Add('  }')
$rl.Add('}')
$rl.Add('if($norm.Count -eq 0){ $norm.Add("lint"); $norm.Add("build") }')
$rl.Add('')
$rl.Add('$npm = FindCmd "npm.cmd"')
$rl.Add('if(-not $npm){ $npm = FindCmd "npm" }')
$rl.Add('if(-not $npm){ throw "npm not found (need npm.cmd on PATH)" }')
$rl.Add('$pwsh = FindCmd "pwsh"')
$rl.Add('if(-not $pwsh){ $pwsh = FindCmd "powershell" }')
$rl.Add('if(-not $pwsh){ throw "pwsh/powershell not found" }')
$rl.Add('')
$rl.Add('function Fail([int]$code, [string]$msg){')
$rl.Add('  $script:r += "## FAIL"')
$rl.Add('  $script:r += $msg')
$rl.Add('  $script:r += ""')
$rl.Add('  WriteUtf8NoBom $script:reportPath ($script:r -join "`n")')
$rl.Add('  Write-Host ("[REPORT] " + $script:reportPath)')
$rl.Add('  if($OpenReport){ Start-Process $script:reportPath | Out-Null }')
$rl.Add('  exit $code')
$rl.Add('}')
$rl.Add('')
$rl.Add('function RunStep([string]$title, [string]$exe, [string[]]$argv){')
$rl.Add('  $script:r += ("### " + $title)')
$rl.Add('  $script:r += "~~~"')
$rl.Add('  $script:r += ("exe: " + $exe)')
$rl.Add('  $script:r += ("args: " + ($argv -join " "))')
$rl.Add('  $script:r += ""')
$rl.Add('  $res = RunProc $exe $argv $script:root')
$rl.Add('  if($res.Text){ $script:r += $res.Text }')
$rl.Add('  $script:r += "~~~"')
$rl.Add('  $script:r += ("exit: " + $res.ExitCode)')
$rl.Add('  $script:r += ""')
$rl.Add('  return $res.ExitCode')
$rl.Add('}')
$rl.Add('')
$rl.Add('foreach($task in $norm){')
$rl.Add('  if($task -eq "lint"){')
$rl.Add('    $ec = RunStep "npm run lint" $npm @("run","lint")')
$rl.Add('    if($ec -ne 0){ Fail $ec ("command failed: npm run lint (exit " + $ec + ")") }')
$rl.Add('    continue')
$rl.Add('  }')
$rl.Add('  if($task -eq "build"){')
$rl.Add('    $ec = RunStep "npm run build" $npm @("run","build")')
$rl.Add('    if($ec -ne 0){ Fail $ec ("command failed: npm run build (exit " + $ec + ")") }')
$rl.Add('    continue')
$rl.Add('  }')
$rl.Add('  if($task -eq "smoke"){')
$rl.Add('    $tools = Join-Path $root "tools"')
$rl.Add('    $cand = @(Get-ChildItem -LiteralPath $tools -File -Filter "*.ps1" -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "^eco-step-148b.*smoke.*\.ps1$" } | Sort-Object LastWriteTime -Descending)')
$rl.Add('    if($cand.Count -eq 0){ Fail 2 "smoke script not found in tools/ (expected eco-step-148b*smoke*.ps1)" }')
$rl.Add('    $smokePath = $cand[0].FullName')
$rl.Add('    $ec = RunStep ("smoke: " + $cand[0].Name) $pwsh @("-NoProfile","-ExecutionPolicy","Bypass","-File",$smokePath)')
$rl.Add('    if($ec -ne 0){ Fail $ec ("command failed: smoke (exit " + $ec + ")") }')
$rl.Add('    continue')
$rl.Add('  }')
$rl.Add('  $script:r += ("### unknown task: " + $task)')
$rl.Add('  $script:r += "~~~"')
$rl.Add('  $script:r += "WARN: task ignorada (use: lint, build, smoke)"')
$rl.Add('  $script:r += "~~~"')
$rl.Add('  $script:r += ""')
$rl.Add('}')
$rl.Add('')
$rl.Add('WriteUtf8NoBom $reportPath ($r -join "`n")')
$rl.Add('Write-Host ("[REPORT] " + $reportPath)')
$rl.Add('if($OpenReport){ Start-Process $reportPath | Out-Null }')
$rl.Add('exit 0')

WriteUtf8NoBom $runnerPath ($rl.ToArray() -join "`n")

$log += "## PATCH"
$log += ("- wrote: " + $runnerPath)
$log += ""

# --- VERIFY: run runner (lint build) using spaces (no commas)
$pwshExe = FindCmd "pwsh"
if(-not $pwshExe){ $pwshExe = FindCmd "powershell" }
if(-not $pwshExe){ throw "pwsh/powershell not found for verify" }

$log += "## VERIFY"
$log += "### eco-runner (spaces): -Tasks lint build"
$log += "~~~"
$res = RunProc $pwshExe @("-NoProfile","-ExecutionPolicy","Bypass","-File",$runnerPath,"-Tasks","lint","build") $root
if($res.Text){ $log += $res.Text }
$log += "~~~"
$log += ("exit: " + $res.ExitCode)
$log += ""

# optional verify smoke if exists
$smokeCandidates = @(Get-ChildItem -LiteralPath $tools -File -Filter "*.ps1" -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "^eco-step-148b.*smoke.*\.ps1$" } | Sort-Object LastWriteTime -Descending)
if($smokeCandidates.Count -gt 0){
  $log += "### eco-runner (spaces): -Tasks lint build smoke"
  $log += "~~~"
  $res2 = RunProc $pwshExe @("-NoProfile","-ExecutionPolicy","Bypass","-File",$runnerPath,"-Tasks","lint","build","smoke") $root
  if($res2.Text){ $log += $res2.Text }
  $log += "~~~"
  $log += ("exit: " + $res2.ExitCode)
  $log += ""
} else {
  $log += "### smoke"
  $log += "- smoke script eco-step-148b*smoke*.ps1 não encontrado (skip verify smoke)"
  $log += ""
}

WriteUtf8NoBom $reportPath ($log -join "`n")
Write-Host ("[REPORT] " + $reportPath)
if($OpenReport){ Start-Process $reportPath | Out-Null }

if($res.ExitCode -ne 0){
  throw ("VERIFY failed: eco-runner lint build exit " + $res.ExitCode + " (see report): " + $reportPath)
}