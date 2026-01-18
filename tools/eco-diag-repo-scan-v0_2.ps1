param(
  [switch]$OpenReport,
  [string]$OutDir = "reports"
)

$ErrorActionPreference = "Stop"
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$root = (Resolve-Path ".").Path
$me = "eco-diag-repo-scan-v0_2"

function EnsureDir([string]$p) {
  if ([string]::IsNullOrWhiteSpace($p)) { return }
  New-Item -ItemType Directory -Force -Path $p | Out-Null
}
function ReadRaw([string]$p) {
  try { if (Test-Path -LiteralPath $p) { return Get-Content -LiteralPath $p -Raw -ErrorAction Stop } } catch {}
  return $null
}
function WriteUtf8NoBom([string]$p, [string]$content) {
  if ([string]::IsNullOrWhiteSpace($p)) { throw "WriteUtf8NoBom: path vazio" }
  $parent = Split-Path -Parent $p
  if (-not [string]::IsNullOrWhiteSpace($parent)) { EnsureDir $parent }
  [System.IO.File]::WriteAllText($p, $content, [System.Text.UTF8Encoding]::new($false))
}
function AddLine([System.Collections.Generic.List[string]]$r, [string]$s) { $r.Add($s) | Out-Null }
function AddH2([System.Collections.Generic.List[string]]$r, [string]$t) { AddLine $r ""; AddLine $r ("## " + $t) }
function AddCode([System.Collections.Generic.List[string]]$r, [string]$lang, [string]$text) {
  AddLine $r ""
  AddLine $r ("~~~" + $lang)
  if ($null -ne $text -and $text.Length -gt 0) {
    ($text -split "\r?\n") | ForEach-Object { AddLine $r $_ }
  }
  AddLine $r "~~~"
}
function RelPath([string]$p) {
  try {
    $full = (Resolve-Path -LiteralPath $p -ErrorAction Stop).Path
    if ($full.StartsWith($root)) { return $full.Substring($root.Length).TrimStart("\") }
    return $full
  } catch { return $p }
}

function ParseEnvLine([string]$raw, [string]$key) {
  if ([string]::IsNullOrWhiteSpace($raw)) { return $null }
  $lines = $raw -split "\r?\n"
  foreach ($ln in $lines) {
    $t = $ln.Trim()
    if ($t.StartsWith("#")) { continue }
    if ($t.StartsWith($key + "=")) {
      $v = $t.Substring(($key + "=").Length).Trim()
      if ($v.Length -ge 2) {
        $c0 = [int][char]$v[0]
        $c1 = [int][char]$v[$v.Length-1]
        if (($c0 -eq 34 -and $c1 -eq 34) -or ($c0 -eq 39 -and $c1 -eq 39)) {
          $v = $v.Substring(1, $v.Length - 2)
        }
      }
      return $v
    }
  }
  return $null
}

function TryResolveSqlitePath([string]$url) {
  if ([string]::IsNullOrWhiteSpace($url)) { return $null }
  if ($url -notmatch "^file:") { return $null }
  $p = $url.Substring(5).Trim()
  if ($p.StartsWith("//")) { $p = $p.Substring(2) }
  $q = $p.IndexOf("?")
  if ($q -ge 0) { $p = $p.Substring(0, $q) }
  if ([string]::IsNullOrWhiteSpace($p)) { return $null }
  $cand1 = Join-Path $root $p.TrimStart("/")
  if (Test-Path -LiteralPath $cand1) { return $cand1 }
  $cand2 = Join-Path (Join-Path $root "prisma") $p.TrimStart("/")
  if (Test-Path -LiteralPath $cand2) { return $cand2 }
  return $cand1
}

$r = New-Object System.Collections.Generic.List[string]
AddLine $r ("# " + $me + " — repo scan — " + $stamp)
AddLine $r ""
AddLine $r ("- Root: `" + $root + "`")

AddH2 $r "package.json (scripts + deps)"
$pkgPath = Join-Path $root "package.json"
$pkgRaw = ReadRaw $pkgPath
if ($null -eq $pkgRaw) {
  AddLine $r "- package.json: **NAO ACHEI**"
} else {
  AddLine $r ("- package.json: `" + (RelPath $pkgPath) + "`")
  try {
    $pkg = $pkgRaw | ConvertFrom-Json
    $scripts = $pkg.scripts
    if ($null -ne $scripts) {
      $s = @()
      foreach ($k in ($scripts.PSObject.Properties.Name | Sort-Object)) { $s += ($k + " = " + [string]$scripts.$k) }
      AddCode $r "txt" ($s -join "`n")
    }
    $deps = @()
    if ($null -ne $pkg.dependencies) {
      foreach ($k in ($pkg.dependencies.PSObject.Properties.Name | Sort-Object)) {
        if ($k -in @("next","react","react-dom","@prisma/client","prisma","typescript")) { $deps += ($k + " = " + [string]$pkg.dependencies.$k) }
      }
    }
    if ($null -ne $pkg.devDependencies) {
      foreach ($k in ($pkg.devDependencies.PSObject.Properties.Name | Sort-Object)) {
        if ($k -in @("next","react","react-dom","@prisma/client","prisma","typescript")) { $deps += ($k + " = " + [string]$pkg.devDependencies.$k + " (dev)") }
      }
    }
    if ($deps.Count -gt 0) { AddCode $r "txt" ($deps -join "`n") }
  } catch { AddLine $r ("- erro parse package.json: " + $_.Exception.Message) }
}

AddH2 $r ".env / DATABASE_URL"
$env1 = ReadRaw (Join-Path $root ".env")
$env2 = ReadRaw (Join-Path $root ".env.local")
$db1 = ParseEnvLine $env1 "DATABASE_URL"
$db2 = ParseEnvLine $env2 "DATABASE_URL"
$db = $db2; if ([string]::IsNullOrWhiteSpace($db)) { $db = $db1 }
if ([string]::IsNullOrWhiteSpace($db)) { $db = [string]$env:DATABASE_URL }
AddLine $r ("- .env: " + (if($env1){ "OK" } else { "nao achei" }))
AddLine $r ("- .env.local: " + (if($env2){ "OK" } else { "nao achei" }))
AddLine $r ("- DATABASE_URL (best-effort): `" + (if($db){$db}else{"(vazio)"}) + "`")
$dbResolved = TryResolveSqlitePath $db
if ($dbResolved) { AddLine $r ("- SQLite resolved path: `" + $dbResolved + "`") }

AddH2 $r "Prisma (schema + models)"
$schemas = Get-ChildItem -Path $root -Recurse -File -Filter "schema.prisma" -ErrorAction SilentlyContinue | Select-Object -First 10
if ($null -eq $schemas -or $schemas.Count -eq 0) {
  AddLine $r "- schema.prisma: **NAO ACHEI**"
} else {
  AddLine $r "- schema.prisma (top 10):"
  $list = @(); foreach ($s in $schemas) { $list += ("  - " + (RelPath $s.FullName)) }
  AddCode $r "txt" ($list -join "`n")
  $schemaRaw = ReadRaw $schemas[0].FullName
  if ($schemaRaw) {
    $models = @()
    foreach ($ln in ($schemaRaw -split "\r?\n")) {
      $t = $ln.Trim()
      if ($t.StartsWith("model ")) {
        $parts = $t.Split(" ", [System.StringSplitOptions]::RemoveEmptyEntries)
        if ($parts.Length -ge 2) { $models += $parts[1] }
      }
    }
    if ($models.Count -gt 0) { AddLine $r ("- models (schema[0]): **" + $models.Count + "**"); AddCode $r "txt" (($models | Sort-Object) -join "`n") }
    $urlHint = $null
    foreach ($ln in ($schemaRaw -split "\r?\n")) { $t = $ln.Trim(); if ($t -match "^url\s*=") { $urlHint = $t; break } }
    if ($urlHint) { AddLine $r ("- datasource url line (schema[0] first match): `" + $urlHint + "`") }
  }
}

AddH2 $r "DB files (scan)"
$dbFiles = Get-ChildItem -Path $root -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
  $_.Extension -in @(".db",".sqlite",".sqlite3") -or $_.Name -match "dev\.db$" -or $_.Name -match ".*\.db-journal$"
} | Select-Object -First 50
if ($null -eq $dbFiles -or $dbFiles.Count -eq 0) {
  AddLine $r "- nenhum .db/.sqlite encontrado (top 50)"
} else {
  AddLine $r ("- encontrados (top 50): **" + $dbFiles.Count + "**")
  $rows = @(); foreach ($f in $dbFiles) { $rows += ((RelPath $f.FullName) + "  (" + [Math]::Round(($f.Length/1MB), 2) + " MB)") }
  AddCode $r "txt" ($rows -join "`n")
}

AddH2 $r "Routes (App Router)"
$ecoPages = Get-ChildItem -Path (Join-Path $root "src\app\eco") -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -in @("page.tsx","page.ts") }
if ($null -eq $ecoPages -or $ecoPages.Count -eq 0) { AddLine $r "- src/app/eco: nao achei pages" }
else { AddLine $r ("- /eco pages: **" + $ecoPages.Count + "**"); $rows = @(); foreach ($p in $ecoPages) { $rows += (RelPath $p.FullName) }; AddCode $r "txt" (($rows | Sort-Object) -join "`n") }
$ecoApi = Get-ChildItem -Path (Join-Path $root "src\app\api\eco") -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "route.ts*" }
if ($null -eq $ecoApi -or $ecoApi.Count -eq 0) { AddLine $r "- /api/eco routes: nao achei route.ts" }
else { AddLine $r ("- /api/eco routes: **" + $ecoApi.Count + "**"); $rows = @(); foreach ($p in $ecoApi) { $rows += (RelPath $p.FullName) }; AddCode $r "txt" (($rows | Sort-Object) -join "`n") }

AddH2 $r "Prisma client usage (hints)"
$hintFiles = @()
$hintFiles += Get-ChildItem -Path (Join-Path $root "src") -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "prisma\.(ts|tsx|js)$" } | Select-Object -First 20
if ($hintFiles.Count -gt 0) {
  AddLine $r "- arquivos prisma.* (top 20):"
  $rows = @(); foreach ($f in $hintFiles) { $rows += (RelPath $f.FullName) }
  AddCode $r "txt" (($rows | Sort-Object) -join "`n")
} else {
  AddLine $r "- nao achei prisma.ts/prisma.js em src (ok se estiver em lib/)"
}

$outDirFull = Join-Path $root $OutDir
EnsureDir $outDirFull
$reportPath = Join-Path $outDirFull ($me + "-" + $stamp + ".md")
WriteUtf8NoBom $reportPath ($r -join "`n")
Write-Host ("[REPORT] " + $reportPath) -ForegroundColor Green
Write-Host ""
Write-Host "[NEXT] cola aqui no chat o conteudo do report (ou as secoes DATABASE_URL / DB files / Prisma)." -ForegroundColor Cyan
if ($OpenReport) { try { Start-Process -FilePath $reportPath | Out-Null } catch {} }