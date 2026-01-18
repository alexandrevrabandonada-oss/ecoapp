#!/usr/bin/env pwsh
param()

$ErrorActionPreference = "Stop"
$me = "eco-step-134c-inline-mapa-no-mural-safe-v0_3"
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$root = (Resolve-Path ".").Path

# bootstrap (preferir tools/_bootstrap.ps1)
$bootstrap = Join-Path $root "tools\_bootstrap.ps1"
if (Test-Path $bootstrap) {
  . $bootstrap
} else {
  function EnsureDir($p){ if(-not (Test-Path $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
  function WriteUtf8NoBom($path,$content){ EnsureDir (Split-Path -Parent $path); [IO.File]::WriteAllText($path,$content,[Text.UTF8Encoding]::new($false)) }
  function BackupFile($path,$dir){ EnsureDir $dir; if(Test-Path $path){ Copy-Item -Force -LiteralPath $path -Destination (Join-Path $dir ([IO.Path]::GetFileName($path))) } }
  function NewReport($name,$stamp){ $rp = Join-Path $root ("reports\" + $name + "-" + $stamp + ".md"); EnsureDir (Split-Path -Parent $rp); return $rp }
}

Write-Host ("== " + $me + " == " + $stamp)
Write-Host ("[DIAG] Root: " + $root)

$backupDir = Join-Path $root ("tools\_patch_backup\" + $me + "-" + $stamp)
EnsureDir $backupDir
$reportPath = NewReport $me $stamp

$pageFile = Join-Path $root "src\app\eco\mural\page.tsx"
$compFile = Join-Path $root "src\app\eco\mural\_components\MuralInlineMapa.tsx"

if (-not (Test-Path $pageFile)) { throw ("page.tsx não encontrado: " + $pageFile) }
BackupFile $pageFile $backupDir
if (Test-Path $compFile) { BackupFile $compFile $backupDir }

# criar componente TSX via here-string (seguro)
$tsx = @'
export default function MuralInlineMapa() {
  return (
    <details
      style={{
        marginTop: 12,
        border: "1px solid #111",
        borderRadius: 12,
        background: "#fff",
        overflow: "hidden",
      }}
    >
      <summary
        style={{
          padding: 10,
          cursor: "pointer",
          fontWeight: 900,
          userSelect: "none",
        }}
      >
        🗺️ Mapa embutido (beta)
      </summary>
      <div style={{ padding: 10 }}>
        <iframe
          title="Mapa do Cuidado"
          src="/eco/mapa"
          style={{
            width: "100%",
            height: 680,
            border: "1px solid #111",
            borderRadius: 12,
            background: "#fff",
          }}
        />
        <div style={{ fontSize: 12, opacity: 0.8, marginTop: 8 }}>
          Dica: clique num ponto na lista do mapa para focar o marcador.
        </div>
      </div>
    </details>
  );
}
'@

WriteUtf8NoBom $compFile $tsx
Write-Host ("[PATCH] created/updated -> " + $compFile)

# patch page.tsx (import + render)
$lines = Get-Content -LiteralPath $pageFile
$importLine = "import MuralInlineMapa from ""./_components/MuralInlineMapa"";"

$hasImport = $false
$hasRender = $false
for ($i=0; $i -lt $lines.Count; $i++) {
  if ($lines[$i] -eq $importLine) { $hasImport = $true }
  if ($lines[$i] -match "<MuralInlineMapa\s*/>") { $hasRender = $true }
}

if (-not $hasImport) {
  $lastImport = -1
  for ($i=0; $i -lt $lines.Count; $i++) {
    if ($lines[$i].TrimStart().StartsWith("import ")) { $lastImport = $i }
  }
  if ($lastImport -ge 0) {
    $ins = $lastImport + 1
    if ($ins -le $lines.Count-1) {
      $lines = $lines[0..$lastImport] + @($importLine) + $lines[$ins..($lines.Count-1)]
    } else {
      $lines = $lines + @($importLine)
    }
  } else {
    $lines = @($importLine) + $lines
  }
  Write-Host "[PATCH] page.tsx import: OK"
}

if (-not $hasRender) {
  $idx = -1
  for ($i=0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match "<MuralClient") { $idx = $i; break }
  }
  if ($idx -ge 0) {
    $indent = ([regex]::Match($lines[$idx], "^(\\s*)")).Groups[1].Value
    $insertLine = $indent + "<MuralInlineMapa />"
    $lines = $lines[0..$idx] + @($insertLine) + $lines[($idx+1)..($lines.Count-1)]
    Write-Host "[PATCH] page.tsx render: OK"
  } else {
    Write-Host "[WARN] Não achei <MuralClient ...> pra inserir <MuralInlineMapa /> automaticamente."
  }
}

WriteUtf8NoBom $pageFile ($lines -join "`n")

# report
$r = @()
$r += ("# " + $me)
$r += ""
$r += ("- stamp: " + $stamp)
$r += ("- backup: " + $backupDir)
$r += ""
$r += "## Mudanças"
$r += ("- created/updated: " + $compFile)
$r += ("- patched: " + $pageFile)
$r += ""
$r += "## Verify"
$r += "- Ctrl+C -> npm run dev"
$r += "- abrir /eco/mural e expandir **Mapa embutido (beta)**"
$r += "- conferir se o iframe renderiza /eco/mapa"
WriteUtf8NoBom $reportPath ($r -join "`n")
Write-Host ("[REPORT] " + $reportPath)

Write-Host ""
Write-Host "[VERIFY] rode:"
Write-Host "  Ctrl+C -> npm run dev"
Write-Host "  abrir /eco/mural e expandir Mapa embutido (beta)"