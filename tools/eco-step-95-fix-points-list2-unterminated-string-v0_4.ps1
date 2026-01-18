param([string]$Root = (Get-Location).Path)

$ts = Get-Date -Format "yyyyMMdd-HHmmss"
Write-Host ('== eco-step-95-fix-points-list2-unterminated-string-v0_4 == ' + $ts)
Write-Host ('[DIAG] Root: ' + $Root)

$boot = Join-Path $Root 'tools/_bootstrap.ps1'
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
  $src = Join-Path $root 'src'
  if (-not (Test-Path -LiteralPath $src)) { return $null }
  $hits = Get-ChildItem -LiteralPath $src -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
    ($_.FullName -replace '\\','/') -like ('*/' + $suffix)
  }
  if ($hits -and $hits.Count -ge 1) { return $hits[0].FullName }
  return $null
}

$backupDir = Join-Path $Root ('tools/_patch_backup/' + $ts + '-eco-step-95-fix-points-list2-unterminated-string-v0_4')
$reportDir = Join-Path $Root 'reports'
EnsureDir $backupDir
EnsureDir $reportDir

$file = Join-Path $Root 'src/app/api/eco/points/list2/route.ts'
if (-not (Test-Path -LiteralPath $file)) { $file = FindFileBySuffix $Root 'app/api/eco/points/list2/route.ts' }
if (-not $file) { throw '[STOP] Nao achei src/app/api/eco/points/list2/route.ts' }

Write-Host ('[DIAG] Target: ' + $file)
BackupFile $Root $file $backupDir

$raw = Get-Content -LiteralPath $file -Raw -ErrorAction Stop
$before = $raw

# 1) ["\n NAME \n"] -> ["NAME"]
$raw = [regex]::Replace(
  $raw,
  '\[\s*"\s*[\r\n]+\s*([A-Za-z0-9_]+)\s*[\r\n]+\s*"\s*\]',
  '["$1"]'
)

# 2) ['\n NAME \n'] -> ["NAME"]   (mesma saida; evita aspas simples no replacement)
$raw = [regex]::Replace(
  $raw,
  "\[\s*'\s*[\r\n]+\s*([A-Za-z0-9_]+)\s*[\r\n]+\s*'\s*\]",
  '["$1"]'
)

$changed = ($raw -ne $before)

# Sanity: ainda existe ["<newline> ... ?
$stillBad = $false
if ($raw -match '\[\s*"\s*[\r\n]') { $stillBad = $true }
if ($raw -match "\[\s*'\s*[\r\n]") { $stillBad = $true }

WriteUtf8NoBom $file $raw
Write-Host ('[PATCH] wrote route.ts (changed=' + $changed + ', stillBad=' + $stillBad + ')')

$rep = Join-Path $reportDir ('eco-step-95-fix-points-list2-unterminated-string-v0_4-' + $ts + '.md')
$repText = @(
'# eco-step-95-fix-points-list2-unterminated-string-v0_4',
'',
('- Time: ' + $ts),
('- Backup: ' + $backupDir),
('- File: ' + $file),
'',
'## Patch',
'- Corrige bracket access com string multiline em TS:',
'- pc?.["<newline>ecoPointConfirm<newline>"] -> pc?.["ecoPointConfirm"]',
"- pc?.['<newline>ecoPointConfirm<newline>'] -> pc?.[""ecoPointConfirm""]",
'',
'## Verify',
'1) Ctrl+C',
'2) npm run dev',
'3) http://localhost:3000/api/eco/points/list2?limit=10 (200)',
'',
('## Notes'),
('- changed=' + $changed),
('- stillBad=' + $stillBad)
) -join "`n"
WriteUtf8NoBom $rep $repText
Write-Host ('[REPORT] ' + $rep)

Write-Host ''
Write-Host '[VERIFY] Ctrl+C -> npm run dev'
Write-Host '[VERIFY] http://localhost:3000/api/eco/points/list2?limit=10'