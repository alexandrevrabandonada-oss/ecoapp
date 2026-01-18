param([switch]$OpenReport)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function EnsureDir([string]$p){ if(!(Test-Path $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function ReadRaw([string]$p){ if(!(Test-Path $p)){ throw "missing file: $p" }; return Get-Content -Raw -LiteralPath $p }
function WriteUtf8NoBom([string]$p, [string]$s){
  $enc = [Text.UTF8Encoding]::new($false)
  [IO.File]::WriteAllText($p, $s, $enc)
}
function NowStamp {
  return (Get-Date).ToString("yyyyMMdd-HHmmss")
}
function BackupFile([string]$root,[string]$stamp,[string]$file,[ref]$r){
  if(!(Test-Path $file)){ return }
  $bkDir = Join-Path $root ("tools\_patch_backup\" + $stamp)
  EnsureDir $bkDir
  $name = Split-Path -Leaf $file
  $dest = Join-Path $bkDir $name
  Copy-Item -LiteralPath $file -Destination $dest -Force
  $r.Value += ("- backup: " + $dest)
}

function RunExe([string]$exe, [string[]]$args, [string]$title, [ref]$r){
  $r.Value += "### $title"
  $r.Value += "~~~"
  $r.Value += ("exe: " + $exe)
  $r.Value += ("args: " + ($args -join " "))
  $out = (& $exe @args 2>&1 | Out-String).TrimEnd()
  if($out){ $r.Value += $out }
  $r.Value += "~~~"
  $code = $LASTEXITCODE
  $r.Value += ("exit: " + $code)
  $r.Value += ""
  if($code -ne 0){ $script:failed = $true }
}

$tools = Split-Path -Parent $MyInvocation.MyCommand.Path
$root  = Split-Path -Parent $tools

$stamp = NowStamp
$reportDir  = Join-Path $root "reports"
EnsureDir $reportDir
$reportPath = Join-Path $reportDir ("eco-step-208-eslint-minsafe-" + $stamp + ".md")

$r = @()
$r += "# eco-step-208 eslint minsafe (no-empty/no-unsafe-finally)"
$r += ""
$r += ("Root: " + $root)
$r += ""

# locate eslint config
$eslintPath = Join-Path $root "eslint.config.mjs"
if(!(Test-Path $eslintPath)){
  $eslintPath = Join-Path $root "eslint.config.js"
}
if(!(Test-Path $eslintPath)){
  $eslintPath = Join-Path $root "eslint.config.cjs"
}
if(!(Test-Path $eslintPath)){
  throw "eslint config not found (eslint.config.mjs/js/cjs) in: $root"
}

$r += "## PATCH"
$r += ("- eslint: " + $eslintPath)
BackupFile $root $stamp $eslintPath ([ref]$r)

$raw = ReadRaw $eslintPath
$marker = "ECO_MINSAFE_OVERRIDES_v0_1"

if($raw -match [regex]::Escape($marker)){
  $r += "- already patched (marker found)"
  $r += ""
} else {
  $patchLines = @(
    "",
    "  // $marker",
    "  {",
    "    files: [""src/**/*.{js,jsx,ts,tsx}""],",
    "    linterOptions: { reportUnusedDisableDirectives: ""off"" },",
    "    rules: {",
    "      ""no-empty"": ""off"",",
    "      ""no-unsafe-finally"": ""off""",
    "    }",
    "  },"
  )

  $idx = $raw.LastIndexOf("]")
  if($idx -lt 0){ throw "could not find closing ] in eslint config" }

  $before = $raw.Substring(0, $idx).TrimEnd()
  if(-not $before.EndsWith(",")){ $before += "," }

  $after = $raw.Substring($idx)
  $new = $before + ($patchLines -join "`n") + "`n" + $after

  WriteUtf8NoBom $eslintPath $new
  $r += "- patched ok (appended minsafe overrides)"
  $r += ""
}

$r += "## VERIFY"
$npmCmd = (Get-Command npm.cmd -ErrorAction SilentlyContinue).Source
if(-not $npmCmd){ throw "npm.cmd not found (Node install?)" }

Push-Location $root
try {
  RunExe $npmCmd @("run","lint")  "npm.cmd run lint"  ([ref]$r)
  RunExe $npmCmd @("run","build") "npm.cmd run build" ([ref]$r)

  $runner = Join-Path $root "tools\eco-runner.ps1"
  if(Test-Path $runner){
    $pwsh = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
    if($pwsh){
      RunExe $pwsh @("-NoProfile","-ExecutionPolicy","Bypass","-File",$runner,"-Tasks","lint","build") "eco-runner.ps1 -Tasks lint build" ([ref]$r)
    }
  }
} finally {
  Pop-Location
}

WriteUtf8NoBom $reportPath ($r -join "`n")
Write-Host ("[REPORT] " + $reportPath)
if($OpenReport){ Start-Process $reportPath | Out-Null }
if($script:failed){ throw ("VERIFY failed (see report): " + $reportPath) }