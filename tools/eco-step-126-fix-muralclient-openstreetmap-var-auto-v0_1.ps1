param([string]$Root = (Get-Location).Path)
$ErrorActionPreference = "Stop"

function TryDotSourceBootstrap($rootPath) {
  $b1 = Join-Path $rootPath "tools\_bootstrap.ps1"
  if (Test-Path $b1) { . $b1; return $true }
  return $false
}

if (-not (TryDotSourceBootstrap $Root)) {
  function EnsureDir([string]$p) { if (-not (Test-Path $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null } }
  function WriteUtf8NoBom([string]$p,[string]$c) { EnsureDir (Split-Path -Parent $p); [IO.File]::WriteAllText($p,$c,[Text.UTF8Encoding]::new($false)) }
  function BackupFile([string]$p,[string]$dir) {
    EnsureDir $dir
    if (Test-Path $p) {
      $leaf = Split-Path -Leaf $p
      $dst = Join-Path $dir ($leaf + "." + (Get-Date -Format "yyyyMMdd-HHmmss") + ".bak")
      Copy-Item -Force $p $dst
    }
  }
}

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$me = "eco-step-126-fix-muralclient-openstreetmap-var-auto-v0_1"
Write-Host ("== " + $me + " == " + $stamp)

$backupDir = Join-Path $Root ("tools\_patch_backup\" + $stamp + "-" + $me)
EnsureDir $backupDir

$targets = @(
  (Join-Path $Root "src\app\eco\mural\MuralClient.tsx"),
  (Join-Path $Root "src\app\eco\mural-acoes\MuralAcoesClient.tsx")
)

$report = @()
$report += "# " + $me
$report += ""
$report += "- Time: " + $stamp
$report += "- Backup: " + $backupDir
$report += ""

foreach ($target in $targets) {
  if (-not (Test-Path $target)) {
    $report += "## " + $target
    $report += "- SKIP: file not found"
    $report += ""
    continue
  }

  $raw = Get-Content -LiteralPath $target -Raw
  if (-not $raw) { continue }

  $var = $null
  $m = [regex]::Match($raw, "items\s*\.\s*map\s*\(\s*\(\s*([A-Za-z_][A-Za-z0-9_]*)")
  if ($m.Success) { $var = $m.Groups[1].Value }
  if (-not $var) {
    $m2 = [regex]::Match($raw, "\.map\s*\(\s*\(\s*([A-Za-z_][A-Za-z0-9_]*)")
    if ($m2.Success) { $var = $m2.Groups[1].Value }
  }
  if (-not $var) { $var = "item" }

  $lines = $raw -split "`n"
  $changedLines = 0
  for ($i=0; $i -lt $lines.Count; $i++) {
    $ln = $lines[$i]
    if ($ln -like "*openstreetmap.org*") {
      $ln2 = $ln
      $ln2 = [regex]::Replace($ln2, "String\(([A-Za-z_][A-Za-z0-9_]*)\.lat\)", ("String(" + $var + ".lat)"))
      $ln2 = [regex]::Replace($ln2, "String\(([A-Za-z_][A-Za-z0-9_]*)\.lng\)", ("String(" + $var + ".lng)"))
      $ln2 = $ln2.Replace("it.", ($var + ".")).Replace("item.", ($var + ".")).Replace("p.", ($var + "."))
      if ($ln2 -ne $ln) { $lines[$i] = $ln2; $changedLines++ }
    }
  }
  $new = $lines -join "`n"

  $pHits = [regex]::Matches($new, "\bp\.").Count
  $itHits = [regex]::Matches($new, "\bit\.").Count

  $report += "## " + (Split-Path -Leaf $target)
  $report += "- mapVar: " + $var
  $report += "- openstreetmap lines changed: " + $changedLines
  $report += "- remaining hits: p. = " + $pHits + " | it. = " + $itHits

  if ($new -ne $raw) {
    BackupFile $target $backupDir
    WriteUtf8NoBom $target $new
    $report += "- patched: YES"
  } else {
    $report += "- patched: NO (already ok)"
  }
  $report += ""
}

$reportPath = Join-Path $Root ("reports\" + $me + "-" + $stamp + ".md")
EnsureDir (Split-Path -Parent $reportPath)
WriteUtf8NoBom $reportPath ($report -join "`n")
Write-Host ("[REPORT] " + $reportPath)

Write-Host ""
Write-Host "[VERIFY] rode:"
Write-Host "  Ctrl+C -> npm run dev"
Write-Host "  abrir /eco/mural (sem p/it undefined)"
Write-Host "  abrir /eco/mapa"
