param(
  [switch]$NoClean,
  [switch]$OpenReport
)

$ErrorActionPreference = "Stop"
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$root = (Resolve-Path ".").Path
Write-Host ("== eco-step-143-disable-turbopack-fix-invalid-sourcemap-v0_1 == " + $stamp) -ForegroundColor Cyan
Write-Host ("[DIAG] Root: " + $root)

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
  if (-not (Test-Path -LiteralPath $src)) { throw "BackupFile: nao achei $src" }
  $name = (Split-Path -Leaf $src) + ".bak"
  Copy-Item -LiteralPath $src -Destination (Join-Path $backupDir $name) -Force
}

$pkgPath = Join-Path $root "package.json"
if (-not (Test-Path -LiteralPath $pkgPath)) { throw "Nao achei: $pkgPath" }

$backupDir = Join-Path $root ("tools\_patch_backup\eco-step-143-disable-turbopack-fix-invalid-sourcemap-v0_1-" + $stamp)
EnsureDir $backupDir
BackupFile $pkgPath $backupDir
Write-Host ("[DIAG] backup -> " + $backupDir) -ForegroundColor DarkGray

$raw = [System.IO.File]::ReadAllText($pkgPath, [System.Text.UTF8Encoding]::new($false))
$obj = $raw | ConvertFrom-Json
if ($null -eq $obj.scripts) { $obj | Add-Member -NotePropertyName "scripts" -NotePropertyValue (@{}) }

$oldDev = $obj.scripts.dev

# Windows-safe: npm scripts rodam via cmd.exe, entao "set VAR=1 && ..." funciona
$wantDev = "set NEXT_DISABLE_TURBOPACK=1 && next dev"

if ([string]::IsNullOrWhiteSpace($oldDev)) {
  Write-Host "[PATCH] scripts.dev estava vazio -> setando (webpack/dev sem turbopack)" -ForegroundColor Yellow
  $obj.scripts.dev = $wantDev
} elseif ($oldDev -match "NEXT_DISABLE_TURBOPACK" -or $oldDev -match "--no-turbo") {
  Write-Host "[PATCH] scripts.dev ja desliga turbopack (ok)" -ForegroundColor Green
} else {
  Write-Host ("[PATCH] scripts.dev: """ + $oldDev + """ -> """ + $wantDev + """") -ForegroundColor Yellow
  $obj.scripts.dev = $wantDev
}

if ($null -eq $obj.scripts."dev:turbo" -or [string]::IsNullOrWhiteSpace($obj.scripts."dev:turbo")) {
  $obj.scripts | Add-Member -NotePropertyName "dev:turbo" -NotePropertyValue "next dev" -Force
  Write-Host "[PATCH] added scripts.dev:turbo = next dev" -ForegroundColor Yellow
}

$json = $obj | ConvertTo-Json -Depth 100
# deixa legivel (evita \\u0026)
$json = $json.Replace("\u0026","&")
WriteUtf8NoBom $pkgPath $json
Write-Host ("[PATCH] updated -> " + $pkgPath) -ForegroundColor Green

if (-not $NoClean) {
  $nextDir = Join-Path $root ".next"
  if (Test-Path -LiteralPath $nextDir) {
    Write-Host "[PATCH] removendo .next (cache)" -ForegroundColor DarkGray
    Remove-Item -LiteralPath $nextDir -Recurse -Force -ErrorAction SilentlyContinue
  }
} else {
  Write-Host "[PATCH] NoClean ligado: nao removi .next" -ForegroundColor DarkGray
}

# report
$reportDir = Join-Path $root "reports"
EnsureDir $reportDir
$reportPath = Join-Path $reportDir ("eco-step-143-disable-turbopack-fix-invalid-sourcemap-v0_1-" + $stamp + ".md")
$r = @()
$r += "# eco-step-143-disable-turbopack-fix-invalid-sourcemap-v0_1 - $stamp"
$r += ""
$r += "## Contexto"
$r += "- Erro em dev: Invalid source map / sourceMapURL could not be parsed (chunks SSR node_modules... turbopack)."
$r += ""
$r += "## Patch"
$r += "- package.json: scripts.dev -> $wantDev"
$r += "- package.json: scripts.dev:turbo -> next dev (para voltar ao turbopack quando quiser)"
$r += "- limpeza: .next removido (a menos que -NoClean)"
$r += ""
$r += "## Verify"
$r += "- Ctrl+C (se o dev estiver rodando)"
$r += "- npm run dev  (agora em webpack/dev, sem turbopack)"
$r += "- abrir /eco/mural e /eco/mural?map=1 e conferir se sumiu o overlay/console do sourcemap"
WriteUtf8NoBom $reportPath ($r -join "`n")
Write-Host ("[REPORT] " + $reportPath) -ForegroundColor Green

if ($OpenReport) {
  try { Start-Process $reportPath | Out-Null } catch {}
}

Write-Host ""
Write-Host "[VERIFY] rode:" -ForegroundColor Cyan
Write-Host "  Ctrl+C  (se estiver rodando dev)"
Write-Host "  npm run dev"
Write-Host "  (se quiser turbopack de novo: npm run dev:turbo)"