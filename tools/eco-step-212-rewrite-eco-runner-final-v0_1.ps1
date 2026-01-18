param([switch]$OpenReport)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function NowStamp { Get-Date -Format "yyyyMMdd-HHmmss" }
function EnsureDir([string]$p){ if(-not (Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function WriteUtf8NoBom([string]$path,[string]$content){ [IO.File]::WriteAllText($path, $content, [Text.UTF8Encoding]::new($false)) }
function FindCmd([string]$name){ $c = Get-Command $name -ErrorAction SilentlyContinue; if($c){ return $c.Source }; return $null }
function BackupFile([string]$root,[string]$stamp,[string]$target,[ref]$log){
  if(-not (Test-Path -LiteralPath $target)){ $log.Value += ("- backup: skip (not found) " + $target); return }
  $bdir = Join-Path (Join-Path $root "tools") "_patch_backup"
  EnsureDir $bdir
  $name = Split-Path -Leaf $target
  $bak = Join-Path $bdir ($name + ".bak-" + $stamp)
  Copy-Item -LiteralPath $target -Destination $bak -Force
  $log.Value += ("- backup: " + $bak)
}

$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$tools = Join-Path $root "tools"
$reports = Join-Path $root "reports"
EnsureDir $reports
$stamp = NowStamp
$reportPath = Join-Path $reports ("eco-step-212-rewrite-eco-runner-" + $stamp + ".md")

$log = @()
$log += ("# ECO STEP 212 — rewrite eco-runner.ps1 (argv + tasks + smoke) — " + $stamp)
$log += ""
$log += ("Root: " + $root)
$log += ""

$runnerPath = Join-Path $tools "eco-runner.ps1"
BackupFile $root $stamp $runnerPath ([ref]$log)

# --- write tools\eco-runner.ps1 (as lines, no here-strings)
$rl = New-Object System.Collections.Generic.List[string]
$rl.Add("param(")
$rl.Add("  [string[]]$Tasks = @('lint','build'),")
$rl.Add("  [switch]$OpenReport")
$rl.Add(")")
$rl.Add("")
$rl.Add("Set-StrictMode -Version Latest")
$rl.Add("$ErrorActionPreference = 'Stop'")
$rl.Add("")
$rl.Add("function NowStamp { Get-Date -Format 'yyyyMMdd-HHmmss' }")
$rl.Add("function EnsureDir([string]$p){ if(-not (Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }")
$rl.Add("function WriteUtf8NoBom([string]$path,[string]$content){ [IO.File]::WriteAllText($path, $content, [Text.UTF8Encoding]::new($false)) }")
$rl.Add("function FindCmd([string]$name){ $c = Get-Command $name -ErrorAction SilentlyContinue; if($c){ return $c.Source }; return $null }")
$rl.Add("")
$rl.Add("$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path")
$rl.Add("$reports = Join-Path $root 'reports'")
$rl.Add("EnsureDir $reports")
$rl.Add("$stamp = NowStamp")
$rl.Add("$reportPath = Join-Path $reports ('eco-runner-' + $stamp + '.md')")
$rl.Add("")
$rl.Add("# normalize tasks: accept spaces + commas")
$rl.Add("$norm = New-Object System.Collections.Generic.List[string]")
$rl.Add("foreach($t in $Tasks){")
$rl.Add("  if([string]::IsNullOrWhiteSpace($t)){ continue }")
$rl.Add("  foreach($p in $t.Split(',',[System.StringSplitOptions]::RemoveEmptyEntries)){")
$rl.Add("    $v = $p.Trim().ToLowerInvariant()")
$rl.Add("    if($v){ [void]$norm.Add($v) }")
$rl.Add("  }")
$rl.Add("}")
$rl.Add("if($norm.Count -eq 0){ [void]$norm.Add('lint'); [void]$norm.Add('build') }")
$rl.Add("")
$rl.Add("$npmExe = FindCmd 'npm.cmd'")
$rl.Add("if(-not $npmExe){ $npmExe = FindCmd 'npm' }")
$rl.Add("if(-not $npmExe){ throw 'npm not found on PATH' }")
$rl.Add("")
$rl.Add("$pwshExe = FindCmd 'pwsh'")
$rl.Add("if(-not $pwshExe){ $pwshExe = FindCmd 'powershell' }")
$rl.Add("if(-not $pwshExe){ throw 'pwsh/powershell not found on PATH' }")
$rl.Add("")
$rl.Add("$r = @()")
$rl.Add("$r += ('# eco-runner - ' + $stamp)")
$rl.Add("$r += ''")
$rl.Add("$r += ('Root: ' + $root)")
$rl.Add("$r += ('Tasks: ' + ($norm -join ', '))")
$rl.Add("$r += ''")
$rl.Add("$r += '## RUN'")
$rl.Add("$r += ''")
$rl.Add("")
$rl.Add("function RunExe([string]$title, [string]$exe, [string[]]$argv){")
$rl.Add("  $script:r += ('### ' + $title)")
$rl.Add("  $script:r += '~~~'")
$rl.Add("  $script:r += ('exe: ' + $exe)")
$rl.Add("  $script:r += ('args: ' + ($argv -join ' '))")
$rl.Add("  $script:r += ''")
$rl.Add("  Push-Location $script:root")
$rl.Add("  try {")
$rl.Add("    $out = & $exe @argv 2>&1 | Out-String")
$rl.Add("    $ec = $LASTEXITCODE")
$rl.Add("  } finally { Pop-Location }")
$rl.Add("  if($out){ $script:r += $out.TrimEnd() }")
$rl.Add("  $script:r += '~~~'")
$rl.Add("  $script:r += ('exit: ' + $ec)")
$rl.Add("  $script:r += ''")
$rl.Add("  return $ec")
$rl.Add("}")
$rl.Add("")
$rl.Add("foreach($task in $norm){")
$rl.Add("  switch($task){")
$rl.Add("    'lint' {")
$rl.Add("      $ec = RunExe 'npm run lint' $npmExe @('run','lint')")
$rl.Add("      if($ec -ne 0){ throw ('command failed: npm run lint (exit ' + $ec + ')') }")
$rl.Add("    }")
$rl.Add("    'build' {")
$rl.Add("      $ec = RunExe 'npm run build' $npmExe @('run','build')")
$rl.Add("      if($ec -ne 0){ throw ('command failed: npm run build (exit ' + $ec + ')') }")
$rl.Add("    }")
$rl.Add("    'smoke' {")
$rl.Add("      $toolsDir = Join-Path $root 'tools'")
$rl.Add("      $cand = @(Get-ChildItem -LiteralPath $toolsDir -File -Filter '*.ps1' -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^eco-step-148b.*smoke.*\.ps1$' } | Sort-Object LastWriteTime -Descending)")
$rl.Add("      if($cand.Count -eq 0){ throw 'smoke script not found in tools/ (expected eco-step-148b*smoke*.ps1)' }")
$rl.Add("      $smokePath = $cand[0].FullName")
$rl.Add("      $argv = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$smokePath)")
$rl.Add("      if($OpenReport){ $argv += '-OpenReport' }")
$rl.Add("      $ec = RunExe ('smoke: ' + $cand[0].Name) $pwshExe $argv")
$rl.Add("      if($ec -ne 0){ throw ('command failed: smoke (exit ' + $ec + ')') }")
$rl.Add("    }")
$rl.Add("    Default {")
$rl.Add("      $script:r += ('### unknown task: ' + $task)")
$rl.Add("      $script:r += '~~~'")
$rl.Add("      $script:r += 'WARN: task ignorada (use: lint, build, smoke)'")
$rl.Add("      $script:r += '~~~'")
$rl.Add("      $script:r += ''")
$rl.Add("    }")
$rl.Add("  }")
$rl.Add("}")
$rl.Add("")
$rl.Add("WriteUtf8NoBom $reportPath ($r -join ""`n"")")
$rl.Add("Write-Host ('[REPORT] ' + $reportPath)")
$rl.Add("if($OpenReport){ Start-Process $reportPath | Out-Null }")

WriteUtf8NoBom $runnerPath ($rl.ToArray() -join "`n")
$log += "## PATCH"
$log += ("- wrote: " + $runnerPath)
$log += ""

# VERIFY: run runner with spaces (lint build)
$pwsh = FindCmd "pwsh"; if(-not $pwsh){ $pwsh = FindCmd "powershell" }
$log += "## VERIFY"
$log += "### eco-runner (lint build) via spaces"
$log += "~~~"
try {
  $out = & $pwsh -NoProfile -ExecutionPolicy Bypass -File $runnerPath -Tasks lint build 2>&1 | Out-String
  $ec = $LASTEXITCODE
  if($out){ $log += $out.TrimEnd() }
  $log += ("exit: " + $ec)
} catch {
  $log += ($_ | Out-String)
  $ec = 1
}
$log += "~~~"

WriteUtf8NoBom $reportPath ($log -join "`n")
Write-Host ("[REPORT] " + $reportPath)
if($OpenReport){ Start-Process $reportPath | Out-Null }
if($ec -ne 0){ throw ("VERIFY failed (see report): " + $reportPath) }