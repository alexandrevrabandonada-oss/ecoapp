param([string]$Root = (Get-Location).Path)
$ErrorActionPreference = "Stop"

function TryDotSourceBootstrap($rootPath) {
  $b1 = Join-Path $rootPath "tools\_bootstrap.ps1"
  if (Test-Path $b1) { . $b1; return $true }
  return $false
}
[void](TryDotSourceBootstrap $Root)

# --- FALLBACKS (se bootstrap não carregou)
if (-not (Get-Command EnsureDir -ErrorAction SilentlyContinue)) {
  function EnsureDir([string]$p) { if (-not (Test-Path $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null } }
}
if (-not (Get-Command WriteUtf8NoBom -ErrorAction SilentlyContinue)) {
  function WriteUtf8NoBom([string]$path, [string]$content) {
    $enc = New-Object System.Text.UTF8Encoding($false)
    [IO.File]::WriteAllText($path, $content, $enc)
  }
}
if (-not (Get-Command BackupFile -ErrorAction SilentlyContinue)) {
  function BackupFile([string]$full, [string]$backupDir) {
    if (-not (Test-Path $full)) { return }
    EnsureDir $backupDir
    $safe = ($full -replace "[:\\\/ ]","_")
    Copy-Item -Force $full (Join-Path $backupDir $safe)
  }
}

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$me = "eco-step-121b-fix-mural-readable-styles-v0_1"
Write-Host ("== " + $me + " == " + $stamp)
Write-Host ("[DIAG] Root: " + $Root)

$backupDir = Join-Path $Root ("tools\_patch_backup\" + $stamp + "-" + $me)
EnsureDir $backupDir

$styleFile = Join-Path $Root "src\app\eco\mural\_components\MuralReadableStyles.tsx"
if (-not (Test-Path $styleFile)) { throw ("[STOP] Não achei: " + $styleFile) }
BackupFile $styleFile $backupDir

$lines = @(
'"use client";',
'import React from "react";',
'',
'const css =',
'  "/* ===== MODO LEGÍVEL (alto contraste) — só dentro de .eco-mural ===== */\n" +',
'  ".eco-mural { background: #f6f6f6 !important; color: #111 !important; min-height: 100vh !important; }\n" +',
'  ".eco-mural, .eco-mural * { color: #111 !important; opacity: 1 !important; filter: none !important; text-shadow: none !important; }\n" +',
'  ".eco-mural h1 { font-size: 30px !important; line-height: 1.1 !important; font-weight: 900 !important; margin: 10px 0 6px 0 !important; }\n" +',
'  ".eco-mural p { font-size: 14px !important; line-height: 1.35 !important; margin: 0 0 10px 0 !important; }\n" +',
'  ".eco-mural a { color: #111 !important; text-decoration: none !important; font-weight: 800 !important; }\n" +',
'  ".eco-mural button { font-size: 14px !important; font-weight: 900 !important; border: 1px solid #111 !important; border-radius: 12px !important; background: #fff !important; }\n" +',
'  ".eco-mural input, .eco-mural select, .eco-mural textarea { background: #fff !important; color: #111 !important; border: 1px solid #111 !important; border-radius: 12px !important; padding: 10px !important; font-size: 14px !important; }\n" +',
'  ".eco-mural div[style*=\\"border\\"] { background: #fff !important; }\n";',
'',
'export default function MuralReadableStyles() {',
'  return <style>{css}</style>;',
'}',
''
)

WriteUtf8NoBom $styleFile ($lines -join "`n")
Write-Host ("[PATCH] fixed -> " + $styleFile)

$reportPath = Join-Path $Root ("reports\" + $me + "-" + $stamp + ".md")
EnsureDir (Split-Path -Parent $reportPath)
WriteUtf8NoBom $reportPath (@(
"# $me",
"",
"- Time: $stamp",
"- Backup: $backupDir",
"- Patched: $styleFile",
"",
"## Verify",
"1) Ctrl+C -> npm run dev",
"2) abrir /eco/mural (deve ficar legível)"
) -join "`n")
Write-Host ("[REPORT] " + $reportPath)

Write-Host ""
Write-Host "[VERIFY] rode:"
Write-Host "  Ctrl+C -> npm run dev"
Write-Host "  abrir /eco/mural"