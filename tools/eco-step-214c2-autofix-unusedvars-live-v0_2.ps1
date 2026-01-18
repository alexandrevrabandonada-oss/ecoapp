param(
  [switch]$OpenReport
)

$ErrorActionPreference = "Stop"

$ToolsDir = $PSScriptRoot
$Root = (Resolve-Path (Join-Path $ToolsDir "..")).Path

function EnsureDir([string]$p){
  if([string]::IsNullOrWhiteSpace($p)){ return }
  if(-not (Test-Path $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null }
}

function NowStamp(){ return (Get-Date -Format "yyyy-MM-dd HH:mm:ss") }

function BackupFileLocal([string]$fullPath, [string]$stamp){
  if(-not (Test-Path $fullPath)){ return }
  $rel = $fullPath
  if($fullPath.StartsWith($Root, [System.StringComparison]::OrdinalIgnoreCase)){
    $rel = $fullPath.Substring($Root.Length).TrimStart('\','/')
  }
  $backupBase = Join-Path $Root ("tools\_patch_backup\eco-step-214c2-" + $stamp)
  $dest = Join-Path $backupBase $rel
  EnsureDir (Split-Path -Parent $dest)
  Copy-Item -LiteralPath $fullPath -Destination $dest -Force
}

function ReadLinesUtf8([string]$p){
  return [IO.File]::ReadAllLines($p, [Text.UTF8Encoding]::new($false))
}
function WriteLinesUtf8([string]$p, [string[]]$lines){
  [IO.File]::WriteAllLines($p, $lines, [Text.UTF8Encoding]::new($false))
}

function IsInsideImportBraces([string[]]$lines, [int]$idx){
  $start = [Math]::Max(0, $idx - 30)
  for($i=$idx; $i -ge $start; $i--){
    $ln = $lines[$i]
    if($ln -match "^\s*import\b" -and $ln -match "\{"){
      # if we see a closing brace between i..idx, it's not "inside"
      for($k=$i; $k -le $idx; $k++){
        if($lines[$k] -match "\}"){ return $false }
      }
      return $true
    }
    if($ln -match "^\s*(const|let|var)\b"){ break }
  }
  return $false
}

function IsInsideObjectDestructure([string[]]$lines, [int]$idx){
  $start = [Math]::Max(0, $idx - 30)
  for($i=$idx; $i -ge $start; $i--){
    $ln = $lines[$i]
    if($ln -match "^\s*(const|let|var)\s*\{"){
      for($k=$i; $k -le $idx; $k++){
        if($lines[$k] -match "\}"){ return $false }
      }
      return $true
    }
    if($ln -match "^\s*import\b"){ break }
  }
  return $false
}

function FixUnusedVarAtLine([string[]]$lines, [int]$idx0, [string]$name){
  if($name.StartsWith("_")){ return $false }
  $line = $lines[$idx0]

  # catch(e) -> catch(_e)
  if($line -match "catch\s*\(\s*" + [Regex]::Escape($name) + "\s*\)"){
    $new = [Regex]::Replace($line, "catch\s*\(\s*" + [Regex]::Escape($name) + "\s*\)", ("catch (_" + $name + ")"))
    if($new -ne $line){ $lines[$idx0] = $new; return $true }
  }

  $inImport = IsInsideImportBraces $lines $idx0
  if($inImport){
    if($line -match "\b" + [Regex]::Escape($name) + "\s+as\s+_" ){ return $false }
    $new = [Regex]::Replace($line, "\b" + [Regex]::Escape($name) + "\b(?!\s+as\b)", ($name + " as _" + $name), 1)
    if($new -ne $line){ $lines[$idx0] = $new; return $true }
  }

  $inObj = IsInsideObjectDestructure $lines $idx0
  if($inObj){
    if($line -match "\b" + [Regex]::Escape($name) + "\s*:"){ return $false }
    $new = [Regex]::Replace($line, "\b" + [Regex]::Escape($name) + "\b(?!\s*:)", ($name + ": _" + $name), 1)
    if($new -ne $line){ $lines[$idx0] = $new; return $true }
  }

  # default: prefix underscore
  $new2 = [Regex]::Replace($line, "\b" + [Regex]::Escape($name) + "\b", ("_" + $name), 1)
  if($new2 -ne $line){ $lines[$idx0] = $new2; return $true }

  return $false
}

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$reportDir = Join-Path $Root "reports"
EnsureDir $reportDir

$reportPath = Join-Path $reportDir ("eco-step-214c2-unusedvars-live-" + $stamp + ".md")
$lintLog    = Join-Path $reportDir ("eco-step-214c2-lint-" + $stamp + ".log")
$verifyLog  = Join-Path $reportDir ("eco-step-214c2-verify-" + $stamp + ".log")

$runner = Join-Path $Root "tools\eco-runner.ps1"
if(-not (Test-Path $runner)){
  throw "tools\eco-runner.ps1 not found"
}

Write-Host ("[" + (NowStamp) + "] STEP 214c2 starting...")
Write-Host ("Root: " + $Root)
Write-Host ("Runner: " + $runner)
Write-Host ""

# 1) LINT (stream to screen + file)
Write-Host ("[" + (NowStamp) + "] Running LINT (streaming)...")
& pwsh -NoProfile -ExecutionPolicy Bypass -File $runner -Tasks lint 2>&1 | Tee-Object -FilePath $lintLog
$lintExit = $LASTEXITCODE
Write-Host ("[" + (NowStamp) + "] LINT done. exit=" + $lintExit)
Write-Host ("Lint log: " + $lintLog)
Write-Host ""

# 2) Parse no-unused-vars from lint log
$raw = [IO.File]::ReadAllLines($lintLog, [Text.UTF8Encoding]::new($false))
$entries = New-Object System.Collections.Generic.List[object]
$curFile = $null

foreach($ln in $raw){
  $mFile = [Regex]::Match($ln, "((?:[A-Za-z]:\\)?(?:\.\.\\|\.\\)?src[\\/].+\.(?:ts|tsx|js|jsx))")
  if($mFile.Success){
    $curFile = $mFile.Groups[1].Value
    continue
  }
  if($ln -match "no-unused-vars"){
    $mPos = [Regex]::Match($ln, "(\d+):(\d+)")
    $mVar = [Regex]::Match($ln, "'([^']+)'")
    if($curFile -and $mPos.Success -and $mVar.Success){
      $entries.Add([pscustomobject]@{
        File=$curFile
        Line=[int]$mPos.Groups[1].Value
        Col=[int]$mPos.Groups[2].Value
        Name=$mVar.Groups[1].Value
        Raw=$ln
      }) | Out-Null
    }
  }
}

Write-Host ("[" + (NowStamp) + "] no-unused-vars entries found: " + $entries.Count)
Write-Host ""

# 3) PATCH
$md = New-Object System.Collections.Generic.List[string]
function MD([string]$s){ $md.Add($s) | Out-Null }

MD "# ECO STEP 214c2 — autofix unused vars (LIVE) — $stamp"
MD ""
MD "Logs:"
MD "- Lint: `"$lintLog`""
MD "- Verify: `"$verifyLog`""
MD ""
MD "## DIAG"
MD "- no-unused-vars entries: $($entries.Count)"
MD ""

$patchedFiles = @{}
$changed = 0

MD "## PATCH"

foreach($e in $entries){
  $rel = ($e.File -replace "^\.\.?[\\/]", "")
  $full = Join-Path $Root $rel
  if(-not (Test-Path $full)){
    MD ("- [SKIP] missing: " + $rel)
    continue
  }

  $idx0 = $e.Line - 1
  $name = $e.Name

  $lines = ReadLinesUtf8 $full
  if($idx0 -lt 0 -or $idx0 -ge $lines.Length){
    MD ("- [SKIP] OOR: " + $rel + ":" + $e.Line + " '" + $name + "'")
    continue
  }

  $before = $lines[$idx0]
  $did = FixUnusedVarAtLine $lines $idx0 $name
  if(-not $did){
    MD ("- [OK]   no change: " + $rel + ":" + $e.Line + " '" + $name + "'")
    continue
  }

  if(-not $patchedFiles.ContainsKey($full)){
    BackupFileLocal $full $stamp
    $patchedFiles[$full] = $true
  }

  WriteLinesUtf8 $full $lines
  $after = $lines[$idx0]
  $changed++

  MD ("- [PATCH] " + $rel + ":" + $e.Line + " '" + $name + "'")
  MD ("  - old: ``" + $before + "``")
  MD ("  - new: ``" + $after + "``")
}

MD ""
MD ("Patched entries: " + $changed)
MD ""

Write-Host ("[" + (NowStamp) + "] PATCH done. changed=" + $changed)
Write-Host ""

# 4) VERIFY (stream)
Write-Host ("[" + (NowStamp) + "] Running VERIFY (lint build) streaming...")
& pwsh -NoProfile -ExecutionPolicy Bypass -File $runner -Tasks lint build 2>&1 | Tee-Object -FilePath $verifyLog
$verifyExit = $LASTEXITCODE
Write-Host ("[" + (NowStamp) + "] VERIFY done. exit=" + $verifyExit)
Write-Host ("Verify log: " + $verifyLog)
Write-Host ""

MD "## VERIFY"
MD "- exit: $verifyExit"
MD ""
MD "If verify failed, inspect logs above."

[IO.File]::WriteAllText($reportPath, ($md -join "`n"), [Text.UTF8Encoding]::new($false))
Write-Host ("[REPORT] " + $reportPath)

if($OpenReport){
  try { ii $reportPath } catch {}
}

if($verifyExit -ne 0){
  throw ("STEP 214c2 failed verify (see report): " + $reportPath)
}

Write-Host ("[" + (NowStamp) + "] STEP 214c2 OK.")