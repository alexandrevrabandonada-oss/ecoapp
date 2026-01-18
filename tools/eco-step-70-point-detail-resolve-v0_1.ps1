param(
  [string]$Root = (Get-Location).Path
)

$ts = Get-Date -Format "yyyyMMdd-HHmmss"

# bootstrap (se existir)
$boot = Join-Path $Root "tools/_bootstrap.ps1"
if (Test-Path -LiteralPath $boot) { . $boot }

# fallbacks
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
      Write-Host ("[BK] " + $rel + " -> " + (Split-Path -Leaf $dest))
    }
  }
}
function WriteLines([string]$p, [string[]]$lines) { WriteUtf8NoBom $p ($lines -join "`n") }

$backupDir = Join-Path $Root ("tools/_patch_backup/" + $ts + "-eco-step-70-point-detail-resolve-v0_1")
$reportDir = Join-Path $Root "reports"
EnsureDir $backupDir
EnsureDir $reportDir

Write-Host ("== eco-step-70-point-detail-resolve-v0_1 == " + $ts)
Write-Host ("[DIAG] Root: " + $Root)

$src = Join-Path $Root "src"
if (-not (Test-Path -LiteralPath $src)) { throw ("[STOP] Não achei src/: " + $src) }

# Paths
$apiGet     = Join-Path $Root "src/app/api/eco/points/get/route.ts"
$apiResolve = Join-Path $Root "src/app/api/eco/points/resolve/route.ts"

$pageDetail = Join-Path $Root "src/app/eco/pontos/[id]/page.tsx"
$client     = Join-Path $Root "src/app/eco/pontos/[id]/PointDetailClient.tsx"

Write-Host ("[DIAG] Will write: " + $apiGet)
Write-Host ("[DIAG] Will write: " + $apiResolve)
Write-Host ("[DIAG] Will write: " + $pageDetail)
Write-Host ("[DIAG] Will write: " + $client)

BackupFile $Root $apiGet $backupDir
BackupFile $Root $apiResolve $backupDir
BackupFile $Root $pageDetail $backupDir
BackupFile $Root $client $backupDir

EnsureDir (Split-Path -Parent $apiGet)
EnsureDir (Split-Path -Parent $apiResolve)
EnsureDir (Split-Path -Parent $pageDetail)
EnsureDir (Split-Path -Parent $client)

# ---------------- API: /api/eco/points/get ----------------
$LGet = @(
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
'    if (m && typeof m.findUnique === "function") return { key: k, model: m as any };',
'  }',
'  return null;',
'}',
'',
'export async function GET(req: Request) {',
'  const { searchParams } = new URL(req.url);',
'  const id = String(searchParams.get("id") || searchParams.get("pointId") || "").trim();',
'  if (!id) return NextResponse.json({ ok: false, error: "bad_id" }, { status: 400 });',
'',
'  const pm = getPointModel();',
'  if (!pm?.model) return NextResponse.json({ ok: false, error: "model_not_ready" }, { status: 503 });',
'',
'  try {',
'    const item = await pm.model.findUnique({ where: { id } });',
'    if (!item) return NextResponse.json({ ok: false, error: "not_found" }, { status: 404 });',
'    return NextResponse.json({ ok: true, item, meta: { pointModel: pm.key } });',
'  } catch (e) {',
'    const msg = asMsg(e);',
'    if (looksLikeMissingTable(msg)) return NextResponse.json({ ok: false, error: "db_not_ready", detail: msg }, { status: 503 });',
'    return NextResponse.json({ ok: false, error: "db_error", detail: msg }, { status: 500 });',
'  }',
'}',
''
)
WriteLines $apiGet $LGet
Write-Host "[PATCH] wrote /api/eco/points/get"

# ---------------- API: /api/eco/points/resolve ----------------
$LResolve = @(
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
'    if (m && typeof m.update === "function" && typeof m.findUnique === "function") return { key: k, model: m as any };',
'  }',
'  return null;',
'}',
'function safeStr(v: any, maxLen: number) {',
'  const s = String(v || "").trim();',
'  if (!s) return "";',
'  return s.length > maxLen ? s.slice(0, maxLen) : s;',
'}',
'',
'async function tryUpdate(model: any, id: string, data: any) {',
'  try {',
'    const item = await model.update({ where: { id }, data });',
'    return { ok: true, item, mode: Object.keys(data).join(",") };',
'  } catch {',
'    return { ok: false, item: null, mode: "" };',
'  }',
'}',
'',
'export async function POST(req: Request) {',
'  const body = (await req.json().catch(() => null)) as any;',
'  const id = String(body?.id || body?.pointId || "").trim();',
'  if (!id) return NextResponse.json({ ok: false, error: "bad_id" }, { status: 400 });',
'',
'  const proofNote = safeStr(body?.proofNote || body?.note || body?.obs || "", 800);',
'  const proofUrl = safeStr(body?.proofUrl || body?.evidenceUrl || body?.photoUrl || "", 600);',
'',
'  const pm = getPointModel();',
'  if (!pm?.model) return NextResponse.json({ ok: false, error: "model_not_ready" }, { status: 503 });',
'',
'  try {',
'    const cur = await pm.model.findUnique({ where: { id } });',
'    if (!cur) return NextResponse.json({ ok: false, error: "not_found" }, { status: 404 });',
'',
'    const nowIso = new Date().toISOString();',
'',
'    # try: status + proofNote + resolvedAt',
'    let r = await tryUpdate(pm.model, id, { status: "RESOLVED", proofNote, resolvedAt: nowIso, proofUrl });',
'    if (r.ok) return NextResponse.json({ ok: true, item: r.item, meta: { pointModel: pm.key, mode: "full:" + r.mode } });',
'',
'    # try: status + note in description/details',
'    const desc = proofNote ? ("[RESOLVIDO] " + proofNote) : "[RESOLVIDO]";',
'    r = await tryUpdate(pm.model, id, { status: "RESOLVED", description: desc });',
'    if (r.ok) return NextResponse.json({ ok: true, item: r.item, meta: { pointModel: pm.key, mode: "desc" } });',
'',
'    r = await tryUpdate(pm.model, id, { status: "RESOLVED", details: desc });',
'    if (r.ok) return NextResponse.json({ ok: true, item: r.item, meta: { pointModel: pm.key, mode: "details" } });',
'',
'    # try: meta blob',
'    try {',
'      const meta0 = (cur as any)?.meta;',
'      const meta = (meta0 && typeof meta0 === "object") ? meta0 : {};',
'      (meta as any).resolvedAt = nowIso;',
'      if (proofNote) (meta as any).proofNote = proofNote;',
'      if (proofUrl) (meta as any).proofUrl = proofUrl;',
'      const item = await pm.model.update({ where: { id }, data: { status: "RESOLVED", meta } });',
'      return NextResponse.json({ ok: true, item, meta: { pointModel: pm.key, mode: "meta" } });',
'    } catch { }',
'',
'    # last: status only',
'    r = await tryUpdate(pm.model, id, { status: "RESOLVED" });',
'    if (r.ok) return NextResponse.json({ ok: true, item: r.item, meta: { pointModel: pm.key, mode: "status_only" } });',
'',
'    return NextResponse.json({ ok: false, error: "update_failed" }, { status: 500 });',
'  } catch (e) {',
'    const msg = asMsg(e);',
'    if (looksLikeMissingTable(msg)) return NextResponse.json({ ok: false, error: "db_not_ready", detail: msg }, { status: 503 });',
'    return NextResponse.json({ ok: false, error: "db_error", detail: msg }, { status: 500 });',
'  }',
'}',
''
)

# NOTE: TS não aceita '#', então troco por comentário TS válido
$LResolveFixed = @()
foreach ($line in $LResolve) {
  if ($line -like '*# try:*') { $LResolveFixed += ('  // ' + ($line -replace '^\s*#\s*','')) }
  elseif ($line -like '*# last:*') { $LResolveFixed += ('  // ' + ($line -replace '^\s*#\s*','')) }
  else { $LResolveFixed += $line }
}
WriteLines $apiResolve $LResolveFixed
Write-Host "[PATCH] wrote /api/eco/points/resolve"

# ---------------- UI: /eco/pontos/[id] ----------------
$LPage = @(
'import PointDetailClient from "./PointDetailClient";',
'',
'export default async function Page({ params }: { params: { id: string } }) {',
'  return (',
'    <main style={{ padding: 16, maxWidth: 980, margin: "0 auto" }}>',
'      <h1 style={{ margin: "0 0 8px 0" }}>Ponto</h1>',
'      <p style={{ margin: "0 0 14px 0", opacity: 0.85 }}>',
'        Abandono x Cuidado. Confirmacao comunitaria e prova. Recibo e lei.',
'      </p>',
'      <PointDetailClient id={params.id} />',
'    </main>',
'  );',
'}',
''
)
WriteLines $pageDetail $LPage
Write-Host "[PATCH] wrote /eco/pontos/[id]/page.tsx"

$LClient = @(
'"use client";',
'',
'import { useEffect, useMemo, useState } from "react";',
'',
'type AnyObj = any;',
'',
'function pickNum(r: AnyObj, keys: string[]) {',
'  for (const k of keys) {',
'    const v = r?.[k];',
'    const n = Number(v);',
'    if (Number.isFinite(n)) return n;',
'  }',
'  return null;',
'}',
'function pickStr(r: AnyObj, keys: string[]) {',
'  for (const k of keys) {',
'    const v = r?.[k];',
'    if (typeof v === "string" && v.trim()) return v.trim();',
'  }',
'  return "";',
'}',
'function fmtDate(s: AnyObj) {',
'  if (!s) return "";',
'  try {',
'    const d = new Date(String(s));',
'    return d.toLocaleString();',
'  } catch {',
'    return String(s);',
'  }',
'}',
'',
'export default function PointDetailClient({ id }: { id: string }) {',
'  const [item, setItem] = useState<AnyObj | null>(null);',
'  const [loading, setLoading] = useState(false);',
'  const [err, setErr] = useState<string | null>(null);',
'  const [proofNote, setProofNote] = useState("");',
'  const [proofUrl, setProofUrl] = useState("");',
'  const [msg, setMsg] = useState("");',
'',
'  const lat = useMemo(() => (item ? pickNum(item, ["lat","latitude","geoLat"]) : null), [item]);',
'  const lng = useMemo(() => (item ? pickNum(item, ["lng","lon","longitude","geoLng"]) : null), [item]);',
'  const status = useMemo(() => (item ? String(item?.status || "") : ""), [item]);',
'  const category = useMemo(() => (item ? pickStr(item, ["category","kind","type","categoria"]) : ""), [item]);',
'  const bairro = useMemo(() => (item ? pickStr(item, ["bairro","neighborhood","area","regiao","region"]) : ""), [item]);',
'  const title = useMemo(() => (item ? pickStr(item, ["title","name","titulo"]) : ""), [item]);',
'  const description = useMemo(() => (item ? pickStr(item, ["description","desc","details","detalhes","note","notes","obs"]) : ""), [item]);',
'  const confirmations = useMemo(() => (item ? (pickNum(item, ["confirmations","confirmCount","votes","upvotes","confirmationsCount"]) ?? 0) : 0), [item]);',
'',
'  async function load() {',
'    setLoading(true);',
'    setErr(null);',
'    setMsg("");',
'    try {',
'      const res = await fetch("/api/eco/points/get?id=" + encodeURIComponent(id), { cache: "no-store" } as any);',
'      const j = await res.json().catch(() => null);',
'      if (!res.ok || !j?.ok) throw new Error(j?.detail || j?.error || ("HTTP " + res.status));',
'      setItem(j.item);',
'    } catch (e: any) {',
'      setErr(e?.message || String(e));',
'    } finally {',
'      setLoading(false);',
'    }',
'  }',
'',
'  useEffect(() => { void load(); }, [id]);',
'',
'  async function confirm() {',
'    setErr(null);',
'    setMsg("");',
'    try {',
'      const res = await fetch("/api/eco/points/confirm", {',
'        method: "POST",',
'        headers: { "Content-Type": "application/json" },',
'        body: JSON.stringify({ id }),',
'      });',
'      const j = await res.json().catch(() => null);',
'      if (!res.ok || !j?.ok) throw new Error(j?.detail || j?.error || ("HTTP " + res.status));',
'      setMsg("Confirmacao registrada (eu vi tambem).");',
'      await load();',
'    } catch (e: any) {',
'      setErr(e?.message || String(e));',
'    }',
'  }',
'',
'  async function resolve() {',
'    setErr(null);',
'    setMsg("");',
'    try {',
'      if (proofNote.trim().length < 6) throw new Error("Escreva uma nota de prova (>= 6 caracteres).");',
'      const res = await fetch("/api/eco/points/resolve", {',
'        method: "POST",',
'        headers: { "Content-Type": "application/json" },',
'        body: JSON.stringify({ id, proofNote: proofNote.trim(), proofUrl: proofUrl.trim() || undefined }),',
'      });',
'      const j = await res.json().catch(() => null);',
'      if (!res.ok || !j?.ok) throw new Error(j?.detail || j?.error || ("HTTP " + res.status));',
'      setMsg("Ponto marcado como RESOLVIDO (cuidado) com prova.");',
'      await load();',
'    } catch (e: any) {',
'      setErr(e?.message || String(e));',
'    }',
'  }',
'',
'  const mapsHref = (lat != null && lng != null) ? ("https://www.google.com/maps?q=" + String(lat) + "," + String(lng)) : "";',
'',
'  return (',
'    <section style={{ display: "grid", gap: 12 }}>',
'      <div style={{ padding: 12, border: "1px solid #e5e5e5", borderRadius: 12, background: "#fff" }}>',
'        <div style={{ display: "flex", justifyContent: "space-between", gap: 10, flexWrap: "wrap", alignItems: "center" }}>',
'          <div style={{ fontWeight: 900 }}>Detalhe</div>',
'          <button onClick={() => void load()} disabled={loading} style={{ padding: "8px 10px", borderRadius: 10, border: "1px solid #ccc", background: "#fff" }}>',
'            Atualizar',
'          </button>',
'        </div>',
'',
'        {loading ? <div style={{ marginTop: 10, opacity: 0.75 }}>Carregando...</div> : null}',
'        {err ? <div style={{ marginTop: 10, color: "#b00020" }}>{err}</div> : null}',
'        {msg ? <div style={{ marginTop: 10, opacity: 0.9 }}>{msg}</div> : null}',
'',
'        {item ? (',
'          <div style={{ marginTop: 10, display: "grid", gap: 8 }}>',
'            <div style={{ fontWeight: 900 }}>',
'              {status === "OPEN" ? "ABANDONO" : (status === "RESOLVED" ? "CUIDADO" : status)}',
'              {category ? (" - " + category) : ""}',
'              {bairro ? (" - " + bairro) : ""}',
'            </div>',
'            {title ? <div style={{ opacity: 0.95 }}>{title}</div> : null}',
'            {description ? <div style={{ opacity: 0.9 }}>{description}</div> : null}',
'            <div style={{ display: "flex", gap: 10, flexWrap: "wrap", alignItems: "center" }}>',
'              <div style={{ fontSize: 12, opacity: 0.75 }}>ID: {String(item?.id || id)}</div>',
'              <div style={{ fontSize: 12, opacity: 0.75 }}>Criado: {fmtDate(item?.createdAt)}</div>',
'              <div style={{ fontSize: 12, opacity: 0.75 }}>Atualizado: {fmtDate(item?.updatedAt)}</div>',
'            </div>',
'            <div style={{ display: "flex", gap: 10, flexWrap: "wrap" }}>',
'              <button onClick={() => void confirm()} style={{ padding: "10px 12px", borderRadius: 12, border: "1px solid #111", background: "#fff" }}>',
'                Eu vi tambem ({Number(confirmations || 0)})',
'              </button>',
'              {mapsHref ? (',
'                <a href={mapsHref} target="_blank" rel="noreferrer" style={{ textDecoration: "none", padding: "10px 12px", borderRadius: 12, border: "1px solid #111", color: "#111" }}>',
'                  Abrir no mapa',
'                </a>',
'              ) : null}',
'            </div>',
'          </div>',
'        ) : null}',
'      </div>',
'',
'      <div style={{ padding: 12, border: "1px solid #e5e5e5", borderRadius: 12, background: "#fff" }}>',
'        <div style={{ fontWeight: 900, marginBottom: 8 }}>Marcar como resolvido (com prova)</div>',
'        <div style={{ opacity: 0.8, fontSize: 12, marginBottom: 10 }}>',
'          Regra: cuidado tem prova. Escreva o que foi feito, por quem (coletivo), e se tem registro (foto/link).',
'        </div>',
'        <label style={{ display: "grid", gap: 6 }}>',
'          <span>Nota de prova</span>',
'          <textarea value={proofNote} onChange={(e) => setProofNote((e.target as any).value)} rows={3} placeholder="Ex: mutirao fez limpeza, retirou sacos, area sinalizada, contato do operador..." style={{ padding: 10, borderRadius: 10, border: "1px solid #ccc" }} />',
'        </label>',
'        <label style={{ display: "grid", gap: 6, marginTop: 10 }}>',
'          <span>Link da prova (opcional)</span>',
'          <input value={proofUrl} onChange={(e) => setProofUrl((e.target as any).value)} placeholder="https://..." style={{ padding: 10, borderRadius: 10, border: "1px solid #ccc" }} />',
'        </label>',
'        <div style={{ marginTop: 10, display: "flex", gap: 10, flexWrap: "wrap" }}>',
'          <button onClick={() => void resolve()} style={{ padding: "10px 12px", borderRadius: 12, border: "1px solid #111", background: "#111", color: "#fff" }}>',
'            Marcar RESOLVIDO',
'          </button>',
'        </div>',
'      </div>',
'    </section>',
'  );',
'}',
''
)
WriteLines $client $LClient
Write-Host "[PATCH] wrote /eco/pontos/[id]/PointDetailClient.tsx"

# REPORT
$rep = Join-Path $reportDir ("eco-step-70-point-detail-resolve-v0_1-" + $ts + ".md")
$repLines = @(
"# eco-step-70-point-detail-resolve-v0_1",
"",
"- Time: " + $ts,
"- Backup: " + $backupDir,
"",
"## Added",
"- GET /api/eco/points/get?id=...",
"- POST /api/eco/points/resolve { id, proofNote, proofUrl? }",
"- Page /eco/pontos/[id] + PointDetailClient",
"",
"## Verify",
"1) Ctrl+C -> npm run dev",
"2) Abra /eco/mapa, clique 'Ver detalhe' em um item",
"3) Clique 'Eu vi tambem' e ver se aumenta contador",
"4) Escreva nota >= 6 chars e clique 'Marcar RESOLVIDO' (status deve mudar)",
"",
"## Notes",
"- Resolve tenta varios campos (status/proofNote/resolvedAt/meta/description) para aguentar variações do schema."
)
WriteUtf8NoBom $rep ($repLines -join "`n")
Write-Host ("[REPORT] " + $rep)

Write-Host ""
Write-Host "[VERIFY] Ctrl+C -> npm run dev"
Write-Host "[VERIFY] Abra http://localhost:3000/eco/mapa e depois /eco/pontos/<id>"
Write-Host "[VERIFY] irm `"http://localhost:3000/api/eco/points/get?id=SEU_ID`" -Headers @{Accept=`"application/json`"}"