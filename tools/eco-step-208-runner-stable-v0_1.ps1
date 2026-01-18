param([switch]$OpenReport)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function NowStamp { Get-Date -Format "yyyyMMdd-HHmmss" }
function EnsureDir([string]$p){ if(!(Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function WriteUtf8NoBom([string]$p, [string]$c){ [IO.File]::WriteAllText($p, $c, [Text.UTF8Encoding]::new($false)) }
function BackupFile([string]$backupDir, [string]$srcPath, [ref]$log){
  if(Test-Path -LiteralPath $srcPath){
    $name = Split-Path -Leaf $srcPath
    $dst = Join-Path $backupDir $name
    Copy-Item -LiteralPath $srcPath -Destination $dst -Force
    $log.Value += ("[BACKUP] " + $srcPath + " -> " + $dst)
  } else {
    $log.Value += ("[BACKUP] (skip, missing) " + $srcPath)
  }
}

$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$stamp = NowStamp
$reportDir = Join-Path $root "reports"
EnsureDir $reportDir
$reportPath = Join-Path $reportDir ("eco-step-208-runner-stable-" + $stamp + ".md")

$backupDir = Join-Path $root ("tools\_patch_backup\eco-step-208\" + $stamp)
EnsureDir $backupDir

$r = @()
$r += ("# eco-step-208 — runner estável (argv correto p/ npm) — " + $stamp)
$r += ""
$r += ("Root: " + $root)
$r += ""

# ---------------- PATCH: tools\eco-runner.ps1 ----------------
$runnerPath = Join-Path $root "tools\eco-runner.ps1"
BackupFile $backupDir $runnerPath ([ref]$r)

$runnerLines = @(
'param(',
'  [Parameter()] [string[]] $Tasks = @("lint","build"),',
'  [switch] $OpenReport',
')',
'',
'Set-StrictMode -Version Latest',
'$ErrorActionPreference = "Stop"',
'',
'function NowStamp { Get-Date -Format "yyyyMMdd-HHmmss" }',
'function EnsureDir([string]$p){ if(!(Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }',
'function WriteUtf8NoBom([string]$p, [string]$c){ [IO.File]::WriteAllText($p, $c, [Text.UTF8Encoding]::new($false)) }',
'',
'$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path',
'$stamp = NowStamp',
'$reportDir = Join-Path $root "reports"',
'EnsureDir $reportDir',
'$reportPath = Join-Path $reportDir ("eco-runner-" + $stamp + ".md")',
'',
'$script:failed = $false',
'$script:r = @()',
'$script:r += ("# eco-runner - " + $stamp)',
'$script:r += ""',
'$script:r += ("Root: " + $root)',
'$script:r += ""',
'$script:r += "## RUN"',
'$script:r += ""',
'',
'function RunNative {',
'  param(',
'    [string]$title,',
'    [string]$exe,',
'    [string[]]$args',
'  )',
'  $script:r += ("### " + $title)',
'  $script:r += "~~~"',
'  $script:r += ("exe: " + $exe)',
'  $script:r += ("args: " + ($args -join " "))',
'  $script:r += ""',
'',
'  $out = & $exe @args 2>&1',
'  $exit = $LASTEXITCODE',
'  if($out){ $script:r += $out }',
'  $script:r += "----------------------------------------"',
'  $script:r += ("exit: " + $exit)',
'  $script:r += "~~~"',
'  $script:r += ""',
'',
'  if($exit -ne 0){ $script:failed = $true }',
'}',
'',
'function FindLatestSmoke {',
'  $toolsDir = Join-Path $root "tools"',
'  $candidates = Get-ChildItem -LiteralPath $toolsDir -File -Filter "eco-step-148b*smoke*.ps1" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending',
'  if($candidates -and $candidates.Count -gt 0){ return $candidates[0].FullName }',
'  return $null',
'}',
'',
'# npm.cmd (args SEMPRE separados)',
'$npmCmd = (Get-Command npm.cmd -ErrorAction Stop).Source',
'',
'foreach($t in $Tasks){',
'  $k = $t.ToLowerInvariant().Trim()',
'  if($k -eq "lint"){',
'    RunNative "npm.cmd run lint" $npmCmd @("run","lint")',
'    continue',
'  }',
'  if($k -eq "build"){',
'    RunNative "npm.cmd run build" $npmCmd @("run","build")',
'    continue',
'  }',
'  if($k -eq "smoke"){',
'    $smoke = FindLatestSmoke',
'    if(!$smoke){',
'      $script:r += "### smoke"',
'      $script:r += "~~~"',
'      $script:r += "WARN: nenhum eco-step-148b*smoke*.ps1 encontrado em tools/"',
'      $script:r += "exit: 0"',
'      $script:r += "~~~"',
'      $script:r += ""',
'      continue',
'    }',
'    # tenta detectar se o smoke aceita -OpenReport (sem quebrar caso não aceite)',
'    $head = (Get-Content -LiteralPath $smoke -TotalCount 80 -ErrorAction SilentlyContinue) -join "`n"',
'    $args = @("-NoProfile","-ExecutionPolicy","Bypass","-File",$smoke)',
'    if($head -match "\bOpenReport\b"){ $args += "-OpenReport" }',
'    RunNative ("pwsh smoke: " + (Split-Path -Leaf $smoke)) "pwsh" $args',
'    continue',
'  }',
'',
'  $script:r += ("### unknown task: " + $t)',
'  $script:r += "~~~"',
'  $script:r += "WARN: task ignorada (use: lint, build, smoke)"',
'  $script:r += "exit: 0"',
'  $script:r += "~~~"',
'  $script:r += ""',
'}',
'',
'WriteUtf8NoBom $reportPath ($script:r -join "`n")',
'Write-Host ("[REPORT] " + $reportPath)',
'if($OpenReport){ try { Start-Process $reportPath | Out-Null } catch {} }',
'',
'if($script:failed){ throw ("Runner failed (see report): " + $reportPath) }'
)

EnsureDir (Split-Path -Parent $runnerPath)
WriteUtf8NoBom $runnerPath ($runnerLines -join "`n")

$r += "## PATCH"
$r += ("- wrote: " + $runnerPath)
$r += ""

# ---------------- VERIFY (rodar o runner novo) ----------------
$r += "## VERIFY"
$r += "~~~"
try{
  $out = & pwsh -NoProfile -ExecutionPolicy Bypass -File $runnerPath -Tasks lint build 2>&1
  $ec = $LASTEXITCODE
  if($out){ $r += $out }
  $r += ("exit: " + $ec)
  if($ec -ne 0){ throw ("runner exit " + $ec) }
}catch{
  $r += ($_ | Out-String)
  $r += "exit: 1"
  WriteUtf8NoBom $reportPath ($r -join "`n")
  Write-Host ("[REPORT] " + $reportPath)
  if($OpenReport){ Start-Process $reportPath | Out-Null }
  throw
}
$r += "~~~"
$r += ""

WriteUtf8NoBom $reportPath ($r -join "`n")
Write-Host ("[REPORT] " + $reportPath)
if($OpenReport){ Start-Process $reportPath | Out-Null }