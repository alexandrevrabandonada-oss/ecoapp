# eco-step-129-remove-osm-inline-links-v0_1
param()

$ErrorActionPreference = "Stop"
$Root = (Resolve-Path ".").Path
$me = "eco-step-129-remove-osm-inline-links-v0_1"
$stamp = (Get-Date).ToString("yyyyMMdd-HHmmss")

function EnsureDir([string]$p) {
  if ([string]::IsNullOrWhiteSpace($p)) { return }
  if (!(Test-Path $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null }
}
function WriteUtf8NoBom([string]$path, [string]$content) {
  EnsureDir (Split-Path -Parent $path)
  [IO.File]::WriteAllText($path, $content, [System.Text.UTF8Encoding]::new($false))
}
function BackupFile([string]$src, [string]$backupDir) {
  EnsureDir $backupDir
  if (Test-Path $src) {
    $leaf = Split-Path -Leaf $src
    $dst  = Join-Path $backupDir ($leaf + ".bak")
    Copy-Item -Force $src $dst
  }
}

Write-Host "== $me == $stamp"
Write-Host "[DIAG] Root: $Root"

$backupDir = Join-Path $Root ("tools\_patch_backup\" + $stamp + "-" + $me)
EnsureDir $backupDir

$targets = @(
  "src\app\eco\mural\MuralClient.tsx",
  "src\app\eco\mural-acoes\MuralAcoesClient.tsx"
)

$report = @()
$report += "# $me"
$report += ""
$report += "- Time: $stamp"
$report += "- Backup: $backupDir"
$report += ""

foreach ($rel in $targets) {
  $full = Join-Path $Root $rel
  if (!(Test-Path $full)) {
    Write-Host "[WARN] missing: $rel"
    $report += "- WARN missing: $rel"
    continue
  }

  BackupFile $full $backupDir

  $raw = Get-Content -Raw -LiteralPath $full
  $lines = $raw -split "`r?`n"
  $removed = 0

  $out = New-Object System.Collections.Generic.List[string]
  foreach ($ln in $lines) {
    if ($ln -match "openstreetmap\.org" -or $ln -match "mlat=" -or $ln -match "mlon=") {
      $removed++
      continue
    }
    $out.Add($ln)
  }

  if ($removed -gt 0) {
    WriteUtf8NoBom $full ($out -join "`n")
    Write-Host ("[PATCH] removed " + $removed + " OSM line(s) -> " + $rel)
    $report += "- Patched: $rel (removed OSM lines: $removed)"
  } else {
    Write-Host ("[OK] no OSM lines found -> " + $rel)
    $report += "- OK: $rel (no OSM lines found)"
  }
}

$report += ""
$report += "## Verify"
$report += "1) Ctrl+C -> npm run dev"
$report += "2) abrir /eco/mural (não pode dar 'item/p/it is not defined')"
$report += "3) abrir /eco/mapa"
$report += ""

$reportPath = Join-Path $Root ("reports\" + $me + "-" + $stamp + ".md")
WriteUtf8NoBom $reportPath ($report -join "`n")
Write-Host ("[REPORT] " + $reportPath)

Write-Host ""
Write-Host "[VERIFY] rode:"
Write-Host "  Ctrl+C -> npm run dev"
Write-Host "  abrir /eco/mural"
Write-Host "  abrir /eco/mapa"