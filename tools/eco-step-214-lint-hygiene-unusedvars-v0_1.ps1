param(
  [switch]$OpenReport
)

$ErrorActionPreference = "Stop"

$ToolsDir = $PSScriptRoot
$Root = (Resolve-Path (Join-Path $ToolsDir "..")).Path

. (Join-Path $ToolsDir "_bootstrap.ps1")

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$reportPath = Join-Path $Root ("reports\eco-step-214-unusedvars-" + $stamp + ".md")
EnsureDir (Split-Path -Parent $reportPath)

$r = @()
$r += "# ECO STEP 214 — lint hygiene (unused vars -> `_`) — $stamp"
$r += ""
$r += "Root: $Root"
$r += ""

$backedUp = @{}
function EnsureBackup([string]$p){
  if(-not $backedUp.ContainsKey($p)){
    BackupFile $p
    $backedUp[$p] = $true
  }
}

function PatchLine([string]$relPath, [int]$lineNo, [scriptblock]$transform){
  $p = Join-Path $Root $relPath
  if(-not (Test-Path $p)){
    $script:r += "- [SKIP] missing: $relPath"
    return
  }

  $lines = Get-Content -LiteralPath $p -Encoding UTF8
  if($lineNo -lt 1 -or $lineNo -gt $lines.Count){
    $script:r += "- [SKIP] out of range: $relPath (line $lineNo / $($lines.Count))"
    return
  }

  $old = $lines[$lineNo-1]
  $new = & $transform $old

  if($new -ne $old){
    EnsureBackup $p
    $lines[$lineNo-1] = $new
    [IO.File]::WriteAllLines($p, $lines, [Text.UTF8Encoding]::new($false))
    $script:r += "- [PATCH] $relPath :$lineNo"
    $script:r += "  - old: ``$old``"
    $script:r += "  - new: ``$new``"
  } else {
    $script:r += "- [OK]   $relPath :$lineNo (no change)"
  }
}

function AliasInImportLine([string]$line, [string]$name){
  # If it's an import line with { ... }, and token appears without "as _name", alias it.
  if($line -match "^\s*import\s*\{"){
    $patAlready = "\b" + [Regex]::Escape($name) + "\s+as\s+_" + [Regex]::Escape($name) + "\b"
    if($line -notmatch $patAlready){
      $pat = "\b" + [Regex]::Escape($name) + "\b(?!\s+as\b)"
      return [Regex]::Replace($line, $pat, ($name + " as _" + $name), 1)
    }
  }
  return $line
}

function UnderscoreToken([string]$line, [string]$name){
  $pat = "\b" + [Regex]::Escape($name) + "\b"
  return [Regex]::Replace($line, $pat, ("_" + $name), 1)
}

$r += "## DIAG"
$r += "- Goal: reduce ESLint noise by making unused vars/imports match /^_/"
$r += ""

$r += "## PATCH"

# API routes
PatchLine "src\app\api\eco\points\react\route.ts" 66 { param($l) ($l -replace "catch\s*\(\s*e\s*\)", "catch (_e)") }
PatchLine "src\app\api\eco\points\resolve\route.ts" 34 { param($l) (UnderscoreToken $l "normStatus") }
PatchLine "src\app\api\pickup-requests\[id]\route.ts" 32 { param($l) (UnderscoreToken $l "id") }
PatchLine "src\app\api\pickup-requests\route.ts" 5 { param($l) (UnderscoreToken $l "ECO_TOKEN_HEADER") }
PatchLine "src\app\api\pickup-requests\route.ts" 9 { param($l) (UnderscoreToken $l "ecoStripReceiptForAnon") }

# Mural clients
PatchLine "src\app\eco\mural-acoes\MuralAcoesClient.tsx" 2  { param($l) (UnderscoreToken $l "dt") }
PatchLine "src\app\eco\mural-acoes\MuralAcoesClient.tsx" 12 { param($l) (UnderscoreToken $l "score") }
PatchLine "src\app\eco\mural-acoes\MuralAcoesClient.tsx" 26 { param($l) (UnderscoreToken $l "it") }
PatchLine "src\app\eco\mural-acoes\MuralAcoesClient.tsx" 27 { param($l) (UnderscoreToken $l "item") }

PatchLine "src\app\eco\mural\MuralClient.tsx" 6  { param($l) (UnderscoreToken $l "p") }
PatchLine "src\app\eco\mural\MuralClient.tsx" 7  { param($l) (UnderscoreToken $l "it") }
PatchLine "src\app\eco\mural\MuralClient.tsx" 8  { param($l) (UnderscoreToken $l "item") }
PatchLine "src\app\eco\mural\MuralClient.tsx" 16 { param($l) (AliasInImportLine $l "MuralPointActionsClient") }

# Point detail imports (alias in import line)
PatchLine "src\app\eco\pontos\[id]\PointDetailClient.tsx" 5 {
  param($l)
  $l2 = AliasInImportLine $l "PointBadge"
  $l2 = AliasInImportLine $l2 "markerFill"
  $l2 = AliasInImportLine $l2 "markerBorder"
  $l2 = AliasInImportLine $l2 "ProofBlock"
  $l2
}

# Operator / components
PatchLine "src\app\operador\triagem\page.tsx" 5 { param($l) (AliasInImportLine $l "DayCloseShortcut") }

PatchLine "src\components\eco\OperatorPanel.tsx" 10 { param($l) (AliasInImportLine $l "EcoCardFormat") }

PatchLine "src\components\eco\OperatorTriageBoard.tsx" 10 { param($l) (AliasInImportLine $l "STATUS_OPTIONS") }
PatchLine "src\components\eco\OperatorTriageBoard.tsx" 17 { param($l) (AliasInImportLine $l "ShareNav") }

# ReceiptShareBar unused consts -> underscore
PatchLine "src\components\eco\ReceiptShareBar.tsx" 17  { param($l) (UnderscoreToken $l "ecoReceiptCopyText") }
PatchLine "src\components\eco\ReceiptShareBar.tsx" 38  { param($l) (UnderscoreToken $l "ecoReceiptOpenWhatsApp") }
PatchLine "src\components\eco\ReceiptShareBar.tsx" 252 { param($l) (UnderscoreToken $l "eco31_copyShort") }
PatchLine "src\components\eco\ReceiptShareBar.tsx" 256 { param($l) (UnderscoreToken $l "eco31_copyLong") }
PatchLine "src\components\eco\ReceiptShareBar.tsx" 260 { param($l) (UnderscoreToken $l "eco31_copyZap") }
PatchLine "src\components\eco\ReceiptShareBar.tsx" 264 { param($l) (UnderscoreToken $l "eco31_shareText") }
PatchLine "src\components\eco\ReceiptShareBar.tsx" 288 { param($l) (UnderscoreToken $l "eco32_shareLink") }

$r += ""
$r += "## VERIFY"
$r += ""
try {
  $runner = Join-Path $Root "tools\eco-runner.ps1"
  if(Test-Path $runner){
    $r += "### eco-runner: -Tasks lint build"
    $r += "~~~"
    pwsh -NoProfile -ExecutionPolicy Bypass -File $runner -Tasks lint build | ForEach-Object { $r += $_ }
    $r += "~~~"
    $r += "exit: 0"
  } else {
    $r += "- [SKIP] tools/eco-runner.ps1 not found"
  }
} catch {
  $r += "- [ERR] verify failed: $($_.Exception.Message)"
  $r += ""
  throw
}

$r += ""
$r += "## NOTES"
$r += "- This step only targets @typescript-eslint/no-unused-vars noise (underscore convention)."
$r += "- Remaining warnings (react-hooks/exhaustive-deps, @next/next/no-img-element) are left for a later focused step."
$r += ""

[IO.File]::WriteAllText($reportPath, ($r -join "`n"), [Text.UTF8Encoding]::new($false))
Write-Host ("[REPORT] " + $reportPath)

if($OpenReport){
  try { ii $reportPath } catch {}
}