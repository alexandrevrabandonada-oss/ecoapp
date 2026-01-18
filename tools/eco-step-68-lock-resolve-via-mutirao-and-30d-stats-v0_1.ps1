param(
  [string]$Root = (Get-Location).Path
)

$ts = Get-Date -Format 'yyyyMMdd-HHmmss'

# --- bootstrap
$boot = Join-Path $Root "tools/_bootstrap.ps1"
if (Test-Path -LiteralPath $boot) { . $boot }

# --- fallbacks (LiteralPath-safe)
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
function WriteLines([string]$p, [string[]]$lines) { WriteUtf8NoBom $p ($lines -join "`n") }

$backupDir = Join-Path $Root ('tools/_patch_backup/' + $ts + '-eco-step-68-lock-resolve-via-mutirao-and-30d-stats-v0_1')
$reportDir = Join-Path $Root 'reports'
EnsureDir $backupDir
EnsureDir $reportDir

Write-Host ('== eco-step-68-lock-resolve-via-mutirao-and-30d-stats-v0_1 == ' + $ts)
Write-Host ('[DIAG] Root: ' + $Root)

$src = Join-Path $Root 'src'
if (-not (Test-Path -LiteralPath $src)) { throw ('[STOP] Não achei src/: ' + $src) }

# ------------------------------------------------------------
# 1) API: /api/eco/points/stats (30 dias)
# ------------------------------------------------------------
$apiStats = Join-Path $Root 'src/app/api/eco/points/stats/route.ts'
BackupFile $Root $apiStats $backupDir
EnsureDir (Split-Path -Parent $apiStats)

$LApiStats = @(
'import { NextResponse } from "next/server";',
'import { prisma } from "@/lib/prisma";',
'',
'export const runtime = "nodejs";',
'export const dynamic = "force-dynamic";',
'',
'function asMsg(e: unknown) {',
'  if (e instanceof Error) return e.message;',
'  try { return String(e); } catch { return "unknown"; }',
'}',
'function looksLikeMissingTable(msg: string) {',
'  const m = msg.toLowerCase();',
'  return m.includes("does not exist") || m.includes("no such table") || m.includes("p2021");',
'}',
'function getPointModel() {',
'  const pc: any = prisma as any;',
'  const candidates = ["ecoPoint", "ecoCriticalPoint", "criticalPoint", "ecoPonto", "ponto", "ecoPontoCritico"];',
'  for (const k of candidates) {',
'    const m = pc?.[k];',
'    if (m && typeof m.findMany === "function") return { key: k, model: m as any };',
'  }',
'  return null;',
'}',
'function normStatus(v: any) {',
'  const t = String(v || "").trim().toUpperCase();',
'  if (!t) return "UNKNOWN";',
'  if (t === "ABERTO") return "OPEN";',
'  if (t === "RESOLVIDO") return "RESOLVED";',
'  if (t === "DONE") return "RESOLVED";',
'  return t;',
'}',
'function pickBairro(row: any) {',
'  return String(row?.bairro || row?.neighborhood || row?.area || row?.regiao || row?.region || "").trim();',
'}',
'',
'export async function GET(req: Request) {',
'  const { searchParams } = new URL(req.url);',
'  const days = Math.max(1, Math.min(365, Number(searchParams.get("days") || 30) || 30));',
'  const bairro = String(searchParams.get("bairro") || "").trim();',
'',
'  const pm = getPointModel();',
'  if (!pm?.model) return NextResponse.json({ ok: false, error: "model_not_ready" }, { status: 503 });',
'',
'  const end = new Date();',
'  const start = new Date(end.getTime() - days * 24 * 60 * 60 * 1000);',
'',
'  try {',
'    let rows: any[] = [];',
'    // Tentativa 1: filtra por createdAt (se existir)',
'    try {',
'      rows = await pm.model.findMany({',
'        where: { createdAt: { gte: start, lte: end } },',
'        take: 5000,',
'        orderBy: { createdAt: "desc" },',
'      });',
'    } catch {',
'      // fallback: traz (dev) e filtra no JS se conseguir',
'      rows = await pm.model.findMany({ take: 5000 }).catch(() => []);',
'    }',
'',
'    // filtros JS (bairro + janela por createdAt/updatedAt se existirem)',
'    const out: any[] = [];',
'    for (const r of rows) {',
'      if (bairro) {',
'        const b = pickBairro(r);',
'        if (!b || b.toLowerCase() !== bairro.toLowerCase()) continue;',
'      }',
'      const ca = (r as any)?.createdAt ? new Date((r as any).createdAt) : null;',
'      const ua = (r as any)?.updatedAt ? new Date((r as any).updatedAt) : null;',
'      const inWindow = (ca && ca >= start && ca <= end) || (ua && ua >= start && ua <= end) || (!ca && !ua);',
'      if (!inWindow) continue;',
'      out.push(r);',
'    }',
'',
'    const byStatus: Record<string, number> = {};',
'    let open = 0;',
'    let resolved = 0;',
'    for (const r of out) {',
'      const st = normStatus((r as any)?.status);',
'      byStatus[st] = (byStatus[st] || 0) + 1;',
'      if (st === "OPEN") open += 1;',
'      if (st === "RESOLVED") resolved += 1;',
'    }',
'',
'    return NextResponse.json({',
'      ok: true,',
'      windowDays: days,',
'      start: start.toISOString(),',
'      end: end.toISOString(),',
'      bairro: bairro || null,',
'      totals: { total: out.length, open, resolved },',
'      byStatus,',
'      meta: { pointModel: pm.key, sample: out.slice(0, 1).map((x) => ({ id: (x as any)?.id, status: (x as any)?.status })) },',
'    });',
'  } catch (e) {',
'    const msg = asMsg(e);',
'    if (looksLikeMissingTable(msg)) return NextResponse.json({ ok: false, error: "db_not_ready", detail: msg }, { status: 503 });',
'    return NextResponse.json({ ok: false, error: "db_error", detail: msg }, { status: 500 });',
'  }',
'}',
''
)
WriteLines $apiStats $LApiStats
Write-Host "[PATCH] wrote /api/eco/points/stats"

# ------------------------------------------------------------
# 2) Widget: EcoPoints30dWidget
# ------------------------------------------------------------
$widget = Join-Path $Root 'src/app/eco/_components/EcoPoints30dWidget.tsx'
BackupFile $Root $widget $backupDir
EnsureDir (Split-Path -Parent $widget)

$LWidget = @(
'"use client";',
'',
'import { useEffect, useState } from "react";',
'',
'export default function EcoPoints30dWidget(props: { days?: number; bairro?: string }) {',
'  const days = props?.days ?? 30;',
'  const bairro = props?.bairro || "";',
'  const [data, setData] = useState<any>(null);',
'  const [err, setErr] = useState<string | null>(null);',
'  const [loading, setLoading] = useState<boolean>(false);',
'',
'  async function load() {',
'    setLoading(true);',
'    setErr(null);',
'    try {',
'      const qs = new URLSearchParams();',
'      qs.set("days", String(days));',
'      if (bairro) qs.set("bairro", bairro);',
'      const res = await fetch("/api/eco/points/stats?" + qs.toString(), { cache: "no-store" } as any);',
'      const j = await res.json().catch(() => null);',
'      if (!res.ok || !j?.ok) throw new Error(j?.detail || j?.error || ("HTTP " + res.status));',
'      setData(j);',
'    } catch (e: any) {',
'      setErr(e?.message || String(e));',
'    } finally {',
'      setLoading(false);',
'    }',
'  }',
'',
'  useEffect(() => { void load(); }, [days, bairro]);',
'',
'  const t = data?.totals;',
'  const open = Number(t?.open || 0);',
'  const resolved = Number(t?.resolved || 0);',
'  const total = Number(t?.total || 0);',
'  const ratio = total > 0 ? Math.round((resolved / total) * 100) : 0;',
'',
'  return (',
'    <section style={{ margin: "14px 0", padding: 12, border: "1px solid #e5e5e5", borderRadius: 12, background: "#fff" }}>',
'      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", gap: 10 }}>',
'        <div style={{ fontWeight: 900 }}>Vitrine (últimos {days} dias): Pontos</div>',
'        <button onClick={() => void load()} disabled={loading} style={{ padding: "6px 10px", borderRadius: 10, border: "1px solid #ccc", background: "#fff" }}>',
'          Atualizar',
'        </button>',
'      </div>',
'',
'      <div style={{ marginTop: 6, opacity: 0.75, fontSize: 12 }}>',
'        {bairro ? ("Bairro: " + bairro) : "Cidade (geral)"}',
'      </div>',
'',
'      {err ? <div style={{ marginTop: 10, color: "#b00020" }}>{err}</div> : null}',
'',
'      <div style={{ marginTop: 10, display: "grid", gridTemplateColumns: "repeat(3, minmax(0, 1fr))", gap: 10 }}>',
'        <div style={{ padding: 10, borderRadius: 12, border: "1px solid #111" }}>',
'          <div style={{ fontSize: 12, opacity: 0.75 }}>Abertos</div>',
'          <div style={{ fontSize: 28, fontWeight: 900 }}>{open}</div>',
'        </div>',
'        <div style={{ padding: 10, borderRadius: 12, border: "1px solid #111" }}>',
'          <div style={{ fontSize: 12, opacity: 0.75 }}>Resolvidos</div>',
'          <div style={{ fontSize: 28, fontWeight: 900 }}>{resolved}</div>',
'        </div>',
'        <div style={{ padding: 10, borderRadius: 12, border: "1px solid #111" }}>',
'          <div style={{ fontSize: 12, opacity: 0.75 }}>Taxa</div>',
'          <div style={{ fontSize: 28, fontWeight: 900 }}>{ratio}%</div>',
'        </div>',
'      </div>',
'',
'      <div style={{ marginTop: 10, opacity: 0.8, fontSize: 12 }}>',
'        Regra política do ECO: <b>ponto só vira “resolvido” com mutirão finalizado (DONE)</b>. Recibo é lei.',
'      </div>',
'    </section>',
'  );',
'}',
''
)
WriteLines $widget $LWidget
Write-Host "[PATCH] wrote EcoPoints30dWidget.tsx"

# ------------------------------------------------------------
# 3) Patch: tenta inserir widget em uma página do /eco
#    (preferência: /eco/pontos -> /eco/fechamento -> /eco)
# ------------------------------------------------------------
function TryPatchPage([string]$file) {
  if (-not (Test-Path -LiteralPath $file)) { return $false }
  $raw = Get-Content -Raw -LiteralPath $file
  if (-not $raw) { return $false }
  if ($raw -match 'EcoPoints30dWidget') { return $true }

  BackupFile $Root $file $backupDir

  $importLine = 'import EcoPoints30dWidget from "@/app/eco/_components/EcoPoints30dWidget";'
  if ($raw -notmatch [regex]::Escape($importLine)) {
    $m = [regex]::Matches($raw, '^\s*import[^\n]*\n', [System.Text.RegularExpressions.RegexOptions]::Multiline)
    if ($m.Count -gt 0) {
      $last = $m[$m.Count - 1]
      $pos = $last.Index + $last.Length
      $raw = $raw.Insert($pos, $importLine + "`n")
    } else {
      $raw = $importLine + "`n" + $raw
    }
  }

  $ins = "`n      <EcoPoints30dWidget />`n"
  $idxMain = $raw.IndexOf("<main")
  if ($idxMain -ge 0) {
    $gt = $raw.IndexOf(">", $idxMain)
    if ($gt -ge 0) { $raw = $raw.Insert($gt + 1, $ins) }
  } else {
    $idxRet = $raw.IndexOf("return (")
    if ($idxRet -ge 0) {
      $pos = $idxRet + 8
      $raw = $raw.Insert($pos, $ins)
    }
  }

  WriteUtf8NoBom $file $raw
  Write-Host ("[PATCH] inserted EcoPoints30dWidget in: " + $file)
  return $true
}

$patchedPage = $null
$candidates = @(
  (Join-Path $Root 'src/app/eco/pontos/page.tsx'),
  (Join-Path $Root 'src/app/eco/fechamento/page.tsx'),
  (Join-Path $Root 'src/app/eco/page.tsx')
)
foreach ($c in $candidates) {
  if (TryPatchPage $c) { $patchedPage = $c; break }
}
if (-not $patchedPage) {
  Write-Host "[WARN] Não consegui patchar automaticamente uma page.tsx. (Widget criado; você pode inserir manualmente.)"
}

# ------------------------------------------------------------
# 4) Trava anti-gambiarra: bloquear RESOLVED/DONE em rotas de UPDATE de ponto
#    (best-effort: só em arquivos que já possuem POST e leem body)
# ------------------------------------------------------------
function PatchResolveGuard([string]$file) {
  $raw = Get-Content -Raw -LiteralPath $file
  if (-not $raw) { return $false }
  if ($raw -match 'resolve_via_mutirao') { return $false }
  if ($raw -notmatch 'export\s+async\s+function\s+POST') { return $false }
  if ($raw -notmatch 'NextResponse') { return $false }

  $bodyMatch = [regex]::Match($raw, 'const\s+body\s*=\s*\(await\s+req\.json\(\)\.catch\(\(\)\s*=>\s*null\)\)\s+as\s+any;|const\s+body\s*=\s*await\s+req\.json\(\)\.catch\(\(\)\s*=>\s*null\)\s+as\s+any;')
  if (-not $bodyMatch.Success) { return $false }

  BackupFile $Root $file $backupDir

  $guard =
"`n  const __st = String((body as any)?.status || `"`").toUpperCase();`n" +
"  if (__st === `"RESOLVED`" || __st === `"DONE`") {`n" +
"    return NextResponse.json({ ok: false, error: `"resolve_via_mutirao`", hint: `"Para resolver um ponto, finalize um mutirão (DONE) ligado a ele.`" }, { status: 400 });`n" +
"  }`n"

  $insertPos = $bodyMatch.Index + $bodyMatch.Length
  $raw2 = $raw.Insert($insertPos, $guard)

  WriteUtf8NoBom $file $raw2
  Write-Host ("[PATCH] resolve guard inserted: " + $file)
  return $true
}

$apiEco = Join-Path $Root 'src/app/api/eco'
$guarded = @()
if (Test-Path -LiteralPath $apiEco) {
  $routes = Get-ChildItem -LiteralPath $apiEco -Recurse -File -Filter route.ts |
    Where-Object {
      $_.FullName -match '\\(point|ponto|critical|pontos|points)\\' -and $_.FullName -match '\\(update|edit|set|status)\\'
    }

  foreach ($r in $routes) {
    try {
      if (PatchResolveGuard $r.FullName) { $guarded += $r.FullName }
    } catch {
      Write-Host ("[WARN] guard patch failed: " + $r.FullName)
    }
  }
}

# ------------------------------------------------------------
# REPORT
# ------------------------------------------------------------
$rep = Join-Path $reportDir ('eco-step-68-lock-resolve-via-mutirao-and-30d-stats-v0_1-' + $ts + '.md')
$repLines = @(
'# eco-step-68-lock-resolve-via-mutirao-and-30d-stats-v0_1',
'',
'- Time: ' + $ts,
'- Backup: ' + $backupDir,
'- API: src/app/api/eco/points/stats/route.ts',
'- Widget: src/app/eco/_components/EcoPoints30dWidget.tsx',
'- Patched page: ' + ($(if ($patchedPage) { $patchedPage } else { '(none)' })),
'- Guarded update routes (best-effort): ' + ($guarded.Count),
''
)
if ($guarded.Count -gt 0) {
  $repLines += ''
  $repLines += '## Guarded routes'
  foreach ($g in $guarded) { $repLines += ('- ' + $g) }
}
$repLines += ''
$repLines += '## Verify'
$repLines += '1) Ctrl+C -> npm run dev'
$repLines += '2) GET /api/eco/points/stats?days=30 -> ok:true'
$repLines += '3) Abra a página patchada e veja a “Vitrine (últimos 30 dias)”'
$repLines += '4) Se existir rota de update que tentava setar status=RESOLVED, agora deve dar error resolve_via_mutirao'
$repLines += ''
WriteUtf8NoBom $rep ($repLines -join "`n")
Write-Host ('[REPORT] ' + $rep)

Write-Host ''
Write-Host '[VERIFY] Ctrl+C -> npm run dev'
Write-Host '[VERIFY] Teste API: irm "http://localhost:3000/api/eco/points/stats?days=30" -Headers @{Accept="application/json"}'
Write-Host '[VERIFY] Abra a página /eco (ou /eco/fechamento ou /eco/pontos) e veja a Vitrine.'
Write-Host '[VERIFY] Regra: ponto RESOLVED só via mutirão DONE (trava em rotas de update, se existirem).'