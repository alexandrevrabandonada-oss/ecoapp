param([switch]$NoClean)
$ErrorActionPreference = "Stop"
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$root = (Resolve-Path ".").Path

function EnsureDir([string]$p) {
  if ([string]::IsNullOrWhiteSpace($p)) { return }
  New-Item -ItemType Directory -Force -Path $p | Out-Null
}
function WriteUtf8NoBom([string]$path, [string]$content) {
  if ([string]::IsNullOrWhiteSpace($path)) { throw "WriteUtf8NoBom: empty path" }
  $parent = Split-Path -Parent $path
  if (-not [string]::IsNullOrWhiteSpace($parent)) { EnsureDir $parent }
  [System.IO.File]::WriteAllText($path, $content, [System.Text.UTF8Encoding]::new($false))
}
function BackupFile([string]$src, [string]$backupDir) {
  EnsureDir $backupDir
  if (Test-Path -LiteralPath $src) {
    $name = (Split-Path -Leaf $src) + ".bak"
    Copy-Item -LiteralPath $src -Destination (Join-Path $backupDir $name) -Force
  }
}

Write-Host ("== eco-step-144e-fix-mural-searchparams-promise-v0_1 == " + $stamp) -ForegroundColor Cyan

$pagePath = Join-Path $root "src\app\eco\mural\page.tsx"
if (-not (Test-Path -LiteralPath $pagePath)) { throw ("Not found: " + $pagePath) }
$pkgPath = Join-Path $root "package.json"

$backupDir = Join-Path $root ("tools\_patch_backup\eco-step-144e-fix-mural-searchparams-promise-v0_1-" + $stamp)
EnsureDir $backupDir
BackupFile $pagePath $backupDir
if (Test-Path -LiteralPath $pkgPath) { BackupFile $pkgPath $backupDir }

if (-not $NoClean) {
  $nextDir = Join-Path $root ".next"
  if (Test-Path -LiteralPath $nextDir) {
    Remove-Item -Recurse -Force -LiteralPath $nextDir
    Write-Host "[CLEAN] removed .next" -ForegroundColor DarkGray
  }
}

# package.json: dev -> webpack (best-effort)
try {
  if (Test-Path -LiteralPath $pkgPath) {
    $pkg = (Get-Content -Raw -LiteralPath $pkgPath) | ConvertFrom-Json
    if (-not $pkg.scripts) { $pkg | Add-Member -NotePropertyName scripts -NotePropertyValue (@{}) }
    $pkg.scripts.dev = "next dev --no-turbo"
    if (-not $pkg.scripts."dev:turbo") {
      $pkg.scripts | Add-Member -NotePropertyName "dev:turbo" -NotePropertyValue "next dev --turbo"
    }
    $json = $pkg | ConvertTo-Json -Depth 50
    WriteUtf8NoBom $pkgPath ($json + "`n")
    Write-Host "[PATCH] package.json: scripts.dev -> next dev --no-turbo" -ForegroundColor Green
  }
} catch {
  Write-Host ("[WARN] package.json patch failed: " + $_.Exception.Message) -ForegroundColor Yellow
}

# page.tsx: unwrap searchParams Promise + mapOpen safe
$raw = Get-Content -Raw -LiteralPath $pagePath
$lines = $raw -split "`r?`n"
$out = New-Object System.Collections.Generic.List[string]
$inserted = $false

foreach ($line0 in $lines) {
  $line = $line0
  $t = $line.Trim()

  if ($line -match "export default function Page") {
    $line = $line.Replace("export default function Page", "export default async function Page")
  }

  # remove old mapOpen derivations that touch searchParams.map directly
  if ($t -match "^const\s+mapRaw\b" -or $t -match "^const\s+mapVal\b" -or $t -match "^const\s+mapOpen\b" -or $line -match "searchParams\?\.map" -or $line -match "searchParams\.map") {
    continue
  }

  # ensure data-map on <main ... eco-mural ...>
  if ($line -match "<main" -and $line -match "eco-mural" -and -not ($line -match "data-map")) {
    if ($line -match ">") {
      $line = $line.Replace(">", " data-map={mapOpen ? ""1"" : ""0""}>")
    }
  }

  $out.Add($line)

  if (-not $inserted -and $line -match "export default" -and $line -match "Page" -and $line -match "{") {
    $out.Add("  // Next 16: searchParams can be a Promise (sync dynamic APIs)")
    $out.Add("  const sp: any = searchParams ? (typeof (searchParams as any).then === ""function"" ? await (searchParams as any) : searchParams) : {};")
    $out.Add("  const mapRaw = sp?.map;")
    $out.Add("  const mapVal = Array.isArray(mapRaw) ? mapRaw[0] : mapRaw;")
    $out.Add("  const mapOpen = (mapVal === ""1"" || mapVal === ""true"");")
    $inserted = $true
  }
}

if (-not $inserted) { throw "Could not insert mapOpen block (did not find export default Page { line)." }
WriteUtf8NoBom $pagePath ($out.ToArray() -join "`n")
Write-Host "[PATCH] page.tsx: async + unwrap searchParams + mapOpen safe" -ForegroundColor Green

# report
$reportDir = Join-Path $root "reports"
EnsureDir $reportDir
$reportPath = Join-Path $reportDir ("eco-step-144e-fix-mural-searchparams-promise-v0_1-" + $stamp + ".md")
$r = @()
$r += "# eco-step-144e-fix-mural-searchparams-promise-v0_1 - $stamp"
$r += ""
$r += "## PATCH"
$r += "- src/app/eco/mural/page.tsx: Page async + unwrap searchParams Promise + mapOpen"
$r += "- src/app/eco/mural/page.tsx: ensure data-map on <main>"
$r += "- package.json (best-effort): scripts.dev -> next dev --no-turbo"
$r += ""
$r += "## VERIFY"
$r += "- Ctrl+C (if dev running)"
$r += "- npm run dev"
$r += "- open: /eco/mural and /eco/mural?map=1 (no searchParams Promise error)"
WriteUtf8NoBom $reportPath ($r -join "`n")
Write-Host ("[REPORT] " + $reportPath) -ForegroundColor DarkGray
Write-Host "[VERIFY] Ctrl+C -> npm run dev -> /eco/mural?map=1" -ForegroundColor Cyan