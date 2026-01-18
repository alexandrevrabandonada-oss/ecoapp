#requires -Version 7.0
$ErrorActionPreference = "Stop"

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$root  = (Resolve-Path ".").Path

function EnsureDir([string]$p) {
  if ([string]::IsNullOrWhiteSpace($p)) { return }
  New-Item -ItemType Directory -Force -Path $p | Out-Null
}
function WriteUtf8NoBom([string]$path, [string]$content) {
  if ([string]::IsNullOrWhiteSpace($path)) { throw "WriteUtf8NoBom: path vazio" }
  $parent = Split-Path -Parent $path
  if (-not [string]::IsNullOrWhiteSpace($parent)) { EnsureDir $parent }
  [System.IO.File]::WriteAllText($path, $content, [System.Text.UTF8Encoding]::new($false))
}
function BackupFile([string]$src, [string]$backupDir) {
  EnsureDir $backupDir
  if (-not (Test-Path -LiteralPath $src)) { throw "BackupFile: não achei $src" }
  $name = (Split-Path -Leaf $src) + ".bak"
  Copy-Item -LiteralPath $src -Destination (Join-Path $backupDir $name) -Force
}

Write-Host ("== eco-step-146b-dev-scripts-and-allowedDevOrigins-v0_1 == " + $stamp) -ForegroundColor Cyan
Write-Host ("[DIAG] Root: " + $root)

$pkgPath = Join-Path $root "package.json"
if (-not (Test-Path -LiteralPath $pkgPath)) { throw "Não achei: $pkgPath" }

$nextCfgCandidates = @(
  (Join-Path $root "next.config.js"),
  (Join-Path $root "next.config.mjs"),
  (Join-Path $root "next.config.ts")
)
$nextCfgPath = $nextCfgCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1

$backupDir = Join-Path $root ("tools\_patch_backup\eco-step-146b-" + $stamp)
EnsureDir $backupDir
BackupFile $pkgPath $backupDir
if ($nextCfgPath) { BackupFile $nextCfgPath $backupDir }

# PATCH package.json
$pkgRaw = [System.IO.File]::ReadAllText($pkgPath, [System.Text.UTF8Encoding]::new($false))
$pkg = $pkgRaw | ConvertFrom-Json
if (-not $pkg.scripts) { $pkg | Add-Member -NotePropertyName scripts -NotePropertyValue ([pscustomobject]@{}) }

$pkg.scripts.dev = "next dev"
if (-not $pkg.scripts."dev:turbo")   { $pkg.scripts | Add-Member -NotePropertyName "dev:turbo"   -NotePropertyValue "next dev --turbo" }
if (-not $pkg.scripts."dev:webpack") { $pkg.scripts | Add-Member -NotePropertyName "dev:webpack" -NotePropertyValue "set NEXT_DISABLE_TURBOPACK=1 && next dev" }

$pkgOut = $pkg | ConvertTo-Json -Depth 50
WriteUtf8NoBom $pkgPath ($pkgOut + "`n")
Write-Host "[PATCH] package.json ok (dev/dev:turbo/dev:webpack)" -ForegroundColor Green

# PATCH next.config allowedDevOrigins
$allowed = '["localhost","127.0.0.1","192.168.29.50"]'

if (-not $nextCfgPath) {
  $nextCfgPath = Join-Path $root "next.config.js"
  $cfg = @"
/** @type {import('next').NextConfig} */
const nextConfig = {
  allowedDevOrigins: $allowed,
};
module.exports = nextConfig;
"@
  WriteUtf8NoBom $nextCfgPath $cfg
  Write-Host ("[PATCH] created -> " + $nextCfgPath) -ForegroundColor Green
} else {
  $cfgRaw = [System.IO.File]::ReadAllText($nextCfgPath, [System.Text.UTF8Encoding]::new($false))
  if ($cfgRaw -match "allowedDevOrigins") {
    Write-Host "[PATCH] next.config já tem allowedDevOrigins (skip)" -ForegroundColor Yellow
  } else {
    $needle1 = "const nextConfig = {"
    $needle2 = "module.exports = {"
    $insert  = "`n  allowedDevOrigins: $allowed,"

    $idx1 = $cfgRaw.IndexOf($needle1)
    $idx2 = $cfgRaw.IndexOf($needle2)

    if ($idx1 -ge 0) {
      $pos = $idx1 + $needle1.Length
      $cfgRaw2 = $cfgRaw.Insert($pos, $insert)
      WriteUtf8NoBom $nextCfgPath ($cfgRaw2 + "`n")
      Write-Host "[PATCH] next.config: inserted allowedDevOrigins (nextConfig)" -ForegroundColor Green
    } elseif ($idx2 -ge 0) {
      $pos = $idx2 + $needle2.Length
      $cfgRaw2 = $cfgRaw.Insert($pos, $insert)
      WriteUtf8NoBom $nextCfgPath ($cfgRaw2 + "`n")
      Write-Host "[PATCH] next.config: inserted allowedDevOrigins (module.exports)" -ForegroundColor Green
    } else {
      Write-Host "[WARN] não consegui inserir allowedDevOrigins automaticamente (mantive seu config intacto)." -ForegroundColor Yellow
    }
  }
}

# REPORT
$reportDir = Join-Path $root "reports"
EnsureDir $reportDir
$reportPath = Join-Path $reportDir ("eco-step-146b-dev-scripts-and-allowedDevOrigins-v0_1-" + $stamp + ".md")

$r = @()
$r += "# eco-step-146b-dev-scripts-and-allowedDevOrigins-v0_1 - $stamp"
$r += ""
$r += "## PATCH"
$r += "- package.json: scripts.dev=next dev; add dev:turbo, dev:webpack"
$r += "- next.config: allowedDevOrigins (silencia warning cross-origin no dev)"
$r += ""
$r += "## VERIFY"
$r += "- Ctrl+C -> npm run dev"
$r += "- abrir /eco/mural e /eco/mural?map=1"
$r += "- se quiser testar: npm run dev:webpack"
WriteUtf8NoBom $reportPath ($r -join "`n")
Write-Host ("[REPORT] " + $reportPath) -ForegroundColor Green

Write-Host ""
Write-Host "[VERIFY] rode:" -ForegroundColor Cyan
Write-Host "  Ctrl+C -> npm run dev"
Write-Host "  abrir /eco/mural e /eco/mural?map=1"
Write-Host "  (opcional) npm run dev:webpack"