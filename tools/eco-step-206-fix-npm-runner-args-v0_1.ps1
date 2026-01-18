# eco-step-206 — fix npm runner args + scripts with ":" (eslint9) — v0.1
# DIAG -> PATCH -> VERIFY -> REPORT
param([switch]$OpenReport)

$ErrorActionPreference = "Stop"

function NowStamp() { Get-Date -Format "yyyyMMdd-HHmmss" }

function EnsureDir([string]$p) { if(-not (Test-Path -LiteralPath $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null } }

function WriteUtf8NoBom([string]$path, [string]$content) {
  [IO.File]::WriteAllText($path, $content, [Text.UTF8Encoding]::new($false))
}

function BackupFile([string]$src, [string]$dst) {
  EnsureDir (Split-Path -Parent $dst)
  Copy-Item -LiteralPath $src -Destination $dst -Force
}

function GetCmd([string]$name) {
  $c = Get-Command $name -ErrorAction SilentlyContinue
  if($c) { return $c.Source }
  return $null
}

function RunCmd([string]$title, [string]$exe, [string[]]$args) {
  $script:r += ""
  $script:r += "### $title"
  $script:r += "~~~"
  $script:r += ("exe: " + $exe)
  if($args -and $args.Count -gt 0) {
    $script:r += ("args: " + ($args -join " "))
  } else {
    $script:r += "args: (none)"
  }

  $out = @()
  try {
    if($args -and $args.Count -gt 0) {
      $out = & $exe @args 2>&1
    } else {
      $out = & $exe 2>&1
    }
    if($LASTEXITCODE -ne 0) {
      $script:r += ($out | ForEach-Object { $_.ToString() })
      throw ("command failed: " + $title + " (exit " + $LASTEXITCODE + ")")
    }
    $script:r += ($out | ForEach-Object { $_.ToString() })
  } catch {
    $script:r += ($out | ForEach-Object { $_.ToString() })
    throw
  } finally {
    $script:r += "~~~"
  }
}

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$stamp = NowStamp
EnsureDir (Join-Path $root "reports")
EnsureDir (Join-Path $root "tools\_patch_backup")

$reportPath = Join-Path $root ("reports\eco-step-206-fix-npm-runner-args-" + $stamp + ".md")
$script:r = @()
$script:r += "# eco-step-206 — fix npm runner args + scripts ':' (eslint9) — $stamp"
$script:r += ""
$script:r += "Root: $root"
$script:r += ""

# ----------------
# DIAG
# ----------------
$script:r += "## DIAG"
$script:r += ""
$script:r += "- PSVersion: $($PSVersionTable.PSVersion)"
$node = GetCmd "node"
$npmcmd = GetCmd "npm.cmd"
$npm = GetCmd "npm"
$script:r += "- node: " + ($node ?? "(not found)")
$script:r += "- npm.cmd: " + ($npmcmd ?? "(not found)")
$script:r += "- npm: " + ($npm ?? "(not found)")
$script:r += ""

if($node) {
  try { $nv = & $node -v 2>&1 } catch { $nv = $_.Exception.Message }
  $script:r += "- node -v: " + ($nv -join " ")
}
if($npmcmd) {
  try { $vv = & $npmcmd -v 2>&1 } catch { $vv = $_.Exception.Message }
  $script:r += "- npm.cmd -v: " + ($vv -join " ")
} elseif($npm) {
  try { $vv = & $npm -v 2>&1 } catch { $vv = $_.Exception.Message }
  $script:r += "- npm -v: " + ($vv -join " ")
}

$script:r += ""

# prefer npm.cmd on Windows
$npmExe = $npmcmd
if(-not $npmExe) { $npmExe = $npm }
if(-not $npmExe) { throw "npm not found (nem npm.cmd nem npm)" }

# ----------------
# PATCH
# ----------------
$script:r += "## PATCH"
$pkgPath = Join-Path $root "package.json"
if(-not (Test-Path -LiteralPath $pkgPath)) { throw "package.json not found" }

$bak = Join-Path $root ("tools\_patch_backup\package.json--" + $stamp)
BackupFile $pkgPath $bak
$script:r += "- backup: $bak"

$raw = Get-Content -LiteralPath $pkgPath -Raw
# IMPORTANT: -AsHashtable so we can safely set keys like 'lint:debug'
$pkg = $raw | ConvertFrom-Json -AsHashtable

if(-not $pkg.ContainsKey("scripts") -or -not ($pkg["scripts"] -is [hashtable])) {
  $pkg["scripts"] = @{}
}

# keep your current working lint (real lint on src/)
$pkg["scripts"]["lint"] = "node ./node_modules/eslint/bin/eslint.js src --max-warnings 9999"
$pkg["scripts"]["lint:fix"] = "node ./node_modules/eslint/bin/eslint.js src --fix --max-warnings 9999"
# useful debug: print resolved config for one file
$pkg["scripts"]["lint:debug"] = "node ./node_modules/eslint/bin/eslint.js --print-config src/app/layout.tsx"
$pkg["scripts"]["verify"] = "npm run lint && npm run build"

WriteUtf8NoBom $pkgPath (($pkg | ConvertTo-Json -Depth 100))
$script:r += "- ok: scripts.lint / lint:fix / lint:debug / verify"

$script:r += ""
$script:r += "scripts now:"
$script:r += ""
$script:r += "- lint: " + $pkg["scripts"]["lint"]
$script:r += "- lint:fix: " + $pkg["scripts"]["lint:fix"]
$script:r += "- lint:debug: " + $pkg["scripts"]["lint:debug"]
$script:r += "- verify: " + $pkg["scripts"]["verify"]

# ----------------
# VERIFY
# ----------------
$script:r += ""
$script:r += "## VERIFY"
# IMPORTANT: args separated (NO quotes like 'run lint')
RunCmd "npm.cmd run lint" $npmExe @("run","lint")
RunCmd "npm.cmd run build" $npmExe @("run","build")

# ----------------
# REPORT
# ----------------
WriteUtf8NoBom $reportPath ($script:r -join "`n")
Write-Host ("[REPORT] " + $reportPath)

if($OpenReport) { Start-Process $reportPath | Out-Null }