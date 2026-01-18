param([string]$Root = (Resolve-Path ".").Path)
$ErrorActionPreference = "Stop"

# --- bootstrap (tenta usar tools/_bootstrap.ps1, mas cai em fallback se faltar função)
function _TryDotSource([string]$p) { try { if (Test-Path -LiteralPath $p) { . $p; return $true } } catch {} return $false }
$b1 = Join-Path $Root "tools\_bootstrap.ps1"
[void](_TryDotSource $b1)
if (-not (Get-Command EnsureDir -ErrorAction SilentlyContinue)) {
  function EnsureDir([string]$p) { if ([string]::IsNullOrWhiteSpace($p)) { return }; New-Item -ItemType Directory -Force -Path $p | Out-Null }
}
if (-not (Get-Command WriteUtf8NoBom -ErrorAction SilentlyContinue)) {
  function WriteUtf8NoBom([string]$path,[string]$content) {
    $enc = New-Object System.Text.UTF8Encoding($false)
    EnsureDir (Split-Path -Parent $path)
    [IO.File]::WriteAllText($path, $content, $enc)
  }
}
if (-not (Get-Command BackupFile -ErrorAction SilentlyContinue)) {
  function BackupFile([string]$path,[string]$backupDir) {
    if (-not (Test-Path -LiteralPath $path)) { return }
    EnsureDir $backupDir
    $leaf = Split-Path -Leaf $path
    $dst = Join-Path $backupDir ($leaf + ".bak")
    Copy-Item -LiteralPath $path -Destination $dst -Force
  }
}

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$me = "eco-step-127-fix-p-undefined-openstreetmap-and-sort-auto-v0_1"
Write-Host ("== " + $me + " == " + $stamp)
$backupDir = Join-Path $Root ("tools\_patch_backup\" + $stamp + "-" + $me)
EnsureDir $backupDir

$targets = @(
  (Join-Path $Root "src\app\eco\mural\MuralClient.tsx"),
  (Join-Path $Root "src\app\eco\mural-acoes\MuralAcoesClient.tsx")
)

function _Count([string]$raw, [string]$pat) { return ([regex]::Matches($raw, $pat)).Count }

$report = @()
$report += ("# " + $me)
$report += ""
$report += ("- Time: " + $stamp)
$report += ("- Backup: " + $backupDir)
$report += ""

foreach ($f in $targets) {
  $report += ("## " + (Split-Path -Leaf $f))
  if (-not (Test-Path -LiteralPath $f)) {
    $report += ("- MISSING: " + $f)
    $report += ""
    continue
  }

  $raw = Get-Content -Raw -LiteralPath $f
  $pBefore = _Count $raw "\bp\."
  $itBefore = _Count $raw "\bit\."
  $itemBefore = _Count $raw "\bitem\."
  $report += ("- before: p.=" + $pBefore + " it.=" + $itBefore + " item.=" + $itemBefore)

  $raw2 = $raw

  # 1) Fix OSM vars based on nearest .map((VAR near openstreetmap)
  $idx = $raw2.IndexOf("openstreetmap.org")
  $mapVar = $null
  if ($idx -ge 0) {
    $start = [Math]::Max(0, $idx - 2500)
    $seg = $raw2.Substring($start, [Math]::Min(2500, $raw2.Length - $start))
    $ms = [regex]::Matches($seg, "\.map\(\(\s*([A-Za-z_][A-Za-z0-9_]*)")
    if ($ms.Count -gt 0) { $mapVar = $ms[$ms.Count-1].Groups[1].Value }
  }
  if (-not $mapVar) { $mapVar = "item" }
  $report += ("- mapVarNearOSM: " + $mapVar)

  # replace only typical OSM lat/lng String(...) usages
  $raw2 = [regex]::Replace($raw2, "String\(\s*(p|it|item)\.lat\s*\)", ("String(" + $mapVar + ".lat)"))
  $raw2 = [regex]::Replace($raw2, "String\(\s*(p|it|item)\.lng\s*\)", ("String(" + $mapVar + ".lng)"))

  # 2) If still has p. but there is NO declaration of p, try to map p. -> first sort param (a)
  $hasDeclP = ($raw2 -match "\.map\(\(\s*p\b") -or ($raw2 -match "\b(const|let|var|function)\s+p\b")
  $pMid = _Count $raw2 "\bp\."
  if (($pMid -gt 0) -and (-not $hasDeclP)) {
    $mSort = [regex]::Match($raw2, "\.sort\(\(\s*([A-Za-z_][A-Za-z0-9_]*)\s*,\s*([A-Za-z_][A-Za-z0-9_]*)")
    if ($mSort.Success) {
      $aName = $mSort.Groups[1].Value
      $raw2 = [regex]::Replace($raw2, "\bp\.", ($aName + "."))
      $report += ("- extraFix: replaced p. -> " + $aName + ". (no p declared)")
    } else {
      $report += ("- extraFix: p. remained but no sort((a,b) found; left as-is")
    }
  }

  $changed = ($raw2 -ne $raw)
  if ($changed) {
    BackupFile $f $backupDir
    WriteUtf8NoBom $f $raw2
    $report += ("- patched: YES")
  } else {
    $report += ("- patched: NO (no changes)")
  }

  $pAfter = _Count $raw2 "\bp\."
  $itAfter = _Count $raw2 "\bit\."
  $itemAfter = _Count $raw2 "\bitem\."
  $report += ("- after:  p.=" + $pAfter + " it.=" + $itAfter + " item.=" + $itemAfter)
  $report += ""
}

# --- write report
$reportPath = Join-Path $Root ("reports\" + $me + "-" + $stamp + ".md")
EnsureDir (Split-Path -Parent $reportPath)
WriteUtf8NoBom $reportPath ($report -join "`n")
Write-Host ("[REPORT] " + $reportPath)

Write-Host ""
Write-Host "[VERIFY] rode:"
Write-Host "  Ctrl+C -> npm run dev"
Write-Host "  abrir /eco/mural (não pode dar p/it undefined)"
Write-Host "  abrir /eco/mural-acoes (se existir)"
Write-Host "  abrir /eco/mapa"
