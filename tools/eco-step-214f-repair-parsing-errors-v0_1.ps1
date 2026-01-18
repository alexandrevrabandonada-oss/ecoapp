param([switch]$OpenReport)

$ErrorActionPreference = "Stop"

$ToolsDir = $PSScriptRoot
$Root = (Resolve-Path (Join-Path $ToolsDir "..")).Path
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"

function EnsureDir([string]$p){
  if([string]::IsNullOrWhiteSpace($p)){ return }
  if(-not (Test-Path -LiteralPath $p)){
    New-Item -ItemType Directory -Force -Path $p | Out-Null
  }
}

$reportDir = Join-Path $Root "reports"
EnsureDir $reportDir
$reportPath = Join-Path $reportDir ("eco-step-214f-repair-parsing-" + $stamp + ".md")
$lintLog    = Join-Path $reportDir ("eco-step-214f-lint-before-" + $stamp + ".log")
$lintLog2   = Join-Path $reportDir ("eco-step-214f-lint-after-" + $stamp + ".log")

function BackupRel([string]$fullPath){
  if(-not (Test-Path -LiteralPath $fullPath)){ return $null }
  $rel = $fullPath
  if($fullPath.StartsWith($Root, [System.StringComparison]::OrdinalIgnoreCase)){
    $rel = $fullPath.Substring($Root.Length).TrimStart('\','/')
  }
  $bbase = Join-Path $Root ("tools\_patch_backup\eco-step-214f-" + $stamp)
  $dest  = Join-Path $bbase $rel
  EnsureDir (Split-Path -Parent $dest)
  Copy-Item -LiteralPath $fullPath -Destination $dest -Force
  return $dest
}

function ReadRaw([string]$fullPath){
  return Get-Content -LiteralPath $fullPath -Raw -Encoding UTF8
}

function WriteRaw([string]$fullPath, [string]$text){
  [IO.File]::WriteAllText($fullPath, $text, [Text.UTF8Encoding]::new($false))
}

function StripAsUnderscoreEverywhere([string]$text){
  # remove only patterns like " as _Something" (we introduced these)
  return [Regex]::Replace($text, "\s+as\s+_[A-Za-z0-9_]+", "")
}

function PatchStripAs([string]$relPath, [ref]$log){
  $full = Join-Path $Root $relPath
  if(-not (Test-Path -LiteralPath $full)){
    $log.Value += "- [SKIP] missing: $relPath"
    return 0
  }

  $raw = ReadRaw $full
  $new = StripAsUnderscoreEverywhere $raw

  if($new -ne $raw){
    $bak = BackupRel $full
    WriteRaw $full $new
    $log.Value += "- [PATCH] $relPath (removed 'as _*') backup: $bak"
    return 1
  } else {
    $log.Value += "- [OK]    $relPath (no change)"
    return 0
  }
}

$runner = Join-Path $Root "tools\eco-runner.ps1"
if(-not (Test-Path -LiteralPath $runner)){
  throw "tools/eco-runner.ps1 not found"
}

Write-Host "[STEP 214f] lint BEFORE (streaming)..."
& pwsh -NoProfile -ExecutionPolicy Bypass -File $runner -Tasks lint 2>&1 | Tee-Object -FilePath $lintLog
$lintExit1 = $LASTEXITCODE
Write-Host ("[STEP 214f] lint BEFORE exit=" + $lintExit1)
Write-Host ("log: " + $lintLog)
Write-Host ""

$log = @()
$log += "# ECO STEP 214f — repair parsing errors (strip 'as _*') — $stamp"
$log += ""
$log += "Root: $Root"
$log += ""
$log += "## DIAG"
$log += "- lint before exit: $lintExit1"
$log += "- lint log: $lintLog"
$log += ""
$log += "## PATCH"

$patched = 0

# Files that are currently failing with Parsing error (from eco-runner report)
$patched += PatchStripAs "src\app\eco\mural-acoes\MuralAcoesClient.tsx" ([ref]$log)
$patched += PatchStripAs "src\app\eco\mural\MuralClient.tsx" ([ref]$log)
$patched += PatchStripAs "src\app\operador\triagem\page.tsx" ([ref]$log)
$patched += PatchStripAs "src\components\eco\OperatorPanel.tsx" ([ref]$log)
$patched += PatchStripAs "src\components\eco\OperatorTriageBoard.tsx" ([ref]$log)

$log += ""
$log += ("Patched files: " + $patched)
$log += ""
$log += "## VERIFY"
$log += ""

Write-Host "[STEP 214f] lint AFTER (streaming)..."
& pwsh -NoProfile -ExecutionPolicy Bypass -File $runner -Tasks lint 2>&1 | Tee-Object -FilePath $lintLog2
$lintExit2 = $LASTEXITCODE
Write-Host ("[STEP 214f] lint AFTER exit=" + $lintExit2)
Write-Host ("log: " + $lintLog2)
Write-Host ""

$log += "- lint after exit: $lintExit2"
$log += "- lint log after: $lintLog2"
$log += ""

[IO.File]::WriteAllText($reportPath, ($log -join "`n"), [Text.UTF8Encoding]::new($false))
Write-Host ("[REPORT] " + $reportPath)

if($OpenReport){
  try { ii $reportPath } catch {}
}

if($lintExit2 -ne 0){
  throw ("STEP 214f still failing lint (see report): " + $reportPath)
}

Write-Host "[STEP 214f] OK — parsing errors fixed."