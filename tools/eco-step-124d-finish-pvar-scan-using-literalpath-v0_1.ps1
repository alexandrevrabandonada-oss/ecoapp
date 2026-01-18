# eco-step-124d-finish-pvar-scan-using-literalpath-v0_1
$ErrorActionPreference = "Stop"

$Root = (Resolve-Path ".").Path
$me = "eco-step-124d-finish-pvar-scan-using-literalpath-v0_1"
$stamp = (Get-Date -Format "yyyyMMdd-HHmmss")
$backupDir = Join-Path $Root ("tools\_patch_backup\" + $stamp + "-" + $me)

# bootstrap (agora deve estar OK)
$boot = Join-Path $Root "tools\_bootstrap.ps1"
if (Test-Path $boot) { . $boot }

function SafeEnsureDir([string]$p) {
  if ([string]::IsNullOrWhiteSpace($p)) { return }
  if (!(Test-Path -LiteralPath $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null }
}

function BackupFileLiteral([string]$src, [string]$backupDir) {
  if (!(Test-Path -LiteralPath $src)) { return $null }
  SafeEnsureDir $backupDir
  $leaf = ($src -replace "[:\\\/]", "_")
  $dst = Join-Path $backupDir ($leaf + ".bak")
  Copy-Item -Force -LiteralPath $src -Destination $dst
  return $dst
}

function WriteUtf8NoBomLiteral([string]$path, [string]$content) {
  SafeEnsureDir (Split-Path -Parent $path)
  $enc = [System.Text.UTF8Encoding]::new($false)
  [System.IO.File]::WriteAllText($path, $content, $enc)
}

function FindNearestMapParam([string]$raw, [int]$idx) {
  $start = [Math]::Max(0, $idx - 2200)
  $window = $raw.Substring($start, $idx - $start)
  $ms = [regex]::Matches($window, "\.map\(\(\s*([A-Za-z_\$][A-Za-z0-9_\$]*)")
  if ($ms.Count -gt 0) { return $ms[$ms.Count - 1].Groups[1].Value }
  return $null
}

function PatchOpenStreetMapPVar([string]$raw) {
  $changed = 0
  $pos = 0
  while ($true) {
    $idx = $raw.IndexOf("openstreetmap", $pos, [System.StringComparison]::OrdinalIgnoreCase)
    if ($idx -lt 0) { break }

    $param = FindNearestMapParam $raw $idx
    if ([string]::IsNullOrWhiteSpace($param)) { $param = "it" }

    $blockStart = $raw.LastIndexOf("`n", $idx)
    if ($blockStart -lt 0) { $blockStart = 0 } else { $blockStart = $blockStart + 1 }

    $blockEnd = $blockStart
    for ($i=0; $i -lt 4; $i++) {
      $nl = $raw.IndexOf("`n", $blockEnd)
      if ($nl -lt 0) { $blockEnd = $raw.Length; break }
      $blockEnd = $nl + 1
    }

    $blk = $raw.Substring($blockStart, $blockEnd - $blockStart)
    $before = $blk

    if ($param -ne "p") {
      $blk = $blk.Replace("p?.lat", ($param + "?.lat"))
      $blk = $blk.Replace("p?.lng", ($param + "?.lng"))
      $blk = $blk.Replace("p.lat",  ($param + ".lat"))
      $blk = $blk.Replace("p.lng",  ($param + ".lng"))
      $blk = $blk.Replace("p?.latitude", ($param + "?.latitude"))
      $blk = $blk.Replace("p?.longitude", ($param + "?.longitude"))
      $blk = $blk.Replace("p.latitude",  ($param + ".latitude"))
      $blk = $blk.Replace("p.longitude", ($param + ".longitude"))
    }

    if ($blk -ne $before) {
      $raw = $raw.Substring(0, $blockStart) + $blk + $raw.Substring($blockEnd)
      $changed++
      $pos = $blockStart + $blk.Length
    } else {
      $pos = $idx + 12
    }
  }
  return @{ raw = $raw; changed = $changed }
}

function PatchSortComparatorPVar([string]$raw) {
  $changed = 0
  $matches = [regex]::Matches($raw, "\.sort\(\(\s*([A-Za-z_\$][A-Za-z0-9_\$]*)\s*,\s*([A-Za-z_\$][A-Za-z0-9_\$]*)")
  foreach ($m in $matches) {
    $a = $m.Groups[1].Value
    $start = $m.Index
    $len = [Math]::Min(900, $raw.Length - $start)
    if ($len -le 0) { continue }

    $seg = $raw.Substring($start, $len)
    if ($seg.Contains("p.") -or $seg.Contains("p?.")) {
      $before = $seg
      if ($a -ne "p") {
        $seg = $seg.Replace("p?.", ($a + "?."))
        $seg = $seg.Replace("p.",  ($a + "."))
      }
      if ($seg -ne $before) {
        $raw = $raw.Substring(0, $start) + $seg + $raw.Substring($start + $len)
        $changed++
      }
    }
  }
  return @{ raw = $raw; changed = $changed }
}

SafeEnsureDir $backupDir
SafeEnsureDir (Join-Path $Root "reports")

Write-Host ("== " + $me + " == " + $stamp)
Write-Host ("[DIAG] Root: " + $Root)

$ecoDir = Join-Path $Root "src\app\eco"
if (!(Test-Path -LiteralPath $ecoDir)) { throw ("eco dir not found: " + $ecoDir) }

$files = Get-ChildItem -LiteralPath $ecoDir -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -in ".ts",".tsx" }

$patched = @()
$skipped = @()
$totalMap = 0
$totalSort = 0

foreach ($f in $files) {
  try {
    $raw = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Stop
    if ([string]::IsNullOrWhiteSpace($raw)) { continue }

    $need = $false
    if ($raw.ToLower().Contains("openstreetmap") -and ($raw.Contains("p.lat") -or $raw.Contains("p.lng") -or $raw.Contains("p?.lat") -or $raw.Contains("p?.lng"))) { $need = $true }
    if (($raw.Contains(".sort((") -or $raw.Contains(".sort( (")) -and ($raw.Contains("p.") -or $raw.Contains("p?."))) { $need = $true }
    if (-not $need) { continue }

    $before = $raw

    $r1 = PatchOpenStreetMapPVar $raw
    $raw = $r1.raw
    $totalMap += [int]$r1.changed

    $r2 = PatchSortComparatorPVar $raw
    $raw = $r2.raw
    $totalSort += [int]$r2.changed

    if ($raw -ne $before) {
      BackupFileLiteral $f.FullName $backupDir | Out-Null
      WriteUtf8NoBomLiteral $f.FullName $raw
      $patched += $f.FullName
      Write-Host ("[PATCH] fixed -> " + $f.FullName)
    }
  } catch {
    $skipped += ($f.FullName + " :: " + $_.Exception.Message)
  }
}

$report = @()
$report += "# $me"
$report += ""
$report += "- Time: $stamp"
$report += "- Backup: $backupDir"
$report += ""
$report += "## Results"
$report += ("- Patched files: " + $patched.Count)
foreach ($p in $patched) { $report += ("  - " + $p) }
$report += ("- openstreetmap blocks fixed: " + $totalMap)
$report += ("- sort blocks fixed: " + $totalSort)
$report += ("- skipped (read errors): " + $skipped.Count)
if ($skipped.Count -gt 0) {
  $report += ""
  $report += "### Skipped"
  foreach ($s in $skipped) { $report += ("- " + $s) }
}
$report += ""
$report += "## Verify"
$report += "1) Ctrl+C -> npm run dev"
$report += "2) abrir /eco/mural (sem 'p is not defined')"
$report += "3) clicar 🗺️ Abrir Mapa / 🗺️ Mapa nos cards"
$report += "4) abrir /eco/mapa"
$report += ""

$reportPath = Join-Path $Root ("reports\" + $me + "-" + $stamp + ".md")
WriteUtf8NoBomLiteral $reportPath ($report -join "`n")
Write-Host ("[REPORT] " + $reportPath)

Write-Host ""
Write-Host "[VERIFY] rode:"
Write-Host "  Ctrl+C -> npm run dev"
Write-Host "  abrir /eco/mural"
Write-Host "  clicar 🗺️ Abrir Mapa e 🗺️ Mapa nos cards"
Write-Host "  abrir /eco/mapa"