param([string]$Root = (Get-Location).Path)

$ts = Get-Date -Format "yyyyMMdd-HHmmss"
Write-Host ("== eco-step-95-fix-points-list2-unterminated-string-v0_1 == " + $ts)
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

function FindFileBySuffix([string]$root, [string]$suffix) {
  $src = Join-Path $root "src"
  if (-not (Test-Path -LiteralPath $src)) { return $null }
  $hits = Get-ChildItem -LiteralPath $src -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
    ($_.FullName -replace '\\','/') -like ("*/" + $suffix)
  }
  if ($hits -and $hits.Count -ge 1) { return $hits[0].FullName }
  return $null
}

$backupDir = Join-Path $Root ("tools/_patch_backup/" + $ts + "-eco-step-95-fix-points-list2-unterminated-string-v0_1")
$reportDir = Join-Path $Root "reports"
EnsureDir $backupDir
EnsureDir $reportDir

$file = Join-Path $Root "src/app/api/eco/points/list2/route.ts"
if (-not (Test-Path -LiteralPath $file)) {
  $file = FindFileBySuffix $Root "app/api/eco/points/list2/route.ts"
}
if (-not $file) { throw "[STOP] Nao achei src/app/api/eco/points/list2/route.ts" }

Write-Host ("[DIAG] Target: " + $file)
BackupFile $Root $file $backupDir

$raw = Get-Content -LiteralPath $file -Raw -ErrorAction Stop

# Fix pattern: pickModel(pc, "\n   ecoPoint\n", [ ... ])
$pattern = 'pickModel\(\s*pc\s*,\s*"\s*[\r\n]+\s*([A-Za-z0-9_]+)\s*[\r\n]+\s*",\s*\['
$before = $raw
$raw = [regex]::Replace($raw, $pattern, 'pickModel(pc, "$1", [')
$changed1 = ($raw -ne $before)

# Extra safeguard: any leftover pickModel(pc, " <newline> NAME <newline> ")
$pattern2 = 'pickModel\(\s*pc\s*,\s*"\s*[\r\n]+\s*([A-Za-z0-9_]+)\s*[\r\n]+\s*",'
$before2 = $raw
$raw = [regex]::Replace($raw, $pattern2, 'pickModel(pc, "$1", ')
$changed2 = ($raw -ne $before2)

# Quick check: do we still have a suspicious open multiline string after pickModel(pc, " ?
$stillBad = $false
if ($raw -match 'pickModel\(\s*pc\s*,\s*"\s*[\r\n]') { $stillBad = $true }

WriteUtf8NoBom $file $raw
Write-Host ("[PATCH] wrote fixed route.ts (changed1=" + $changed1 + ", changed2=" + $changed2 + ", stillBad=" + $stillBad + ")")

# report
$rep = Join-Path $reportDir ("eco-step-95-fix-points-list2-unterminated-string-v0_1-" + $ts + ".md")
$repText = @(
"# eco-step-95-fix-points-list2-unterminated-string-v0_1",
"",
"- Time: " + $ts,
"- Backup: " + $backupDir,
"- File: " + $file,
"",
"## What happened",
"- Next/Turbopack estava falhando com **Unterminated string constant** em /api/eco/points/list2/route.ts",
"- A causa era um `pickModel(pc, \"` gerado com quebra de linha dentro da string.",
"",
"## Patch",
"- Normaliza chamadas no formato multiline:",
"  - `pickModel(pc, \"\\n  ecoPoint\\n\", [ ... ])` -> `pickModel(pc, \"ecoPoint\", [ ... ])`",
"",
"## Verify",
"1) Ctrl+C",
"2) npm run dev",
"3) GET /api/eco/points/list2?limit=10 (deve 200)",
"4) /eco/mural/confirmados (deve carregar sem 500)",
"",
"## Notes",
"- stillBad=" + $stillBad
) -join "`n"
WriteUtf8NoBom $rep $repText
Write-Host ("[REPORT] " + $rep)

Write-Host ""
Write-Host "[VERIFY] Ctrl+C -> npm run dev"
Write-Host "[VERIFY] /api/eco/points/list2?limit=10"
Write-Host "[VERIFY] /eco/mural/confirmados"