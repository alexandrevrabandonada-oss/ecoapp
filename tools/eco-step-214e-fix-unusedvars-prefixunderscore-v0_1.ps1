param([switch]$OpenReport)

$ErrorActionPreference = "Stop"

$ToolsDir = $PSScriptRoot
$Root = (Resolve-Path (Join-Path $ToolsDir "..")).Path
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$reportPath = Join-Path $Root ("reports\eco-step-214e-unusedvars-" + $stamp + ".md")

function EnsureDir([string]$p){
  if([string]::IsNullOrWhiteSpace($p)){ return }
  if(-not (Test-Path $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null }
}
function WriteUtf8NoBom([string]$p,[string]$s){
  EnsureDir (Split-Path -Parent $p)
  [IO.File]::WriteAllText($p, $s, [Text.UTF8Encoding]::new($false))
}
function BackupFile([string]$file){
  if(-not (Test-Path $file)){ return $null }
  $bdir = Join-Path $Root "tools\_patch_backup"
  EnsureDir $bdir
  $name = Split-Path -Leaf $file
  $dest = Join-Path $bdir ($name + "." + $stamp + ".bak")
  Copy-Item -LiteralPath $file -Destination $dest -Force
  return $dest
}
function PatchFile([string]$relPath, $rules, [ref]$log){
  $p = Join-Path $Root $relPath
  if(-not (Test-Path $p)){
    $log.Value += "- [SKIP] missing: $relPath"
    return 0
  }
  $raw = Get-Content -LiteralPath $p -Raw -Encoding UTF8
  $orig = $raw
  $hits = 0

  foreach($r in $rules){
    $pat = $r.pattern
    $rep = $r.replace
    $m = [Regex]::Matches($raw, $pat).Count
    if($m -gt 0){
      $raw = [Regex]::Replace($raw, $pat, $rep)
      $hits += $m
    }
  }

  if($raw -ne $orig){
    $bak = BackupFile $p
    WriteUtf8NoBom $p $raw
    $log.Value += "- [PATCH] $relPath (matches: $hits) backup: $bak"
    return 1
  } else {
    $log.Value += "- [OK]    $relPath (no change)"
    return 0
  }
}

$log = @()
$log += "# ECO STEP 214e — fix eslint no-unused-vars via `_` — $stamp"
$log += ""
$log += "Root: $Root"
$log += ""
$log += "## PATCH"
$patched = 0

# api/eco/points/react: catch(e) -> catch(_e)
$patched += PatchFile "src\app\api\eco\points\react\route.ts" @(
  @{ pattern = "catch\s*\(\s*e\s*\)"; replace = "catch (_e)" }
) ([ref]$log)

# api/eco/points/resolve: normStatus -> _normStatus (declaration)
$patched += PatchFile "src\app\api\eco\points\resolve\route.ts" @(
  @{ pattern = "(?m)^(\s*(?:const|let)\s+)normStatus\b"; replace = "`$1_normStatus" }
) ([ref]$log)

# pickup-requests/[id]: id -> _id (declaration)
$patched += PatchFile "src\app\api\pickup-requests\[id]\route.ts" @(
  @{ pattern = "(?m)^(\s*(?:const|let)\s+)id\b"; replace = "`$1_id" }
) ([ref]$log)

# pickup-requests route: ECO_TOKEN_HEADER + ecoStripReceiptForAnon
$patched += PatchFile "src\app\api\pickup-requests\route.ts" @(
  @{ pattern = "(?m)^(\s*const\s+)ECO_TOKEN_HEADER\b"; replace = "`$1_ECO_TOKEN_HEADER" },
  @{ pattern = "(?m)^(\s*(?:const|function)\s+)ecoStripReceiptForAnon\b"; replace = "`$1_ecoStripReceiptForAnon" }
) ([ref]$log)

# MuralAcoesClient: dt/score imports + it/item params
$patched += PatchFile "src\app\eco\mural-acoes\MuralAcoesClient.tsx" @(
  @{ pattern = "\bdt\b(?!\s+as\b)"; replace = "dt as _dt" },
  @{ pattern = "\bscore\b(?!\s+as\b)"; replace = "score as _score" },
  @{ pattern = "\(\s*it\s*\)\s*=>"; replace = "(_it) =>" },
  @{ pattern = "\(\s*item\s*\)\s*=>"; replace = "(_item) =>" }
) ([ref]$log)

# MuralClient: p/it/item params + MuralPointActionsClient import
$patched += PatchFile "src\app\eco\mural\MuralClient.tsx" @(
  @{ pattern = "\bMuralPointActionsClient\b(?!\s+as\b)"; replace = "MuralPointActionsClient as _MuralPointActionsClient" },
  @{ pattern = "\(\s*p\s*\)\s*=>"; replace = "(_p) =>" },
  @{ pattern = "\(\s*it\s*\)\s*=>"; replace = "(_it) =>" },
  @{ pattern = "\(\s*item\s*\)\s*=>"; replace = "(_item) =>" },
  @{ pattern = "(?m)^(\s*(?:const|let)\s+)p\b"; replace = "`$1_p" },
  @{ pattern = "(?m)^(\s*(?:const|let)\s+)it\b"; replace = "`$1_it" },
  @{ pattern = "(?m)^(\s*(?:const|let)\s+)item\b"; replace = "`$1_item" }
) ([ref]$log)

# PointDetailClient: unused imports + ProofBlock local
$patched += PatchFile "src\app\eco\pontos\[id]\PointDetailClient.tsx" @(
  @{ pattern = "\bPointBadge\b(?!\s+as\b)"; replace = "PointBadge as _PointBadge" },
  @{ pattern = "\bmarkerFill\b(?!\s+as\b)"; replace = "markerFill as _markerFill" },
  @{ pattern = "\bmarkerBorder\b(?!\s+as\b)"; replace = "markerBorder as _markerBorder" },
  @{ pattern = "(?m)^(\s*(?:const|function)\s+)ProofBlock\b"; replace = "`$1_ProofBlock" }
) ([ref]$log)

# operador/triagem page: DayCloseShortcut import
$patched += PatchFile "src\app\operador\triagem\page.tsx" @(
  @{ pattern = "\bDayCloseShortcut\b(?!\s+as\b)"; replace = "DayCloseShortcut as _DayCloseShortcut" }
) ([ref]$log)

# OperatorPanel: EcoCardFormat import
$patched += PatchFile "src\components\eco\OperatorPanel.tsx" @(
  @{ pattern = "\bEcoCardFormat\b(?!\s+as\b)"; replace = "EcoCardFormat as _EcoCardFormat" }
) ([ref]$log)

# OperatorTriageBoard: STATUS_OPTIONS + ShareNav imports
$patched += PatchFile "src\components\eco\OperatorTriageBoard.tsx" @(
  @{ pattern = "\bSTATUS_OPTIONS\b(?!\s+as\b)"; replace = "STATUS_OPTIONS as _STATUS_OPTIONS" },
  @{ pattern = "\bShareNav\b(?!\s+as\b)"; replace = "ShareNav as _ShareNav" }
) ([ref]$log)

# ReceiptShareBar: rename locals to _
$patched += PatchFile "src\components\eco\ReceiptShareBar.tsx" @(
  @{ pattern = "(?m)^(\s*const\s+)ecoReceiptCopyText\b"; replace = "`$1_ecoReceiptCopyText" },
  @{ pattern = "(?m)^(\s*const\s+)ecoReceiptOpenWhatsApp\b"; replace = "`$1_ecoReceiptOpenWhatsApp" },
  @{ pattern = "(?m)^(\s*const\s+)eco31_copyShort\b"; replace = "`$1_eco31_copyShort" },
  @{ pattern = "(?m)^(\s*const\s+)eco31_copyLong\b"; replace = "`$1_eco31_copyLong" },
  @{ pattern = "(?m)^(\s*const\s+)eco31_copyZap\b"; replace = "`$1_eco31_copyZap" },
  @{ pattern = "(?m)^(\s*const\s+)eco31_shareText\b"; replace = "`$1_eco31_shareText" },
  @{ pattern = "(?m)^(\s*const\s+)eco32_shareLink\b"; replace = "`$1_eco32_shareLink" }
) ([ref]$log)

$log += ""
$log += ("Patched files: " + $patched)
$log += ""
$log += "## VERIFY (lint)"
$log += ""

$runner = Join-Path $Root "tools\eco-runner.ps1"
if(Test-Path $runner){
  $out = & pwsh -NoProfile -ExecutionPolicy Bypass -File $runner -Tasks lint 2>&1
  foreach($ln in $out){ $log += $ln }
  $nu = ($out | Where-Object { $_ -match "no-unused-vars" } | Measure-Object).Count
  $log += ""
  $log += ("no-unused-vars lines in output: " + $nu)
} else {
  $log += "- WARN: tools/eco-runner.ps1 nao encontrado; rode: npm run lint"
}

WriteUtf8NoBom $reportPath ($log -join "`n")
Write-Host ("[REPORT] " + $reportPath)
if($OpenReport){ try { ii $reportPath } catch {} }