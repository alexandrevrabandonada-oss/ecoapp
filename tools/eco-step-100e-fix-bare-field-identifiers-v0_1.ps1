param([string]$Root = (Get-Location).Path)

$ts = Get-Date -Format "yyyyMMdd-HHmmss"
Write-Host ("== eco-step-100e-fix-bare-field-identifiers-v0_1 == " + $ts)
Write-Host ("[DIAG] Root: " + $Root)

$boot = Join-Path $Root "tools/_bootstrap.ps1"
if (Test-Path -LiteralPath $boot) { . $boot }

if (-not (Get-Command EnsureDir -ErrorAction SilentlyContinue)) {
  function EnsureDir([string]$p) { if (-not (Test-Path -LiteralPath $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null } }
}
if (-not (Get-Command WriteUtf8NoBom -ErrorAction SilentlyContinue)) {
  function WriteUtf8NoBom([string]$p, [string]$content) {
    EnsureDir (Split-Path -Parent $p)
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($p, $content, $enc)
  }
}
if (-not (Get-Command BackupFile -ErrorAction SilentlyContinue)) {
  function BackupFile([string]$root, [string]$p, [string]$backupDir) {
    if (Test-Path -LiteralPath $p) {
      $rel = $p.Substring($root.Length).TrimStart('\','/')
      $dest = Join-Path $backupDir ($rel -replace '[\\/]', '__')
      Copy-Item -Force -LiteralPath $p -Destination $dest
      Write-Host ('[BK] ' + $rel + ' -> ' + (Split-Path -Leaf $dest))
    }
  }
}

$backupDir = Join-Path $Root ("tools/_patch_backup/" + $ts + "-eco-step-100e-fix-bare-field-identifiers-v0_1")
$reportDir = Join-Path $Root "reports"
EnsureDir $backupDir
EnsureDir $reportDir

$apiRoot = Join-Path $Root "src/app/api/eco"
if (-not (Test-Path -LiteralPath $apiRoot)) { throw "[STOP] Nao achei src/app/api/eco" }

$routes = Get-ChildItem -LiteralPath $apiRoot -Recurse -File | Where-Object {
  $_.Name -ieq "route.ts" -or $_.Name -ieq "route.tsx"
}

Write-Host ("[DIAG] Found route files: " + $routes.Count)

$fields = @("pointId","criticalPointId","ecoCriticalPointId","ecoPointId")

$changed = New-Object System.Collections.Generic.List[string]
$scanned = New-Object System.Collections.Generic.List[string]

foreach ($f in $routes) {
  $p = $f.FullName
  $scanned.Add($p) | Out-Null

  $raw = Get-Content -LiteralPath $p -Raw -ErrorAction Stop
  $orig = $raw

  # Fix groupBy: by: [pointId]  -> by: ["pointId"] as any
  foreach ($k in $fields) {
    $raw = [regex]::Replace(
      $raw,
      "(by\s*:\s*)\[\s*" + [regex]::Escape($k) + "\s*\](\s*as\s*any)?",
      { param($m) ($m.Groups[1].Value + '["' + $k + '"] as any') },
      [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
    )
  }

  # Fix bracket accessor: pc?.[ecoPointConfirm] -> pc?.["ecoPointConfirm"]
  $raw = [regex]::Replace(
    $raw,
    "pc\?\.\[\s*([A-Za-z_][A-Za-z0-9_]*)\s*\]",
    { param($m) 'pc?.["' + $m.Groups[1].Value + '"]' }
  )

  # Fix arrays that accidentally got bare field identifiers (rare but deadly):
  # ... = [pointId, ...]  -> ... = ["pointId", ...]
  foreach ($k in $fields) {
    $raw = [regex]::Replace(
      $raw,
      "\[\s*" + [regex]::Escape($k) + "\s*(?=,|\])",
      '["' + $k + '"',
      [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
    )
    $raw = [regex]::Replace(
      $raw,
      "(?<=,)\s*" + [regex]::Escape($k) + "\s*(?=,|\])",
      ' "' + $k + '"',
      [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
    )
  }

  if ($raw -ne $orig) {
    BackupFile $Root $p $backupDir
    WriteUtf8NoBom $p $raw
    $changed.Add($p) | Out-Null
    Write-Host ("[PATCH] fixed " + $p)
  }
}

$rep = Join-Path $reportDir ("eco-step-100e-fix-bare-field-identifiers-v0_1-" + $ts + ".md")
$repLines = New-Object System.Collections.Generic.List[string]
$repLines.Add("# eco-step-100e-fix-bare-field-identifiers-v0_1") | Out-Null
$repLines.Add("") | Out-Null
$repLines.Add("- Time: " + $ts) | Out-Null
$repLines.Add("- Backup: " + $backupDir) | Out-Null
$repLines.Add("") | Out-Null
$repLines.Add("## Scanned") | Out-Null
foreach ($p in $scanned) { $repLines.Add("- " + $p.Substring($Root.Length).TrimStart('\','/')) | Out-Null }
$repLines.Add("") | Out-Null
$repLines.Add("## Patched") | Out-Null
if ($changed.Count -eq 0) {
  $repLines.Add("- (none)") | Out-Null
} else {
  foreach ($p in $changed) { $repLines.Add("- " + $p.Substring($Root.Length).TrimStart('\','/')) | Out-Null }
}
$repLines.Add("") | Out-Null
$repLines.Add("## Verify") | Out-Null
$repLines.Add("1) Ctrl+C -> npm run dev") | Out-Null
$repLines.Add("2) Abrir /eco/mural/confirmados (nao pode dar 500)") | Out-Null
$repLines.Add("3) GET /api/eco/points/list2?limit=10 (200)") | Out-Null

WriteUtf8NoBom $rep ($repLines -join "`n")
Write-Host ("[REPORT] " + $rep)

Write-Host ""
Write-Host "[VERIFY] Ctrl+C -> npm run dev"
Write-Host "[VERIFY] /eco/mural/confirmados"
Write-Host "[VERIFY] /api/eco/points/list2?limit=10"