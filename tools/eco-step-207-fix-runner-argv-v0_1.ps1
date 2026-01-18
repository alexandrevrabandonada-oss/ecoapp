param([switch]$OpenReport)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function EnsureDir([string]$p){ if(-not (Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function NowStamp(){ (Get-Date).ToString("yyyyMMdd-HHmmss") }
function WriteUtf8NoBom([string]$p,[string]$c){ [IO.File]::WriteAllText($p,$c,[Text.UTF8Encoding]::new($false)) }
function BackupFile([string]$src,[string]$destDir,[string]$stamp){
  if(Test-Path -LiteralPath $src){
    EnsureDir $destDir
    $name = [IO.Path]::GetFileName($src)
    $dst = Join-Path $destDir ($name + "--" + $stamp)
    Copy-Item -LiteralPath $src -Destination $dst -Force
    return $dst
  }
  return $null
}
function ResolveCmd([string]$cmd){ $c = Get-Command $cmd -ErrorAction SilentlyContinue; if($null -eq $c){ return $null }; return $c.Source }

$root = (Get-Location).Path
$stamp = NowStamp()
EnsureDir (Join-Path $root "tools")
EnsureDir (Join-Path $root "reports")
EnsureDir (Join-Path $root "tools\_patch_backup")
$backupDir = Join-Path $root ("tools\_patch_backup\eco-step-207\" + $stamp)
EnsureDir $backupDir
$reportPath = Join-Path $root ("reports\eco-step-207-fix-runner-argv-" + $stamp + ".md")

$r = @()
$r += "# eco-step-207 — fix runner argv (npm.cmd) — " + $stamp
$r += ""
$r += "Root: " + $root
$r += ""
$r += "## DIAG"
$r += ""
$r += ("PSVersion: " + $($PSVersionTable.PSVersion))
$r += ("node: " + (ResolveCmd "node"))
$r += ("npm.cmd: " + (ResolveCmd "npm.cmd"))
$r += ("npm: " + (ResolveCmd "npm"))
$r += ""
$r += "## PATCH"
$r += ""

# --- escreve tools\eco-runner.ps1 (canônico) ---
$runnerPath = Join-Path $root "tools\eco-runner.ps1"
$old = BackupFile $runnerPath $backupDir $stamp
if($old){ $r += ("- backup: " + $runnerPath + " -> " + $old) }

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
$runner += '$stamp = NowStamp()'
$runner += '$reportsDir = Join-Path $root "reports"'
$runner += 'EnsureDir $reportsDir'
$runner += '$reportPath = Join-Path $reportsDir ("eco-runner-" + $stamp + ".md")'
$runner += ''
$runner += '$script:failed = $false'
$runner += '$script:r = @()'
$runner += '$script:r += "# eco-runner — " + $stamp'
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
$runner += 'function RunPs1([string]$title, [string]$scriptPath){'
$runner += '  $script:r += "### " + $title'
$runner += '  $script:r += "~~~"'
$runner += '  $script:r += ("ps1: " + $scriptPath)'
$runner += '  $exit = 0'
$runner += '  try {'
$runner += '    $out = (& $scriptPath 2>&1 | Out-String)'
$runner += '    if($out){ $script:r += $out.TrimEnd() }'
$runner += '  } catch {'
$runner += '    $exit = 1'
$runner += '    $script:r += ($_ | Out-String)'
$runner += '  }'
$runner += '  $script:r += ("exit: " + $exit)'
$runner += '  $script:r += "~~~"'
$runner += '  $script:r += ""'
$runner += '  if($exit -ne 0){ $script:failed = $true }'
$runner += '}'
$runner += ''
$runner += '$npmCmd = (Get-Command npm.cmd -ErrorAction Stop).Source'
$runner += ''
$runner += 'foreach($t in $Tasks){'
$runner += '  $k = ($t ?? "").ToString().Trim().ToLowerInvariant()'
$runner += '  switch($k){'
$runner += '    "lint"  { RunExe "npm.cmd run lint"  $npmCmd @("run","lint") }'
$runner += '    "build" { RunExe "npm.cmd run build" $npmCmd @("run","build") }'
$runner += '    "smoke" {'
$runner += '      $toolsDir = Join-Path $root "tools"'
$runner += '      $sm = Get-ChildItem -LiteralPath $toolsDir -Filter "eco-step-148b*smoke*.ps1" -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1'
$runner += '      if($null -eq $sm){'
$runner += '        $script:r += "### smoke"'
$runner += '        $script:r += "~~~"'
$runner += '        $script:r += "WARN: nao achei tools\eco-step-148b*smoke*.ps1"'
$runner += '        $script:r += "exit: 0"'
$runner += '        $script:r += "~~~"'
$runner += '        $script:r += ""'
$runner += '      } else {'
$runner += '        RunPs1 ("smoke: " + $sm.Name) $sm.FullName'
$runner += '      }'
$runner += '    }'
$runner += '    default {'
$runner += '      if($k){'
$runner += '        $script:r += "### unknown task: " + $k'
$runner += '        $script:r += "~~~"'
$runner += '        $script:r += "exit: 0"'
$runner += '        $script:r += "~~~"'
$runner += '        $script:r += ""'
$runner += '      }'
$runner += '    }'
$runner += '  }'
$runner += '}'
$runner += ''
$runner += 'WriteUtf8NoBom $reportPath ($script:r -join "`n")'
$runner += 'Write-Host ("[REPORT] " + $reportPath)'
$runner += 'if($OpenReport){ Start-Process $reportPath }'
$runner += 'if($script:failed){ throw ("Runner failed (see report): " + $reportPath) }'

WriteUtf8NoBom $runnerPath ($runner -join "`n")
$r += ("[OK] wrote: " + $runnerPath)
$r += ""

## VERIFY
$r += ""
$pwsh = ResolveCmd "pwsh"
if(-not $pwsh){ $pwsh = ResolveCmd "powershell" }
$call = @("-NoProfile","-ExecutionPolicy","Bypass","-File",$runnerPath,"-Tasks","lint","build")
if($OpenReport){ $call += "-OpenReport" }
$r += "### run eco-runner (lint+build)"
$r += "~~~"
$r += ("exe: " + $pwsh)
$r += ("args: " + ($call -join " "))
try { $out = (& $pwsh @call 2>&1 | Out-String); if($out){ $r += $out.TrimEnd() } } catch { $r += ($_ | Out-String) }
$r += "~~~"
$r += ""

WriteUtf8NoBom $reportPath ($r -join "`n")
Write-Host ("[REPORT] " + $reportPath)
if($OpenReport){ Start-Process $reportPath }