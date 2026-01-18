param(
  [string]$Root = (Get-Location).Path
)

$ts = Get-Date -Format "yyyyMMdd-HHmmss"

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

Write-Host ('== eco-step-87b-fix-mural-page-p-div-nesting-v0_1 == ' + $ts)
Write-Host ('[DIAG] Root: ' + $Root)

$page = Join-Path $Root 'src/app/eco/mural/page.tsx'
if (-not (Test-Path -LiteralPath $page)) { throw "[STOP] Nao achei src/app/eco/mural/page.tsx" }

$backupDir = Join-Path $Root ('tools/_patch_backup/' + $ts + '-eco-step-87b-fix-mural-page-p-div-nesting-v0_1')
$reportDir = Join-Path $Root 'reports'
EnsureDir $backupDir
EnsureDir $reportDir
BackupFile $Root $page $backupDir

$raw = [System.IO.File]::ReadAllText($page)
if (-not $raw) { throw "[STOP] Falha ao ler page.tsx" }

$lines = $raw -split "`n"

# alvo: <div ... margin: "10px 0 14px 0" ...> caindo dentro de um <p ... opacity: 0.85 ...>
$idxDiv = -1
for ($i=0; $i -lt $lines.Length; $i++) {
  $ln = $lines[$i]
  if ($ln.Contains('<div') -and $ln.Contains('margin: "10px 0 14px 0"')) { $idxDiv = $i; break }
}

if ($idxDiv -lt 0) {
  Write-Host "[OK] Nao achei o <div> alvo (margin 10px 0 14px 0). Nada a fazer."
  exit 0
}

# procura o <p ... opacity: 0.85> mais proximo acima
$idxP = -1
for ($i=$idxDiv; $i -ge 0; $i--) {
  $ln = $lines[$i]
  if ($ln.Contains('<p') -and $ln.Contains('opacity: 0.85')) { $idxP = $i; break }
}

if ($idxP -lt 0) {
  Write-Host "[OK] Nao achei <p ... opacity: 0.85> acima do div. Nada a fazer."
  exit 0
}

# verifica se ja existe </p> entre idxP e idxDiv
$hasClose = $false
for ($i=$idxP; $i -le $idxDiv; $i++) {
  if ($lines[$i].Contains('</p>')) { $hasClose = $true; break }
}

if ($hasClose) {
  Write-Host "[OK] Ja existe </p> antes do <div>. Nada a fazer."
  exit 0
}

# insere </p> imediatamente antes do div
$indent = ($lines[$idxDiv] -replace '(^\s*).*','$1')
$new = New-Object System.Collections.Generic.List[string]
for ($i=0; $i -lt $lines.Length; $i++) {
  if ($i -eq $idxDiv) {
    $new.Add($indent + '</p>')
  }
  $new.Add($lines[$i])
}

WriteUtf8NoBom $page ($new.ToArray() -join "`n")
Write-Host "[PATCH] Inserido </p> antes do <div> (corrigindo nesting p>div)."

$rep = Join-Path $reportDir ('eco-step-87b-fix-mural-page-p-div-nesting-v0_1-' + $ts + '.md')
$repLines = @(
'# eco-step-87b-fix-mural-page-p-div-nesting-v0_1',
'',
'- Time: ' + $ts,
'- Backup: ' + $backupDir,
'- File: src/app/eco/mural/page.tsx',
'',
'## What',
'- Corrige HTML invalido: <div> dentro de <p> (insere </p> antes do bloco).',
'',
'## Verify',
'1) Ctrl+C -> npm run dev',
'2) Abra /eco/mural',
'3) Nao deve mais aparecer erro: "div cannot be a descendant of p"'
)
WriteUtf8NoBom $rep ($repLines -join "`n")
Write-Host ('[REPORT] ' + $rep)

Write-Host ""
Write-Host "[VERIFY] Ctrl+C -> npm run dev"
Write-Host "[VERIFY] /eco/mural -> erro de nesting deve sumir"