param()

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
  if (-not (Test-Path -LiteralPath $src)) { throw "BackupFile: não achei $src" }
  $name = (Split-Path -Leaf $src) + ".bak"
  Copy-Item -LiteralPath $src -Destination (Join-Path $backupDir $name) -Force
}

Write-Host ("== eco-step-146-mural-map-toggle-and-fix-dev-script-v0_1 == " + $stamp) -ForegroundColor Cyan
Write-Host ("[DIAG] Root: " + $root)

$pagePath = Join-Path $root "src\app\eco\mural\page.tsx"
$pkgPath  = Join-Path $root "package.json"
$compDir  = Join-Path $root "src\app\eco\mural\_components"
$togglePath = Join-Path $compDir "MapToggleLink.tsx"

if (-not (Test-Path -LiteralPath $pagePath)) { throw "Não achei: $pagePath" }
if (-not (Test-Path -LiteralPath $pkgPath))  { throw "Não achei: $pkgPath" }
EnsureDir $compDir

$backupDir = Join-Path $root ("tools\_patch_backup\eco-step-146-mural-map-toggle-and-fix-dev-script-v0_1-" + $stamp)
EnsureDir $backupDir
BackupFile $pagePath $backupDir
BackupFile $pkgPath  $backupDir
if (Test-Path -LiteralPath $togglePath) { BackupFile $togglePath $backupDir }

# -------------------------------
# PATCH 1: criar MapToggleLink.tsx
# -------------------------------
$toggle = @(
  '"use client";',
  '',
  'import Link from "next/link";',
  'import { usePathname, useSearchParams } from "next/navigation";',
  'import { useMemo } from "react";',
  '',
  'export default function MapToggleLink() {',
  '  const pathname = usePathname();',
  '  const sp = useSearchParams();',
  '',
  '  const isOpen = (sp.get("map") === "1" || sp.get("map") === "true");',
  '',
  '  const href = useMemo(() => {',
  '    const p = new URLSearchParams(sp.toString());',
  '    const mapVal = p.get("map");',
  '    const open = (mapVal === "1" || mapVal === "true");',
  '    if (open) { p.delete("map"); } else { p.set("map", "1"); }',
  '    const q = p.toString();',
  '    return q ? (pathname + "?" + q) : pathname;',
  '  }, [pathname, sp]);',
  '',
  '  return (',
  '    <Link',
  '      href={href}',
  '      prefetch={false}',
  '      style={{',
  '        display: "inline-flex",',
  '        alignItems: "center",',
  '        justifyContent: "center",',
  '        gap: 8,',
  '        padding: "7px 12px",',
  '        borderRadius: 999,',
  '        border: "1px solid rgba(255,255,255,0.25)",',
  '        background: "rgba(0,0,0,0.35)",',
  '        color: "#eaeaea",',
  '        fontSize: 12,',
  '        fontWeight: 700,',
  '        textDecoration: "none",',
  '        letterSpacing: "0.2px",',
  '        userSelect: "none"',
  '      }}',
  '      aria-label={isOpen ? "Fechar mapa" : "Abrir mapa"}',
  '      title={isOpen ? "Fechar mapa" : "Abrir mapa"}',
  '    >',
  '      {isOpen ? "Fechar mapa" : "Abrir mapa"}',
  '    </Link>',
  '  );',
  '}'
) -join "`n"

WriteUtf8NoBom $togglePath $toggle
Write-Host ("[PATCH] wrote -> " + $togglePath) -ForegroundColor Green

# -------------------------------
# PATCH 2: page.tsx (import + render do toggle)
# -------------------------------
$raw = [System.IO.File]::ReadAllText($pagePath, [System.Text.UTF8Encoding]::new($false))

if (-not ($raw.Contains("MapToggleLink"))) {
  $lines = $raw -split "`r?`n"
  $out = New-Object System.Collections.Generic.List[string]

  # 2a) Import: tenta inserir após import do MuralWideStyles; senão, após o último import.
  $insertedImport = $false
  $lastImportIndex = -1
  for ($i = 0; $i -lt $lines.Length; $i++) {
    $line = $lines[$i]
    if ($line.TrimStart().StartsWith("import ")) { $lastImportIndex = $out.Count }

    if (-not $insertedImport -and $line.Contains("MuralWideStyles") -and $line.TrimStart().StartsWith("import ")) {
      $out.Add($line)
      $out.Add('import MapToggleLink from "./_components/MapToggleLink";')
      $insertedImport = $true
      continue
    }
    $out.Add($line)
  }
  if (-not $insertedImport) {
    if ($lastImportIndex -ge 0) {
      $out.Insert($lastImportIndex + 1, 'import MapToggleLink from "./_components/MapToggleLink";')
      $insertedImport = $true
    } else {
      # fallback: topo do arquivo
      $out.Insert(0, 'import MapToggleLink from "./_components/MapToggleLink";')
      $insertedImport = $true
    }
  }

  # 2b) Render: insere logo após <MuralWideStyles .../> (sem mexer no split)
  $final = $out.ToArray()
  $out2 = New-Object System.Collections.Generic.List[string]
  $insertedJsx = $false
  for ($i = 0; $i -lt $final.Length; $i++) {
    $line = $final[$i]
    $out2.Add($line)

    if (-not $insertedJsx -and $line.Contains("<MuralWideStyles") ) {
      # tenta inserir depois da linha do componente (mesmo que seja <MuralWideStyles /> ou <MuralWideStyles/> )
      $out2.Add('      <div style={{ display: "flex", justifyContent: "flex-end", gap: 10, margin: "10px 0 14px" }}>')
      $out2.Add('        <MapToggleLink />')
      $out2.Add('      </div>')
      $insertedJsx = $true
    }
  }

  WriteUtf8NoBom $pagePath ($out2.ToArray() -join "`n")
  Write-Host ("[PATCH] updated -> " + $pagePath) -ForegroundColor Green
} else {
  Write-Host "[PATCH] page.tsx já referencia MapToggleLink (skip)" -ForegroundColor Yellow
}

# -------------------------------
# PATCH 3: package.json (conserta --no-turbo e deixa dev:webpack)
# -------------------------------
$pkg = [System.IO.File]::ReadAllText($pkgPath, [System.Text.UTF8Encoding]::new($false))
$pkgLines = $pkg -split "`r?`n"
$outPkg = New-Object System.Collections.Generic.List[string]

$devFixed = $false
$hasDevWebpack = $pkg.Contains('"dev:webpack"')
$hasDevTurbo   = $pkg.Contains('"dev:turbo"')

for ($i = 0; $i -lt $pkgLines.Length; $i++) {
  $line = $pkgLines[$i]

  # corrige dev: --no-turbo (inválido) OU dev: next dev (pra reduzir sourcemap spam)
  if (-not $devFixed -and $line.Contains('"dev":') ) {
    if ($line.Contains("next dev --no-turbo")) {
      $line = $line.Replace("next dev --no-turbo", "set NEXT_DISABLE_TURBOPACK=1 && next dev")
      $devFixed = $true
    } elseif ($line.Contains('"dev": "next dev"')) {
      $line = $line.Replace('"dev": "next dev"', '"dev": "set NEXT_DISABLE_TURBOPACK=1 && next dev"')
      $devFixed = $true
    } elseif ($line.Contains("NEXT_DISABLE_TURBOPACK=1") ) {
      $devFixed = $true
    }
    $outPkg.Add($line)

    # injeta scripts opcionais logo após dev (se não existirem)
    if (-not $hasDevWebpack) {
      $outPkg.Add('    "dev:webpack": "set NEXT_DISABLE_TURBOPACK=1 && next dev",')
      $hasDevWebpack = $true
    }
    if (-not $hasDevTurbo) {
      $outPkg.Add('    "dev:turbo": "next dev --turbo",')
      $hasDevTurbo = $true
    }
    continue
  }

  $outPkg.Add($line)
}

WriteUtf8NoBom $pkgPath ($outPkg.ToArray() -join "`n")
Write-Host ("[PATCH] package.json scripts: dev fixed + dev:webpack/dev:turbo ensured") -ForegroundColor Green

# -------------------------------
# REPORT
# -------------------------------
$reportDir = Join-Path $root "reports"
EnsureDir $reportDir
$reportPath = Join-Path $reportDir ("eco-step-146-mural-map-toggle-and-fix-dev-script-v0_1-" + $stamp + ".md")
$r = @()
$r += "# eco-step-146-mural-map-toggle-and-fix-dev-script-v0_1 - $stamp"
$r += ""
$r += "## PATCH"
$r += "- wrote: src/app/eco/mural/_components/MapToggleLink.tsx"
$r += "- updated: src/app/eco/mural/page.tsx (import + render toggle após MuralWideStyles)"
$r += "- updated: package.json (remove --no-turbo, dev usa NEXT_DISABLE_TURBOPACK=1; adiciona dev:webpack/dev:turbo)"
$r += ""
$r += "## VERIFY"
$r += "- Ctrl+C -> npm run dev"
$r += "- abrir: /eco/mural (botão deve mostrar Abrir mapa)"
$r += "- clicar Abrir mapa -> vira /eco/mural?map=1 (2 colunas + mapa à direita)"
$r += "- clicar Fechar mapa -> volta /eco/mural (preserva outros params se tiver)"
WriteUtf8NoBom $reportPath ($r -join "`n")
Write-Host ("[REPORT] " + $reportPath) -ForegroundColor DarkGray

Write-Host ""
Write-Host "[VERIFY] rode:" -ForegroundColor Cyan
Write-Host "  Ctrl+C -> npm run dev"
Write-Host "  abrir /eco/mural e /eco/mural?map=1 (toggle Abrir/Fechar mapa)"