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

# ---------- setup ----------
$backupDir = Join-Path $Root ('tools/_patch_backup/' + $ts + '-eco-step-81-mural-do-cuidado-pontos-v0_1')
$reportDir = Join-Path $Root 'reports'
EnsureDir $backupDir
EnsureDir $reportDir

Write-Host ('== eco-step-81-mural-do-cuidado-pontos-v0_1 == ' + $ts)
Write-Host ('[DIAG] Root: ' + $Root)

$srcApp = Join-Path $Root 'src/app'
if (-not (Test-Path -LiteralPath $srcApp)) { throw "[STOP] Nao achei src/app" }

# detect base folder: pontos vs points
$base = $null
$tryPontos = Join-Path $srcApp 'eco/pontos'
$tryPoints = Join-Path $srcApp 'eco/points'
if (Test-Path -LiteralPath $tryPontos) { $base = 'pontos' }
elseif (Test-Path -LiteralPath $tryPoints) { $base = 'points' }
else { $base = 'pontos' } # default, nao quebra /eco/mural

Write-Host ('[DIAG] Base folder selected: ' + $base)

# ---------- API: /api/eco/points/list (create only if missing) ----------
$apiList = Join-Path $srcApp 'api/eco/points/list/route.ts'
if (Test-Path -LiteralPath $apiList) {
  Write-Host "[SKIP] api/eco/points/list already exists"
} else {
  $apiListDir = Split-Path -Parent $apiList
  EnsureDir $apiListDir

  $LApi = @(
'// ECO — points/list — v0.1 (normalized, schema-agnostic)',
'',
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
'  const candidates = [',
'    "ecoCriticalPoint",',
'    "criticalPoint",',
'    "ecoPoint",',
'    "point",',
'    "ecoCriticalPoints",',
'    "ecoPoints",',
'  ];',
'  for (const k of candidates) {',
'    const m = pc?.[k];',
'    if (m && typeof m.findMany === "function") return { key: k, model: m as any };',
'  }',
'  return null;',
'}',
'function normStatus(v: any) { return String(v || "").trim().toUpperCase(); }',
'function pickStatus(p: any) {',
'  const m = (p && p.meta && typeof p.meta === "object") ? p.meta : null;',
'  return normStatus(p?.status || p?.state || (m && (m.status || m.state)) || "");',
'}',
'function isResolved(s: string) {',
'  const t = normStatus(s);',
'  return t === "RESOLVED" || t === "RESOLVIDO" || t === "DONE" || t === "CLOSED" || t === "FINALIZADO";',
'}',
'function pickTitle(p: any) { return String(p?.title || p?.name || p?.label || p?.kind || "Ponto critico"); }',
'function pickNeighborhood(p: any) {',
'  const m = (p && p.meta && typeof p.meta === "object") ? p.meta : null;',
'  return String(p?.bairro || p?.neighborhood || (m && (m.bairro || m.neighborhood)) || "").trim();',
'}',
'function pickCity(p: any) {',
'  const m = (p && p.meta && typeof p.meta === "object") ? p.meta : null;',
'  return String(p?.cidade || p?.city || (m && (m.cidade || m.city)) || "Volta Redonda").trim();',
'}',
'function pickLat(p: any) {',
'  const m = (p && p.meta && typeof p.meta === "object") ? p.meta : null;',
'  const v = p?.lat ?? p?.latitude ?? (m && (m.lat ?? m.latitude));',
'  const n = Number(v);',
'  return Number.isFinite(n) ? n : null;',
'}',
'function pickLng(p: any) {',
'  const m = (p && p.meta && typeof p.meta === "object") ? p.meta : null;',
'  const v = p?.lng ?? p?.lon ?? p?.longitude ?? (m && (m.lng ?? m.lon ?? m.longitude));',
'  const n = Number(v);',
'  return Number.isFinite(n) ? n : null;',
'}',
'function pickCreatedAt(p: any) {',
'  const v = p?.createdAt || p?.created_at || null;',
'  try { return v ? new Date(v).toISOString() : null; } catch { return null; }',
'}',
'function pickUpdatedAt(p: any) {',
'  const v = p?.updatedAt || p?.updated_at || null;',
'  try { return v ? new Date(v).toISOString() : null; } catch { return null; }',
'}',
'function safeInt(v: string | null, def: number) {',
'  const n = Number(v);',
'  if (!Number.isFinite(n)) return def;',
'  return Math.max(1, Math.min(200, Math.floor(n)));',
'}',
'',
'export async function GET(req: Request) {',
'  const { searchParams } = new URL(req.url);',
'  const limit = safeInt(searchParams.get("limit"), 80);',
'  const status = normStatus(searchParams.get("status") || ""); // OPEN|RESOLVED|ALL',
'  const bairro = String(searchParams.get("bairro") || "").trim().toLowerCase();',
'  const q = String(searchParams.get("q") || "").trim().toLowerCase();',
'',
'  const mm = getPointModel();',
'  if (!mm?.model) return NextResponse.json({ ok: false, error: "model_not_ready" }, { status: 503 });',
'',
'  try {',
'    let rows: any[] = [];',
'    try {',
'      rows = await mm.model.findMany({ take: limit, orderBy: { createdAt: "desc" } });',
'    } catch {',
'      rows = await mm.model.findMany({ take: limit });',
'    }',
'',
'    let items = rows.map((p: any) => {',
'      const st = pickStatus(p);',
'      return {',
'        id: String(p?.id || ""),',
'        title: pickTitle(p),',
'        status: st || "OPEN",',
'        resolved: isResolved(st),',
'        bairro: pickNeighborhood(p),',
'        cidade: pickCity(p),',
'        lat: pickLat(p),',
'        lng: pickLng(p),',
'        createdAt: pickCreatedAt(p),',
'        updatedAt: pickUpdatedAt(p),',
'        raw: p,',
'      };',
'    }).filter((x: any) => x.id);',
'',
'    if (status && status !== "ALL") {',
'      if (status === "OPEN") items = items.filter((x: any) => !x.resolved);',
'      else if (status === "RESOLVED") items = items.filter((x: any) => x.resolved);',
'      else items = items.filter((x: any) => normStatus(x.status) === status);',
'    }',
'    if (bairro) items = items.filter((x: any) => String(x.bairro || "").toLowerCase().includes(bairro));',
'    if (q) items = items.filter((x: any) => (String(x.title || "") + " " + String(x.bairro || "") + " " + String(x.cidade || "")).toLowerCase().includes(q));',
'',
'    // drop raw to keep payload clean',
'    items = items.map((x: any) => { const { raw, ...rest } = x; return rest; });',
'',
'    return NextResponse.json({ ok: true, items, model: mm.key });',
'  } catch (e) {',
'    const msg = asMsg(e);',
'    if (looksLikeMissingTable(msg)) return NextResponse.json({ ok: false, error: "db_not_ready", detail: msg }, { status: 503 });',
'    return NextResponse.json({ ok: false, error: "db_error", detail: msg }, { status: 500 });',
'  }',
'}',
''
) -join "`n"

  WriteUtf8NoBom $apiList $LApi
  Write-Host "[PATCH] wrote src/app/api/eco/points/list/route.ts"
}

# ---------- UI: /eco/mural ----------
$muralDir = Join-Path $srcApp 'eco/mural'
$pageFile = Join-Path $muralDir 'page.tsx'
$clientFile = Join-Path $muralDir 'MuralClient.tsx'

BackupFile $Root $pageFile $backupDir
BackupFile $Root $clientFile $backupDir

$LPage = @(
'// ECO — Mural do Cuidado — v0.1',
'',
'import { MuralClient } from "./MuralClient";',
'',
'export const runtime = "nodejs";',
'export const dynamic = "force-dynamic";',
'',
'export default async function Page({ params }: any) {',
'  await (params as any);',
'  return (',
'    <main style={{ padding: 16, maxWidth: 1200, margin: "0 auto" }}>',
'      <div style={{ display: "flex", alignItems: "baseline", justifyContent: "space-between", gap: 12, flexWrap: "wrap" }}>',
'        <h1 style={{ margin: "0 0 8px 0" }}>Mural do Cuidado</h1>',
'        <div style={{ opacity: 0.8, fontWeight: 800 }}>Sem likes. Reacao vira acao.</div>',
'      </div>',
'      <p style={{ margin: "0 0 14px 0", opacity: 0.85 }}>',
'        Pontos criticos por bairro. Confirme, apoie, compartilhe e organize.',
'      </p>',
('      <MuralClient base="' + $base + '" />'),
'    </main>',
'  );',
'}',
''
) -join "`n"

$LClient = @(
'"use client";',
'',
'import React, { useEffect, useMemo, useState } from "react";',
'',
'type Item = {',
'  id: string;',
'  title: string;',
'  status: string;',
'  resolved: boolean;',
'  bairro?: string;',
'  cidade?: string;',
'  lat?: number | null;',
'  lng?: number | null;',
'  createdAt?: string | null;',
'  updatedAt?: string | null;',
'};',
'',
'type ListResp = { ok: boolean; items?: Item[]; error?: string; detail?: any; model?: string };',
'',
'function pillStyle(bg: string) {',
'  return { padding: "6px 10px", borderRadius: 999, border: "1px solid #111", background: bg, fontWeight: 900, fontSize: 12 } as const;',
'}',
'',
'async function apiList(status: string, bairro: string, q: string) {',
'  const sp = new URLSearchParams();',
'  sp.set("limit", "120");',
'  if (status) sp.set("status", status);',
'  if (bairro) sp.set("bairro", bairro);',
'  if (q) sp.set("q", q);',
'  const r = await fetch("/api/eco/points/list?" + sp.toString(), { cache: "no-store" });',
'  return (await r.json().catch(() => ({ ok: false, error: "bad_json" }))) as ListResp;',
'}',
'',
'async function apiConfirm(id: string) {',
'  // usa endpoint existente do projeto (criado antes): /api/eco/points/confirm',
'  const url = "/api/eco/points/confirm?id=" + encodeURIComponent(id);',
'  const r = await fetch(url, {',
'    method: "POST",',
'    headers: { "content-type": "application/json" },',
'    body: JSON.stringify({ id }),',
'  });',
'  return await r.json().catch(() => ({ ok: false, error: "bad_json" }));',
'}',
'',
'export function MuralClient(props: { base: string }) {',
'  const base = String(props.base || "pontos");',
'  const [status, setStatus] = useState<string>("OPEN");',
'  const [bairro, setBairro] = useState<string>("");',
'  const [q, setQ] = useState<string>("");',
'  const [loading, setLoading] = useState<boolean>(true);',
'  const [err, setErr] = useState<string>("");',
'  const [items, setItems] = useState<Item[]>([]);',
'  const [model, setModel] = useState<string>("");',
'  const [toast, setToast] = useState<string>("");',
'  const [mounted, setMounted] = useState(false);',
'  const [origin, setOrigin] = useState("");',
'',
'  useEffect(() => {',
'    setMounted(true);',
'    try { setOrigin(window.location.origin || ""); } catch {}',
'  }, []);',
'',
'  const reload = async () => {',
'    setLoading(true); setErr("");',
'    try {',
'      const j = await apiList(status, bairro, q);',
'      if (!j.ok) throw new Error(j.error || "erro_list");',
'      setItems(j.items || []);',
'      setModel(String(j.model || ""));',
'    } catch (e: any) {',
'      setErr(String(e?.message || e));',
'    } finally {',
'      setLoading(false);',
'    }',
'  };',
'',
'  useEffect(() => {',
'    let alive = true;',
'    (async () => {',
'      await reload();',
'    })();',
'    return () => { alive = false; };',
'    // eslint-disable-next-line react-hooks/exhaustive-deps',
'  }, []);',
'',
'  const headerInfo = useMemo(() => {',
'    const open = items.filter(i => !i.resolved).length;',
'    const resolved = items.filter(i => i.resolved).length;',
'    return { open, resolved, total: items.length };',
'  }, [items]);',
'',
'  const shareUrlFor = useMemo(() => {',
'    return (id: string) => {',
'      const path = "/eco/share/ponto/" + encodeURIComponent(id);',
'      return origin ? (origin + path) : path;',
'    };',
'  }, [origin]);',
'',
'  async function doConfirm(id: string) {',
'    try {',
'      const j: any = await apiConfirm(id);',
'      if (!j?.ok) throw new Error(String(j?.error || "nao_confirmou"));',
'      setToast("Confirmado");',
'      setTimeout(() => setToast(""), 1200);',
'      await reload();',
'    } catch (e: any) {',
'      setToast("Falha: " + String(e?.message || e));',
'      setTimeout(() => setToast(""), 1600);',
'    }',
'  }',
'',
'  function btnStyle(bg: string) {',
'    return { padding: "9px 10px", borderRadius: 12, border: "1px solid #111", background: bg, fontWeight: 900, cursor: "pointer" } as const;',
'  }',
'',
'  return (',
'    <section style={{ display: "grid", gap: 14 }}>',
'      <div style={{ display: "flex", gap: 10, flexWrap: "wrap", alignItems: "center" }}>',
'        <div style={{ display: "flex", gap: 10, flexWrap: "wrap", alignItems: "center" }}>',
'          <span style={pillStyle("#FFDD00")}>ABERTOS: {headerInfo.open}</span>',
'          <span style={pillStyle("#B7FFB7")}>RESOLVIDOS: {headerInfo.resolved}</span>',
'          <span style={pillStyle("#fff")}>TOTAL: {headerInfo.total}</span>',
'        </div>',
'        <div style={{ flex: 1, display: "flex" }} />',
'        {model ? <span style={{ fontSize: 12, opacity: 0.7, fontWeight: 800 }}>model: {model}</span> : null}',
'      </div>',
'',
'      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr auto", gap: 10, alignItems: "end" }}>',
'        <div style={{ display: "grid", gap: 6 }}>',
'          <div style={{ fontWeight: 900 }}>Status</div>',
'          <select value={status} onChange={(e) => setStatus(e.target.value)} style={{ padding: 10, borderRadius: 12, border: "1px solid #111" }}>',
'            <option value="OPEN">Abertos</option>',
'            <option value="RESOLVED">Resolvidos</option>',
'            <option value="ALL">Todos</option>',
'          </select>',
'        </div>',
'        <div style={{ display: "grid", gap: 6 }}>',
'          <div style={{ fontWeight: 900 }}>Bairro (opcional)</div>',
'          <input value={bairro} onChange={(e) => setBairro(e.target.value)} placeholder="Ex: Aterrado" style={{ padding: 10, borderRadius: 12, border: "1px solid #111" }} />',
'        </div>',
'        <div style={{ display: "grid", gap: 6 }}>',
'          <div style={{ fontWeight: 900 }}>Busca (opcional)</div>',
'          <input value={q} onChange={(e) => setQ(e.target.value)} placeholder="palavra-chave" style={{ padding: 10, borderRadius: 12, border: "1px solid #111" }} />',
'        </div>',
'        <button onClick={reload} style={btnStyle("#FFDD00")}>Atualizar</button>',
'      </div>',
'',
'      {loading ? <div style={{ opacity: 0.85 }}>Carregando…</div> : null}',
'      {err ? <div style={{ padding: 12, border: "1px solid #111", borderRadius: 14, background: "#fff2f2" }}><b>Erro:</b> {err}</div> : null}',
'',
'      <div style={{ display: "grid", gap: 10 }}>',
'        {items.map((it) => {',
'          const statusBg = it.resolved ? "#B7FFB7" : "#FFDD00";',
'          const place = (it.bairro ? (it.bairro + " - " + (it.cidade || "Volta Redonda")) : (it.cidade || "Volta Redonda"));',
'          const viewHref = "/eco/" + base + "/" + encodeURIComponent(it.id);',
'          const shareHref = "/eco/share/ponto/" + encodeURIComponent(it.id);',
'          const waHref = mounted ? ("https://wa.me/?text=" + encodeURIComponent("ECO — Ponto critico\\n" + it.title + "\\n" + place + "\\n" + (it.resolved ? "RESOLVIDO" : "ABERTO") + "\\n" + shareUrlFor(it.id) + "\\n\\n#ECO #ReciboECO #VoltaRedonda")) : "";',
'',
'          return (',
'            <div key={it.id} style={{ border: "1px solid #111", borderRadius: 16, padding: 12, background: "#fff" }}>',
'              <div style={{ display: "flex", alignItems: "flex-start", justifyContent: "space-between", gap: 10, flexWrap: "wrap" }}>',
'                <div style={{ display: "grid", gap: 6 }}>',
'                  <div style={{ fontWeight: 950, fontSize: 16 }}>{it.title}</div>',
'                  <div style={{ fontSize: 13, opacity: 0.8, fontWeight: 800 }}>{place}</div>',
'                  <div style={{ fontSize: 12, opacity: 0.7 }}>ID: {it.id}</div>',
'                </div>',
'                <div style={{ display: "flex", alignItems: "center", gap: 10 }}>',
'                  <span style={pillStyle(statusBg)}>{it.resolved ? "RESOLVIDO" : (it.status || "ABERTO")}</span>',
'                </div>',
'              </div>',
'',
'              <div style={{ display: "flex", gap: 10, flexWrap: "wrap", marginTop: 10, alignItems: "center" }}>',
'                <a href={viewHref} style={{ padding: "9px 10px", borderRadius: 12, border: "1px solid #111", textDecoration: "none", color: "#111", fontWeight: 900, background: "#fff" }}>Ver</a>',
'                <a href={shareHref} style={{ padding: "9px 10px", borderRadius: 12, border: "1px solid #111", textDecoration: "none", color: "#111", fontWeight: 900, background: "#fff" }}>Compartilhar</a>',
'                <button onClick={() => doConfirm(it.id)} style={btnStyle("#fff")}>Confirmar</button>',
'                {mounted ? (',
'                  <a href={waHref} target="_blank" rel="noreferrer" style={{ padding: "9px 10px", borderRadius: 12, border: "1px solid #111", textDecoration: "none", color: "#111", fontWeight: 900, background: "#fff" }}>',
'                    Apoiar (WhatsApp)',
'                  </a>',
'                ) : (',
'                  <span style={{ padding: "9px 10px", borderRadius: 12, border: "1px solid #111", opacity: 0.6, fontWeight: 900 }}>Apoiar (WhatsApp)</span>',
'                )}',
'              </div>',
'            </div>',
'          );',
'        })}',
'        {!loading && !err && items.length === 0 ? (',
'          <div style={{ padding: 14, borderRadius: 14, border: "1px dashed #111", opacity: 0.85 }}>',
'            Nada aqui com esses filtros. Tente status=ALL ou limpe a busca.',
'          </div>',
'        ) : null}',
'      </div>',
'',
'      {toast ? (',
'        <div style={{ position: "sticky", bottom: 10, display: "flex", justifyContent: "center" }}>',
'          <div style={{ padding: "10px 12px", borderRadius: 14, border: "1px solid #111", background: "#FFDD00", fontWeight: 950 }}>',
'            {toast}',
'          </div>',
'        </div>',
'      ) : null}',
'    </section>',
'  );',
'}',
''
) -join "`n"

WriteUtf8NoBom $pageFile $LPage
WriteUtf8NoBom $clientFile $LClient
Write-Host "[PATCH] wrote /eco/mural (page + client)"

# ---------- REPORT ----------
$rep = Join-Path $reportDir ('eco-step-81-mural-do-cuidado-pontos-v0_1-' + $ts + '.md')
$repLines = @(
'# eco-step-81-mural-do-cuidado-pontos-v0_1',
'',
'- Time: ' + $ts,
'- Backup: ' + $backupDir,
'- Base points folder: eco/' + $base,
'',
'## Added/Updated',
'- src/app/eco/mural/page.tsx',
'- src/app/eco/mural/MuralClient.tsx',
'- (if missing) src/app/api/eco/points/list/route.ts',
'',
'## Verify',
'1) Ctrl+C -> npm run dev',
'2) Abra /eco/mural',
'3) Teste filtros + Atualizar',
'4) Clique: Ver / Compartilhar / Confirmar',
'5) WhatsApp abre sem hydration warning'
)
WriteUtf8NoBom $rep ($repLines -join "`n")
Write-Host ('[REPORT] ' + $rep)

Write-Host ""
Write-Host "[VERIFY] Ctrl+C -> npm run dev"
Write-Host "[VERIFY] Abra: http://localhost:3000/eco/mural"