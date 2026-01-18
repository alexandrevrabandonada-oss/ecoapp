param(
  [string]$Root = (Get-Location).Path
)

$ts = Get-Date -Format "yyyyMMdd-HHmmss"

$boot = Join-Path $Root "tools/_bootstrap.ps1"
if (Test-Path -LiteralPath $boot) { . $boot }

if (-not (Get-Command EnsureDir -ErrorAction SilentlyContinue)) {
  function EnsureDir([string]$p) { if (-not (Test-Path -LiteralPath $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null } }
}
if (-not (Get-Command WriteUtf8NoBom -ErrorAction SilentlyContinue)) {
  function WriteUtf8NoBom([string]$p, [string]$content) {
    EnsureDir (Split-Path -Parent $p)
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($p, $content, $enc)
  }
}
if (-not (Get-Command BackupFile -ErrorAction SilentlyContinue)) {
  function BackupFile([string]$root, [string]$p, [string]$backupDir) {
    if (Test-Path -LiteralPath $p) {
      $rel = $p.Substring($root.Length).TrimStart('\','/')
      $dest = Join-Path $backupDir ($rel -replace '[\\/]', '__')
      Copy-Item -Force -LiteralPath $p -Destination $dest
      Write-Host ('[BK] ' + $rel + ' -> ' + (Split-Path -Leaf $dest))
    }
  }
}

Write-Host ('== eco-step-87c-rewrite-mural-page-safe-v0_1 == ' + $ts)
Write-Host ('[DIAG] Root: ' + $Root)

$page = Join-Path $Root 'src/app/eco/mural/page.tsx'
if (-not (Test-Path -LiteralPath $page)) { throw "[STOP] Nao achei src/app/eco/mural/page.tsx" }

$backupDir = Join-Path $Root ('tools/_patch_backup/' + $ts + '-eco-step-87c-rewrite-mural-page-safe-v0_1')
$reportDir = Join-Path $Root 'reports'
EnsureDir $backupDir
EnsureDir $reportDir
BackupFile $Root $page $backupDir

$raw = [System.IO.File]::ReadAllText($page)
if (-not $raw) { throw "[STOP] Falha ao ler page.tsx" }

$lines = $raw -split "`n"

# Detecta se existe "use client"
$useClient = $false
foreach ($ln in $lines) {
  $t = $ln.Trim()
  if ($t -eq '"use client";' -or $t -eq "'use client';") { $useClient = $true; break }
  if ($t.StartsWith("import ")) { break }
}

# Coleta imports existentes (pra não quebrar o import do MuralClient)
$imports = New-Object System.Collections.Generic.List[string]
foreach ($ln in $lines) {
  $t = $ln.Trim()
  if ($t.StartsWith("import ")) { $imports.Add($ln.TrimEnd()) }
}

# Garante import do MuralTopBar
$hasTop = $false
foreach ($ln in $imports) { if ($ln -match 'MuralTopBar') { $hasTop = $true; break } }
if (-not $hasTop) {
  $imports.Add('import MuralTopBar from "./_components/MuralTopBar";')
}

# tenta manter exports runtime/dynamic existentes
$runtimeLine = $null
$dynamicLine = $null
foreach ($ln in $lines) {
  $t = $ln.Trim()
  if ($t.StartsWith("export const runtime")) { $runtimeLine = $ln.TrimEnd() }
  if ($t.StartsWith("export const dynamic")) { $dynamicLine = $ln.TrimEnd() }
}

# Monta arquivo novo (safe)
$out = New-Object System.Collections.Generic.List[string]
if ($useClient) { $out.Add('"use client";') ; $out.Add('') }

# imports (dedupe)
$seen = @{}
foreach ($ln in $imports) {
  $k = $ln.Trim()
  if (-not $seen.ContainsKey($k)) { $seen[$k] = $true; $out.Add($ln) }
}
$out.Add('')

if ($runtimeLine) { $out.Add($runtimeLine) }
if ($dynamicLine) { $out.Add($dynamicLine) }
if ($runtimeLine -or $dynamicLine) { $out.Add('') }

# Se for client component, não pode usar server component async MuralTopBar.
# Nesse caso, a gente só não renderiza o topo (pra não quebrar build) — depois fazemos TopBar client-side.
$renderTop = -not $useClient

$out.Add('export default function Page() {')
$out.Add('  return (')
$out.Add('    <main style={{ padding: 16, maxWidth: 1100, margin: "0 auto" }}>')
if ($renderTop) {
  $out.Add('      <MuralTopBar />')
  $out.Add('')
}
$out.Add('      <h1 style={{ margin: "0 0 8px 0" }}>Mural do Cuidado</h1>')
$out.Add('      <p style={{ margin: "0 0 14px 0", opacity: 0.85 }}>')
$out.Add('        Pontos críticos por bairro. Confirme, apoie, compartilhe e organize.')
$out.Add('      </p>')
$out.Add('')
$out.Add('      <div style={{ margin: "10px 0 14px 0", display: "flex", gap: 10, flexWrap: "wrap" }}>')
$out.Add('        <a')
$out.Add('          href="/eco/mural-acoes"')
$out.Add('          style={{')
$out.Add('            padding: "9px 10px",')
$out.Add('            borderRadius: 12,')
$out.Add('            border: "1px solid #111",')
$out.Add('            textDecoration: "none",')
$out.Add('            color: "#111",')
$out.Add('            fontWeight: 900,')
$out.Add('            background: "#fff",')
$out.Add('          }}')
$out.Add('        >')
$out.Add('          Ver versão com ações (fallback)')
$out.Add('        </a>')
$out.Add('      </div>')
$out.Add('')
$out.Add('      <MuralClient base="pontos" />')
$out.Add('    </main>')
$out.Add('  );')
$out.Add('}')
$out.Add('')

WriteUtf8NoBom $page ($out -join "`n")
Write-Host "[PATCH] Reescrevi src/app/eco/mural/page.tsx (safe JSX) — build deve voltar."

$rep = Join-Path $reportDir ('eco-step-87c-rewrite-mural-page-safe-v0_1-' + $ts + '.md')
$repLines = @(
'# eco-step-87c-rewrite-mural-page-safe-v0_1',
'',
'- Time: ' + $ts,
'- Backup: ' + $backupDir,
'- File: src/app/eco/mural/page.tsx',
'',
'## What',
'- Reconstrói o page.tsx com JSX válido (remove nesting p>div e corrige parser).',
'- Mantém imports existentes (incluindo MuralClient) e garante import do MuralTopBar.',
'- Se a página estiver como "use client", não renderiza MuralTopBar (evita erro server->client).',
'',
'## Verify',
'1) Ctrl+C -> npm run dev',
'2) Abrir /eco/mural',
'3) Não deve mais ter "Parsing ecmascript source code failed"',
'4) Se não aparecer topo fixo, verificar se tinha "use client" (aí fazemos TopBar client-side)'
)
WriteUtf8NoBom $rep ($repLines -join "`n")
Write-Host ('[REPORT] ' + $rep)

Write-Host ""
Write-Host "[VERIFY] Ctrl+C -> npm run dev"
Write-Host "[VERIFY] /eco/mural -> página deve abrir sem erro de parser"