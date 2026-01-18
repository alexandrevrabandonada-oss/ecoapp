#!/usr/bin/env pwsh
param()

$ErrorActionPreference = "Stop"
$me = "eco-step-134d-fix-bootstrap-writeutf8-newreport-v0_1"
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$root = (Resolve-Path ".").Path

Write-Host ("== " + $me + " == " + $stamp)
Write-Host ("[DIAG] Root: " + $root)

$bootstrapPath = Join-Path $root "tools\_bootstrap.ps1"
$backupDir = Join-Path $root ("tools\_patch_backup\" + $me + "-" + $stamp)
if (-not (Test-Path -LiteralPath $backupDir)) { New-Item -ItemType Directory -Force -Path $backupDir | Out-Null }

if (Test-Path -LiteralPath $bootstrapPath) {
  $dst = Join-Path $backupDir ("_bootstrap.ps1.bak")
  Copy-Item -Force -LiteralPath $bootstrapPath -Destination $dst
  Write-Host ("[DIAG] backup -> " + $dst)
}

# reescrever bootstrap (robusto contra path vazio)
$content = @'
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function EnsureDir([string]$Path) {
  if ([string]::IsNullOrWhiteSpace($Path)) { return }
  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
  }
}

function WriteUtf8NoBom([string]$path, [string]$content) {
  if ([string]::IsNullOrWhiteSpace($path)) {
    throw "WriteUtf8NoBom: path vazio"
  }
  $dir = Split-Path -Parent $path
  if (-not [string]::IsNullOrWhiteSpace($dir)) { EnsureDir $dir }
  $enc = [System.Text.UTF8Encoding]::new($false)
  [System.IO.File]::WriteAllText($path, $content, $enc)
}

function BackupFile([string]$path, [string]$backupDir) {
  if ([string]::IsNullOrWhiteSpace($backupDir)) { return }
  EnsureDir $backupDir
  if (-not [string]::IsNullOrWhiteSpace($path) -and (Test-Path -LiteralPath $path)) {
    $leaf = [System.IO.Path]::GetFileName($path)
    $dst = Join-Path $backupDir $leaf
    Copy-Item -Force -LiteralPath $path -Destination $dst
  }
}

function NewReport([string]$name, [string]$stamp) {
  if ([string]::IsNullOrWhiteSpace($name)) { $name = "report" }
  if ([string]::IsNullOrWhiteSpace($stamp)) { $stamp = (Get-Date -Format "yyyyMMdd-HHmmss") }
  $root = (Resolve-Path ".").Path
  $rp = Join-Path $root ("reports\" + $name + "-" + $stamp + ".md")
  $dir = Split-Path -Parent $rp
  if (-not [string]::IsNullOrWhiteSpace($dir)) { EnsureDir $dir }
  return $rp
}
'@

WriteUtf8NoBom $bootstrapPath $content
Write-Host ("[PATCH] rewrote -> " + $bootstrapPath)

# smoke rápido
. $bootstrapPath
$rp = NewReport "bootstrap-smoke" $stamp
WriteUtf8NoBom $rp ("ok " + $stamp)
Write-Host ("[VERIFY] report ok -> " + $rp)

$outReport = Join-Path $root ("reports\" + $me + "-" + $stamp + ".md")
$lines = @(
  "# " + $me,
  "",
  "- stamp: " + $stamp,
  "- bootstrap: " + $bootstrapPath,
  "- backupDir: " + $backupDir,
  "",
  "## O que mudou",
  "- WriteUtf8NoBom agora falha com mensagem clara se path vazio",
  "- NewReport sempre retorna um caminho válido em reports/",
  "- EnsureDir ignora path vazio (não explode)",
  "",
  "## Verify",
  "- Ctrl+C -> npm run dev",
  "- abrir /eco/mural e expandir 🗺️ Mapa embutido (beta)"
)
WriteUtf8NoBom $outReport ($lines -join "`n")
Write-Host ("[REPORT] " + $outReport)

Write-Host ""
Write-Host "[NEXT] agora roda:"
Write-Host "  Ctrl+C -> npm run dev"
Write-Host "  abrir /eco/mural e expandir 🗺️ Mapa embutido (beta)"