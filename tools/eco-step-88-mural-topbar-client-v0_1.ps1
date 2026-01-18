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

Write-Host ('== eco-step-88-mural-topbar-client-v0_1 == ' + $ts)
Write-Host ('[DIAG] Root: ' + $Root)

$srcApp = Join-Path $Root 'src/app'
if (-not (Test-Path -LiteralPath $srcApp)) { throw "[STOP] Nao achei src/app" }

$backupDir = Join-Path $Root ('tools/_patch_backup/' + $ts + '-eco-step-88-mural-topbar-client-v0_1')
$reportDir = Join-Path $Root 'reports'
EnsureDir $backupDir
EnsureDir $reportDir

function ReadText([string]$p) {
  if (-not (Test-Path -LiteralPath $p)) { return $null }
  return [System.IO.File]::ReadAllText($p)
}

function WriteLines([string]$p, [string[]]$lines) {
  WriteUtf8NoBom $p ($lines -join "`n")
}

# 1) Write Client component
$compDir = Join-Path $srcApp 'eco/mural/_components'
EnsureDir $compDir
$clientComp = Join-Path $compDir 'MuralTopBarClient.tsx'

$L = New-Object System.Collections.Generic.List[string]
$L.Add('"use client";')
$L.Add('')
$L.Add('import Link from "next/link";')
$L.Add('import { useEffect, useMemo, useState } from "react";')
$L.Add('')
$L.Add('type AnyRow = any;')
$L.Add('')
$L.Add('function num(v: any) {')
$L.Add('  const n = Number(v);')
$L.Add('  return Number.isFinite(n) ? n : 0;')
$L.Add('}')
$L.Add('')
$L.Add('function pickCount(p: any, keys: string[]) {')
$L.Add('  for (const k of keys) {')
$L.Add('    const v = p?.[k] ?? p?.counts?.[k] ?? p?.actions?.[k] ?? p?.stats?.[k];')
$L.Add('    const n = num(v);')
$L.Add('    if (n) return n;')
$L.Add('  }')
$L.Add('  return 0;')
$L.Add('}')
$L.Add('')
$L.Add('async function tryJson(url: string) {')
$L.Add('  const res = await fetch(url, { cache: "no-store" });')
$L.Add('  if (!res.ok) throw new Error("fetch_failed:" + res.status);')
$L.Add('  return await res.json();')
$L.Add('}')
$L.Add('')
$L.Add('async function loadList(tries: string[]) {')
$L.Add('  for (const t of tries) {')
$L.Add('    try {')
$L.Add('      const j = await tryJson(t);')
$L.Add('      const items = j?.items ?? j?.data ?? j?.list ?? j?.rows ?? j?.points ?? j?.mutiroes ?? j?.criticalPoints;')
$L.Add('      if (Array.isArray(items)) return { ok: true as const, items, src: t };')
$L.Add('    } catch {}')
$L.Add('  }')
$L.Add('  return { ok: false as const, items: [] as AnyRow[], src: "none" };')
$L.Add('}')
$L.Add('')
$L.Add('export default function MuralTopBarClient() {')
$L.Add('  const [pointsRes, setPointsRes] = useState<{ ok: boolean; items: AnyRow[]; src: string }>({ ok: false, items: [], src: "loading" });')
$L.Add('  const [mutRes, setMutRes] = useState<{ ok: boolean; items: AnyRow[]; src: string }>({ ok: false, items: [], src: "loading" });')
$L.Add('')
$L.Add('  useEffect(() => {')
$L.Add('    let alive = true;')
$L.Add('    ;(async () => {')
$L.Add('      const p = await loadList([')
$L.Add('        "/api/eco/points/list?limit=200",')
$L.Add('        "/api/eco/points?limit=200",')
$L.Add('        "/api/eco/critical/list?limit=200",')
$L.Add('        "/api/eco/critical?limit=200",')
$L.Add('      ]);')
$L.Add('      const m = await loadList([')
$L.Add('        "/api/eco/mutirao/list?limit=20",')
$L.Add('        "/api/eco/mutiroes/list?limit=20",')
$L.Add('        "/api/eco/mutirao?limit=20",')
$L.Add('      ]);')
$L.Add('      if (!alive) return;')
$L.Add('      setPointsRes(p as any);')
$L.Add('      setMutRes(m as any);')
$L.Add('    })();')
$L.Add('    return () => { alive = false; };')
$L.Add('  }, []);')
$L.Add('')
$L.Add('  const computed = useMemo(() => {')
$L.Add('    const points = pointsRes.items || [];')
$L.Add('    const chamados = points')
$L.Add('      .filter((p: any) => String(p?.status || p?.state || "").toUpperCase() === "OPEN")')
$L.Add('      .map((p: any) => ({')
$L.Add('        p,')
$L.Add('        called: pickCount(p, ["call", "callCount", "chamado", "chamados", "CALL", "CALLED"]),')
$L.Add('        confirm: pickCount(p, ["confirm", "confirmCount", "confirmar", "seen", "ok", "OK"]),')
$L.Add('      }))')
$L.Add('      .sort((a: any, b: any) => (b.called - a.called) || (b.confirm - a.confirm))')
$L.Add('      .slice(0, 6);')
$L.Add('')
$L.Add('    const confirmados = points')
$L.Add('      .map((p: any) => ({')
$L.Add('        p,')
$L.Add('        confirm: pickCount(p, ["confirm", "confirmCount", "confirmar", "seen", "ok", "OK"]),')
$L.Add('        called: pickCount(p, ["call", "callCount", "chamado", "chamados", "CALL", "CALLED"]),')
$L.Add('      }))')
$L.Add('      .sort((a: any, b: any) => (b.confirm - a.confirm) || (b.called - a.called))')
$L.Add('      .slice(0, 6);')
$L.Add('')
$L.Add('    const mutiroes = (mutRes.items || []).slice(0, 6);')
$L.Add('    return { chamados, confirmados, mutiroes };')
$L.Add('  }, [pointsRes, mutRes]);')
$L.Add('')
$L.Add('  const box: any = { border: "1px solid #111", borderRadius: 14, padding: 12, background: "#fff" };')
$L.Add('  const h: any = { margin: "0 0 6px 0", fontSize: 12, fontWeight: 950, letterSpacing: 0.2, opacity: 0.9 };')
$L.Add('  const a: any = { textDecoration: "none", color: "#111" };')
$L.Add('  const row: any = { display: "flex", justifyContent: "space-between", gap: 10, fontSize: 12, padding: "6px 0", borderTop: "1px dashed rgba(0,0,0,0.15)" };')
$L.Add('')
$L.Add('  return (')
$L.Add('    <section')
$L.Add('      style={{')
$L.Add('        position: "sticky",')
$L.Add('        top: 0,')
$L.Add('        zIndex: 50,')
$L.Add('        background: "rgba(245,245,245,0.92)",')
$L.Add('        backdropFilter: "blur(6px)",')
$L.Add('        padding: "10px 0 12px 0",')
$L.Add('        borderBottom: "1px solid rgba(0,0,0,0.15)",')
$L.Add('      }}')
$L.Add('    >')
$L.Add('      <div style={{ display: "grid", gridTemplateColumns: "repeat(3, minmax(0, 1fr))", gap: 10 }}>')
$L.Add('        <div style={box}>')
$L.Add('          <div style={h}>📣 Chamados ativos</div>')
$L.Add('          <div style={{ fontSize: 12, opacity: 0.75, marginBottom: 6 }}>Pontos OPEN com chamado</div>')
$L.Add('          <div>')
$L.Add('            {computed.chamados.length === 0 ? (')
$L.Add('              <div style={{ fontSize: 12, opacity: 0.75 }}>Nenhum chamado encontrado.</div>')
$L.Add('            ) : (')
$L.Add('              computed.chamados.map((x: any, idx: number) => (')
$L.Add('                <div key={idx} style={row}>')
$L.Add('                  <Link href={"/eco/pontos/" + String(x.p?.id || "")} style={a}>')
$L.Add('                    {String(x.p?.title || x.p?.name || x.p?.bairro || "Ponto")}') 
$L.Add('                  </Link>')
$L.Add('                  <span style={{ fontWeight: 950 }}>📣 {x.called || 0}</span>')
$L.Add('                </div>')
$L.Add('              ))')
$L.Add('            )}')
$L.Add('          </div>')
$L.Add('          <div style={{ marginTop: 8, fontSize: 11, opacity: 0.6 }}>src: {pointsRes.src}</div>')
$L.Add('        </div>')
$L.Add('')
$L.Add('        <div style={box}>')
$L.Add('          <div style={h}>✅ Mais confirmados</div>')
$L.Add('          <div style={{ fontSize: 12, opacity: 0.75, marginBottom: 6 }}>Onde mais gente disse “eu vi também”</div>')
$L.Add('          <div>')
$L.Add('            {computed.confirmados.length === 0 ? (')
$L.Add('              <div style={{ fontSize: 12, opacity: 0.75 }}>Sem dados ainda.</div>')
$L.Add('            ) : (')
$L.Add('              computed.confirmados.map((x: any, idx: number) => (')
$L.Add('                <div key={idx} style={row}>')
$L.Add('                  <Link href={"/eco/pontos/" + String(x.p?.id || "")} style={a}>')
$L.Add('                    {String(x.p?.title || x.p?.name || x.p?.bairro || "Ponto")}')
$L.Add('                  </Link>')
$L.Add('                  <span style={{ fontWeight: 950 }}>✅ {x.confirm || 0}</span>')
$L.Add('                </div>')
$L.Add('              ))')
$L.Add('            )}')
$L.Add('          </div>')
$L.Add('          <div style={{ marginTop: 8, fontSize: 11, opacity: 0.6 }}>src: {pointsRes.src}</div>')
$L.Add('        </div>')
$L.Add('')
$L.Add('        <div style={box}>')
$L.Add('          <div style={h}>🧹 Mutirões recentes</div>')
$L.Add('          <div style={{ fontSize: 12, opacity: 0.75, marginBottom: 6 }}>Antes/depois + prova</div>')
$L.Add('          <div>')
$L.Add('            {computed.mutiroes.length === 0 ? (')
$L.Add('              <div style={{ fontSize: 12, opacity: 0.75 }}>Sem mutirões listados.</div>')
$L.Add('            ) : (')
$L.Add('              computed.mutiroes.map((m: any, idx: number) => (')
$L.Add('                <div key={idx} style={row}>')
$L.Add('                  <Link href={"/eco/mutiroes/" + String(m?.id || "")} style={a}>')
$L.Add('                    {String(m?.title || m?.bairro || "Mutirão")}')
$L.Add('                  </Link>')
$L.Add('                  <span style={{ fontWeight: 950, opacity: 0.9 }}>→</span>')
$L.Add('                </div>')
$L.Add('              ))')
$L.Add('            )}')
$L.Add('          </div>')
$L.Add('          <div style={{ marginTop: 8, fontSize: 11, opacity: 0.6 }}>src: {mutRes.src}</div>')
$L.Add('        </div>')
$L.Add('      </div>')
$L.Add('    </section>')
$L.Add('  );')
$L.Add('}')
$L.Add('')

WriteUtf8NoBom $clientComp ($L -join "`n")
Write-Host ('[PATCH] wrote ' + $clientComp)

# 2) Patch pages to use MuralTopBarClient
function PatchPage([string]$pagePath) {
  if (-not (Test-Path -LiteralPath $pagePath)) { return $false }
  $raw = ReadText $pagePath
  if (-not $raw) { return $false }

  $changed = $false
  $lines = $raw -split "`n"

  BackupFile $Root $pagePath $backupDir

  # Remove import MuralTopBar (server) if present
  $new = New-Object System.Collections.Generic.List[string]
  foreach ($ln in $lines) {
    if ($ln -match 'import\s+MuralTopBar\s+from\s+"\./_components/MuralTopBar"') { $changed = $true; continue }
    $new.Add($ln)
  }
  $lines = $new.ToArray()

  # Ensure import MuralTopBarClient exists
  $hasClientImport = $false
  foreach ($ln in $lines) { if ($ln -match 'MuralTopBarClient') { $hasClientImport = $true; break } }

  if (-not $hasClientImport) {
    $lastImport = -1
    for ($i=0; $i -lt $lines.Length; $i++) { if ($lines[$i].TrimStart().StartsWith("import ")) { $lastImport = $i } }
    if ($lastImport -ge 0) {
      $ins = New-Object System.Collections.Generic.List[string]
      for ($i=0; $i -lt $lines.Length; $i++) {
        $ins.Add($lines[$i])
        if ($i -eq $lastImport) {
          $ins.Add('import MuralTopBarClient from "./_components/MuralTopBarClient";')
          $changed = $true
        }
      }
      $lines = $ins.ToArray()
    } else {
      # no imports? add at top
      $lines = @('import MuralTopBarClient from "./_components/MuralTopBarClient";') + @('') + $lines
      $changed = $true
    }
  }

  # Replace component usage
  $repl = New-Object System.Collections.Generic.List[string]
  foreach ($ln in $lines) {
    if ($ln -match '<MuralTopBar\s*/>') { $repl.Add($ln.Replace('<MuralTopBar />','<MuralTopBarClient />')); $changed = $true; continue }
    if ($ln -match '<MuralTopBar>') { $repl.Add($ln.Replace('<MuralTopBar>','<MuralTopBarClient>')); $changed = $true; continue }
    $repl.Add($ln)
  }
  $lines = $repl.ToArray()

  # If page doesn't render top bar at all, insert under <main>
  $hasTop = $false
  foreach ($ln in $lines) { if ($ln -match 'MuralTopBarClient') { $hasTop = $true; break } }
  if (-not $hasTop) {
    $idxMain = -1
    for ($i=0; $i -lt $lines.Length; $i++) { if ($lines[$i] -match '<main\b') { $idxMain = $i; break } }
    if ($idxMain -ge 0) {
      $indent = ($lines[$idxMain] -replace '(^\s*).*','$1') + '  '
      $ins2 = New-Object System.Collections.Generic.List[string]
      for ($i=0; $i -lt $lines.Length; $i++) {
        $ins2.Add($lines[$i])
        if ($i -eq $idxMain) {
          $ins2.Add($indent + '<MuralTopBarClient />')
          $ins2.Add('')
          $changed = $true
        }
      }
      $lines = $ins2.ToArray()
    }
  }

  if ($changed) {
    WriteLines $pagePath $lines
    Write-Host ('[PATCH] patched ' + $pagePath)
    return $true
  } else {
    Write-Host ('[OK] no changes ' + $pagePath)
    return $false
  }
}

$muralPage = Join-Path $srcApp 'eco/mural/page.tsx'
$muralAcoesPage = Join-Path $srcApp 'eco/mural-acoes/page.tsx'

$didMural = PatchPage $muralPage
$didAcoes = PatchPage $muralAcoesPage

# 3) Report
$rep = Join-Path $reportDir ('eco-step-88-mural-topbar-client-v0_1-' + $ts + '.md')
$repLines = @(
'# eco-step-88-mural-topbar-client-v0_1',
'',
'- Time: ' + $ts,
'- Backup: ' + $backupDir,
'',
'## Files',
'- New: src/app/eco/mural/_components/MuralTopBarClient.tsx',
('- Patched mural page: ' + $didMural),
('- Patched mural-acoes page: ' + $didAcoes),
'',
'## What',
'- Topo fixo do Mural agora é client-side (fetch relativo /api), sem depender de NEXT_PUBLIC_BASE_URL.',
'- Evita problemas de SSR com URL absoluta e deixa o topo funcionar em dev/prod.',
'',
'## Verify',
'1) Ctrl+C -> npm run dev',
'2) Abrir /eco/mural',
'3) Topo fixo aparece e carrega itens',
'4) Abrir /eco/mural-acoes (se existir) e ver topo'
)
WriteUtf8NoBom $rep ($repLines -join "`n")
Write-Host ('[REPORT] ' + $rep)

Write-Host ""
Write-Host "[VERIFY] Ctrl+C -> npm run dev"
Write-Host "[VERIFY] /eco/mural -> topo fixo carrega sem precisar de baseUrl"
Write-Host "[VERIFY] /eco/mural-acoes (se houver) -> topo fixo também"