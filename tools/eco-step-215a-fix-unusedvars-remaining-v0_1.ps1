param([switch]$OpenReport)

$ErrorActionPreference = "Stop"

$ToolsDir = $PSScriptRoot
$Root = (Resolve-Path (Join-Path $ToolsDir "..")).Path
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"

function EnsureDir([string]$p){
  if([string]::IsNullOrWhiteSpace($p)){ return }
  if(-not (Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null }
}

function WriteUtf8NoBom([string]$p,[string]$s){
  EnsureDir (Split-Path -Parent $p)
  [IO.File]::WriteAllText($p, $s, [Text.UTF8Encoding]::new($false))
}

function BackupRel([string]$fullPath){
  if(-not (Test-Path -LiteralPath $fullPath)){ return $null }
  $rel = $fullPath
  if($fullPath.StartsWith($Root, [System.StringComparison]::OrdinalIgnoreCase)){
    $rel = $fullPath.Substring($Root.Length).TrimStart('\','/')
  }
  $bbase = Join-Path $Root ("tools\_patch_backup\eco-step-215a-" + $stamp)
  $dest  = Join-Path $bbase $rel
  EnsureDir (Split-Path -Parent $dest)
  Copy-Item -LiteralPath $fullPath -Destination $dest -Force
  return $dest
}

function ReadLines([string]$p){
  return [IO.File]::ReadAllLines($p, [Text.UTF8Encoding]::new($false))
}
function WriteLines([string]$p, [string[]]$lines){
  [IO.File]::WriteAllLines($p, $lines, [Text.UTF8Encoding]::new($false))
}

function PatchFileLines([string]$relPath, [ScriptBlock]$mutator, [ref]$log){
  $full = Join-Path $Root $relPath
  if(-not (Test-Path -LiteralPath $full)){
    $log.Value += ("- [SKIP] missing: " + $relPath)
    return 0
  }
  $lines = ReadLines $full
  $before = ($lines -join "`n")
  & $mutator ([ref]$lines) | Out-Null
  $after = ($lines -join "`n")
  if($after -ne $before){
    $bak = BackupRel $full
    WriteLines $full $lines
    $log.Value += ("- [PATCH] " + $relPath + " backup: " + $bak)
    return 1
  } else {
    $log.Value += ("- [OK]    " + $relPath + " (no change)")
    return 0
  }
}

function AliasInImportLine([string]$line, [string]$name, [string]$alias){
  # Only touch: import { ... } from '...'
  if($line -notmatch "^\s*import\s+\{"){ return $line }
  if($line -notmatch "\}\s*from\s*['`"]"){ return $line }
  # replace token inside braces, only if not already "as ..."
  $pat = "\b" + [Regex]::Escape($name) + "\b(?!\s+as\b)"
  return [Regex]::Replace($line, $pat, ($name + " as " + $alias), 1)
}

function RenameConstLet([string]$line, [string]$name, [string]$newName){
  $pat = "^\s*(const|let)\s+" + [Regex]::Escape($name) + "\b"
  if($line -match $pat){
    return [Regex]::Replace($line, $pat, ("`$1 " + $newName), 1)
  }
  return $line
}

function RenameDestructureKey([string]$line, [string]$key, [string]$newName){
  # const { id } = ...  -> const { id: _id } = ...
  if($line -notmatch "^\s*(const|let)\s*\{"){ return $line }
  if($line -match ("\b" + [Regex]::Escape($key) + "\s*:")){ return $line } # already aliased
  $pat = "\b" + [Regex]::Escape($key) + "\b(?!\s*:)"
  return [Regex]::Replace($line, $pat, ($key + ": " + $newName), 1)
}

function RemoveCatchBinding([string]$line){
  # catch (_e) {  -> catch {
  return [Regex]::Replace($line, "catch\s*\(\s*_[A-Za-z0-9_]+\s*\)\s*\{", "catch {")
}

$reportDir = Join-Path $Root "reports"
EnsureDir $reportDir
$reportPath = Join-Path $reportDir ("eco-step-215a-unusedvars-remaining-" + $stamp + ".md")
$lintLog    = Join-Path $reportDir ("eco-step-215a-lint-" + $stamp + ".log")

$log = @()
$log += "# ECO STEP 215a — fix remaining no-unused-vars — $stamp"
$log += ""
$log += "Root: $Root"
$log += ""
$log += "## PATCH"
$patched = 0

# 1) route.ts: remove catch binding (eslint still warns even with _e)
$patched += PatchFileLines "src\app\api\eco\points\react\route.ts" {
  param([ref]$lines)
  for($i=0; $i -lt $lines.Value.Length; $i++){
    $lines.Value[$i] = RemoveCatchBinding $lines.Value[$i]
  }
} ([ref]$log)

# 2) normStatus -> _normStatus (declaration)
$patched += PatchFileLines "src\app\api\eco\points\resolve\route.ts" {
  param([ref]$lines)
  for($i=0; $i -lt $lines.Value.Length; $i++){
    $lines.Value[$i] = RenameConstLet $lines.Value[$i] "normStatus" "_normStatus"
  }
} ([ref]$log)

# 3) id -> _id (handle both destructure and const)
$patched += PatchFileLines "src\app\api\pickup-requests\[id]\route.ts" {
  param([ref]$lines)
  for($i=0; $i -lt $lines.Value.Length; $i++){
    $ln = $lines.Value[$i]
    $ln = RenameDestructureKey $ln "id" "_id"
    $ln = RenameConstLet $ln "id" "_id"
    $lines.Value[$i] = $ln
  }
} ([ref]$log)

# 4) MuralAcoesClient: dt/score alias only in import lines; it/item rename if declared
$patched += PatchFileLines "src\app\eco\mural-acoes\MuralAcoesClient.tsx" {
  param([ref]$lines)
  for($i=0; $i -lt $lines.Value.Length; $i++){
    $ln = $lines.Value[$i]
    $ln = AliasInImportLine $ln "dt" "_dt"
    $ln = AliasInImportLine $ln "score" "_score"
    $ln = RenameConstLet $ln "it" "_it"
    $ln = RenameConstLet $ln "item" "_item"
    $lines.Value[$i] = $ln
  }
} ([ref]$log)

# 5) MuralClient: MuralPointActionsClient alias only in import lines
$patched += PatchFileLines "src\app\eco\mural\MuralClient.tsx" {
  param([ref]$lines)
  for($i=0; $i -lt $lines.Value.Length; $i++){
    $lines.Value[$i] = AliasInImportLine $lines.Value[$i] "MuralPointActionsClient" "_MuralPointActionsClient"
  }
} ([ref]$log)

# 6) triagem page: DayCloseShortcut alias only in import lines
$patched += PatchFileLines "src\app\operador\triagem\page.tsx" {
  param([ref]$lines)
  for($i=0; $i -lt $lines.Value.Length; $i++){
    $lines.Value[$i] = AliasInImportLine $lines.Value[$i] "DayCloseShortcut" "_DayCloseShortcut"
  }
} ([ref]$log)

# 7) OperatorPanel: EcoCardFormat alias only in import lines
$patched += PatchFileLines "src\components\eco\OperatorPanel.tsx" {
  param([ref]$lines)
  for($i=0; $i -lt $lines.Value.Length; $i++){
    $lines.Value[$i] = AliasInImportLine $lines.Value[$i] "EcoCardFormat" "_EcoCardFormat"
  }
} ([ref]$log)

# 8) OperatorTriageBoard: STATUS_OPTIONS + ShareNav alias only in import lines
$patched += PatchFileLines "src\components\eco\OperatorTriageBoard.tsx" {
  param([ref]$lines)
  for($i=0; $i -lt $lines.Value.Length; $i++){
    $ln = $lines.Value[$i]
    $ln = AliasInImportLine $ln "STATUS_OPTIONS" "_STATUS_OPTIONS"
    $ln = AliasInImportLine $ln "ShareNav" "_ShareNav"
    $lines.Value[$i] = $ln
  }
} ([ref]$log)

# 9) PointDetailClient: alias unused imports + rename ProofBlock if declared
$patched += PatchFileLines "src\app\eco\pontos\[id]\PointDetailClient.tsx" {
  param([ref]$lines)
  for($i=0; $i -lt $lines.Value.Length; $i++){
    $ln = $lines.Value[$i]
    $ln = AliasInImportLine $ln "PointBadge" "_PointBadge"
    $ln = AliasInImportLine $ln "markerFill" "_markerFill"
    $ln = AliasInImportLine $ln "markerBorder" "_markerBorder"
    $ln = [Regex]::Replace($ln, "^\s*function\s+ProofBlock\b", "function _ProofBlock")
    $ln = [Regex]::Replace($ln, "^\s*const\s+ProofBlock\b", "const _ProofBlock")
    $lines.Value[$i] = $ln
  }
} ([ref]$log)

$log += ""
$log += ("Patched files: " + $patched)
$log += ""

# VERIFY (lint) — stream + log
$runner = Join-Path $Root "tools\eco-runner.ps1"
if(-not (Test-Path -LiteralPath $runner)){
  throw "tools/eco-runner.ps1 not found"
}

$log += "## VERIFY (npm run lint)"
$log += ""

Write-Host "[STEP 215a] running lint (stream)..."
& pwsh -NoProfile -ExecutionPolicy Bypass -File $runner -Tasks lint 2>&1 | Tee-Object -FilePath $lintLog
$exit = $LASTEXITCODE

$log += ("lint log: " + $lintLog)
$log += ("lint exit: " + $exit)
$log += ""

# count no-unused-vars lines
$raw = [IO.File]::ReadAllLines($lintLog, [Text.UTF8Encoding]::new($false))
$nu = ($raw | Where-Object { $_ -match "no-unused-vars" } | Measure-Object).Count
$log += ("no-unused-vars lines in lint: " + $nu)

WriteUtf8NoBom $reportPath ($log -join "`n")
Write-Host ("[REPORT] " + $reportPath)

if($OpenReport){
  try { ii $reportPath } catch {}
}

Write-Host ("[STEP 215a] done. lint exit=" + $exit + " | no-unused-vars lines=" + $nu)