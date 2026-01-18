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

Write-Host ('== eco-step-84-mural-acoes-view-v0_1 == ' + $ts)
Write-Host ('[DIAG] Root: ' + $Root)

$srcApp = Join-Path $Root 'src/app'
if (-not (Test-Path -LiteralPath $srcApp)) { throw "[STOP] Nao achei src/app" }

$backupDir = Join-Path $Root ('tools/_patch_backup/' + $ts + '-eco-step-84-mural-acoes-view-v0_1')
$reportDir = Join-Path $Root 'reports'
EnsureDir $backupDir
EnsureDir $reportDir

# ---------- 1) Component: PointActionBar ----------
$comp = Join-Path $srcApp 'eco/_components/PointActionBar.tsx'
BackupFile $Root $comp $backupDir

$LComp = @(
'"use client";',
'',
'import React, { useMemo, useState } from "react";',
'',
'type Reactions = {',
'  confirm?: number;',
'  support?: number;',
'  call?: number;',
'  gratitude?: number;',
'  replicate?: number;',
'};',
'',
'function safeNum(v: any) {',
'  const n = Number(v || 0);',
'  return Number.isFinite(n) ? n : 0;',
'}',
'function btnStyle(bg: string) {',
'  return { padding: "9px 10px", borderRadius: 12, border: "1px solid #111", background: bg, fontWeight: 900, cursor: "pointer", whiteSpace: "nowrap" } as const;',
'}',
'',
'async function apiReact(id: string, action: string) {',
'  const r = await fetch("/api/eco/points/react", {',
'    method: "POST",',
'    headers: { "Content-Type": "application/json" },',
'    body: JSON.stringify({ id, action, inc: 1 }),',
'  });',
'  return await r.json().catch(() => ({ ok: false, error: "bad_json" }));',
'}',
'',
'export function PointActionBar(props: { pointId: string; initial?: any; compact?: boolean }) {',
'  const pointId = String(props.pointId || "");',
'  const compact = !!props.compact;',
'',
'  const init = useMemo(() => {',
'    const rx = props.initial && typeof props.initial === "object" ? props.initial : null;',
'    return {',
'      confirm: safeNum(rx?.confirm),',
'      support: safeNum(rx?.support),',
'      call: safeNum(rx?.call),',
'      gratitude: safeNum(rx?.gratitude),',
'      replicate: safeNum(rx?.replicate),',
'    } as Reactions;',
'  }, [props.initial]);',
'',
'  const [rx, setRx] = useState<Reactions>(init);',
'  const [toast, setToast] = useState("");',
'  const [busy, setBusy] = useState<string>("");',
'',
'  async function act(action: string, label: string) {',
'    if (!pointId) return;',
'    setBusy(action);',
'    try {',
'      const j: any = await apiReact(pointId, action);',
'      if (!j?.ok) throw new Error(String(j?.error || "falha"));',
'      const next = j.reactions || {};',
'      setRx({',
'        confirm: safeNum(next.confirm),',
'        support: safeNum(next.support),',
'        call: safeNum(next.call),',
'        gratitude: safeNum(next.gratitude),',
'        replicate: safeNum(next.replicate),',
'      });',
'      setToast(label + " ✅");',
'      setTimeout(() => setToast(""), 1100);',
'    } catch (e: any) {',
'      setToast("Falhou: " + String(e?.message || e));',
'      setTimeout(() => setToast(""), 1400);',
'    } finally {',
'      setBusy("");',
'    }',
'  }',
'',
'  const wrapStyle = compact',
'    ? ({ display: "flex", gap: 8, flexWrap: "wrap", alignItems: "center" } as const)',
'    : ({ display: "flex", gap: 10, flexWrap: "wrap", alignItems: "center" } as const);',
'',
'  return (',
'    <div style={{ display: "grid", gap: 8 }}>',
'      <div style={wrapStyle}>',
'        <button disabled={!!busy} onClick={() => act("confirm", "Confirmado")} style={btnStyle("#FFDD00")}>✅ Confirmar ({safeNum(rx.confirm)})</button>',
'        <button disabled={!!busy} onClick={() => act("support", "Apoiado")} style={btnStyle("#fff")}>🤝 Apoiar ({safeNum(rx.support)})</button>',
'        <button disabled={!!busy} onClick={() => act("call", "Chamado")} style={btnStyle("#fff")}>📣 Chamado ({safeNum(rx.call)})</button>',
'        <button disabled={!!busy} onClick={() => act("gratitude", "Gratidao")} style={btnStyle("#fff")}>🌱 Gratidao ({safeNum(rx.gratitude)})</button>',
'        <button disabled={!!busy} onClick={() => act("replicate", "Replicado")} style={btnStyle("#fff")}>♻️ Replicar ({safeNum(rx.replicate)})</button>',
'      </div>',
'      {toast ? (',
'        <div style={{ fontSize: 12, fontWeight: 900, opacity: 0.9 }}>{toast}</div>',
'      ) : null}',
'    </div>',
'  );',
'}',
''
) -join "`n"

WriteUtf8NoBom $comp $LComp
Write-Host "[PATCH] wrote src/app/eco/_components/PointActionBar.tsx"

# ---------- 2) New route: /eco/mural-acoes ----------
$page = Join-Path $srcApp 'eco/mural-acoes/page.tsx'
$client = Join-Path $srcApp 'eco/mural-acoes/MuralAcoesClient.tsx'
BackupFile $Root $page $backupDir
BackupFile $Root $client $backupDir

$LPage = @(
'import { MuralAcoesClient } from "./MuralAcoesClient";',
'',
'export const dynamic = "force-dynamic";',
'',
'export default function Page() {',
'  return (',
'    <main style={{ padding: 16, maxWidth: 1100, margin: "0 auto" }}>',
'      <h1 style={{ margin: "0 0 8px 0" }}>Mural do Cuidado (v0) — Acoes</h1>',
'      <p style={{ margin: "0 0 14px 0", opacity: 0.85 }}>',
'        Aqui as reacoes viram acoes (Confirmar, Apoiar, Chamado, Gratidao, Replicar).',
'      </p>',
'      <MuralAcoesClient />',
'    </main>',
'  );',
'}',
''
) -join "`n"

$LClient = @(
'"use client";',
'',
'import React, { useEffect, useMemo, useState } from "react";',
'import { PointActionBar } from "../_components/PointActionBar";',
'',
'type Item = {',
'  id: string;',
'  title?: string;',
'  status?: string;',
'  resolved?: boolean;',
'  bairro?: string;',
'  cidade?: string;',
'  lat?: number | null;',
'  lng?: number | null;',
'  meta?: any;',
'  data?: any;',
'  extra?: any;',
'};',
'',
'function pickReactions(it: any) {',
'  const m = it?.meta || it?.data || it?.extra || it?.payload || it?.details;',
'  if (m && m.reactions && typeof m.reactions === "object") return m.reactions;',
'  return (it?.reactions && typeof it.reactions === "object") ? it.reactions : null;',
'}',
'',
'async function fetchJson(url: string) {',
'  const r = await fetch(url, { cache: "no-store" });',
'  const j = await r.json().catch(() => null);',
'  return { ok: r.ok, status: r.status, json: j };',
'}',
'',
'async function fetchPointsAny() {',
'  const candidates = [',
'    "/api/eco/points/list?limit=60",',
'    "/api/eco/points/list?limit=50",',
'    "/api/eco/points?limit=60",',
'    "/api/eco/critical-points/list?limit=60",',
'    "/api/eco/critical-points?limit=60",',
'  ];',
'  for (const u of candidates) {',
'    const r = await fetchJson(u);',
'    const j: any = r.json;',
'    if (!j) continue;',
'    if (j.ok && (Array.isArray(j.items) || Array.isArray(j.list) || Array.isArray(j.points))) {',
'      const arr = (j.items || j.list || j.points) as any[];',
'      return { ok: true, url: u, items: arr };',
'    }',
'    // alguns endpoints devolvem direto array',
'    if (Array.isArray(j)) return { ok: true, url: u, items: j as any[] };',
'  }',
'  return { ok: false, url: "", items: [] as any[] };',
'}',
'',
'export function MuralAcoesClient() {',
'  const [loading, setLoading] = useState(true);',
'  const [err, setErr] = useState("");',
'  const [items, setItems] = useState<Item[]>([]);',
'  const [src, setSrc] = useState("");',
'',
'  useEffect(() => {',
'    let alive = true;',
'    (async () => {',
'      setLoading(true); setErr("");',
'      try {',
'        const r = await fetchPointsAny();',
'        if (!r.ok) throw new Error("Nao achei endpoint de lista de pontos (points/list).");',
'        if (!alive) return;',
'        setSrc(r.url);',
'        const mapped = (r.items || []).map((x: any) => ({',
'          id: String(x?.id || ""),',
'          title: x?.title || x?.name || x?.descricao || x?.desc || "Ponto",',
'          status: x?.status || x?.state || "OPEN",',
'          resolved: !!(x?.resolved || x?.isResolved),',
'          bairro: x?.bairro || x?.neighborhood || x?.bairroName,',
'          cidade: x?.cidade || x?.city || "Volta Redonda",',
'          lat: (typeof x?.lat === "number") ? x.lat : null,',
'          lng: (typeof x?.lng === "number") ? x.lng : null,',
'          meta: x?.meta,',
'          data: x?.data,',
'          extra: x?.extra,',
'        })) as Item[];',
'        setItems(mapped.filter((m) => !!m.id));',
'      } catch (e: any) {',
'        if (!alive) return;',
'        setErr(String(e?.message || e));',
'      } finally {',
'        if (!alive) return;',
'        setLoading(false);',
'      }',
'    })();',
'    return () => { alive = false; };',
'  }, []);',
'',
'  const header = useMemo(() => {',
'    if (!src) return "";',
'    return "Fonte: " + src;',
'  }, [src]);',
'',
'  return (',
'    <section style={{ display: "grid", gap: 14 }}>',
'      {loading ? <div style={{ opacity: 0.85 }}>Carregando…</div> : null}',
'      {err ? <div style={{ padding: 12, border: "1px solid #111", borderRadius: 14, background: "#fff2f2" }}><b>Erro:</b> {err}</div> : null}',
'      {header ? <div style={{ fontSize: 12, opacity: 0.7 }}>{header}</div> : null}',
'',
'      <div style={{ display: "grid", gap: 12 }}>',
'        {items.map((p) => {',
'          const place = (p.bairro ? (p.bairro + " — " + (p.cidade || "Volta Redonda")) : (p.cidade || "Volta Redonda"));',
'          const tag = p.resolved ? "RESOLVIDO" : (p.status || "OPEN");',
'          const shareHref = "/eco/share/ponto/" + encodeURIComponent(p.id);',
'          const initialRx = pickReactions(p);',
'          return (',
'            <div key={p.id} style={{ border: "1px solid #111", borderRadius: 16, padding: 12, background: "#fff", display: "grid", gap: 10 }}>',
'              <div style={{ display: "flex", justifyContent: "space-between", gap: 10, alignItems: "baseline", flexWrap: "wrap" }}>',
'                <div style={{ display: "grid", gap: 6 }}>',
'                  <div style={{ fontWeight: 950, fontSize: 16 }}>{p.title || "Ponto"}</div>',
'                  <div style={{ fontSize: 13, opacity: 0.8, fontWeight: 850 }}>{place}</div>',
'                  <div style={{ fontSize: 12, opacity: 0.7 }}>ID: {p.id}</div>',
'                </div>',
'                <div style={{ padding: "8px 12px", borderRadius: 999, border: "1px solid #111", background: p.resolved ? "#B7FFB7" : "#FFDD00", fontWeight: 950 }}>',
'                  {tag}',
'                </div>',
'              </div>',
'',
'              <PointActionBar pointId={p.id} initial={initialRx} />',
'',
'              <div style={{ display: "flex", gap: 10, flexWrap: "wrap" }}>',
'                <a href={shareHref} style={{ padding: "9px 10px", borderRadius: 12, border: "1px solid #111", textDecoration: "none", color: "#111", fontWeight: 900, background: "#fff" }}>',
'                  Abrir compartilhar',
'                </a>',
'              </div>',
'            </div>',
'          );',
'        })}',
'      </div>',
'',
'      {!loading && !err && items.length === 0 ? (',
'        <div style={{ opacity: 0.8 }}>Nenhum ponto encontrado ainda.</div>',
'      ) : null}',
'    </section>',
'  );',
'}',
''
) -join "`n"

WriteUtf8NoBom $page $LPage
WriteUtf8NoBom $client $LClient
Write-Host "[PATCH] wrote /eco/mural-acoes route"

# ---------- REPORT ----------
$rep = Join-Path $reportDir ('eco-step-84-mural-acoes-view-v0_1-' + $ts + '.md')
$repLines = @(
'# eco-step-84-mural-acoes-view-v0_1',
'',
'- Time: ' + $ts,
'- Backup: ' + $backupDir,
'',
'## Added/Updated',
'- src/app/eco/_components/PointActionBar.tsx',
'- src/app/eco/mural-acoes/page.tsx',
'- src/app/eco/mural-acoes/MuralAcoesClient.tsx',
'',
'## Verify',
'1) Ctrl+C -> npm run dev',
'2) Abra /eco/mural-acoes',
'3) Clique Confirmar/Apoiar/Chamado/Gratidao/Replicar',
'4) Abra /eco/share/ponto/[id] e veja os mesmos contadores (persistencia no meta)'
)
WriteUtf8NoBom $rep ($repLines -join "`n")
Write-Host ('[REPORT] ' + $rep)

Write-Host ""
Write-Host "[VERIFY] Ctrl+C -> npm run dev"
Write-Host "[VERIFY] Abra /eco/mural-acoes e teste os botoes"