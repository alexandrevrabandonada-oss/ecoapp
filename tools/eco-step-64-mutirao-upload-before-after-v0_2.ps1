param(
  [string]$Root = (Get-Location).Path
)

$ts = Get-Date -Format 'yyyyMMdd-HHmmss'

# --- bootstrap
$boot = Join-Path $Root "tools/_bootstrap.ps1"
if (Test-Path $boot) { . $boot }

# --- fallbacks (se o bootstrap não tiver)
if (-not (Get-Command EnsureDir -ErrorAction SilentlyContinue)) {
  function EnsureDir([string]$p) { if (-not (Test-Path $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null } }
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
    if (Test-Path $p) {
      $rel = $p.Substring($root.Length).TrimStart('\','/')
      $dest = Join-Path $backupDir ($rel -replace '[\\/]', '__')
      Copy-Item -Force -LiteralPath $p -Destination $dest
      Write-Host ('[BK] ' + $rel + ' -> ' + (Split-Path -Leaf $dest))
    }
  }
}

function WriteLinesUtf8NoBom([string]$p, [string[]]$lines) {
  $text = ($lines -join "`n")
  WriteUtf8NoBom $p $text
}

$backupDir = Join-Path $Root ('tools/_patch_backup/' + $ts + '-eco-step-64-mutirao-upload-before-after-v0_2')
$reportDir = Join-Path $Root 'reports'
EnsureDir $backupDir
EnsureDir $reportDir

Write-Host ('== eco-step-64-mutirao-upload-before-after-v0_2 == ' + $ts)
Write-Host ('[DIAG] Root: ' + $Root)

$apiUpload    = Join-Path $Root 'src/app/api/eco/upload/route.ts'
$detailClient = Join-Path $Root 'src/app/eco/mutiroes/[id]/MutiraoDetailClient.tsx'
$cardRoute    = Join-Path $Root 'src/app/api/eco/mutirao/card/route.tsx'

Write-Host ('[DIAG] Will write: ' + $apiUpload)
Write-Host ('[DIAG] Will patch: ' + $detailClient)
Write-Host ('[DIAG] Will patch: ' + $cardRoute)

BackupFile $Root $apiUpload $backupDir
BackupFile $Root $detailClient $backupDir
BackupFile $Root $cardRoute $backupDir

# --- API: /api/eco/upload
$LUpload = @(
'import { NextResponse } from "next/server";',
'import { mkdir, writeFile } from "node:fs/promises";',
'import path from "node:path";',
'import crypto from "node:crypto";',
'',
'export const runtime = "nodejs";',
'export const dynamic = "force-dynamic";',
'',
'function cleanPrefix(v: any) {',
'  const s = String(v || "").trim().toLowerCase();',
'  if (!s) return "eco";',
'  return s.replace(/[^a-z0-9_-]/g, "").slice(0, 24) || "eco";',
'}',
'function extFrom(file: File) {',
'  const name = String((file as any).name || "");',
'  const t = String((file as any).type || "");',
'  if (t.includes("png")) return "png";',
'  if (t.includes("webp")) return "webp";',
'  if (t.includes("jpeg") || t.includes("jpg")) return "jpg";',
'  const m = name.toLowerCase().match(/\.([a-z0-9]{1,5})$/);',
'  if (m && m[1]) return m[1];',
'  return "jpg";',
'}',
'',
'export async function POST(req: Request) {',
'  try {',
'    const form = await req.formData();',
'    const file = form.get("file");',
'    const prefix = cleanPrefix(form.get("prefix"));',
'    if (!file || !(file instanceof File)) {',
'      return NextResponse.json({ ok: false, error: "missing_file" }, { status: 400 });',
'    }',
'    const maxBytes = 6 * 1024 * 1024;',
'    const size = Number((file as any).size || 0);',
'    if (size <= 0) return NextResponse.json({ ok: false, error: "bad_file" }, { status: 400 });',
'    if (size > maxBytes) return NextResponse.json({ ok: false, error: "too_big", maxBytes }, { status: 413 });',
'',
'    const ab = await file.arrayBuffer();',
'    const buf = Buffer.from(ab);',
'',
'    const now = new Date();',
'    const yyyy = String(now.getFullYear());',
'    const mm = String(now.getMonth() + 1).padStart(2, "0");',
'    const ext = extFrom(file);',
'    const name = prefix + "_" + now.getTime() + "_" + crypto.randomUUID().slice(0, 8) + "." + ext;',
'',
'    const relDir = path.join("public", "eco-uploads", yyyy, mm);',
'    const absDir = path.join(process.cwd(), relDir);',
'    await mkdir(absDir, { recursive: true });',
'',
'    const absFile = path.join(absDir, name);',
'    await writeFile(absFile, buf);',
'',
'    const url = "/eco-uploads/" + yyyy + "/" + mm + "/" + name;',
'    return NextResponse.json({ ok: true, url, bytes: buf.length, type: String((file as any).type || "") });',
'  } catch (e: any) {',
'    const msg = e && e.message ? String(e.message) : "upload_failed";',
'    return NextResponse.json({ ok: false, error: "upload_failed", detail: msg }, { status: 500 });',
'  }',
'}',
''
)
WriteLinesUtf8NoBom $apiUpload $LUpload
Write-Host '[PATCH] wrote src/app/api/eco/upload/route.ts'

# --- UI: MutiraoDetailClient (upload antes/depois)
$LDetail = @(
'"use client";',
'',
'import { useEffect, useMemo, useState } from "react";',
'',
'type AnyObj = Record<string, any>;',
'',
'async function jget(url: string): Promise<AnyObj> {',
'  const res = await fetch(url, { headers: { Accept: "application/json" }, cache: "no-store" });',
'  const data = await res.json().catch(() => ({}));',
'  if (!res.ok) return { ok: false, status: res.status, ...data };',
'  return data;',
'}',
'async function jpost(url: string, body: AnyObj): Promise<AnyObj> {',
'  const res = await fetch(url, { method: "POST", headers: { "Content-Type": "application/json", Accept: "application/json" }, body: JSON.stringify(body), cache: "no-store" });',
'  const data = await res.json().catch(() => ({}));',
'  if (!res.ok) return { ok: false, status: res.status, ...data };',
'  return data;',
'}',
'',
'function chkDefault() {',
'  return { luvas: false, sacos: false, agua: false, separacao: false, destino: false, aviso_vizinhos: false };',
'}',
'',
'async function uploadEco(file: File, prefix: string) {',
'  const fd = new FormData();',
'  fd.append("file", file);',
'  fd.append("prefix", prefix);',
'  const res = await fetch("/api/eco/upload", { method: "POST", body: fd, cache: "no-store" });',
'  const data = await res.json().catch(() => ({}));',
'  if (!res.ok) return { ok: false, status: res.status, ...data };',
'  return data;',
'}',
'',
'export default function MutiraoDetailClient({ id }: { id: string }) {',
'  const [status, setStatus] = useState<string>("carregando");',
'  const [item, setItem] = useState<AnyObj | null>(null);',
'  const [msg, setMsg] = useState<string>("");',
'',
'  const [beforeUrl, setBeforeUrl] = useState<string>("");',
'  const [afterUrl, setAfterUrl] = useState<string>("");',
'  const [check, setCheck] = useState<AnyObj>(chkDefault());',
'',
'  const [upBefore, setUpBefore] = useState<boolean>(false);',
'  const [upAfter, setUpAfter] = useState<boolean>(false);',
'',
'  const card3x4 = useMemo(() => "/api/eco/mutirao/card?format=3x4&id=" + encodeURIComponent(id), [id]);',
'  const shareUrl = useMemo(() => "/eco/share/mutirao/" + encodeURIComponent(id), [id]);',
'',
'  async function refresh() {',
'    setStatus("carregando");',
'    setMsg("");',
'    const d = await jget("/api/eco/mutirao/get?id=" + encodeURIComponent(id));',
'    if (d && d.ok && d.item) {',
'      setItem(d.item);',
'      setBeforeUrl(String(d.item.beforeUrl || ""));',
'      setAfterUrl(String(d.item.afterUrl || ""));',
'      setCheck(d.item.checklist && typeof d.item.checklist === "object" ? d.item.checklist : chkDefault());',
'      setStatus("ok");',
'    } else {',
'      setItem(null);',
'      setStatus("erro");',
'      setMsg("Erro: " + String(d?.error || d?.detail || "unknown"));',
'    }',
'  }',
'  useEffect(() => { refresh(); }, [id]);',
'',
'  function toggle(k: string) { setCheck((prev: AnyObj) => ({ ...prev, [k]: !prev?.[k] })); }',
'',
'  async function saveDraft() {',
'    setMsg("");',
'    const d = await jpost("/api/eco/mutirao/update", { id, beforeUrl, afterUrl, checklist: check });',
'    if (d && d.ok) { setMsg("Rascunho salvo."); await refresh(); }',
'    else setMsg("Erro: " + String(d?.error || d?.detail || "unknown"));',
'  }',
'  async function finish() {',
'    setMsg("");',
'    const d = await jpost("/api/eco/mutirao/finish", { id, beforeUrl, afterUrl, checklist: check });',
'    if (d && d.ok) { setMsg("Mutirão finalizado (DONE)."); await refresh(); }',
'    else setMsg("Erro: " + String(d?.error || d?.detail || "unknown"));',
'  }',
'',
'  async function onPickBefore(f: File | null) {',
'    if (!f) return;',
'    setUpBefore(true);',
'    setMsg("");',
'    const r = await uploadEco(f, "mutirao_before");',
'    setUpBefore(false);',
'    if (r && r.ok && r.url) { setBeforeUrl(String(r.url)); setMsg("Upload (antes) ok."); }',
'    else setMsg("Upload falhou: " + String(r?.error || r?.detail || "unknown"));',
'  }',
'  async function onPickAfter(f: File | null) {',
'    if (!f) return;',
'    setUpAfter(true);',
'    setMsg("");',
'    const r = await uploadEco(f, "mutirao_after");',
'    setUpAfter(false);',
'    if (r && r.ok && r.url) { setAfterUrl(String(r.url)); setMsg("Upload (depois) ok."); }',
'    else setMsg("Upload falhou: " + String(r?.error || r?.detail || "unknown"));',
'  }',
'',
'  const p = item?.point || {};',
'',
'  return (',
'    <section style={{ display: "grid", gap: 12 }}>',
'      <div style={{ display: "flex", gap: 10, flexWrap: "wrap", alignItems: "center" }}>',
'        <a href="/eco/mutiroes" style={{ textDecoration: "none", padding: "8px 10px", borderRadius: 10, border: "1px solid #111" }}>Voltar</a>',
'        <a href={shareUrl} style={{ textDecoration: "none", padding: "8px 10px", borderRadius: 10, border: "1px solid #111" }}>Página de share</a>',
'        <a href={card3x4} target="_blank" rel="noreferrer" style={{ textDecoration: "none", padding: "8px 10px", borderRadius: 10, border: "1px solid #111" }}>Ver card (3:4)</a>',
'        <div style={{ opacity: 0.7 }}>status: {status}</div>',
'      </div>',
'',
'      <div style={{ display: "grid", gap: 8, padding: 12, border: "1px solid #ddd", borderRadius: 12 }}>',
'        <div style={{ fontWeight: 900 }}>Ponto</div>',
'        <div style={{ opacity: 0.9 }}>{String(p.kind || "—")}</div>',
'        <div style={{ opacity: 0.85 }}>{p.note ? String(p.note) : "—"}</div>',
'        <div style={{ opacity: 0.7, fontSize: 12 }}>confirmações: {String(p.confirmCount || 0)}</div>',
'      </div>',
'',
'      <div style={{ display: "grid", gap: 10, padding: 12, border: "1px solid #ddd", borderRadius: 12 }}>',
'        <div style={{ fontWeight: 900 }}>Antes / Depois (upload simples)</div>',
'',
'        <div style={{ display: "grid", gap: 8 }}>',
'          <div style={{ display: "flex", gap: 10, flexWrap: "wrap", alignItems: "center" }}>',
'            <label style={{ display: "grid", gap: 6 }}>',
'              <span>Foto ANTES</span>',
'              <input type="file" accept="image/*" disabled={upBefore} onChange={(e) => onPickBefore(e.target.files && e.target.files[0] ? e.target.files[0] : null)} />',
'            </label>',
'            <div style={{ opacity: 0.7 }}>{upBefore ? "enviando..." : (beforeUrl ? "ok" : "sem foto")}</div>',
'          </div>',
'          {beforeUrl ? <img src={beforeUrl} alt="antes" style={{ width: "100%", maxWidth: 520, borderRadius: 12, border: "1px solid #eee" }} /> : null}',
'          <label style={{ display: "grid", gap: 4 }}>',
'            <span>Antes (URL manual — opcional)</span>',
'            <input value={beforeUrl} onChange={(e) => setBeforeUrl(e.target.value)} placeholder="/eco-uploads/... ou https://..." style={{ padding: 10, borderRadius: 10, border: "1px solid #ccc" }} />',
'          </label>',
'        </div>',
'',
'        <div style={{ display: "grid", gap: 8 }}>',
'          <div style={{ display: "flex", gap: 10, flexWrap: "wrap", alignItems: "center" }}>',
'            <label style={{ display: "grid", gap: 6 }}>',
'              <span>Foto DEPOIS</span>',
'              <input type="file" accept="image/*" disabled={upAfter} onChange={(e) => onPickAfter(e.target.files && e.target.files[0] ? e.target.files[0] : null)} />',
'            </label>',
'            <div style={{ opacity: 0.7 }}>{upAfter ? "enviando..." : (afterUrl ? "ok" : "sem foto")}</div>',
'          </div>',
'          {afterUrl ? <img src={afterUrl} alt="depois" style={{ width: "100%", maxWidth: 520, borderRadius: 12, border: "1px solid #eee" }} /> : null}',
'          <label style={{ display: "grid", gap: 4 }}>',
'            <span>Depois (URL manual — opcional)</span>',
'            <input value={afterUrl} onChange={(e) => setAfterUrl(e.target.value)} placeholder="/eco-uploads/... ou https://..." style={{ padding: 10, borderRadius: 10, border: "1px solid #ccc" }} />',
'          </label>',
'        </div>',
'',
'        <div style={{ opacity: 0.7, fontSize: 12 }}>Depois do upload, clique em “Salvar rascunho” ou “Finalizar (DONE)” pra gravar no banco.</div>',
'      </div>',
'',
'      <div style={{ display: "grid", gap: 10, padding: 12, border: "1px solid #ddd", borderRadius: 12 }}>',
'        <div style={{ fontWeight: 900 }}>Checklist do mutirão</div>',
'        <div style={{ display: "grid", gap: 8 }}>',
'          {["luvas","sacos","agua","separacao","destino","aviso_vizinhos"].map((k) => (',
'            <label key={k} style={{ display: "flex", gap: 10, alignItems: "center" }}>',
'              <input type="checkbox" checked={!!check?.[k]} onChange={() => toggle(k)} />',
'              <span style={{ opacity: 0.9 }}>{k}</span>',
'            </label>',
'          ))}',
'        </div>',
'      </div>',
'',
'      <div style={{ display: "flex", gap: 10, flexWrap: "wrap", alignItems: "center" }}>',
'        <button onClick={saveDraft} style={{ padding: "10px 12px", borderRadius: 12, border: "1px solid #111", background: "#fff", cursor: "pointer" }}>Salvar rascunho</button>',
'        <button onClick={finish} style={{ padding: "10px 12px", borderRadius: 12, border: "1px solid #111", background: "#111", color: "#F7D500", fontWeight: 900, cursor: "pointer" }}>Finalizar (DONE)</button>',
'      </div>',
'',
'      {msg ? <div style={{ padding: 10, borderRadius: 10, background: "#fff7cc", border: "1px solid #f0d000" }}>{msg}</div> : null}',
'    </section>',
'  );',
'}',
''
)
WriteLinesUtf8NoBom $detailClient $LDetail
Write-Host '[PATCH] wrote src/app/eco/mutiroes/[id]/MutiraoDetailClient.tsx'

# --- OG card: imagens antes/depois
$LCard = @(
'/* eslint-disable @next/next/no-img-element */',
'import { ImageResponse } from "next/og";',
'import { NextResponse } from "next/server";',
'import { prisma } from "@/lib/prisma";',
'',
'export const runtime = "nodejs";',
'export const dynamic = "force-dynamic";',
'',
'function getMutiraoModel() { const pc: any = prisma as any; return pc?.ecoMutirao; }',
'function clampFormat(f: string) { return f === "1x1" ? "1x1" : "3x4"; }',
'function safe(s: any, max: number) { return String(s || "").slice(0, max); }',
'',
'function fmtDay(iso: string) {',
'  try { const d = new Date(iso); const pad = (n: number) => String(n).padStart(2, "0"); return pad(d.getDate()) + "/" + pad(d.getMonth() + 1) + "/" + d.getFullYear(); } catch { return ""; }',
'}',
'function fmtTime(iso: string) {',
'  try { const d = new Date(iso); const pad = (n: number) => String(n).padStart(2, "0"); return pad(d.getHours()) + ":" + pad(d.getMinutes()); } catch { return ""; }',
'}',
'function absSrc(origin: string, url: any) {',
'  const s = String(url || "").trim();',
'  if (!s) return null;',
'  if (s.startsWith("http://") || s.startsWith("https://") || s.startsWith("data:")) return s;',
'  if (s.startsWith("/")) return origin + s;',
'  return null;',
'}',
'',
'export async function GET(req: Request) {',
'  const { searchParams } = new URL(req.url);',
'  const id = String(searchParams.get("id") || "").trim();',
'  const format = clampFormat(String(searchParams.get("format") || "3x4"));',
'  if (!id) return NextResponse.json({ ok: false, error: "bad_id" }, { status: 400 });',
'',
'  const m = getMutiraoModel();',
'  if (!m?.findUnique) return NextResponse.json({ ok: false, error: "model_not_ready" }, { status: 503 });',
'',
'  const item = await m.findUnique({ where: { id }, include: { point: true } });',
'  if (!item) return NextResponse.json({ ok: false, error: "not_found" }, { status: 404 });',
'',
'  const origin = new URL(req.url).origin;',
'  const W = 1080;',
'  const H = format === "1x1" ? 1080 : 1350;',
'',
'  const startIso = item.startAt ? String(item.startAt) : "";',
'  const day = startIso ? fmtDay(startIso) : "";',
'  const time = startIso ? fmtTime(startIso) : "";',
'  const dur = String(item.durationMin || 90);',
'  const st = String(item.status || "SCHEDULED");',
'',
'  const kind = safe(item.point?.kind, 24);',
'  const note = safe(item.point?.note, 140);',
'  const confirm = String(item.point?.confirmCount || 0);',
'',
'  const beforeSrc = absSrc(origin, (item as any).beforeUrl);',
'  const afterSrc  = absSrc(origin, (item as any).afterUrl);',
'',
'  const boxW = format === "1x1" ? 470 : 420;',
'  const boxH = format === "1x1" ? 330 : 420;',
'',
'  return new ImageResponse(',
'    (',
'      <div style={{ width: W, height: H, background: "#0b0b0b", color: "#F7D500", padding: 56, display: "flex", flexDirection: "column", justifyContent: "space-between" }}>',
'        <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>',
'          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>',
'            <div style={{ fontSize: 34, fontWeight: 900, letterSpacing: 1 }}>ECO — MUTIRÃO</div>',
'            <div style={{ fontSize: 22, fontWeight: 800, padding: "8px 12px", borderRadius: 999, background: st === "DONE" ? "#F7D500" : "#222", color: st === "DONE" ? "#111" : "#F7D500" }}>{st}</div>',
'          </div>',
'          <div style={{ display: "flex", gap: 10, flexWrap: "wrap", alignItems: "center", color: "#fff" }}>',
'            <div style={{ fontSize: 24, fontWeight: 900 }}>{day} {time ? ("• " + time) : ""}</div>',
'            <div style={{ opacity: 0.9, fontSize: 20 }}>⏱ {dur} min</div>',
'            <div style={{ opacity: 0.9, fontSize: 20 }}>✅ conf.: {confirm}</div>',
'          </div>',
'          <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>',
'            <div style={{ fontSize: 22, fontWeight: 900, color: "#F7D500" }}>{kind || "PONTO"}</div>',
'            <div style={{ fontSize: 18, color: "#ddd" }}>{note || "—"}</div>',
'          </div>',
'        </div>',
'',
'        <div style={{ display: "flex", gap: 16 }}>',
'          <div style={{ width: boxW, height: boxH, borderRadius: 18, border: "2px solid #333", background: "#111", display: "flex", alignItems: "center", justifyContent: "center", overflow: "hidden" }}>',
'            {beforeSrc ? <img src={beforeSrc} alt="antes" style={{ width: "100%", height: "100%", objectFit: "cover" }} /> : (',
'              <div style={{ display: "flex", flexDirection: "column", gap: 6, alignItems: "center" }}>',
'                <div style={{ fontSize: 20, fontWeight: 900, color: "#F7D500" }}>ANTES</div>',
'                <div style={{ fontSize: 14, color: "#bbb" }}>sem foto</div>',
'              </div>',
'            )}',
'          </div>',
'          <div style={{ width: boxW, height: boxH, borderRadius: 18, border: "2px solid #333", background: "#111", display: "flex", alignItems: "center", justifyContent: "center", overflow: "hidden" }}>',
'            {afterSrc ? <img src={afterSrc} alt="depois" style={{ width: "100%", height: "100%", objectFit: "cover" }} /> : (',
'              <div style={{ display: "flex", flexDirection: "column", gap: 6, alignItems: "center" }}>',
'                <div style={{ fontSize: 20, fontWeight: 900, color: "#F7D500" }}>DEPOIS</div>',
'                <div style={{ fontSize: 14, color: "#bbb" }}>sem foto</div>',
'              </div>',
'            )}',
'          </div>',
'        </div>',
'',
'        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>',
'          <div style={{ fontSize: 16, color: "#bbb" }}>Recibo é lei. Cuidado é coletivo. Trabalho digno é o centro.</div>',
'          <div style={{ fontSize: 16, color: "#bbb" }}>#ECO — Escutar • Cuidar • Organizar</div>',
'        </div>',
'      </div>',
'    ),',
'    { width: W, height: H }',
'  );',
'}',
''
)
WriteLinesUtf8NoBom $cardRoute $LCard
Write-Host '[PATCH] wrote src/app/api/eco/mutirao/card/route.tsx'

$rep = Join-Path $reportDir ('eco-step-64-mutirao-upload-before-after-v0_2-' + $ts + '.md')
$repLines = @(
'# eco-step-64-mutirao-upload-before-after-v0_2',
'',
'- Time: ' + $ts,
'- Backup: ' + $backupDir,
'',
'## Added',
'- POST /api/eco/upload (multipart -> public/eco-uploads)',
'',
'## Patched',
'- /eco/mutiroes/[id] upload antes/depois',
'- /api/eco/mutirao/card renderiza imagens',
'',
'## Verify',
'1) restart dev',
'2) abrir /eco/mutiroes/[id], subir fotos, salvar',
'3) abrir /api/eco/mutirao/card?format=3x4&id=...',
''
)
WriteLinesUtf8NoBom $rep $repLines
Write-Host ('[REPORT] ' + $rep)

Write-Host ''
Write-Host '[VERIFY] Ctrl+C -> npm run dev'
Write-Host '[VERIFY] /eco/mutiroes/[id] -> upload -> salvar -> card 3:4'