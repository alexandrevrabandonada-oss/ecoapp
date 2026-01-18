param([switch]$OpenReport)

$ErrorActionPreference = "Stop"

$ToolsDir = $PSScriptRoot
$Root = (Resolve-Path (Join-Path $ToolsDir "..")).Path

# bootstrap espera $r.Value; garante um [ref] antes de carregar
$global:r = [ref]@()
. (Join-Path $ToolsDir "_bootstrap.ps1")

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$reportPath = Join-Path $Root ("reports\eco-step-214d-unusedvars-" + $stamp + ".md")
EnsureDir (Split-Path -Parent $reportPath)

function Log([string]$s){ $global:r.Value += $s }

function ApplyRules([string]$relPath, $rules){
  $p = Join-Path $Root $relPath
  if(-not (Test-Path $p)){
    Log ("- [SKIP] missing: " + $relPath)
    return 0
  }

  $raw = Get-Content -LiteralPath $p -Raw -Encoding UTF8
  if($null -eq $raw){ throw ("Could not read: " + $relPath) }

  $orig = $raw
  foreach($rule in $rules){
    $pattern = $rule.pattern
    $replace = $rule.replace
    $raw = [Regex]::Replace($raw, $pattern, $replace)
  }

  if($raw -ne $orig){
    BackupFile $p
    [IO.File]::WriteAllText($p, $raw, [Text.UTF8Encoding]::new($false))
    Log ("- [PATCH] " + $relPath)
    return 1
  } else {
    Log ("- [OK]    " + $relPath + " (no change)")
    return 0
  }
}

Log "# ECO STEP 214d — fix eslint no-unused-vars by `_` prefix — $stamp"
Log ""
Log "Root: $Root"
Log ""
Log "## PATCH"

$patched = 0

# 1) catch (e) -> catch (_e)
$patched += ApplyRules "src\app\api\eco\points\react\route.ts" @(
  @{ pattern = "catch\s*\(\s*e\s*\)"; replace = "catch (_e)" }
)

# 2) const/let normStatus -> _normStatus
$patched += ApplyRules "src\app\api\eco\points\resolve\route.ts" @(
  @{ pattern = "(\b(?:const|let)\s+)normStatus\b"; replace = "`$1_normStatus" }
)

# 3) const/let id -> _id (no [id] route)
$patched += ApplyRules "src\app\api\pickup-requests\[id]\route.ts" @(
  @{ pattern = "(\b(?:const|let)\s+)id\b"; replace = "`$1_id" }
)

# 4) pickup-requests route: ECO_TOKEN_HEADER / ecoStripReceiptForAnon -> underscore
$patched += ApplyRules "src\app\api\pickup-requests\route.ts" @(
  @{ pattern = "(\bconst\s+)ECO_TOKEN_HEADER\b"; replace = "`$1_ECO_TOKEN_HEADER" },
  @{ pattern = "(\b(?:export\s+)?(?:const|function)\s+)ecoStripReceiptForAnon\b"; replace = "`$1_ecoStripReceiptForAnon" }
)

# 5) MuralAcoesClient: alias imports dt/score, underscore unused arrow params it/item
$patched += ApplyRules "src\app\eco\mural-acoes\MuralAcoesClient.tsx" @(
  @{ pattern = "(?m)^(\s*import\s*\{[^}]*?)\bdt\b(?!\s+as\b)"; replace = "`$1dt as _dt" },
  @{ pattern = "(?m)^(\s*import\s*\{[^}]*?)\bscore\b(?!\s+as\b)"; replace = "`$1score as _score" },
  @{ pattern = "\(\s*it\s*\)\s*=>"; replace = "(_it) =>" },
  @{ pattern = "\(\s*item\s*\)\s*=>"; replace = "(_item) =>" }
)

# 6) MuralClient: underscore unused arrow params + alias unused import
$patched += ApplyRules "src\app\eco\mural\MuralClient.tsx" @(
  @{ pattern = "(?m)^(\s*import\s*\{[^}]*?)\bMuralPointActionsClient\b(?!\s+as\b)"; replace = "`$1MuralPointActionsClient as _MuralPointActionsClient" },
  @{ pattern = "\(\s*p\s*\)\s*=>"; replace = "(_p) =>" },
  @{ pattern = "\(\s*it\s*\)\s*=>"; replace = "(_it) =>" },
  @{ pattern = "\(\s*item\s*\)\s*=>"; replace = "(_item) =>" }
)

# 7) PointDetailClient: alias unused imports + ProofBlock rename if declared
$patched += ApplyRules "src\app\eco\pontos\[id]\PointDetailClient.tsx" @(
  @{ pattern = "(?m)^(\s*import\s*\{[^}]*?)\bPointBadge\b(?!\s+as\b)"; replace = "`$1PointBadge as _PointBadge" },
  @{ pattern = "(?m)^(\s*import\s*\{[^}]*?)\bmarkerFill\b(?!\s+as\b)"; replace = "`$1markerFill as _markerFill" },
  @{ pattern = "(?m)^(\s*import\s*\{[^}]*?)\bmarkerBorder\b(?!\s+as\b)"; replace = "`$1markerBorder as _markerBorder" },
  @{ pattern = "(\b(?:const|let|function)\s+)ProofBlock\b"; replace = "`$1_ProofBlock" }
)

# 8) triagem page: alias unused import
$patched += ApplyRules "src\app\operador\triagem\page.tsx" @(
  @{ pattern = "(?m)^(\s*import\s*\{[^}]*?)\bDayCloseShortcut\b(?!\s+as\b)"; replace = "`$1DayCloseShortcut as _DayCloseShortcut" }
)

# 9) OperatorPanel: alias unused import
$patched += ApplyRules "src\components\eco\OperatorPanel.tsx" @(
  @{ pattern = "(?m)^(\s*import\s*\{[^}]*?)\bEcoCardFormat\b(?!\s+as\b)"; replace = "`$1EcoCardFormat as _EcoCardFormat" }
)

# 10) OperatorTriageBoard: alias unused imports
$patched += ApplyRules "src\components\eco\OperatorTriageBoard.tsx" @(
  @{ pattern = "(?m)^(\s*import\s*\{[^}]*?)\bSTATUS_OPTIONS\b(?!\s+as\b)"; replace = "`$1STATUS_OPTIONS as _STATUS_OPTIONS" },
  @{ pattern = "(?m)^(\s*import\s*\{[^}]*?)\bShareNav\b(?!\s+as\b)"; replace = "`$1ShareNav as _ShareNav" }
)

# 11) ReceiptShareBar: rename unused consts -> underscore
$patched += ApplyRules "src\components\eco\ReceiptShareBar.tsx" @(
  @{ pattern = "(\b(?:export\s+)?const\s+)ecoReceiptCopyText\b"; replace = "`$1_ecoReceiptCopyText" },
  @{ pattern = "(\b(?:export\s+)?const\s+)ecoReceiptOpenWhatsApp\b"; replace = "`$1_ecoReceiptOpenWhatsApp" },
  @{ pattern = "(\b(?:export\s+)?const\s+)eco31_copyShort\b"; replace = "`$1_eco31_copyShort" },
  @{ pattern = "(\b(?:export\s+)?const\s+)eco31_copyLong\b"; replace = "`$1_eco31_copyLong" },
  @{ pattern = "(\b(?:export\s+)?const\s+)eco31_copyZap\b"; replace = "`$1_eco31_copyZap" },
  @{ pattern = "(\b(?:export\s+)?const\s+)eco31_shareText\b"; replace = "`$1_eco31_shareText" },
  @{ pattern = "(\b(?:export\s+)?const\s+)eco32_shareLink\b"; replace = "`$1_eco32_shareLink" }
)

Log ""
Log ("Patched files: " + $patched)
Log ""
Log "## VERIFY (lint)"
Log ""

$runner = Join-Path $Root "tools\eco-runner.ps1"
if(-not (Test-Path $runner)){ throw "tools/eco-runner.ps1 not found" }

$lines = & pwsh -NoProfile -ExecutionPolicy Bypass -File $runner -Tasks lint 2>&1
foreach($ln in $lines){ Log $ln }

# tenta descobrir o report path do runner
$reportLine = $lines | Where-Object { $_ -like "[REPORT]*" } | Select-Object -First 1
$runnerReport = $null
if($reportLine){
  $runnerReport = ($reportLine -replace "^\[REPORT\]\s*", "").Trim()
}

if($runnerReport -and (Test-Path $runnerReport)){
  $cnt = (Select-String -LiteralPath $runnerReport -Pattern "no-unused-vars" -SimpleMatch -ErrorAction SilentlyContinue | Measure-Object).Count
  Log ""
  Log ("no-unused-vars occurrences in runner report: " + $cnt)
} else {
  $cnt2 = ($lines | Where-Object { $_ -match "no-unused-vars" } | Measure-Object).Count
  Log ""
  Log ("no-unused-vars occurrences in lint output: " + $cnt2)
}

[IO.File]::WriteAllText($reportPath, ($global:r.Value -join "`n"), [Text.UTF8Encoding]::new($false))
Write-Host ("[REPORT] " + $reportPath)

if($OpenReport){
  try { ii $reportPath } catch {}
}