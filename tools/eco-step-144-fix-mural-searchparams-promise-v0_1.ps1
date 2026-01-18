$ErrorActionPreference = "Stop"

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$root = (Resolve-Path ".").Path

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
  if (-not (Test-Path -LiteralPath $src)) { return }
  $name = (Split-Path -Leaf $src) + ".bak"
  Copy-Item -LiteralPath $src -Destination (Join-Path $backupDir $name) -Force
}

Write-Host ("== eco-step-144-fix-mural-searchparams-promise-v0_1 == " + $stamp) -ForegroundColor Cyan
Write-Host ("[DIAG] Root: " + $root)

$pagePath = Join-Path $root "src\app\eco\mural\page.tsx"
$pkgPath  = Join-Path $root "package.json"

if (-not (Test-Path -LiteralPath $pagePath)) { throw ("Nao achei: " + $pagePath) }

$backupDir = Join-Path $root ("tools\_patch_backup\eco-step-144-fix-mural-searchparams-promise-v0_1-" + $stamp)
EnsureDir $backupDir
BackupFile $pagePath $backupDir
BackupFile $pkgPath  $backupDir

# ----------------------------
# PATCH 1: page.tsx (searchParams Promise)
# ----------------------------
$raw = [System.IO.File]::ReadAllText($pagePath, [System.Text.UTF8Encoding]::new($false))
$raw = $raw.Replace("`r", "")
$lines = $raw.Split("`n")

$start = -1
for ($i = 0; $i -lt $lines.Length; $i++) {
  $t = $lines[$i].Trim()
  if ($t.StartsWith("export default function Page") -or $t.StartsWith("export default async function Page")) {
    $start = $i
    break
  }
}
if ($start -lt 0) { throw "Nao encontrei o header: export default function Page(...)" }

$end = -1
for ($j = $start; $j -lt $lines.Length; $j++) {
  if ($lines[$j].Contains("{")) { $end = $j; break }
}
if ($end -lt 0) { throw "Nao encontrei a chave '{' do Page()." }

$header = "export default async function Page({ searchParams }: { searchParams: Promise<Record<string, string | string[]>> }) {"
$needSp = (-not $raw.Contains("const sp = await searchParams")) -and (-not $raw.Contains("const sp = (await searchParams)"))

$out = New-Object System.Collections.Generic.List[string]
for ($i = 0; $i -lt $lines.Length; $i++) {
  if ($i -eq $start) {
    $out.Add($header)
    if ($needSp) { $out.Add("  const sp = (await searchParams) || {};") }
    $i = $end
    continue
  }

  $line = $lines[$i]
  if ($i -gt $end) {
    $line = $line.Replace("searchParams?.", "sp?.")
    $line = $line.Replace("searchParams.", "sp.")
  }
  $out.Add($line)
}

WriteUtf8NoBom $pagePath ($out.ToArray() -join "`n")
Write-Host ("[PATCH] updated -> " + $pagePath) -ForegroundColor Green

# ----------------------------
# PATCH 2 (opcional): package.json dev:webpack
# ----------------------------
if (Test-Path -LiteralPath $pkgPath) {
  $pkg = [System.IO.File]::ReadAllText($pkgPath, [System.Text.UTF8Encoding]::new($false))

  if (-not $pkg.Contains('"dev:webpack"')) {
    $needle = '"scripts": {'
    $pos = $pkg.IndexOf($needle)

    if ($pos -ge 0) {
      $nl = "`r`n"
      if ($pkg.Contains("`n") -and (-not $pkg.Contains("`r`n"))) { $nl = "`n" }

      $insert = $nl + '    "dev:webpack": "next dev --no-turbo",'
      $pkg2 = $pkg.Insert($pos + $needle.Length, $insert)

      WriteUtf8NoBom $pkgPath $pkg2
      Write-Host '[PATCH] package.json: added dev:webpack -> next dev --no-turbo' -ForegroundColor Green
    } else {
      Write-Host '[WARN] package.json: nao achei "scripts": { ... } (skip dev:webpack)' -ForegroundColor Yellow
    }
  } else {
    Write-Host '[PATCH] package.json: dev:webpack ja existe (skip)' -ForegroundColor DarkGray
  }
}

# ----------------------------
# REPORT
# ----------------------------
$reportDir = Join-Path $root "reports"
EnsureDir $reportDir
$reportPath = Join-Path $reportDir ("eco-step-144-fix-mural-searchparams-promise-v0_1-" + $stamp + ".md")

$r = @()
$r += "# eco-step-144-fix-mural-searchparams-promise-v0_1 - " + $stamp
$r += ""
$r += "## PATCH"
$r += "- page.tsx: Page() async + await searchParams; trocou searchParams.* -> sp.*"
$r += "- (opcional) package.json: adiciona dev:webpack = next dev --no-turbo"
$r += ""
$r += "## VERIFY"
$r += "- Ctrl+C -> npm run dev:webpack (recomendado p/ evitar overlay de sourcemap)"
$r += "- abrir: /eco/mural"
$r += "- abrir: /eco/mural?map=1 (>=1100px: 2 colunas, mapa aparece e fica sticky)"
WriteUtf8NoBom $reportPath ($r -join "`n")

Write-Host ("[REPORT] " + $reportPath) -ForegroundColor Cyan
Write-Host "[VERIFY] rode:" -ForegroundColor Cyan
Write-Host "  Ctrl+C -> npm run dev:webpack"
Write-Host "  abrir /eco/mural?map=1"
Write-Host "  abrir /eco/mural"