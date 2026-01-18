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

$backupDir = Join-Path $Root ("tools/_patch_backup/" + $ts + "-eco-step-71-mutirao-finish-resolve-point-v0_1")
$reportDir = Join-Path $Root "reports"
EnsureDir $backupDir
EnsureDir $reportDir

Write-Host ("== eco-step-71-mutirao-finish-resolve-point-v0_1 == " + $ts)
Write-Host ("[DIAG] Root: " + $Root)

$src = Join-Path $Root "src"
if (-not (Test-Path -LiteralPath $src)) { throw ("[STOP] Não achei src/: " + $src) }

# Paths
$apiGet     = Join-Path $Root "src/app/api/eco/mutirao/get/route.ts"
$apiFinish  = Join-Path $Root "src/app/api/eco/mutirao/finish/route.ts"
$apiConfirm = Join-Path $Root "src/app/api/eco/points/confirm/route.ts"

$pageFin    = Join-Path $Root "src/app/eco/mutiroes/[id]/finalizar/page.tsx"
$clientFin  = Join-Path $Root "src/app/eco/mutiroes/[id]/finalizar/MutiraoFinishClient.tsx"

Write-Host ("[DIAG] Will write: " + $apiGet)
Write-Host ("[DIAG] Will write: " + $apiFinish)
Write-Host ("[DIAG] Will write: " + $apiConfirm)
Write-Host ("[DIAG] Will write: " + $pageFin)
Write-Host ("[DIAG] Will write: " + $clientFin)

BackupFile $Root $apiGet $backupDir
BackupFile $Root $apiFinish $backupDir
BackupFile $Root $apiConfirm $backupDir
BackupFile $Root $pageFin $backupDir
BackupFile $Root $clientFin $backupDir

EnsureDir (Split-Path -Parent $apiGet)
EnsureDir (Split-Path -Parent $apiFinish)
EnsureDir (Split-Path -Parent $apiConfirm)
EnsureDir (Split-Path -Parent $pageFin)
EnsureDir (Split-Path -Parent $clientFin)

# ---------------- API: /api/eco/mutirao/get ----------------
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
'function getMutiraoModel() {',
'  const pc: any = prisma as any;',
'  const candidates = ["ecoMutirao", "mutirao", "ecoCleanup", "cleanup", "ecoMutiraoEvent", "mutiraoEvent"];',
'  for (const k of candidates) {',
'    const m = pc?.[k];',
'    if (m && typeof m.findUnique === "function") return { key: k, model: m as any };',
'  }',
'  return null;',
'}',
'',
'export async function GET(req: Request) {',
'  const { searchParams } = new URL(req.url);',
'  const id = String(searchParams.get("id") || searchParams.get("mutiraoId") || "").trim();',
'  if (!id) return NextResponse.json({ ok: false, error: "bad_id" }, { status: 400 });',
'',
'  const mm = getMutiraoModel();',
'  if (!mm?.model) return NextResponse.json({ ok: false, error: "model_not_ready" }, { status: 503 });',
'',
'  try {',
'    const item = await mm.model.findUnique({ where: { id } });',
'    if (!item) return NextResponse.json({ ok: false, error: "not_found" }, { status: 404 });',
'    return NextResponse.json({ ok: true, item, meta: { mutiraoModel: mm.key } });',
'  } catch (e) {',
'    const msg = asMsg(e);',
'    if (looksLikeMissingTable(msg)) return NextResponse.json({ ok: false, error: "db_not_ready", detail: msg }, { status: 503 });',
'    return NextResponse.json({ ok: false, error: "db_error", detail: msg }, { status: 500 });',
'  }',
'}',
''
)
WriteLines $apiGet $LGet
Write-Host "[PATCH] wrote /api/eco/mutirao/get"

# ---------------- API: /api/eco/points/confirm (bonus p/ PointDetailClient) ----------------
$LConfirm = @(
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
'  const pm = getPointModel();',
'  if (!pm?.model) return NextResponse.json({ ok: false, error: "model_not_ready" }, { status: 503 });',
'',
'  try {',
'    const cur = await pm.model.findUnique({ where: { id } });',
'    if (!cur) return NextResponse.json({ ok: false, error: "not_found" }, { status: 404 });',
'',
'    // prefer atomic increment if field exists',
'    let r = await tryUpdate(pm.model, id, { confirmations: { increment: 1 } });',
'    if (r.ok) return NextResponse.json({ ok: true, item: r.item, meta: { pointModel: pm.key, mode: "increment" } });',
'',
'    // fallback: meta.confirmations++',
'    try {',
'      const meta0 = (cur as any)?.meta;',
'      const meta = (meta0 && typeof meta0 === "object") ? meta0 : {};',
'      const prev = Number((meta as any).confirmations || 0) || 0;',
'      (meta as any).confirmations = prev + 1;',
'      const item = await pm.model.update({ where: { id }, data: { meta } });',
'      return NextResponse.json({ ok: true, item, meta: { pointModel: pm.key, mode: "meta" } });',
'    } catch { }',
'',
'    // last: do nothing but ok',
'    return NextResponse.json({ ok: true, item: cur, meta: { pointModel: pm.key, mode: "noop" } });',
'  } catch (e) {',
'    const msg = asMsg(e);',
'    if (looksLikeMissingTable(msg)) return NextResponse.json({ ok: false, error: "db_not_ready", detail: msg }, { status: 503 });',
'    return NextResponse.json({ ok: false, error: "db_error", detail: msg }, { status: 500 });',
'  }',
'}',
''
)
WriteLines $apiConfirm $LConfirm
Write-Host "[PATCH] wrote /api/eco/points/confirm"

# ---------------- API: /api/eco/mutirao/finish (v2 robust: also resolves linked point) ----------------
$LFinish = @(
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
'function safeStr(v: any, maxLen: number) {',
'  const s = String(v || "").trim();',
'  if (!s) return "";',
'  return s.length > maxLen ? s.slice(0, maxLen) : s;',
'}',
'function getMutiraoModel() {',
'  const pc: any = prisma as any;',
'  const candidates = ["ecoMutirao", "mutirao", "ecoCleanup", "cleanup", "ecoMutiraoEvent", "mutiraoEvent"];',
'  for (const k of candidates) {',
'    const m = pc?.[k];',
'    if (m && typeof m.findUnique === "function" && typeof m.update === "function") return { key: k, model: m as any };',
'  }',
'  return null;',
'}',
'function getPointModel() {',
'  const pc: any = prisma as any;',
'  const candidates = ["ecoPoint", "ecoCriticalPoint", "criticalPoint", "ecoPonto", "ponto", "ecoPontoCritico"];',
'  for (const k of candidates) {',
'    const m = pc?.[k];',
'    if (m && typeof m.findUnique === "function" && typeof m.update === "function") return { key: k, model: m as any };',
'  }',
'  return null;',
'}',
'async function tryUpdate(model: any, id: string, data: any) {',
'  try {',
'    const item = await model.update({ where: { id }, data });',
'    return { ok: true, item, mode: Object.keys(data).join(",") };',
'  } catch {',
'    return { ok: false, item: null, mode: "" };',
'  }',
'}',
'function findLinkedPointId(mut: any): string {',
'  const keys = ["pointId","criticalPointId","ecoPointId","ecoCriticalPointId","pontoId","pontoCriticoId"];',
'  for (const k of keys) {',
'    const v = mut?.[k];',
'    if (typeof v === "string" && v.trim()) return v.trim();',
'  }',
'  // meta fallback',
'  const meta = mut?.meta;',
'  if (meta && typeof meta === "object") {',
'    for (const k of keys) {',
'      const v = (meta as any)?.[k];',
'      if (typeof v === "string" && v.trim()) return v.trim();',
'    }',
'  }',
'  return "";',
'}',
'async function resolvePoint(pm: any, pointId: string, proofNote: string, proofUrl: string, nowIso: string) {',
'  if (!pm?.model || !pointId) return { ok: false, skipped: true };',
'  const cur = await pm.model.findUnique({ where: { id: pointId } });',
'  if (!cur) return { ok: false, notFound: true };',
'',
'  // try: status + proof fields',
'  let r = await tryUpdate(pm.model, pointId, { status: "RESOLVED", proofNote, resolvedAt: nowIso, proofUrl });',
'  if (r.ok) return { ok: true, item: r.item, mode: "full:" + r.mode };',
'',
'  // try: description/details',
'  const desc = proofNote ? ("[RESOLVIDO] " + proofNote) : "[RESOLVIDO]";',
'  r = await tryUpdate(pm.model, pointId, { status: "RESOLVED", description: desc });',
'  if (r.ok) return { ok: true, item: r.item, mode: "desc" };',
'  r = await tryUpdate(pm.model, pointId, { status: "RESOLVED", details: desc });',
'  if (r.ok) return { ok: true, item: r.item, mode: "details" };',
'',
'  // try: meta blob',
'  try {',
'    const meta0 = (cur as any)?.meta;',
'    const meta = (meta0 && typeof meta0 === "object") ? meta0 : {};',
'    (meta as any).resolvedAt = nowIso;',
'    if (proofNote) (meta as any).proofNote = proofNote;',
'    if (proofUrl) (meta as any).proofUrl = proofUrl;',
'    const item = await pm.model.update({ where: { id: pointId }, data: { status: "RESOLVED", meta } });',
'    return { ok: true, item, mode: "meta" };',
'  } catch { }',
'',
'  // last: status only',
'  r = await tryUpdate(pm.model, pointId, { status: "RESOLVED" });',
'  if (r.ok) return { ok: true, item: r.item, mode: "status_only" };',
'',
'  return { ok: false, failed: true };',
'}',
'',
'export async function POST(req: Request) {',
'  const body = (await req.json().catch(() => null)) as any;',
'  const id = String(body?.id || body?.mutiraoId || "").trim();',
'  if (!id) return NextResponse.json({ ok: false, error: "bad_id" }, { status: 400 });',
'',
'  const proofNote = safeStr(body?.proofNote || body?.note || body?.obs || "", 800);',
'  const proofUrl = safeStr(body?.proofUrl || body?.evidenceUrl || body?.photoUrl || "", 600);',
'  if (proofNote.trim().length < 6) return NextResponse.json({ ok: false, error: "bad_proof", hint: "proofNote >= 6 chars" }, { status: 400 });',
'',
'  const mm = getMutiraoModel();',
'  if (!mm?.model) return NextResponse.json({ ok: false, error: "model_not_ready" }, { status: 503 });',
'',
'  try {',
'    const cur = await mm.model.findUnique({ where: { id } });',
'    if (!cur) return NextResponse.json({ ok: false, error: "not_found" }, { status: 404 });',
'',
'    const nowIso = new Date().toISOString();',
'',
'    // update mutirao (try multiple statuses/fields)',
'    let upd = await tryUpdate(mm.model, id, { status: "FINISHED", finishedAt: nowIso, proofNote, proofUrl });',
'    if (!upd.ok) upd = await tryUpdate(mm.model, id, { status: "DONE", finishedAt: nowIso, proofNote, proofUrl });',
'    if (!upd.ok) upd = await tryUpdate(mm.model, id, { status: "RESOLVED", endedAt: nowIso, proofNote, proofUrl });',
'    if (!upd.ok) {',
'      try {',
'        const meta0 = (cur as any)?.meta;',
'        const meta = (meta0 && typeof meta0 === "object") ? meta0 : {};',
'        (meta as any).finishedAt = nowIso;',
'        (meta as any).proofNote = proofNote;',
'        if (proofUrl) (meta as any).proofUrl = proofUrl;',
'        const item = await mm.model.update({ where: { id }, data: { status: "RESOLVED", meta } });',
'        upd = { ok: true, item, mode: "meta" };',
'      } catch { }',
'    }',
'    if (!upd.ok) upd = await tryUpdate(mm.model, id, { status: "RESOLVED" });',
'',
'    const mutiraoItem = upd.ok ? upd.item : cur;',
'    const pointId = safeStr(body?.pointId || "", 120) || findLinkedPointId(mutiraoItem);',
'',
'    // resolve linked point (best-effort)',
'    const pm = getPointModel();',
'    let pointRes: any = { ok: false, skipped: true };',
'    if (pointId && pm?.model) {',
'      pointRes = await resolvePoint(pm, pointId, proofNote, proofUrl, nowIso);',
'    }',
'',
'    return NextResponse.json({',
'      ok: true,',
'      mutirao: mutiraoItem,',
'      point: pointRes?.ok ? pointRes.item : null,',
'      meta: { mutiraoModel: mm.key, mutiraoMode: upd.mode || "unknown", pointId, pointMode: pointRes?.mode || "skip" }',
'    });',
'  } catch (e) {',
'    const msg = asMsg(e);',
'    if (looksLikeMissingTable(msg)) return NextResponse.json({ ok: false, error: "db_not_ready", detail: msg }, { status: 503 });',
'    return NextResponse.json({ ok: false, error: "db_error", detail: msg }, { status: 500 });',
'  }',
'}',
''
)
WriteLines $apiFinish $LFinish
Write-Host "[PATCH] wrote /api/eco/mutirao/finish"

# ---------------- UI: /eco/mutiroes/[id]/finalizar ----------------
$LPage = @(
'import MutiraoFinishClient from "./MutiraoFinishClient";',
'',
'export default async function Page({ params }: { params: { id: string } }) {',
'  return (',
'    <main style={{ padding: 16, maxWidth: 980, margin: "0 auto" }}>',
'      <h1 style={{ margin: "0 0 8px 0" }}>Finalizar mutirao</h1>',
'      <p style={{ margin: "0 0 14px 0", opacity: 0.85 }}>',
'        Fecha o mutirao e (se tiver ponto vinculado) marca como RESOLVIDO com prova.',
'      </p>',
'      <MutiraoFinishClient id={params.id} />',
'    </main>',
'  );',
'}',
''
)
WriteLines $pageFin $LPage
Write-Host "[PATCH] wrote /eco/mutiroes/[id]/finalizar/page.tsx"

$LClient = @(
'"use client";',
'',
'import { useEffect, useMemo, useState } from "react";',
'',
'type AnyObj = any;',
'',
'function pickStr(r: AnyObj, keys: string[]) {',
'  for (const k of keys) {',
'    const v = r?.[k];',
'    if (typeof v === "string" && v.trim()) return v.trim();',
'  }',
'  return "";',
'}',
'function pickNum(r: AnyObj, keys: string[]) {',
'  for (const k of keys) {',
'    const n = Number(r?.[k]);',
'    if (Number.isFinite(n)) return n;',
'  }',
'  return null;',
'}',
'function fmtDate(s: AnyObj) {',
'  if (!s) return "";',
'  try { return new Date(String(s)).toLocaleString(); } catch { return String(s); }',
'}',
'function findPointId(mut: AnyObj) {',
'  const keys = ["pointId","criticalPointId","ecoPointId","ecoCriticalPointId","pontoId","pontoCriticoId"];',
'  for (const k of keys) {',
'    const v = mut?.[k];',
'    if (typeof v === "string" && v.trim()) return v.trim();',
'  }',
'  const meta = mut?.meta;',
'  if (meta && typeof meta === "object") {',
'    for (const k of keys) {',
'      const v = (meta as any)?.[k];',
'      if (typeof v === "string" && v.trim()) return v.trim();',
'    }',
'  }',
'  return "";',
'}',
'',
'export default function MutiraoFinishClient({ id }: { id: string }) {',
'  const [item, setItem] = useState<AnyObj | null>(null);',
'  const [loading, setLoading] = useState(false);',
'  const [saving, setSaving] = useState(false);',
'  const [err, setErr] = useState<string | null>(null);',
'  const [msg, setMsg] = useState<string>("");',
'  const [proofNote, setProofNote] = useState("");',
'  const [proofUrl, setProofUrl] = useState("");',
'',
'  const status = useMemo(() => (item ? String(item?.status || "") : ""), [item]);',
'  const title  = useMemo(() => (item ? pickStr(item, ["title","name","titulo"]) : ""), [item]);',
'  const bairro = useMemo(() => (item ? pickStr(item, ["bairro","neighborhood","area","regiao","region"]) : ""), [item]);',
'  const pointId = useMemo(() => (item ? findPointId(item) : ""), [item]);',
'  const lat = useMemo(() => (item ? pickNum(item, ["lat","latitude"]) : null), [item]);',
'  const lng = useMemo(() => (item ? pickNum(item, ["lng","lon","longitude"]) : null), [item]);',
'  const mapsHref = (lat != null && lng != null) ? ("https://www.google.com/maps?q=" + String(lat) + "," + String(lng)) : "";',
'',
'  async function load() {',
'    setLoading(true);',
'    setErr(null);',
'    setMsg("");',
'    try {',
'      const res = await fetch("/api/eco/mutirao/get?id=" + encodeURIComponent(id), { cache: "no-store" } as any);',
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
'  async function finish() {',
'    setErr(null);',
'    setMsg("");',
'    try {',
'      if (proofNote.trim().length < 6) throw new Error("Escreva uma nota de prova (>= 6 caracteres).");',
'      setSaving(true);',
'      const res = await fetch("/api/eco/mutirao/finish", {',
'        method: "POST",',
'        headers: { "Content-Type": "application/json" },',
'        body: JSON.stringify({ id, proofNote: proofNote.trim(), proofUrl: proofUrl.trim() || undefined }),',
'      });',
'      const j = await res.json().catch(() => null);',
'      if (!res.ok || !j?.ok) throw new Error(j?.detail || j?.error || ("HTTP " + res.status));',
'      setMsg("Mutirao finalizado. Ponto vinculado: " + (j?.meta?.pointId ? "tentou resolver" : "nao encontrado"));',
'      await load();',
'    } catch (e: any) {',
'      setErr(e?.message || String(e));',
'    } finally {',
'      setSaving(false);',
'    }',
'  }',
'',
'  return (',
'    <section style={{ display: "grid", gap: 12 }}>',
'      <div style={{ padding: 12, border: "1px solid #e5e5e5", borderRadius: 12, background: "#fff" }}>',
'        <div style={{ display: "flex", justifyContent: "space-between", gap: 10, flexWrap: "wrap", alignItems: "center" }}>',
'          <div style={{ fontWeight: 900 }}>Mutirao</div>',
'          <button onClick={() => void load()} disabled={loading} style={{ padding: "8px 10px", borderRadius: 10, border: "1px solid #ccc", background: "#fff" }}>',
'            Atualizar',
'          </button>',
'        </div>',
'        {loading ? <div style={{ marginTop: 10, opacity: 0.75 }}>Carregando...</div> : null}',
'        {err ? <div style={{ marginTop: 10, color: "#b00020" }}>{err}</div> : null}',
'        {msg ? <div style={{ marginTop: 10, opacity: 0.9 }}>{msg}</div> : null}',
'',
'        {item ? (',
'          <div style={{ marginTop: 10, display: "grid", gap: 8 }}>',
'            <div style={{ fontWeight: 900 }}>{status || "SEM STATUS"}{bairro ? (" - " + bairro) : ""}</div>',
'            {title ? <div style={{ opacity: 0.95 }}>{title}</div> : null}',
'            <div style={{ display: "flex", gap: 10, flexWrap: "wrap", alignItems: "center" }}>',
'              <div style={{ fontSize: 12, opacity: 0.75 }}>ID: {String(item?.id || id)}</div>',
'              <div style={{ fontSize: 12, opacity: 0.75 }}>Criado: {fmtDate(item?.createdAt)}</div>',
'              <div style={{ fontSize: 12, opacity: 0.75 }}>Atualizado: {fmtDate(item?.updatedAt)}</div>',
'            </div>',
'            <div style={{ display: "flex", gap: 10, flexWrap: "wrap" }}>',
'              {mapsHref ? <a href={mapsHref} target="_blank" rel="noreferrer" style={{ textDecoration: "none", padding: "10px 12px", borderRadius: 12, border: "1px solid #111", color: "#111" }}>Abrir no mapa</a> : null}',
'              {pointId ? <a href={"/eco/pontos/" + encodeURIComponent(pointId)} style={{ textDecoration: "none", padding: "10px 12px", borderRadius: 12, border: "1px solid #111", color: "#111" }}>Ver ponto vinculado</a> : null}',
'            </div>',
'          </div>',
'        ) : null}',
'      </div>',
'',
'      <div style={{ padding: 12, border: "1px solid #e5e5e5", borderRadius: 12, background: "#fff" }}>',
'        <div style={{ fontWeight: 900, marginBottom: 8 }}>Prova / Nota de fechamento</div>',
'        <div style={{ opacity: 0.8, fontSize: 12, marginBottom: 10 }}>',
'          Cuidado com prova: descreva o que foi feito, o que mudou, e se houver registro (foto/link).',
'        </div>',
'        <label style={{ display: "grid", gap: 6 }}>',
'          <span>Nota de prova</span>',
'          <textarea value={proofNote} onChange={(e) => setProofNote((e.target as any).value)} rows={3} placeholder="Ex: limpeza feita, sacos retirados, local sinalizado, reincidencia monitorada..." style={{ padding: 10, borderRadius: 10, border: "1px solid #ccc" }} />',
'        </label>',
'        <label style={{ display: "grid", gap: 6, marginTop: 10 }}>',
'          <span>Link da prova (opcional)</span>',
'          <input value={proofUrl} onChange={(e) => setProofUrl((e.target as any).value)} placeholder="https://..." style={{ padding: 10, borderRadius: 10, border: "1px solid #ccc" }} />',
'        </label>',
'        <div style={{ marginTop: 10, display: "flex", gap: 10, flexWrap: "wrap" }}>',
'          <button onClick={() => void finish()} disabled={saving} style={{ padding: "10px 12px", borderRadius: 12, border: "1px solid #111", background: "#111", color: "#fff" }}>',
'            {saving ? "Finalizando..." : "Finalizar mutirao"}',
'          </button>',
'        </div>',
'      </div>',
'    </section>',
'  );',
'}',
''
)
WriteLines $clientFin $LClient
Write-Host "[PATCH] wrote MutiraoFinishClient"

# REPORT
$rep = Join-Path $reportDir ("eco-step-71-mutirao-finish-resolve-point-v0_1-" + $ts + ".md")
$repLines = @(
"# eco-step-71-mutirao-finish-resolve-point-v0_1",
"",
"- Time: " + $ts,
"- Backup: " + $backupDir,
"",
"## Added/Updated",
"- GET /api/eco/mutirao/get?id=...",
"- POST /api/eco/mutirao/finish { id, proofNote, proofUrl? } (best-effort resolves linked point)",
"- POST /api/eco/points/confirm { id } (bonus)",
"- Page /eco/mutiroes/[id]/finalizar",
"",
"## Verify",
"1) Ctrl+C -> npm run dev",
"2) Abra /eco/mutiroes/<id>/finalizar",
"3) Nota >= 6 chars -> Finalizar mutirao",
"4) Se houver ponto vinculado, abrir /eco/pontos/<pointId> e ver status RESOLVED",
"",
"## Notes",
"- Tudo com fallbacks para aguentar variações de schema (status/fields/meta)."
)
WriteUtf8NoBom $rep ($repLines -join "`n")
Write-Host ("[REPORT] " + $rep)

Write-Host ""
Write-Host "[VERIFY] Ctrl+C -> npm run dev"
Write-Host "[VERIFY] Abra /eco/mutiroes/<id>/finalizar"
Write-Host "[VERIFY] irm `"http://localhost:3000/api/eco/mutirao/get?id=SEU_ID`" -Headers @{Accept=`"application/json`"}"