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

Write-Host ("== eco-step-142b-fix-mural-map-split-and-dev-webpack-safe-v0_2 == " + $stamp) -ForegroundColor Cyan
Write-Host ("[DIAG] Root: " + $root)

$pagePath = Join-Path $root "src\app\eco\mural\page.tsx"
$widePath = Join-Path $root "src\app\eco\mural\_components\MuralWideStyles.tsx"
$pkgPath  = Join-Path $root "package.json"

if (-not (Test-Path -LiteralPath $pagePath)) { throw ("Nao achei: " + $pagePath) }
if (-not (Test-Path -LiteralPath $widePath)) { throw ("Nao achei: " + $widePath) }

$backupDir = Join-Path $root ("tools\_patch_backup\eco-step-142b-fix-mural-map-split-and-dev-webpack-safe-v0_2-" + $stamp)
EnsureDir $backupDir
BackupFile $pagePath $backupDir
BackupFile $widePath $backupDir
if (Test-Path -LiteralPath $pkgPath) { BackupFile $pkgPath $backupDir }
Write-Host ("[DIAG] backup -> " + $backupDir) -ForegroundColor DarkGray

# =========================
# PATCH 1: MuralWideStyles.tsx (split + sticky)
# =========================
$wideLines = @(
  '"use client";',
  '',
  'export default function MuralWideStyles() {',
  '  return (',
  '    <style>{`',
  '/* ECO — Mural: split + mapa sticky (map=1) */',
  '.eco-mural {',
  '  background: #070b08 !important;',
  '  color: #eaeaea !important;',
  '  max-width: min(1700px, calc(100% - 32px)) !important;',
  '  margin: 0 auto !important;',
  '  padding: 18px 0 60px !important;',
  '}',
  '',
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
# PATCH 2: page.tsx (imports + mapOpen + data-map + split + map)
# =========================
$raw = ReadUtf8NoBom $pagePath

$hasWideImport = $raw.Contains("_components/MuralWideStyles")
$hasMapImport  = $raw.Contains("_components/MuralInlineMapa")
$hasSplit      = $raw.Contains("eco-mural-split")
$hasWideRender = $raw.Contains("<MuralWideStyles")
$hasMapRender  = $raw.Contains("<MuralInlineMapa")

# 2.1 - garantir imports (inserir depois do ultimo import)
$lines = $raw -split "`r?`n"
$out = New-Object System.Collections.Generic.List[string]
$lastImportIdx = -1
for ($i=0; $i -lt $lines.Length; $i++) {
  $line = $lines[$i]
  if ($line -match "^\s*import\s+") { $lastImportIdx = $out.Count }
  $out.Add($line)
}
if (-not $hasWideImport -or -not $hasMapImport) {
  $ins = New-Object System.Collections.Generic.List[string]
  if (-not $hasWideImport) { $ins.Add("import MuralWideStyles from ""./_components/MuralWideStyles"";") }
  if (-not $hasMapImport)  { $ins.Add("import MuralInlineMapa from ""./_components/MuralInlineMapa"";") }
  if ($lastImportIdx -ge 0) {
    $out.InsertRange($lastImportIdx + 1, $ins)
  } else {
    # sem imports: coloca no topo
    $tmp = New-Object System.Collections.Generic.List[string]
    foreach ($x in $ins) { $tmp.Add($x) }
    foreach ($x in $out) { $tmp.Add($x) }
    $out = $tmp
  }
}
$raw2 = ($out.ToArray() -join "`n")

# 2.2 - garantir assinatura Page({ searchParams })
if ($raw2 -notmatch "export\s+default\s+.*function\s+Page\(\s*\{\s*searchParams") {
  $raw2 = [regex]::Replace(
    $raw2,
    "export\s+default\s+(async\s+)?function\s+Page\(\s*\)\s*\{",
    { param($m) if ($m.Groups[1].Value -ne "") { "export default async function Page({ searchParams }: { searchParams?: Record<string, string | string[] | undefined> }) {" } else { "export default function Page({ searchParams }: { searchParams?: Record<string, string | string[] | undefined> }) {" } },
    1
  )
}

# 2.3 - garantir mapOpen (JS ||, nada de -or)
if ($raw2 -notmatch "const\s+mapOpen\s*=") {
  $raw2Lines = $raw2 -split "`r?`n"
  $out2 = New-Object System.Collections.Generic.List[string]
  $inserted = $false
  for ($i=0; $i -lt $raw2Lines.Length; $i++) {
    $line = $raw2Lines[$i]
    $out2.Add($line)
    if (-not $inserted -and $line -match "export\s+default\s+.*function\s+Page\(") {
      $out2.Add("  const mapRaw = searchParams?.map;")
      $out2.Add("  const mapVal = Array.isArray(mapRaw) ? mapRaw[0] : mapRaw;")
      $out2.Add("  const mapOpen = (mapVal === ""1"" || mapVal === ""true"");")
      $inserted = $true
    }
  }
  $raw2 = ($out2.ToArray() -join "`n")
}

# 2.4 - garantir data-map no <main className="eco-mural"...> (suporta tag em multiplas linhas)
$raw2Lines = $raw2 -split "`r?`n"
$out3 = New-Object System.Collections.Generic.List[string]
$inMain = $false
$mainHasEco = $false
$mainHasData = $false
for ($i=0; $i -lt $raw2Lines.Length; $i++) {
  $line = $raw2Lines[$i]

  if ($line -match "<main") { $inMain = $true }
  if ($inMain -and $line.Contains("eco-mural")) { $mainHasEco = $true }
  if ($inMain -and $line.Contains("data-map=")) { $mainHasData = $true }

  if ($inMain -and $mainHasEco -and (-not $mainHasData) -and ($line -match ">")) {
    $line = $line -replace ">", " data-map={mapOpen ? ""1"" : ""0""}>"
    $mainHasData = $true
    $inMain = $false
    $mainHasEco = $false
  } elseif ($inMain -and ($line -match ">")) {
    $inMain = $false
    $mainHasEco = $false
    $mainHasData = $false
  }

  $out3.Add($line)
}
$raw3 = ($out3.ToArray() -join "`n")

# 2.5 - inserir <MuralWideStyles /> se nao existir (logo apos abrir <main ...eco-mural...>)
if ($raw3 -notmatch "<MuralWideStyles") {
  $ls = $raw3 -split "`r?`n"
  $o = New-Object System.Collections.Generic.List[string]
  $done = $false
  for ($i=0; $i -lt $ls.Length; $i++) {
    $o.Add($ls[$i])
    if (-not $done -and $ls[$i].Contains("<main") -and $ls[$i].Contains("eco-mural") -and ($ls[$i] -match ">")) {
      $o.Add("      <MuralWideStyles />")
      $done = $true
    }
  }
  $raw3 = ($o.ToArray() -join "`n")
}

# 2.6 - inserir split wrapper + mapa na direita (se ainda nao tiver split)
if ($raw3 -notmatch "eco-mural-split") {
  $ls = $raw3 -split "`r?`n"
  $o = New-Object System.Collections.Generic.List[string]
  $opened = $false
  $closed = $false
  for ($i=0; $i -lt $ls.Length; $i++) {
    $line = $ls[$i]

    # se achar MuralInlineMapa antigo, remove (vamos por na coluna direita)
    if ($line -match "<MuralInlineMapa") { continue }

    $o.Add($line)

    if (-not $opened -and $line -match "<MuralWideStyles") {
      $o.Add("      <div className=""eco-mural-split"">")
      $o.Add("        <div className=""eco-mural-left"">")
      $opened = $true
    }

    if ($opened -and (-not $closed) -and ($line -match "</main>")) {
      # volta 1 linha (remove </main>), fecha split, recoloca </main>
      $o.RemoveAt($o.Count-1)
      $o.Add("        </div>")
      $o.Add("        <div className=""eco-mural-right"">")
      $o.Add("          <MuralInlineMapa />")
      $o.Add("        </div>")
      $o.Add("      </div>")
      $o.Add("</main>")
      $closed = $true
    }
  }
  $raw3 = ($o.ToArray() -join "`n")
}

WriteUtf8NoBom $pagePath $raw3
Write-Host ("[PATCH] updated -> " + $pagePath) -ForegroundColor Green

# =========================
# PATCH 3: package.json dev:webpack
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
      Write-Host "[PATCH] package.json: added dev:webpack" -ForegroundColor Green
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
$reportPath = Join-Path $reportDir ("eco-step-142b-fix-mural-map-split-and-dev-webpack-safe-v0_2-" + $stamp + ".md")
$r = @()
$r += "# eco-step-142b-fix-mural-map-split-and-dev-webpack-safe-v0_2 - $stamp"
$r += ""
$r += "## PATCH"
$r += "- rewrote: src/app/eco/mural/_components/MuralWideStyles.tsx"
$r += "- updated: src/app/eco/mural/page.tsx (mapOpen + data-map + split + mapa direita)"
$r += "- optional: package.json added dev:webpack (next dev --no-turbo)"
$r += ""
$r += "## VERIFY"
$r += "- Ctrl+C -> npm run dev"
$r += "- abrir: /eco/mural"
$r += "- abrir: /eco/mural?map=1 (>=1100px => 2 colunas, mapa sticky direita)"
$r += "- se overlay sourcemap incomodar: npm run dev:webpack"
WriteUtf8NoBom $reportPath ($r -join "`n")
Write-Host ("[REPORT] " + $reportPath) -ForegroundColor Cyan

Write-Host ""
Write-Host "[VERIFY] rode:" -ForegroundColor Cyan
Write-Host "  Ctrl+C -> npm run dev"
Write-Host "  abrir /eco/mural"
Write-Host "  abrir /eco/mural?map=1"
Write-Host "  (se sourcemap overlay incomodar) npm run dev:webpack"