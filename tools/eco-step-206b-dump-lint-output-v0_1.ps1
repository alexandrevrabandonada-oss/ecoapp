param([switch]$OpenReport)

$ErrorActionPreference = "Stop"

function NowStamp() { Get-Date -Format "yyyyMMdd-HHmmss" }
function EnsureDir([string]$p){ if(!(Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function WriteUtf8NoBom([string]$p,[string]$content){ [IO.File]::WriteAllText($p, $content, [Text.UTF8Encoding]::new($false)) }

function GetCmd([string]$name) {
  $c = Get-Command $name -ErrorAction SilentlyContinue
  if($c){ return $c.Source }
  return $null
}

function RunLogged([string]$title, [string]$exe, [string[]]$args) {
  $script:r += ""
  $script:r += "### $title"
  $script:r += "~~~"
  $script:r += ("exe: " + $exe)
  $script:r += ("args: " + ($args -join " "))

  $out = @()
  $code = 0
  try {
    $out = & $exe @args 2>&1
    $code = $LASTEXITCODE
  } catch {
    $out += ($_ | Out-String)
    $code = 1
  }

  # log no report
  $script:r += ($out | ForEach-Object { $_.ToString() })
  $script:r += ("exit: " + $code)
  $script:r += "~~~"

  # também imprime no console (pra você ver na hora)
  Write-Host ""
  Write-Host ("[RUN] " + $title)
  Write-Host ("  exe: " + $exe)
  Write-Host ("  args: " + ($args -join " "))
  Write-Host "---------------- OUTPUT ----------------"
  ($out | ForEach-Object { $_.ToString() }) | Write-Host
  Write-Host "----------------------------------------"
  Write-Host ("exit: " + $code)

  return $code
}

$root = Split-Path -Parent $PSScriptRoot
if([string]::IsNullOrWhiteSpace($root)) { $root = (Get-Location).Path }
Set-Location $root

$stamp = NowStamp
EnsureDir (Join-Path $root "reports")
$reportPath = Join-Path $root ("reports\eco-step-206b-dump-lint-output-" + $stamp + ".md")

$script:r = @()
$script:r += "# eco-step-206b — dump lint/build output — $stamp"
$script:r += ""
$script:r += ("Root: " + $root)
$script:r += ""

$script:r += "## DIAG"
$script:r += ""
$script:r += ("PSVersion: " + $($PSVersionTable.PSVersion))
$node = GetCmd "node"
$npmcmd = GetCmd "npm.cmd"
$npm = GetCmd "npm"
$script:r += ("node: " + ($node ?? "(not found)"))
$script:r += ("npm.cmd: " + ($npmcmd ?? "(not found)"))
$script:r += ("npm: " + ($npm ?? "(not found)"))
$script:r += ""

if($node){ try { $script:r += ("node -v: " + ((& $node -v 2>&1) -join " ")) } catch {} }
if($npmcmd){ try { $script:r += ("npm.cmd -v: " + ((& $npmcmd -v 2>&1) -join " ")) } catch {} }
elseif($npm){ try { $script:r += ("npm -v: " + ((& $npm -v 2>&1) -join " ")) } catch {} }

$script:r += ""
$script:r += "## VERIFY"

$npmExe = $npmcmd
if(-not $npmExe) { $npmExe = $npm }
if(-not $npmExe) { throw "npm not found" }

$failed = $false
$ecLint = RunLogged "npm.cmd run lint" $npmExe @("run","lint")
if($ecLint -ne 0){ $failed = $true }

$ecBuild = RunLogged "npm.cmd run build" $npmExe @("run","build")
if($ecBuild -ne 0){ $failed = $true }

$script:r += ""
$script:r += "## RESULT"
$script:r += ("failed: " + $failed)

WriteUtf8NoBom $reportPath ($script:r -join "`n")
Write-Host ("[REPORT] " + $reportPath)

if($OpenReport){ Start-Process $reportPath | Out-Null }

if($failed){ throw "VERIFY failed (see report): $reportPath" }