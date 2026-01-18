Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function EnsureDir([string]$p) {
  if ([string]::IsNullOrWhiteSpace($p)) { return }
  New-Item -ItemType Directory -Force -Path $p | Out-Null
}

function WriteUtf8NoBom([string]$path, [string]$content) {
  $parent = Split-Path -Parent $path
  if (-not [string]::IsNullOrWhiteSpace($parent)) { EnsureDir $parent }
  [IO.File]::WriteAllText($path, $content, [System.Text.UTF8Encoding]::new($false))
}

function BackupFile([string]$path, [string]$backupDir) {
  if (-not (Test-Path -LiteralPath $path)) { return }
  EnsureDir $backupDir
  $leaf = Split-Path -Leaf $path
  $dst = Join-Path $backupDir ($leaf + ".bak")
  Copy-Item -LiteralPath $path -Destination $dst -Force
}

$root = (Resolve-Path ".").Path
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupDir = Join-Path $root ("tools\_patch_backup\eco-step-139e-mural-wide-sticky-map-safe-v0_3-" + $stamp)
EnsureDir $backupDir

Write-Host ("== eco-step-139e-mural-wide-sticky-map-safe-v0_3 == " + $stamp) -ForegroundColor Cyan
Write-Host ("[DIAG] Root: " + $root)

$wideFile = Join-Path $root "src\app\eco\mural\_components\MuralWideStyles.tsx"
$pageFile = Join-Path $root "src\app\eco\mural\page.tsx"

# --- rewrite MuralWideStyles.tsx ---
BackupFile $wideFile $backupDir

$tsx = @(
  'const css = `',
  '/* ECO — Mural wide + mapa inline */',
  '.eco-mural[data-eco-wide="1"] { background: #070b08 !important; color: #eaeaea !important; }',
  '',
  '/* se o wrapper tiver maxWidth inline, tentamos soltar */',
  '.eco-mural[data-eco-wide="1"] div[style*="max-width"] {',
  '  max-width: none !important;',
  '  width: min(1700px, calc(100% - 32px)) !important;',
  '  margin: 0 auto !important;',
  '}',
  '',
  '/* iframe do OpenStreetMap maior */',
  '.eco-mural[data-eco-wide="1"] iframe[src*="openstreetmap.org"] {',
  '  width: 100% !important;',
  '  height: min(560px, 70vh) !important;',
  '  border: 2px solid #111 !important;',
  '  border-radius: 12px !important;',
  '  background: #fff !important;',
  '  display: block !important;',
  '}',
  '',
  '/* sticky do mapa em telas largas */',
  "@media (min-width: 1100px) {",
  '  .eco-mural[data-eco-wide="1"] iframe[src*="openstreetmap.org"] {',
  '    position: sticky !important;',
  '    top: 96px !important;',
  '  }',
  '}',
  '`; ',
  '',
  'export default function MuralWideStyles() {',
  '  return <style>{css}</style>;',
  '}',
  ''
)

WriteUtf8NoBom $wideFile ($tsx -join "`n")
Write-Host ("[PATCH] rewrote -> " + $wideFile) -ForegroundColor Green

# --- patch page.tsx ---
if (-not (Test-Path -LiteralPath $pageFile)) {
  Write-Host ("[WARN] page.tsx not found: " + $pageFile) -ForegroundColor Yellow
  exit 0
}

BackupFile $pageFile $backupDir
$raw = Get-Content -LiteralPath $pageFile -Raw

# 1) garante data-eco-wide="1" no wrapper eco-mural
if ($raw -notmatch 'data-eco-wide="1"' -and $raw -match 'className="eco-mural"') {
  $raw = $raw.Replace('className="eco-mural"','className="eco-mural" data-eco-wide="1"')
  Write-Host "[PATCH] page.tsx: added data-eco-wide=1" -ForegroundColor Green
}

# 2) tenta trocar maxWidth do wrapper principal (primeira ocorrência) para wide
if ($raw -match 'maxWidth:' -and $raw -notmatch 'min\(1700px') {
  $raw2 = $raw -replace 'maxWidth:\s*[^,}]+','maxWidth: "min(1700px, calc(100% - 32px))"'
  if ($raw2 -ne $raw) {
    $raw = $raw2
    Write-Host "[PATCH] page.tsx: widened maxWidth -> min(1700px, calc(100% - 32px))" -ForegroundColor Green
  }
}

# 3) garante import
if ($raw -notmatch 'MuralWideStyles') {
  $lines = $raw -split "`r?`n"
  $importLine = 'import MuralWideStyles from "./_components/MuralWideStyles";'
  $lastImport = -1
  for ($i=0; $i -lt $lines.Length; $i++) {
    if ($lines[$i].TrimStart().StartsWith("import ")) { $lastImport = $i }
  }
  if ($lastImport -ge 0) {
    $new = @()
    for ($i=0; $i -lt $lines.Length; $i++) {
      $new += $lines[$i]
      if ($i -eq $lastImport) { $new += $importLine }
    }
    $lines = $new
  } else {
    $lines = @($importLine) + $lines
  }
  $raw = ($lines -join "`n")
  Write-Host "[PATCH] page.tsx: ensured import MuralWideStyles" -ForegroundColor Green
}

# 4) garante render
if ($raw -notmatch '<MuralWideStyles\s*/>') {
  if ($raw -match '<MuralReadableStyles\s*/>') {
    $raw = $raw -replace '<MuralReadableStyles\s*/>'," <MuralWideStyles />`n      <MuralReadableStyles />"
    Write-Host "[PATCH] page.tsx: injected <MuralWideStyles />" -ForegroundColor Green
  }
}

WriteUtf8NoBom $pageFile $raw
Write-Host ("[PATCH] updated -> " + $pageFile) -ForegroundColor Green

Write-Host ""
Write-Host "[VERIFY] rode:" -ForegroundColor Cyan
Write-Host "  Ctrl+C -> npm run dev"
Write-Host "  abrir /eco/mural (deve ficar bem mais largo)"
Write-Host "  rolar ate o mapa: em tela larga ele deve ficar sticky"