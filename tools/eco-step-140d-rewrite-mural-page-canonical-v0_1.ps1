param([switch]$OpenReport)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$root = (Resolve-Path ".").Path
Write-Host ("== eco-step-140d-rewrite-mural-page-canonical-v0_1 == " + $stamp) -ForegroundColor Cyan

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
  $leaf = Split-Path -Leaf $src
  Copy-Item -LiteralPath $src -Destination (Join-Path $backupDir ($leaf + ".bak")) -Force
}

$pagePath = Join-Path $root "src\app\eco\mural\page.tsx"
if (-not (Test-Path -LiteralPath $pagePath)) { throw ("Nao achei: " + $pagePath) }

$backupDir = Join-Path $root ("tools\_patch_backup\eco-step-140d-rewrite-mural-page-canonical-v0_1-" + $stamp)
EnsureDir $backupDir
BackupFile $pagePath $backupDir

# canonical page.tsx (server component) -> split + mapOpen
$pageLines = @(
  'import MuralClient from "./MuralClient";',
  'import MuralInlineMapa from "./_components/MuralInlineMapa";',
  'import MuralWideStyles from "./_components/MuralWideStyles";',
  '',
  'export default function Page({ searchParams }: { searchParams?: Record<string, string | string[]> }) {',
  '  const mapRaw = searchParams?.map;',
  '  const mapVal = Array.isArray(mapRaw) ? mapRaw[0] : mapRaw;',
  '  const mapOpen = (mapVal === "1" || mapVal === "true");',
  '  return (',
  '    <main className="eco-mural" data-eco-wide="1" data-map={mapOpen ? "1" : "0"} style={{ padding: 16 }}>',
  '      <MuralWideStyles />',
  '      <div className="eco-mural-split">',
  '        <div className="eco-mural-left">',
  '          <MuralClient />',
  '        </div>',
  '        <div className="eco-mural-right">',
  '          <MuralInlineMapa />',
  '        </div>',
  '      </div>',
  '    </main>',
  '  );',
  '}'
)

WriteUtf8NoBom $pagePath ($pageLines -join "`n")
Write-Host ("[PATCH] rewrote -> " + $pagePath) -ForegroundColor Green

# report
$reportDir = Join-Path $root "reports"
EnsureDir $reportDir
$reportPath = Join-Path $reportDir ("eco-step-140d-rewrite-mural-page-canonical-v0_1-" + $stamp + ".md")
$r = @()
$r += "# eco-step-140d-rewrite-mural-page-canonical-v0_1 - $stamp"
$r += ""
$r += ("Backup: " + $backupDir)
$r += ""
$r += "Patch:"
$r += "- rewrote: src/app/eco/mural/page.tsx (canonical split + mapOpen)"
$r += ""
$r += "Verify:"
$r += "- Ctrl+C -> npm run dev"
$r += "- abrir /eco/mural"
$r += "- abrir /eco/mural?map=1 (desktop: 2 colunas, mapa sticky na direita via MuralWideStyles)"
WriteUtf8NoBom $reportPath ($r -join "`n")
Write-Host ("[REPORT] " + $reportPath)
if ($OpenReport) { Start-Process $reportPath | Out-Null }