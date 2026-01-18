#!/usr/bin/env pwsh
param()

$ErrorActionPreference = "Stop"
$me = "eco-step-134e-rewrite-bootstrap-safe-v0_1"
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$root = (Resolve-Path ".").Path

Write-Host ("== " + $me + " == " + $stamp)
Write-Host ("[DIAG] Root: " + $root)

$bootstrapPath = Join-Path $root "tools\_bootstrap.ps1"
$backupDir = Join-Path $root ("tools\_patch_backup\" + $me + "-" + $stamp)

function EnsureDirLocal([string]$p) {
  if ([string]::IsNullOrWhiteSpace($p)) { return }
  if (-not (Test-Path -LiteralPath $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null }
}
function WriteUtf8NoBomLocal([string]$p, [string]$c) {
  if ([string]::IsNullOrWhiteSpace($p)) { throw "WriteUtf8NoBomLocal: path vazio" }
  $dir = Split-Path -Parent $p
  if (-not [string]::IsNullOrWhiteSpace($dir)) { EnsureDirLocal $dir }
  $enc = [System.Text.UTF8Encoding]::new($false)
  [System.IO.File]::WriteAllText($p, $c, $enc)
}

EnsureDirLocal $backupDir
if (Test-Path -LiteralPath $bootstrapPath) {
  $dst = Join-Path $backupDir "_bootstrap.ps1.bak"
  Copy-Item -Force -LiteralPath $bootstrapPath -Destination $dst
  Write-Host ("[DIAG] backup -> " + $dst)
}

# ---- bootstrap novo (sem pegadinhas) ----
$b = @(
  'Set-StrictMode -Version Latest',
  '$ErrorActionPreference = "Stop"',
  '',
  'function EnsureDir([string]$Path) {',
  '  if ([string]::IsNullOrWhiteSpace($Path)) { return }',
  '  if (-not (Test-Path -LiteralPath $Path)) { New-Item -ItemType Directory -Force -Path $Path | Out-Null }',
  '}',
  '',
  'function WriteUtf8NoBom([string]$path, [string]$content) {',
  '  if ([string]::IsNullOrWhiteSpace($path)) { throw "WriteUtf8NoBom: path vazio" }',
  '  $dir = Split-Path -Parent $path',
  '  if (-not [string]::IsNullOrWhiteSpace($dir)) { EnsureDir $dir }',
  '  $enc = [System.Text.UTF8Encoding]::new($false)',
  '  [System.IO.File]::WriteAllText($path, $content, $enc)',
  '}',
  '',
  'function BackupFile([string]$path, [string]$backupDir) {',
  '  if ([string]::IsNullOrWhiteSpace($backupDir)) { return }',
  '  EnsureDir $backupDir',
  '  if (-not [string]::IsNullOrWhiteSpace($path) -and (Test-Path -LiteralPath $path)) {',
  '    $leaf = [System.IO.Path]::GetFileName($path)',
  '    $dst = Join-Path $backupDir ($leaf + ".bak")',
  '    Copy-Item -Force -LiteralPath $path -Destination $dst',
  '  }',
  '}',
  '',
  'function NewReport([string]$name, [string]$stamp) {',
  '  if ([string]::IsNullOrWhiteSpace($name)) { $name = "report" }',
  '  if ([string]::IsNullOrWhiteSpace($stamp)) { $stamp = (Get-Date -Format "yyyyMMdd-HHmmss") }',
  '  $root = (Resolve-Path ".").Path',
  '  $rp = Join-Path $root ("reports\" + $name + "-" + $stamp + ".md")',
  '  $dir = Split-Path -Parent $rp',
  '  if (-not [string]::IsNullOrWhiteSpace($dir)) { EnsureDir $dir }',
  '  return $rp',
  '}'
)

$bootstrapContent = ($b -join "`n")
WriteUtf8NoBomLocal $bootstrapPath $bootstrapContent
Write-Host ("[PATCH] rewrote -> " + $bootstrapPath)

# smoke: dot-source + gerar report
. $bootstrapPath
$rp = NewReport "bootstrap-smoke" $stamp
WriteUtf8NoBom $rp ("ok " + $stamp)
Write-Host ("[VERIFY] report ok -> " + $rp)

$outReport = NewReport $me $stamp
$r = @(
  "# " + $me,
  "",
  "- stamp: " + $stamp,
  "- bootstrap: " + $bootstrapPath,
  "- backupDir: " + $backupDir,
  "",
  "## Mudança",
  "- Reescreve tools/_bootstrap.ps1 com EnsureDir/WriteUtf8NoBom/BackupFile/NewReport robustos.",
  "- Corrige o bug de path vazio no WriteUtf8NoBom e NewReport sempre devolve caminho válido.",
  "",
  "## Verify",
  "- Ctrl+C -> npm run dev",
  "- abrir /eco/mural (e testar o mapa embutido se estiver ligado)"
)
WriteUtf8NoBom $outReport ($r -join "`n")
Write-Host ("[REPORT] " + $outReport)

Write-Host ""
Write-Host "[NEXT] rode:"
Write-Host "  Ctrl+C -> npm run dev"
Write-Host "  abrir /eco/mural"