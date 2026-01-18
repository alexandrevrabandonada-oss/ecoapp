param()
$ErrorActionPreference = "Stop"

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$root = (Resolve-Path ".").Path

function EnsureDir([string]$p) {
  if ([string]::IsNullOrWhiteSpace($p)) { return }
  New-Item -ItemType Directory -Force -Path $p | Out-Null
}
function WriteUtf8NoBom([string]$path, [string]$content) {
  if ([string]::IsNullOrWhiteSpace($path)) { throw "WriteUtf8NoBom: path vazio" }
  $parent = Split-Path -Parent $path
  if (-not [string]::IsNullOrWhiteSpace($parent)) { EnsureDir $parent }
  [System.IO.File]::WriteAllText($path, $content, [System.Text.UTF8Encoding]::new($false))
}
function ReadUtf8NoBom([string]$path) {
  return [System.IO.File]::ReadAllText($path, [System.Text.UTF8Encoding]::new($false))
}
function BackupFile([string]$src, [string]$backupDir) {
  EnsureDir $backupDir
  if (-not (Test-Path -LiteralPath $src)) { throw ("BackupFile: nao achei " + $src) }
  $name = (Split-Path -Leaf $src) + ".bak"
  Copy-Item -LiteralPath $src -Destination (Join-Path $backupDir $name) -Force
}

Write-Host ("== eco-step-142-fix-mural-map-split-and-dev-webpack-v0_1 == " + $stamp) -ForegroundColor Cyan
Write-Host ("[DIAG] Root: " + $root)

$pagePath = Join-Path $root 'src\app\eco\mural\page.tsx'
$widePath = Join-Path $root 'src\app\eco\mural\_components\MuralWideStyles.tsx'
$pkgPath  = Join-Path $root 'package.json'

if (-not (Test-Path -LiteralPath $pagePath)) { throw ("Nao achei: " + $pagePath) }
if (-not (Test-Path -LiteralPath $widePath)) { throw ("Nao achei: " + $widePath) }

$backupDir = Join-Path $root ("tools\_patch_backup\eco-step-142-fix-mural-map-split-and-dev-webpack-v0_1-" + $stamp)
EnsureDir $backupDir
BackupFile $pagePath $backupDir
BackupFile $widePath $backupDir
if (Test-Path -LiteralPath $pkgPath) { BackupFile $pkgPath $backupDir }
Write-Host ("[DIAG] backup -> " + $backupDir) -ForegroundColor DarkGray

# =========================
# PATCH 1: MuralWideStyles
# =========================
$wideLines = @(
  '"use client";',
  '',
  'export default function MuralWideStyles() {',
  '  return (',
  '    <style>{`',
  '/* ECO — Mural: split + mapa sticky (map=1) */',
  '',
  '.eco-mural {',
  '  background: #070b08 !important;',
  '  color: #eaeaea !important;',
  '  max-width: min(1700px, calc(100% - 32px)) !important;',
  '  margin: 0 auto !important;',
  '  padding: 18px 0 60px !important;',
  '}',
  '',
  '/* split base */',
  '.eco-mural-split {',
  '  display: grid;',
  '  grid-template-columns: 1fr;',
  '  gap: 16px;',
  '  align-items: start;',
  '}',
  '.eco-mural-right { display: none; }',
  '.eco-mural[data-map="1"] .eco-mural-right { display: block; }',
  '',
  '@media (min-width: 1100px) {',
  '  .eco-mural[data-map="1"] .eco-mural-split {',
  '    grid-template-columns: minmax(640px, 1fr) 600px;',
  '    gap: 18px;',
  '  }',
  '  .eco-mural[data-map="1"] .eco-mural-right {',
  '    position: sticky;',
  '    top: 86px;',
  '    align-self: start;',
  '  }',
  '}',
  '',
  '/* iframe OSM */',
  '.eco-mural iframe[src*="openstreetmap.org"] {',
  '  width: 100% !important;',
  '  height: 420px !important;',
  '  border: 0 !important;',
  '  display: block !important;',
  '  border-radius: 14px !important;',
  '}',
  '@media (min-width: 1100px) {',
  '  .eco-mural iframe[src*="openstreetmap.org"] {',
  '    height: calc(100vh - 160px) !important;',
  '    min-height: 520px !important;',
  '  }',
  '}',
  '',
  '/* grid de cards mais limpo no desktop */',
  '@media (min-width: 900px) {',
  '  .eco-mural .eco-mural-cards {',
  '    display: grid;',
  '    grid-template-columns: repeat(2, minmax(0, 1fr));',
  '    gap: 14px;',
  '  }',
  '}',
  '`}</style>',
  '  );',
  '}'
)
WriteUtf8NoBom $widePath ($wideLines -join "`n")
Write-Host ("[PATCH] rewrote -> " + $widePath) -ForegroundColor Green

# =========================
# PATCH 2: page.tsx (mapOpen + data-map + split wrapper + map) 
# =========================
$raw = ReadUtf8NoBom $pagePath

# ensure imports
$needWideImport = ($raw -notmatch 'from\s+["']\./_components/MuralWideStyles["']')
$needMapImport  = ($raw -notmatch 'from\s+["']\./_components/MuralInlineMapa["']')

$lines = $raw -split "`r?`n"
$out = New-Object System.Collections.Generic.List[string]
$insertedImports = $false
$sawAnyImport = $false
for ($i=0; $i -lt $lines.Length; $i++) {
  $line = $lines[$i]
  $isImport = ($line -match '^\s*import\s+')
  if ($isImport) { $sawAnyImport = $true }

  if (-not $insertedImports -and $sawAnyImport -and (-not $isImport)) {
    if ($needWideImport) { $out.Add('import MuralWideStyles from "./_components/MuralWideStyles";') }
    if ($needMapImport)  { $out.Add('import MuralInlineMapa from "./_components/MuralInlineMapa";') }
    $insertedImports = $true
  }
  $out.Add($line)
}
if (-not $sawAnyImport) {
  $tmp = New-Object System.Collections.Generic.List[string]
  if ($needWideImport) { $tmp.Add('import MuralWideStyles from "./_components/MuralWideStyles";') }
  if ($needMapImport)  { $tmp.Add('import MuralInlineMapa from "./_components/MuralInlineMapa";') }
  foreach ($l in $out) { $tmp.Add($l) }
  $out = $tmp
}
$raw2 = ($out.ToArray() -join "`n")

# ensure Page signature has searchParams
if ($raw2 -match 'export\s+default\s+async\s+function\s+Page\(\s*\)\s*{' ) {
  $raw2 = [regex]::Replace($raw2, 'export\s+default\s+async\s+function\s+Page\(\s*\)\s*{', 'export default async function Page({ searchParams }: { searchParams?: Record<string, string | string[] | undefined> }) {', 1)
} elseif ($raw2 -match 'export\s+default\s+function\s+Page\(\s*\)\s*{' ) {
  $raw2 = [regex]::Replace($raw2, 'export\s+default\s+function\s+Page\(\s*\)\s*{', 'export default function Page({ searchParams }: { searchParams?: Record<string, string | string[] | undefined> }) {', 1)
}

# ensure mapOpen block
if ($raw2 -notmatch 'const\s+mapOpen\s*=' ) {
  $raw2Lines = $raw2 -split "`r?`n"
  $out2 = New-Object System.Collections.Generic.List[string]
  $inserted = $false
  for ($i=0; $i -lt $raw2Lines.Length; $i++) {
    $line = $raw2Lines[$i]
    $out2.Add($line)
    if (-not $inserted -and ($line -match 'export\s+default\s+.*function\s+Page\(') ) {
      $out2.Add('  const mapRaw = searchParams?.map;')
      $out2.Add('  const mapVal = Array.isArray(mapRaw) ? mapRaw[0] : mapRaw;')
      $out2.Add('  const mapOpen = (mapVal === "1" || mapVal === "true");')
      $inserted = $true
    }
  }
  $raw2 = ($out2.ToArray() -join "`n")
}

# ensure data-map on <main className="eco-mural"...>
$raw2Lines = $raw2 -split "`r?`n"
$out3 = New-Object System.Collections.Generic.List[string]
$hasSplit = ($raw2 -match 'eco-mural-split')
$hasStyleRender = ($raw2 -match '<MuralWideStyles\s*/>' -or $raw2 -match '<MuralWideStyles\s*\/\s*>' )
$insertedStyle = $false
$openedSplit = $false
$closedSplit = $false
for ($i=0; $i -lt $raw2Lines.Length; $i++) {
  $line = $raw2Lines[$i]

  # add data-map on main
  if ($line -match '<main' -and $line -match 'eco-mural' -and $line -notmatch 'data-map=') {
    if ($line -match '>') {
      $line = $line.Replace('>', ' data-map={mapOpen ? "1" : "0"}>')
    }
  }

  $out3.Add($line)

  if (-not $hasSplit) {
    # if no style render exists, inject it right after main opening line
    if (-not $hasStyleRender -and -not $insertedStyle -and $line -match '<main' -and $line -match 'eco-mural') {
      $out3.Add('      <MuralWideStyles />')
      $insertedStyle = $true
      $out3.Add('      <div className="eco-mural-split">')
      $out3.Add('        <div className="eco-mural-left">')
      $openedSplit = $true
    }

    # if style render exists, open split right after it
    if ($hasStyleRender -and -not $openedSplit -and $line -match '<MuralWideStyles') {
      $out3.Add('      <div className="eco-mural-split">')
      $out3.Add('        <div className="eco-mural-left">')
      $openedSplit = $true
    }

    # close split right before </main>
    if ($openedSplit -and -not $closedSplit -and $line -match '</main>' ) {
      # back up one: remove the </main> we just added, insert closings, then re-add </main>
      $out3.RemoveAt($out3.Count-1)
      $out3.Add('        </div>')
      $out3.Add('        <div className="eco-mural-right">')
      if ($raw2 -match '<MuralInlineMapa') {
        $out3.Add('          <MuralInlineMapa />')
      } else {
        $out3.Add('          <MuralInlineMapa />')
      }
      $out3.Add('        </div>')
      $out3.Add('      </div>')
      $out3.Add('</main>')
      $closedSplit = $true
    }
  }
}

$raw3 = ($out3.ToArray() -join "`n")
WriteUtf8NoBom $pagePath $raw3
Write-Host ("[PATCH] updated -> " + $pagePath) -ForegroundColor Green

# =========================
# PATCH 3 (optional): package.json add dev:webpack
# =========================
if (Test-Path -LiteralPath $pkgPath) {
  try {
    $pkgText = ReadUtf8NoBom $pkgPath
    $pkg = $pkgText | ConvertFrom-Json
    if ($null -eq $pkg.scripts) { $pkg | Add-Member -MemberType NoteProperty -Name scripts -Value (@{}) }
    $hasDevWebpack = $false
    try { $hasDevWebpack = ($pkg.scripts.PSObject.Properties.Name -contains "dev:webpack") } catch { $hasDevWebpack = $false }
    if (-not $hasDevWebpack) {
      $pkg.scripts | Add-Member -MemberType NoteProperty -Name "dev:webpack" -Value "next dev --no-turbo"
      $newJson = ($pkg | ConvertTo-Json -Depth 50)
      WriteUtf8NoBom $pkgPath ($newJson + "`n")
      Write-Host "[PATCH] package.json: added script dev:webpack" -ForegroundColor Green
    } else {
      Write-Host "[PATCH] package.json: dev:webpack already exists (skip)" -ForegroundColor DarkGray
    }
  } catch {
    Write-Host ("[WARN] package.json patch skipped: " + $_.Exception.Message) -ForegroundColor Yellow
  }
}

# =========================
# REPORT
# =========================
$reportDir = Join-Path $root "reports"
EnsureDir $reportDir
$reportPath = Join-Path $reportDir ("eco-step-142-fix-mural-map-split-and-dev-webpack-v0_1-" + $stamp + ".md")
$r = @()
$r += "# eco-step-142-fix-mural-map-split-and-dev-webpack-v0_1 - $stamp"
$r += ""
$r += "## PATCH"
$r += "- rewrote: src/app/eco/mural/_components/MuralWideStyles.tsx (split + sticky + iframe OSM)"
$r += "- updated: src/app/eco/mural/page.tsx (mapOpen + data-map + split wrapper + right map column)"
$r += "- optional: package.json added dev:webpack (next dev --no-turbo)"
$r += ""
$r += "## VERIFY"
$r += "- Ctrl+C -> npm run dev"
$r += "- abrir: /eco/mural (map fechado => 1 coluna)"
$r += "- abrir: /eco/mural?map=1 (>=1100px => 2 colunas, mapa sticky a direita)"
$r += "- se o overlay de sourcemap irritar no turbo: npm run dev:webpack"
WriteUtf8NoBom $reportPath ($r -join "`n")
Write-Host ("[REPORT] " + $reportPath) -ForegroundColor Cyan

Write-Host ""
Write-Host "[VERIFY] rode:" -ForegroundColor Cyan
Write-Host "  Ctrl+C -> npm run dev"
Write-Host "  abrir /eco/mural"
Write-Host "  abrir /eco/mural?map=1"
Write-Host "  (se sourcemap overlay incomodar) npm run dev:webpack"