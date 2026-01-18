param()
$ErrorActionPreference = "Stop"

$id = "eco-step-139c-mural-wide-sticky-map-safe-v0_1"
$ts = (Get-Date -Format "yyyyMMdd-HHmmss")
$root = (Resolve-Path ".").Path
$backupDir = Join-Path $root ("tools\_patch_backup\" + $id + "-" + $ts)
$reportPath = Join-Path $root ("reports\" + $id + "-" + $ts + ".md")

function EnsureDir([string]$p) {
  if ([string]::IsNullOrWhiteSpace($p)) { return }
  New-Item -ItemType Directory -Force -Path $p | Out-Null
}

function WriteUtf8NoBom([string]$p, [string]$content) {
  $parent = Split-Path -Parent $p
  if (-not [string]::IsNullOrWhiteSpace($parent)) { EnsureDir $parent }
  $enc = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($p, $content, $enc)
}

function BackupFile([string]$p) {
  if (Test-Path -LiteralPath $p) {
    EnsureDir $backupDir
    $leaf = Split-Path -Leaf $p
    Copy-Item -LiteralPath $p -Destination (Join-Path $backupDir ($leaf + ".bak")) -Force
  }
}

Write-Host ("== " + $id + " == " + $ts) -ForegroundColor Cyan
Write-Host ("[DIAG] Root: " + $root)
EnsureDir $backupDir
EnsureDir (Split-Path -Parent $reportPath)

# --- 1) Reescrever MuralWideStyles.tsx ---
$wideStyles = Join-Path $root "src\app\eco\mural\_components\MuralWideStyles.tsx"
BackupFile $wideStyles

$tsLines = @(
  "export const css = `"
  ""
  "/* ECO — Mural wide + mapa inline */"
  ".eco-mural {"
  "  max-width: none !important;"
  "  width: min(1700px, calc(100% - 32px)) !important;"
  "  margin: 0 auto !important;"
  "  padding: 18px 0 60px !important;"
  "}"
  ""
  "/* iframe do OpenStreetMap */"
  ".eco-mural iframe[src*=""openstreetmap.org""] {"
  "  width: 100% !important;"
  "  height: 520px !important;"
  "  border: 2px solid #111 !important;"
  "  border-radius: 16px !important;"
  "  background: #fff !important;"
  "}"
  ""
  "/* desktop: mapa maior + sticky (funciona mesmo em 1 coluna) */"
  "@media (min-width: 1100px) {"
  "  .eco-mural iframe[src*=""openstreetmap.org""] {"
  "    height: min(740px, calc(100vh - 210px)) !important;"
  "    position: sticky !important;"
  "    top: 92px !important;"
  "  }"
  "}"
  ""
  "/* mobile: mapa menor */"
  "@media (max-width: 1099px) {"
  "  .eco-mural iframe[src*=""openstreetmap.org""] { height: 360px !important; }"
  "}"
  ""
  "`";"
  ""
  "export default function MuralWideStyles() {"
  "  return <style>{css}</style>;"
  "}"
)

WriteUtf8NoBom $wideStyles ($tsLines -join "`n")
Write-Host ("[PATCH] rewrote -> " + $wideStyles) -ForegroundColor Green

# --- 2) Garantir import/render no page.tsx ---
$page = Join-Path $root "src\app\eco\mural\page.tsx"
if (Test-Path -LiteralPath $page) {
  $raw = Get-Content -Raw -LiteralPath $page
  $changed = $false

  if (-not $raw.Contains("MuralWideStyles")) {
    BackupFile $page
    $importLine = "import MuralWideStyles from ""./_components/MuralWideStyles"";"

    # inserir import depois do último import
    $lines = $raw -split "`r?`n"
    $lastImportIdx = -1
    for ($i=0; $i -lt $lines.Length; $i++) {
      if ($lines[$i].TrimStart().StartsWith("import ")) { $lastImportIdx = $i }
    }
    if ($lastImportIdx -ge 0) {
      $before = $lines[0..$lastImportIdx]
      $after  = @()
      if ($lastImportIdx + 1 -lt $lines.Length) { $after = $lines[($lastImportIdx+1)..($lines.Length-1)] }
      $lines = @($before + @($importLine) + $after)
      $raw = ($lines -join "`n")
    } else {
      $raw = $importLine + "`n" + $raw
    }

    # inserir <MuralWideStyles /> perto do topo
    if (-not $raw.Contains("<MuralWideStyles")) {
      if ($raw.Contains("<MuralReadableStyles")) {
        $raw = $raw.Replace("<MuralReadableStyles />", "<MuralReadableStyles />`n      <MuralWideStyles />")
      } else {
        $idx = $raw.IndexOf("<main")
        if ($idx -ge 0) {
          $gt = $raw.IndexOf(">", $idx)
          if ($gt -ge 0) {
            $raw = $raw.Insert($gt + 1, "`n      <MuralWideStyles />")
          }
        }
      }
    }

    WriteUtf8NoBom $page $raw
    $changed = $true
  }

  if ($changed) {
    Write-Host "[PATCH] page.tsx ensured import + render of MuralWideStyles" -ForegroundColor Green
  } else {
    Write-Host "[DIAG] page.tsx já tem MuralWideStyles (ok)"
  }
} else {
  Write-Host ("[WARN] não achei: " + $page) -ForegroundColor Yellow
}

# --- REPORT ---
$rep = @()
$rep += ("# " + $id + " - " + $ts)
$rep += ""
$rep += "## PATCH"
$rep += ("- rewrote: " + $wideStyles)
$rep += ("- backupDir: " + $backupDir)
$rep += ""
$rep += "## VERIFY"
$rep += "- Ctrl+C -> npm run dev"
$rep += "- abrir /eco/mural (painel branco deve ficar mais largo)"
$rep += "- abrir /eco/mural?map=1 (mapa inline maior; sticky no desktop)"
WriteUtf8NoBom $reportPath ($rep -join "`n")
Write-Host ("[REPORT] " + $reportPath)

Write-Host ""
Write-Host "[VERIFY] rode:" -ForegroundColor Yellow
Write-Host "  Ctrl+C -> npm run dev"
Write-Host "  abrir /eco/mural"
Write-Host "  abrir /eco/mural?map=1"