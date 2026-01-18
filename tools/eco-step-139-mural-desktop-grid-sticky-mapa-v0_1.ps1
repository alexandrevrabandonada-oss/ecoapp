param()
$ErrorActionPreference = "Stop"

$stamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
Write-Host ("== eco-step-139-mural-desktop-grid-sticky-mapa-v0_1 == " + $stamp) -ForegroundColor Cyan

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
Write-Host ("[DIAG] Root: " + $root) -ForegroundColor DarkGray

# --- bootstrap (best-effort) ---
$boot = Join-Path $PSScriptRoot "_bootstrap.ps1"
if (Test-Path -LiteralPath $boot) { . $boot }

function _EnsureDir([string]$p) {
  if ([string]::IsNullOrWhiteSpace($p)) { return }
  New-Item -ItemType Directory -Force -Path $p | Out-Null
}

function _BackupFile([string]$src, [string]$backupDir) {
  if (!(Test-Path -LiteralPath $src)) { return }
  _EnsureDir $backupDir
  $name = Split-Path -Leaf $src
  Copy-Item -LiteralPath $src -Destination (Join-Path $backupDir ($name + ".bak")) -Force
}

function _WriteUtf8NoBom([string]$path, [string]$content) {
  $parent = Split-Path -Parent $path
  _EnsureDir $parent
  $enc = [System.Text.UTF8Encoding]::new($false)
  [System.IO.File]::WriteAllText($path, $content, $enc)
}

$backupDir = Join-Path $root ("tools/_patch_backup/" + $stamp + "-eco-step-139-mural-desktop-grid-sticky-mapa-v0_1")
_EnsureDir $backupDir

# --- targets ---
$wideStyles = Join-Path $root "src/app/eco/mural/_components/MuralWideStyles.tsx"
$page = Join-Path $root "src/app/eco/mural/page.tsx"

if (!(Test-Path -LiteralPath $page)) { throw ("page.tsx not found: " + $page) }

_BackupFile $wideStyles $backupDir
_BackupFile $page $backupDir

# --- write MuralWideStyles.tsx (desktop grid + sticky map) ---
$wideLines = @(
  'export default function MuralWideStyles() {',
  '  const css = `',
  '/* desktop: 2 colunas (cards + mapa sticky) */',
  '@media (min-width: 1100px) {',
  '  .eco-mural-grid { display: grid !important; grid-template-columns: 1fr 520px; gap: 16px; align-items: start; }',
  '  .eco-mural-feed { min-width: 0; }',
  '  .eco-mural-map { position: sticky; top: 92px; }',
  '}',
  '/* mobile/tablet: 1 coluna */',
  '@media (max-width: 1099px) {',
  '  .eco-mural-grid { display: block !important; }',
  '  .eco-mural-map { position: static; }',
  '}',
  '/* mapa inline */',
  '#mural-mapa { scroll-margin-top: 110px; }',
  '#mural-mapa iframe { width: 100%; height: min(560px, 70vh); border: 2px solid #111; border-radius: 14px; background: #fff; }',
  '#mural-mapa { margin-top: 12px; }',
  '  `;',
  '  return <style>{css}</style>;',
  '}' 
)
$wideContent = ($wideLines -join "`n")
_WriteUtf8NoBom $wideStyles $wideContent
Write-Host ("[PATCH] updated -> " + $wideStyles) -ForegroundColor Green

# --- patch page.tsx: wrap MuralClient + MuralInlineMapa into grid (only if not already) ---
$lines = [System.IO.File]::ReadAllLines($page)
$hasGrid = $false
$idxClient = -1
$idxMapa = -1
for ($i=0; $i -lt $lines.Length; $i++) {
  if ($lines[$i].Contains("eco-mural-grid")) { $hasGrid = $true }
  if ($idxClient -lt 0 -and $lines[$i].Contains("<MuralClient")) { $idxClient = $i }
  if ($idxMapa -lt 0 -and $lines[$i].Contains("<MuralInlineMapa")) { $idxMapa = $i }
}

if ($idxClient -lt 0) { throw "Could not find <MuralClient in page.tsx" }
if ($idxMapa -lt 0) { throw "Could not find <MuralInlineMapa in page.tsx" }

if (-not $hasGrid) {
  $out = New-Object System.Collections.Generic.List[string]
  for ($i=0; $i -lt $lines.Length; $i++) {
    if ($i -eq $idxClient) {
      $out.Add("      <div className=`"eco-mural-grid`">")
      $out.Add("        <div className=`"eco-mural-feed`">")
      $out.Add(("          " + $lines[$i].Trim()))
      $out.Add("        </div>")
      continue
    }
    if ($i -eq $idxMapa) {
      $out.Add("        <aside className=`"eco-mural-map`">")
      $out.Add(("          " + $lines[$i].Trim()))
      $out.Add("        </aside>")
      $out.Add("      </div>")
      continue
    }
    $out.Add($lines[$i])
  }
  $enc = [System.Text.UTF8Encoding]::new($false)
  [System.IO.File]::WriteAllText($page, ($out -join "`n"), $enc)
  Write-Host ("[PATCH] page.tsx: grid wrapper injected") -ForegroundColor Green
} else {
  Write-Host ("[SKIP] page.tsx already has eco-mural-grid") -ForegroundColor DarkGray
}

Write-Host "[VERIFY] Ctrl+C -> npm run dev" -ForegroundColor Yellow
Write-Host "[VERIFY] abrir /eco/mural (desktop: 2 colunas; mapa sticky)" -ForegroundColor Yellow
Write-Host "[VERIFY] abrir /eco/mural?map=1&focus=<id> (deve rolar até #mural-mapa)" -ForegroundColor Yellow