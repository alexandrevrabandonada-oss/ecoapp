param(
  [switch]$SkipPageFix
)

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

Write-Host ("== eco-step-145-fix-dev-and-mural-searchparams-v0_1 == " + $stamp) -ForegroundColor Cyan
Write-Host ("[DIAG] Root: " + $root)

$backupDir = Join-Path $root ("tools\_patch_backup\eco-step-145-fix-dev-and-mural-searchparams-v0_1-" + $stamp)
EnsureDir $backupDir

# --- PATCH A: package.json (dev scripts) ---
$pkgPath = Join-Path $root "package.json"
if (Test-Path -LiteralPath $pkgPath) {
  BackupFile $pkgPath $backupDir

  $pkgRaw = Get-Content -Raw -LiteralPath $pkgPath -Encoding UTF8
  $pkg = $pkgRaw | ConvertFrom-Json -AsHashtable

  if (-not $pkg.ContainsKey("scripts") -or -not $pkg["scripts"]) {
    $pkg["scripts"] = @{}
  }

  $scripts = $pkg["scripts"]
  $prevDev = $null
  if ($scripts.ContainsKey("dev")) { $prevDev = $scripts["dev"] }

  # FIX: --no-turbo não existe. Dev padrão = next dev.
  $scripts["dev"] = "next dev"

  # extras úteis
  $scripts["dev:turbo"]   = "next dev --turbo"
  $scripts["dev:webpack"] = "set NEXT_DISABLE_TURBOPACK=1 && next dev"

  $pkg["scripts"] = $scripts

  $json = ($pkg | ConvertTo-Json -Depth 50)
  WriteUtf8NoBom $pkgPath ($json + "`n")

  Write-Host ("[PATCH] package.json: scripts.dev -> next dev (prev: " + $prevDev + ")") -ForegroundColor Green
  Write-Host ("[PATCH] package.json: scripts.dev:turbo + dev:webpack") -ForegroundColor Green
} else {
  Write-Host ("[WARN] package.json não encontrado: " + $pkgPath) -ForegroundColor Yellow
}

# --- PATCH B: /eco/mural searchParams Promise (se precisar) ---
if (-not $SkipPageFix) {
  $pagePath = Join-Path $root "src\app\eco\mural\page.tsx"
  if (Test-Path -LiteralPath $pagePath) {
    BackupFile $pagePath $backupDir

    $raw = Get-Content -Raw -LiteralPath $pagePath -Encoding UTF8

    $alreadyOk = $false
    if ($raw -match "await\s+searchParams") { $alreadyOk = $true }
    if ($raw -match "React\.use\(\s*searchParams\s*\)") { $alreadyOk = $true }

    if ($alreadyOk) {
      Write-Host "[PATCH] page.tsx: searchParams já está unwrap (skip)" -ForegroundColor DarkGray
    } else {
      $lines = $raw -split "`r?`n"
      $out = New-Object System.Collections.Generic.List[string]

      $didExport = $false
      $inserted  = $false
      $removedOld = 0

      for ($i = 0; $i -lt $lines.Length; $i++) {
        $line = $lines[$i]
        $trim = $line.Trim()

        # normaliza a assinatura do Page
        if (-not $didExport -and $trim.StartsWith("export default") -and $line.Contains("Page(")) {
          $out.Add('export default async function Page({ searchParams }: { searchParams: Promise<Record<string, string | string[] | undefined>> }) {')
          $didExport = $true
          continue
        }

        # remove defs antigas (se existirem)
        if ($trim.StartsWith("const mapOpen") -or $trim.StartsWith("const mapRaw") -or $trim.StartsWith("const mapVal")) {
          $removedOld++
          continue
        }
        if ($trim.StartsWith("const") -and $line.Contains("searchParams") -and $line.Contains(".map")) {
          $removedOld++
          continue
        }

        # injeta defs novas antes do return (
        if (-not $inserted -and $didExport -and $trim.StartsWith("return")) {
          $out.Add('  const sp = await searchParams;')
          $out.Add('  const mapRaw = sp?.map;')
          $out.Add('  const mapVal = Array.isArray(mapRaw) ? mapRaw[0] : mapRaw;')
          $out.Add('  const mapOpen = (mapVal === "1" || mapVal === "true");')
          $out.Add('')
          $inserted = $true
        }

        $out.Add($line)
      }

      if (-not $didExport) { throw "Não encontrei export default ... Page(...) em: $pagePath" }

      WriteUtf8NoBom $pagePath (($out.ToArray() -join "`n") + "`n")
      Write-Host "[PATCH] page.tsx: async + await searchParams + mapOpen safe" -ForegroundColor Green
      if ($removedOld -gt 0) {
        Write-Host ("[PATCH] page.tsx: removidas defs antigas = " + $removedOld) -ForegroundColor DarkGray
      }
    }
  } else {
    Write-Host ("[WARN] page.tsx não encontrado: " + $pagePath) -ForegroundColor Yellow
  }
}

# --- REPORT ---
$reportDir = Join-Path $root "reports"
EnsureDir $reportDir
$reportPath = Join-Path $reportDir ("eco-step-145-fix-dev-and-mural-searchparams-v0_1-" + $stamp + ".md")

$r = @()
$r += "# eco-step-145-fix-dev-and-mural-searchparams-v0_1 - $stamp"
$r += ""
$r += "## PATCH"
$r += "- package.json: scripts.dev = next dev (remove --no-turbo inválido)"
$r += "- package.json: add dev:turbo / dev:webpack"
$r += "- mural/page.tsx: unwrap searchParams Promise (se necessário)"
$r += ""
$r += "## VERIFY"
$r += "- Ctrl+C (se dev estiver rodando)"
$r += "- npm run dev"
$r += "- abrir: /eco/mural?map=1"
$r += "- se ainda ficar spam de sourcemap, testar: npm run dev:webpack"

WriteUtf8NoBom $reportPath ($r -join "`n")
Write-Host ("[REPORT] " + $reportPath) -ForegroundColor Cyan

Write-Host ""
Write-Host "[VERIFY] agora rode:" -ForegroundColor Yellow
Write-Host "  Ctrl+C"
Write-Host "  npm run dev"
Write-Host "  abrir /eco/mural?map=1"
Write-Host "  (opcional) npm run dev:webpack"