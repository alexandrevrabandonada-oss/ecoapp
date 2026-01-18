param([switch]$OpenReport)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function EnsureDir([string]$p){ if(-not (Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function NowStamp(){ (Get-Date).ToString("yyyyMMdd-HHmmss") }
function WriteUtf8NoBom([string]$p,[string]$c){ [IO.File]::WriteAllText($p,$c,[Text.UTF8Encoding]::new($false)) }
function ReadRaw([string]$p){ Get-Content -LiteralPath $p -Raw }
function BackupFile([string]$src,[string]$destDir,[string]$stamp,[ref]$r){
  if(Test-Path -LiteralPath $src){
    EnsureDir $destDir
    $name = Split-Path $src -Leaf
    $dst = Join-Path $destDir ($name + "--" + $stamp)
    Copy-Item -LiteralPath $src -Destination $dst -Force
    $r.Value += ("- backup: " + $src + " -> " + $dst)
    return
  }
  $r.Value += ("- [SKIP] missing: " + $src)
}

$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$stamp = NowStamp
EnsureDir (Join-Path $root "reports")
$reportPath = Join-Path $root ("reports\eco-step-207b-fix-runner-argv-" + $stamp + ".md")
$backupDir = Join-Path $root ("tools\_patch_backup\eco-step-207b\" + $stamp)
EnsureDir $backupDir

$r = @()
$r += "# eco-step-207b - fix runner argv - " + $stamp
$r += ""
$r += ("Root: " + $root)
$r += ""
$r += "## PATCH - write tools\eco-runner.ps1"

$runnerPath = Join-Path $root "tools\eco-runner.ps1"
BackupFile $runnerPath $backupDir $stamp ([ref]$r)

$runner = @()
$runner += 'param([string[]]$Tasks = @("lint","build"), [switch]$OpenReport)'
$runner += 'Set-StrictMode -Version Latest'
$runner += '$ErrorActionPreference = "Stop"'
$runner += ''
$runner += 'function EnsureDir([string]$p){ if(-not (Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }'
$runner += 'function NowStamp(){ (Get-Date).ToString("yyyyMMdd-HHmmss") }'
$runner += 'function WriteUtf8NoBom([string]$p,[string]$c){ [IO.File]::WriteAllText($p,$c,[Text.UTF8Encoding]::new($false)) }'
$runner += ''
$runner += '$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path'
$runner += '$stamp = NowStamp'
$runner += '$reportsDir = Join-Path $root "reports"'
$runner += 'EnsureDir $reportsDir'
$runner += '$reportPath = Join-Path $reportsDir ("eco-runner-" + $stamp + ".md")'
$runner += ''
$runner += '$script:failed = $false'
$runner += '$script:r = @()'
$runner += '$script:r += "# eco-runner - " + $stamp'
$runner += '$script:r += ""'
$runner += '$script:r += ("Root: " + $root)'
$runner += '$script:r += ""'
$runner += '$script:r += "## RUN"'
$runner += '$script:r += ""'
$runner += ''
$runner += 'function RunExe([string]$title, [string]$exe, [string[]]$argv){'
$runner += '  $script:r += "### " + $title'
$runner += '  $script:r += "~~~"'
$runner += '  $script:r += ("exe: " + $exe)'
$runner += '  $script:r += ("args: " + ($argv -join " "))'
$runner += '  $out = (& $exe @argv 2>&1 | Out-String)'
$runner += '  $exit = $LASTEXITCODE'
$runner += '  if($out){ $script:r += $out.TrimEnd() }'
$runner += '  $script:r += ("exit: " + $exit)'
$runner += '  $script:r += "~~~"'
$runner += '  $script:r += ""'
$runner += '  if($exit -ne 0){ $script:failed = $true }'
$runner += '}'
$runner += ''
$runner += '$npmCmd = (Get-Command npm.cmd -ErrorAction Stop).Source'
$runner += ''
$runner += 'foreach($t in $Tasks){'
$runner += '  $k = (($t + "").Trim().ToLowerInvariant())'
$runner += '  if([string]::IsNullOrWhiteSpace($k)){ continue }'
$runner += '  switch($k){'
$runner += '    "lint"  { RunExe "npm.cmd run lint"  $npmCmd @("run","lint") }'
$runner += '    "build" { RunExe "npm.cmd run build" $npmCmd @("run","build") }'
$runner += '    default {'
$runner += '      $script:r += "### unknown task: " + $k'
$runner += '      $script:r += "~~~"'
$runner += '      $script:r += "exit: 0"'
$runner += '      $script:r += "~~~"'
$runner += '      $script:r += ""'
$runner += '    }'
$runner += '  }'
$runner += '}'
$runner += ''
$runner += 'WriteUtf8NoBom $reportPath ($script:r -join "`n")'
$runner += 'Write-Host ("[REPORT] " + $reportPath)'
$runner += 'if($OpenReport){ Start-Process $reportPath | Out-Null }'
$runner += 'if($script:failed){ throw ("Runner failed (see report): " + $reportPath) }'

WriteUtf8NoBom $runnerPath ($runner -join "`n")
$r += ("- wrote: " + $runnerPath)
$r += ""

$r += "## VERIFY - run eco-runner (lint+build)"
$r += "~~~"
try {
  $out = (& pwsh -NoProfile -ExecutionPolicy Bypass -File $runnerPath -Tasks lint build 2>&1 | Out-String)
  if($out){ $r += $out.TrimEnd() }
} catch {
  $r += ($_ | Out-String)
  throw
}
$r += "~~~"
$r += ""

WriteUtf8NoBom $reportPath ($r -join "`n")
Write-Host ("[REPORT] " + $reportPath)
if($OpenReport){ Start-Process $reportPath | Out-Null }