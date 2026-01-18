param()
$ErrorActionPreference = "Stop"
$ts = (Get-Date).ToString("yyyyMMdd-HHmmss")
$root = (Resolve-Path ".").Path
Write-Host ("== eco-step-136b-wide-shell-mural-mapa-safe-v0_1 == " + $ts) -ForegroundColor Cyan
Write-Host ("[DIAG] Root: " + $root)

function EnsureDir([string]$p) {
  if ([string]::IsNullOrWhiteSpace($p)) { return }
  if (!(Test-Path -LiteralPath $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null }
}

function WriteUtf8NoBom([string]$path, [string]$content) {
  if ([string]::IsNullOrWhiteSpace($path)) { throw "WriteUtf8NoBom: path vazio" }
  $parent = Split-Path -Parent $path
  EnsureDir $parent
  $enc = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($path, $content, $enc)
}

function BackupFile([string]$file, [string]$backupDir) {
  if (!(Test-Path -LiteralPath $file)) { return $null }
  EnsureDir $backupDir
  $safe = ($file -replace "[:\\\\/]", "_")
  $dst = Join-Path $backupDir ($safe + ".bak")
  Copy-Item -LiteralPath $file -Destination $dst -Force
  return $dst
}

function PatchFile([string]$file, [scriptblock]$mutator, [string]$backupDir, [ref]$report) {
  if (!(Test-Path -LiteralPath $file)) { $report.Value += "[SKIP] missing -> " + $file; return }
  $raw = Get-Content -Raw -LiteralPath $file
  if ($null -eq $raw) { $report.Value += "[SKIP] empty -> " + $file; return }
  $next = & $mutator $raw
  if ($next -ne $raw) {
    $bak = BackupFile $file $backupDir
    WriteUtf8NoBom $file $next
    $report.Value += "[PATCH] " + $file
    if ($bak) { $report.Value += "        backup: " + $bak }
  } else {
    $report.Value += "[OK] no-change -> " + $file
  }
}

function InsertImportAndRender([string]$raw, [string]$importLine, [string]$jsxTag) {
  if ($raw -notmatch [regex]::Escape($importLine)) {
    $lines = $raw -split "`r?`n"
    $lastImport = -1
    for ($i=0; $i -lt $lines.Length; $i++) {
      $t = $lines[$i].TrimStart()
      if ($t.StartsWith("import ")) { $lastImport = $i }
    }
    if ($lastImport -ge 0) {
      $before = $lines[0..$lastImport]
      $after  = @()
      if ($lastImport + 1 -lt $lines.Length) { $after = $lines[($lastImport+1)..($lines.Length-1)] }
      $lines = @($before + @($importLine) + $after)
    } else {
      $lines = @($importLine) + $lines
    }
    $raw = ($lines -join "`n")
  }
  if ($raw -notmatch "<\s*EcoWideStyles\s*/>") {
    $ix = $raw.IndexOf("<main")
    if ($ix -ge 0) {
      $gt = $raw.IndexOf(">", $ix)
      if ($gt -ge 0) { $raw = $raw.Insert($gt + 1, "`n      " + $jsxTag) }
    }
  }
  return $raw
}

function EnsureMainWideAttr([string]$raw) {
  $ix = $raw.IndexOf("<main")
  if ($ix -lt 0) { return $raw }
  $gt = $raw.IndexOf(">", $ix)
  if ($gt -lt 0) { return $raw }
  $tag = $raw.Substring($ix, $gt - $ix + 1)
  if ($tag -match "data-eco-wide=") { return $raw }
  $tag2 = $tag.Insert($tag.Length-1, " data-eco-wide=`"1`"")
  return $raw.Remove($ix, $tag.Length).Insert($ix, $tag2)
}

$backupDir = Join-Path $root ("tools\_patch_backup\eco-step-136b-wide-shell-mural-mapa-safe-v0_1-" + $ts)
$reportDir = Join-Path $root "reports"
EnsureDir $reportDir
$reportPath = Join-Path $reportDir ("eco-step-136b-wide-shell-mural-mapa-safe-v0_1-" + $ts + ".md")
$report = @()

$muralPage = Join-Path $root "src\app\eco\mural\page.tsx"
$mapaPage  = Join-Path $root "src\app\eco\mapa\page.tsx"
$stylesDir = Join-Path $root "src\app\eco\_components"
$stylesFile = Join-Path $stylesDir "EcoWideStyles.tsx"

$report += "[DIAG] Targets:"
$report += " - " + $muralPage
$report += " - " + $mapaPage
$report += " - " + $stylesFile
$report += ""

EnsureDir $stylesDir

# EcoWideStyles.tsx (sem aspas duplas no CSS, só aspas simples)
$stylesFileLines = @(
  'export default function EcoWideStyles() {',
  '  const css = [',
  '    "main[data-eco-wide=''1''] { max-width: none !important; width: min(1700px, calc(100% - 32px)) !important; margin: 0 auto !important; padding: 18px 0 60px !important; }",',
  '    "@media (max-width: 640px) { main[data-eco-wide=''1''] { width: calc(100% - 16px) !important; padding: 12px 0 48px !important; } }",',
  '    "main[data-eco-wide=''1''] * { box-sizing: border-box; }",',
  '    "iframe[src*=''openstreetmap.org''][src*=''embed''] { width: 100% !important; max-width: 100% !important; border: 1px solid #111 !important; border-radius: 12px !important; }",',
  '    "@media (min-width: 900px) { iframe[src*=''openstreetmap.org''][src*=''embed''] { height: 420px !important; } }",',
  '    "@media (max-width: 899px) { iframe[src*=''openstreetmap.org''][src*=''embed''] { height: 320px !important; } }",',
  '  ].join("\\n");',
  '  return <style>{css}</style>;',
  '}'
)
$stylesContent = ($stylesFileLines -join "`n")
if (Test-Path -LiteralPath $stylesFile) { BackupFile $stylesFile $backupDir | Out-Null }
WriteUtf8NoBom $stylesFile $stylesContent
$report += "[PATCH] created/updated -> " + $stylesFile
$report += ""

PatchFile $muralPage {
  param($raw)
  $raw = EnsureMainWideAttr $raw
  $importLine = "import EcoWideStyles from '../_components/EcoWideStyles'"
  $raw = InsertImportAndRender $raw $importLine "<EcoWideStyles />"
  return $raw
} $backupDir ([ref]$report)
$report += ""

PatchFile $mapaPage {
  param($raw)
  $raw = EnsureMainWideAttr $raw
  $importLine = "import EcoWideStyles from '../_components/EcoWideStyles'"
  $raw = InsertImportAndRender $raw $importLine "<EcoWideStyles />"
  return $raw
} $backupDir ([ref]$report)

$out = @()
$out += ("# eco-step-136b-wide-shell-mural-mapa-safe-v0_1 (" + $ts + ")")
$out += ""
$out += "## Mudanças"
$out += ""
$out += $report
WriteUtf8NoBom $reportPath ($out -join "`n")
Write-Host ("[REPORT] " + $reportPath) -ForegroundColor DarkGray

Write-Host ""
Write-Host "[VERIFY] rode:" -ForegroundColor Yellow
Write-Host "  Ctrl+C -> npm run dev"
Write-Host "  abrir /eco/mural (mais largo no desktop)"
Write-Host "  abrir /eco/mapa (mais largo no desktop)"