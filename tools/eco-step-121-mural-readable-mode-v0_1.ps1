param([string]$Root = (Get-Location).Path)
$ErrorActionPreference = "Stop"

function TryDotSourceBootstrap($rootPath) {
  $b1 = Join-Path $rootPath "tools\_bootstrap.ps1"
  if (Test-Path $b1) { . $b1; return $true }
  return $false
}
[void](TryDotSourceBootstrap $Root)

# --- FALLBACKS (caso bootstrap não tenha as funcs)
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
$me = "eco-step-121-mural-readable-mode-v0_1"
Write-Host ("== " + $me + " == " + $stamp)
Write-Host ("[DIAG] Root: " + $Root)

$backupDir = Join-Path $Root ("tools\_patch_backup\" + $stamp + "-" + $me)
EnsureDir $backupDir

# 1) Criar componente de estilos (injeta CSS com !important)
$styleFile = Join-Path $Root "src\app\eco\mural\_components\MuralReadableStyles.tsx"
EnsureDir (Split-Path -Parent $styleFile)
BackupFile $styleFile $backupDir

$styleTsx = @"
"use client";
import React from "react";

export default function MuralReadableStyles() {
  return (
    <style>{`
      /* ===== MODO LEGÍVEL (alto contraste) — só dentro de .eco-mural ===== */
      .eco-mural {
        background: #f6f6f6 !important;
        color: #111 !important;
        min-height: 100vh !important;
      }

      .eco-mural, .eco-mural * {
        color: #111 !important;
        opacity: 1 !important;
        filter: none !important;
        text-shadow: none !important;
      }

      .eco-mural h1 {
        font-size: 30px !important;
        line-height: 1.1 !important;
        font-weight: 900 !important;
        margin: 10px 0 6px 0 !important;
      }

      .eco-mural p {
        font-size: 14px !important;
        line-height: 1.35 !important;
        margin: 0 0 10px 0 !important;
      }

      .eco-mural a {
        color: #111 !important;
        text-decoration: none !important;
        font-weight: 800 !important;
      }

      .eco-mural button {
        font-size: 14px !important;
        font-weight: 900 !important;
        border: 1px solid #111 !important;
        border-radius: 12px !important;
        background: #fff !important;
      }

      .eco-mural input, .eco-mural select, .eco-mural textarea {
        background: #fff !important;
        color: #111 !important;
        border: 1px solid #111 !important;
        border-radius: 12px !important;
        padding: 10px !important;
        font-size: 14px !important;
      }

      /* “cartões” genéricos: qualquer div com borda inline fica mais legível */
      .eco-mural div[style*="border"] {
        background: #fff !important;
      }
    `}</style>
  );
}
"@

WriteUtf8NoBom $styleFile $styleTsx
Write-Host ("[PATCH] wrote -> " + $styleFile)

# 2) Patch no page.tsx pra:
#    - envolver em className="eco-mural"
#    - renderizar <MuralReadableStyles /> logo no começo do <main>
$page = Join-Path $Root "src\app\eco\mural\page.tsx"
if (-not (Test-Path $page)) { throw ("[STOP] Não achei: " + $page) }
BackupFile $page $backupDir

$raw = Get-Content -Raw -ErrorAction Stop $page

# inserir import se não existir
if ($raw -notmatch "MuralReadableStyles") {
  $lines = $raw -split "`n"
  $lastImport = -1
  for ($i=0; $i -lt $lines.Length; $i++) {
    if ($lines[$i].Trim().StartsWith("import ")) { $lastImport = $i }
  }
  if ($lastImport -ge 0) {
    $newLines = @()
    for ($i=0; $i -le $lastImport; $i++) { $newLines += $lines[$i] }
    $newLines += 'import MuralReadableStyles from "./_components/MuralReadableStyles";'
    for ($i=$lastImport+1; $i -lt $lines.Length; $i++) { $newLines += $lines[$i] }
    $raw = ($newLines -join "`n")
  } else {
    # fallback: joga no topo
    $raw = 'import MuralReadableStyles from "./_components/MuralReadableStyles";' + "`n" + $raw
  }
}

# garantir className="eco-mural" no <main ...>
$idxMain = $raw.IndexOf("<main")
if ($idxMain -lt 0) { throw "[STOP] Não achei <main em page.tsx" }

$idxGt = $raw.IndexOf(">", $idxMain)
if ($idxGt -lt 0) { throw "[STOP] Não achei fechamento do <main ...>" }

$mainOpen = $raw.Substring($idxMain, ($idxGt - $idxMain + 1))

if ($mainOpen -notmatch "className=") {
  $mainOpen2 = $mainOpen.Replace("<main", '<main className="eco-mural"')
  $raw = $raw.Substring(0,$idxMain) + $mainOpen2 + $raw.Substring($idxGt+1)
} elseif ($mainOpen -notmatch "eco-mural") {
  # adiciona eco-mural na className existente (simples)
  $mainOpen2 = $mainOpen -replace 'className="([^"]*)"', 'className="$1 eco-mural"'
  $raw = $raw.Substring(0,$idxMain) + $mainOpen2 + $raw.Substring($idxGt+1)
}

# inserir <MuralReadableStyles /> logo após abrir o <main> (se não existir)
if ($raw -notmatch "<MuralReadableStyles\s*/>") {
  $idxMain2 = $raw.IndexOf("<main")
  $idxGt2 = $raw.IndexOf(">", $idxMain2)
  $raw = $raw.Insert($idxGt2+1, "`n      <MuralReadableStyles />`n")
}

WriteUtf8NoBom $page $raw
Write-Host ("[PATCH] updated -> " + $page)

# --- REPORT
$report = @()
$report += "# $me"
$report += ""
$report += "- Time: $stamp"
$report += "- Backup: $backupDir"
$report += "- Added: src/app/eco/mural/_components/MuralReadableStyles.tsx"
$report += "- Patched: src/app/eco/mural/page.tsx (class eco-mural + inject styles)"
$report += ""
$report += "## Verify"
$report += "1) Ctrl+C -> npm run dev"
$report += "2) abrir /eco/mural"
$report += "3) conferir leitura (alto contraste + fontes maiores)"

$reportPath = Join-Path $Root ("reports\" + $me + "-" + $stamp + ".md")
EnsureDir (Split-Path -Parent $reportPath)
WriteUtf8NoBom $reportPath ($report -join "`n")
Write-Host ("[REPORT] " + $reportPath)

Write-Host ""
Write-Host "[VERIFY] rode:"
Write-Host "  Ctrl+C -> npm run dev"
Write-Host "  abrir /eco/mural"