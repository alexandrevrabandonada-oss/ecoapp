param([switch]$OpenReport)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function NowStamp { Get-Date -Format "yyyyMMdd-HHmmss" }
function EnsureDir([string]$p){ if(-not (Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function WriteUtf8NoBom([string]$path, [string]$content){ [IO.File]::WriteAllText($path, $content, [Text.UTF8Encoding]::new($false)) }

function FindCmd([string]$name){
  $c = Get-Command $name -ErrorAction SilentlyContinue
  if($c){ return $c.Source }
  return $null
}

function RunProc([string]$exe, [string[]]$args, [string]$workdir){
  $psi = [System.Diagnostics.ProcessStartInfo]::new()
  $psi.FileName = $exe
  $psi.WorkingDirectory = $workdir
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError = $true
  $psi.UseShellExecute = $false
  foreach($a in $args){ [void]$psi.ArgumentList.Add($a) }

  $p = [System.Diagnostics.Process]::new()
  $p.StartInfo = $psi
  [void]$p.Start()
  $stdout = $p.StandardOutput.ReadToEnd()
  $stderr = $p.StandardError.ReadToEnd()
  $p.WaitForExit()
  return @{ ExitCode = $p.ExitCode; Text = (($stdout + $stderr).TrimEnd()) }
}

# root do repo
$root = (Resolve-Path ".").Path
$tools = Join-Path $root "tools"
$reports = Join-Path $root "reports"
EnsureDir $reports

$stamp = NowStamp
$reportPath = Join-Path $reports ("eco-step-212-rewrite-eco-runner-" + $stamp + ".md")
$r = @()
$r += ("# eco-step-212 — rewrite eco-runner (Tasks + DryRun + smoke) — " + $stamp)
$r += ""
$r += ("Root: " + $root)
$r += ""

# --- write tools\eco-runner.ps1
$runnerPath = Join-Path $tools "eco-runner.ps1"

$rl = New-Object System.Collections.Generic.List[string]
$rl.Add('param(')
$rl.Add('  [string[]]$Tasks = @("lint","build"),')
$rl.Add('  [switch]$OpenReport,')
$rl.Add('  [switch]$DryRun')
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
$rl.Add('function RunProc([string]$exe, [string[]]$args, [string]$workdir){')
$rl.Add('  $psi = [System.Diagnostics.ProcessStartInfo]::new()')
$rl.Add('  $psi.FileName = $exe')
$rl.Add('  $psi.WorkingDirectory = $workdir')
$rl.Add('  $psi.RedirectStandardOutput = $true')
$rl.Add('  $psi.RedirectStandardError = $true')
$rl.Add('  $psi.UseShellExecute = $false')
$rl.Add('  foreach($a in $args){ [void]$psi.ArgumentList.Add($a) }')
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
$rl.Add('# normalize tasks: accept spaces + commas + quoted single string')
$rl.Add('$raw = ($Tasks -join " ")')
$rl.Add('$t2 = @([regex]::Split($raw, "[,`s]+") | Where-Object { $_ -and $_.Trim() })')
$rl.Add('$t2 = @($t2 | ForEach-Object { $_.Trim().ToLowerInvariant() } | Where-Object { $_ })')
$rl.Add('if($t2.Count -eq 0){ $t2 = @("lint","build") }')
$rl.Add('')
$rl.Add('$npm = FindCmd "npm.cmd"')
$rl.Add('if(-not $npm){ $npm = FindCmd "npm" }')
$rl.Add('if(-not $npm){ throw "npm not found" }')
$rl.Add('')
$rl.Add('$pwsh = FindCmd "pwsh"')
$rl.Add('if(-not $pwsh){ $pwsh = FindCmd "powershell" }')
$rl.Add('if(-not $pwsh){ throw "pwsh/powershell not found" }')
$rl.Add('')
$rl.Add('function RunStep([string]$title, [string]$exe, [string[]]$args){')
$rl.Add('  $script:r += ("### " + $title)')
$rl.Add('  $script:r += "~~~"')
$rl.Add('  $script:r += ("exe: " + $exe)')
$rl.Add('  $script:r += ("args: " + ($args -join " "))')
$rl.Add('  $script:r += ""')
$rl.Add('  if($script:DryRun){')
$rl.Add('    $script:r += "DRY-RUN: skipped"')
$rl.Add('    $script:r += "~~~"')
$rl.Add('    $script:r += "exit: 0"')
$rl.Add('    $script:r += ""')
$rl.Add('    return 0')
$rl.Add('  }')
$rl.Add('  $res = RunProc $exe $args $script:root')
$rl.Add('  if($res.Text){ $script:r += $res.Text }')
$rl.Add('  $script:r += "~~~"')
$rl.Add('  $script:r += ("exit: " + $res.ExitCode)')
$rl.Add('  $script:r += ""')
$rl.Add('  return $res.ExitCode')
$rl.Add('}')
$rl.Add('')
$rl.Add('$exitCode = 0')
$rl.Add('try {')
$rl.Add('  foreach($task in $t2){')
$rl.Add('    if($task -eq "lint"){')
$rl.Add('      $ec = RunStep "npm.cmd run lint" $npm @("run","lint")')
$rl.Add('      if($ec -ne 0){ $exitCode = $ec; throw ("command failed: npm run lint (exit " + $ec + ")") }')
$rl.Add('      continue')
$rl.Add('    }')
$rl.Add('    if($task -eq "build"){')
$rl.Add('      $ec = RunStep "npm.cmd run build" $npm @("run","build")')
$rl.Add('      if($ec -ne 0){ $exitCode = $ec; throw ("command failed: npm run build (exit " + $ec + ")") }')
$rl.Add('      continue')
$rl.Add('    }')
$rl.Add('    if($task -eq "smoke"){')
$rl.Add('      $tools = Join-Path $root "tools"')
$rl.Add('      $cand = @(Get-ChildItem -LiteralPath $tools -File -Filter "*.ps1" -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "^eco-step-148b.*smoke.*\.ps1$" } | Sort-Object LastWriteTime -Descending)')
$rl.Add('      if($cand.Count -eq 0){ $exitCode = 1; throw "smoke script not found in tools/ (expected eco-step-148b*smoke*.ps1)" }')
$rl.Add('      $smokePath = $cand[0].FullName')
$rl.Add('      $ec = RunStep ("smoke: " + $cand[0].Name) $pwsh @("-NoProfile","-ExecutionPolicy","Bypass","-File",$smokePath)')
$rl.Add('      if($ec -ne 0){ $exitCode = $ec; throw ("command failed: smoke (exit " + $ec + ")") }')
$rl.Add('      continue')
$rl.Add('    }')
$rl.Add('    $script:r += ("### unknown task: " + $task)')
$rl.Add('    $script:r += "~~~"')
$rl.Add('    $script:r += "WARN: task ignorada (use: lint, build, smoke)"')
$rl.Add('    $script:r += "~~~"')
$rl.Add('    $script:r += ""')
$rl.Add('  }')
$rl.Add('} finally {')
$rl.Add('  WriteUtf8NoBom $reportPath ($r -join "`n")')
$rl.Add('  Write-Host ("[REPORT] " + $reportPath)')
$rl.Add('  if($OpenReport){ Start-Process $reportPath | Out-Null }')
$rl.Add('}')
$rl.Add('')
$rl.Add('if($exitCode -ne 0){ exit $exitCode }')
$rl.Add('exit 0')

WriteUtf8NoBom $runnerPath ($rl.ToArray() -join "`n")

$r += "## PATCH"
$r += ("- wrote: " + $runnerPath)
$r += ""

# --- VERIFY (DryRun pra testar parsing sem depender do lint)
$pwshExe = FindCmd "pwsh"
if(-not $pwshExe){ $pwshExe = FindCmd "powershell" }
if(-not $pwshExe){ throw "pwsh/powershell not found for verify" }

function V([string]$title, [string[]]$args){
  $script:r += ("### " + $title)
  $script:r += "~~~"
  $res = RunProc $pwshExe $args $root
  if($res.Text){ $script:r += $res.Text }
  $script:r += "~~~"
  $script:r += ("exit: " + $res.ExitCode)
  $script:r += ""
  return $res.ExitCode
}

$r += "## VERIFY"
$ec1 = V "eco-runner DryRun (spaces): -Tasks lint build smoke" @("-NoProfile","-ExecutionPolicy","Bypass","-File",$runnerPath,"-Tasks","lint","build","smoke","-DryRun")
$ec2 = V "eco-runner DryRun (commas): -Tasks 'lint,build,smoke'" @("-NoProfile","-ExecutionPolicy","Bypass","-File",$runnerPath,"-Tasks","lint,build,smoke","-DryRun")
$ec3 = V "eco-runner DryRun (default)" @("-NoProfile","-ExecutionPolicy","Bypass","-File",$runnerPath,"-DryRun")

WriteUtf8NoBom $reportPath ($r -join "`n")
Write-Host ("[REPORT] " + $reportPath)
if($OpenReport){ Start-Process $reportPath | Out-Null }

if(($ec1 + $ec2 + $ec3) -ne 0){
  throw ("VERIFY failed (see report): " + $reportPath)
}