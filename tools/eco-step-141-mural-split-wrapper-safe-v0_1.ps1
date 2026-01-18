$ErrorActionPreference = "Stop"
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$root = (Resolve-Path ".").Path
Write-Host ("== eco-step-141-mural-split-wrapper-safe-v0_1 == " + $stamp) -ForegroundColor Cyan
Write-Host ("[DIAG] Root: " + $root)

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
function BackupFile([string]$src, [string]$backupDir) {
  EnsureDir $backupDir
  if (-not (Test-Path -LiteralPath $src)) { throw ("BackupFile: nao achei " + $src) }
  $name = (Split-Path -Leaf $src) + ".bak"
  Copy-Item -LiteralPath $src -Destination (Join-Path $backupDir $name) -Force
}

$pagePath = Join-Path $root "src\app\eco\mural\page.tsx"
$widePath = Join-Path $root "src\app\eco\mural\_components\MuralWideStyles.tsx"

if (-not (Test-Path -LiteralPath $pagePath)) { throw ("Nao achei: " + $pagePath) }
if (-not (Test-Path -LiteralPath $widePath)) { throw ("Nao achei: " + $widePath) }

$backupDir = Join-Path $root ("tools\_patch_backup\eco-step-141-mural-split-wrapper-safe-v0_1-" + $stamp)
BackupFile $pagePath $backupDir
BackupFile $widePath $backupDir
Write-Host ("[DIAG] backup -> " + $backupDir)

# --- PATCH 1: rewrite MuralWideStyles.tsx ---
$wideLines = @(
  '"use client";',
  '',
  'export default function MuralWideStyles() {',
  '  return (',
  '    <style>{`',
  '/* ECO — Mural: wide + split view + mapa sticky */',
  '.eco-mural {',
  '  background: #070b08 !important;',
  '  color: #eaeaea !important;',
  '}',
  '',
  '/* largura do miolo */',
  '.eco-mural {',
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
  '.eco-mural-right {',
  '  display: none;',
  '}',
  '.eco-mural[data-map="1"] .eco-mural-right {',
  '  display: block;',
  '}',
  '',
  '@media (min-width: 1100px) {',
  '  .eco-mural[data-map="1"] .eco-mural-split {',
  '    grid-template-columns: minmax(620px, 1fr) 600px;',
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
  '  border: 0 !important;',
  '  display: block !important;',
  '  border-radius: 14px !important;',
  '  height: 420px !important;',
  '}',
  '@media (min-width: 1100px) {',
  '  .eco-mural iframe[src*="openstreetmap.org"] {',
  '    height: calc(100vh - 160px) !important;',
  '    min-height: 520px !important;',
  '  }',
  '}',
  '',
  '/* cards em grid no desktop (se existir .eco-mural-cards) */',
  '@media (min-width: 900px) {',
  '  .eco-mural .eco-mural-cards {',
  '    display: grid;',
  '    grid-template-columns: repeat(2, minmax(0, 1fr));',
  '    gap: 14px;',
  '  }',
  '}',
  '    `}</style>',
  '  );',
  '}'
)
WriteUtf8NoBom $widePath ($wideLines -join "`n")
Write-Host ("[PATCH] rewrote -> " + $widePath) -ForegroundColor Green

# --- PATCH 2: patch page.tsx (mapOpen + data-map + split wrapper) ---
$raw = [System.IO.File]::ReadAllText($pagePath, [System.Text.UTF8Encoding]::new($false))
$lines = $raw -split "`r?`n"
$hasSplit = $raw.Contains("ECO_SPLIT_START")
$hasMapOpen = $raw.Contains("const mapOpen")
$out = New-Object System.Collections.Generic.List[string]

$openedSplit = $false
$wrappedMap = $false
$insertedConsts = $false

for ($i=0; $i -lt $lines.Length; $i++) {
  $line = $lines[$i]

  # corrigir vazamento PowerShell no TS (se existir)
  if ($line -like "*const mapOpen*" -and $line -like "*-or*") {
    $line = $line.Replace(" -or ", " || ")
  }

  # garantir signature com searchParams (se estiver Page())
  if ($line -like "export default function Page()*" -and ($line -like "*Page()*")) {
    $line = "export default function Page({ searchParams }: { searchParams?: Record<string, string | string[] | undefined> }) {"
    $out.Add($line)
    if (-not $hasMapOpen) {
      $out.Add("  const mapRaw = searchParams?.map;")
      $out.Add("  const mapVal = Array.isArray(mapRaw) ? mapRaw[0] : mapRaw;")
      $out.Add("  const mapOpen = mapVal === ""1"" || mapVal === ""true"";")
      $insertedConsts = $true
      $hasMapOpen = $true
    }
    continue
  }

  # se já tem searchParams na assinatura mas não tem mapOpen, injeta logo abaixo
  if (-not $hasMapOpen -and -not $insertedConsts -and $line -like "export default function Page*searchParams*") {
    $out.Add($line)
    $out.Add("  const mapRaw = searchParams?.map;")
    $out.Add("  const mapVal = Array.isArray(mapRaw) ? mapRaw[0] : mapRaw;")
    $out.Add("  const mapOpen = mapVal === ""1"" || mapVal === ""true"";")
    $insertedConsts = $true
    $hasMapOpen = $true
    continue
  }

  # adicionar data-map no <main ... eco-mural ...>
  if ($line -like "*<main*" -and $line -like "*eco-mural*" -and ($line -notlike "*data-map*")) {
    if ($line.Contains(">")) {
      $line = $line.Replace(">", " data-map={mapOpen ? ""1"" : ""0""}>")
    }
  }

  # abrir split depois do componente de styles (preferencia)
  if (-not $hasSplit -and -not $openedSplit -and (
      $line -like "*<MuralWideStyles*" -or $line -like "*<EcoWideStyles*" -or $line -like "*<MuralReadableStyles*"
    )) {
    $out.Add($line)
    $out.Add("      {/* ECO_SPLIT_START */}")
    $out.Add("      <div className=""eco-mural-split"">")
    $out.Add("        <div className=""eco-mural-left"">")
    $openedSplit = $true
    continue
  }

  # fallback: se nao achou styles, abre split logo depois do <main ... eco-mural ...>
  if (-not $hasSplit -and -not $openedSplit -and ($line -like "*<main*" -and $line -like "*eco-mural*")) {
    $out.Add($line)
    $out.Add("      {/* ECO_SPLIT_START */}")
    $out.Add("      <div className=""eco-mural-split"">")
    $out.Add("        <div className=""eco-mural-left"">")
    $openedSplit = $true
    continue
  }

  # mover MuralInlineMapa para a coluna direita (render condicional)
  if (-not $hasSplit -and $openedSplit -and -not $wrappedMap -and ($line -like "*<MuralInlineMapa*")) {
    $out.Add("        </div>")
    $out.Add("        <div className=""eco-mural-right"">")
    $out.Add("          {mapOpen ? <MuralInlineMapa /> : null}")
    $out.Add("        </div>")
    $out.Add("      </div>")
    $out.Add("      {/* ECO_SPLIT_END */}")
    $wrappedMap = $true
    continue
  }

  $out.Add($line)
}

if (-not $hasSplit) {
  if (-not $openedSplit) { throw "Nao consegui abrir split (nao achei styles nem <main eco-mural>)." }
  if (-not $wrappedMap) { throw "Nao consegui fechar split (nao achei <MuralInlineMapa />)." }
}

WriteUtf8NoBom $pagePath ($out.ToArray() -join "`n")
Write-Host ("[PATCH] updated -> " + $pagePath) -ForegroundColor Green

# --- REPORT ---
$reportDir = Join-Path $root "reports"
EnsureDir $reportDir
$reportPath = Join-Path $reportDir ("eco-step-141-mural-split-wrapper-safe-v0_1-" + $stamp + ".md")
$r = @()
$r += "# eco-step-141-mural-split-wrapper-safe-v0_1 - $stamp"
$r += ""
$r += "## PATCH"
$r += "- rewrote: src/app/eco/mural/_components/MuralWideStyles.tsx"
$r += "- updated: src/app/eco/mural/page.tsx (mapOpen + data-map + split wrapper)"
$r += ""
$r += "## VERIFY"
$r += "- Ctrl+C -> npm run dev"
$r += "- abrir: /eco/mural (map fechado => 1 coluna)"
$r += "- abrir: /eco/mural?map=1 (>=1100px => 2 colunas, mapa sticky à direita)"
WriteUtf8NoBom $reportPath ($r -join "`n")
Write-Host ("[REPORT] " + $reportPath)

Write-Host ""
Write-Host "[VERIFY] rode:" -ForegroundColor Yellow
Write-Host "  Ctrl+C -> npm run dev"
Write-Host "  abrir /eco/mural"
Write-Host "  abrir /eco/mural?map=1 (em tela larga: mapa à direita sticky)"