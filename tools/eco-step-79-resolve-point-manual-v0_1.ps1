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

function DetectNewline([string]$s) {
  if ($s -match "`r`n") { return "`r`n" }
  return "`n"
}

function InsertAfter([string]$raw, [string]$needle, [string]$insert, [string]$nl) {
  $pos = $raw.IndexOf($needle)
  if ($pos -lt 0) { return $raw }
  $after = $raw.IndexOf($nl, $pos)
  if ($after -lt 0) { $after = $pos + $needle.Length }
  else { $after = $after + $nl.Length }
  return $raw.Insert($after, $insert)
}

function InsertAfterMainOpen([string]$raw, [string]$insert, [string]$nl) {
  $pos = $raw.IndexOf("<main")
  if ($pos -lt 0) { return $raw }
  $after = $raw.IndexOf(">", $pos)
  if ($after -lt 0) { return $raw }
  $after = $after + 1
  return $raw.Insert($after, $nl + $insert)
}

# ---------- setup dirs ----------
$backupDir = Join-Path $Root ('tools/_patch_backup/' + $ts + '-eco-step-79-resolve-point-manual-v0_1')
$reportDir = Join-Path $Root 'reports'
EnsureDir $backupDir
EnsureDir $reportDir

Write-Host ('== eco-step-79-resolve-point-manual-v0_1 == ' + $ts)
Write-Host ('[DIAG] Root: ' + $Root)

$srcApp = Join-Path $Root 'src/app'
if (-not (Test-Path -LiteralPath $srcApp)) { throw "[STOP] Não achei src/app" }

# detect base folder: pontos vs points
$base = $null
$tryPontos = Join-Path $srcApp 'eco/pontos/[id]'
$tryPoints = Join-Path $srcApp 'eco/points/[id]'

if (Test-Path -LiteralPath $tryPontos) { $base = 'pontos' }
elseif (Test-Path -LiteralPath $tryPoints) { $base = 'points' }
else {
  # heuristic: find any /eco/*/[id]/page.tsx that seems to be point detail
  $cands = Get-ChildItem -Path (Join-Path $srcApp 'eco') -Recurse -File -Filter 'page.tsx' -ErrorAction SilentlyContinue
  $best = $null
  $bestScore = -1
  foreach ($f in $cands) {
    $p = $f.FullName.ToLowerInvariant()
    if ($p -match "\\eco\\share\\") { continue }
    $raw = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $raw) { continue }
    $lc = $raw.ToLowerInvariant()
    $score = 0
    if ($p -match "\\eco\\pontos\\\[id\]\\") { $score += 80 }
    if ($p -match "\\eco\\points\\\[id\]\\") { $score += 80 }
    if ($p -match "\\coleta\\p\\\[id\]\\") { $score += 50 }
    if ($lc.Contains("/api/eco/points")) { $score += 60 }
    if ($lc.Contains("ponto")) { $score += 12 }
    if ($lc.Contains("status")) { $score += 8 }
    if ($score -gt $bestScore) { $bestScore = $score; $best = $f.FullName }
  }
  if ($best -and ($best.ToLowerInvariant() -match "\\eco\\pontos\\\[id\]\\")) { $base = 'pontos' }
  elseif ($best -and ($best.ToLowerInvariant() -match "\\eco\\points\\\[id\]\\")) { $base = 'points' }
  else { $base = 'pontos' } # default
}

Write-Host ('[DIAG] Base folder selected: ' + $base)

# ---------- write APIs ----------
$apiGet = Join-Path $srcApp 'api/eco/points/get/route.ts'
$apiResolve = Join-Path $srcApp 'api/eco/points/resolve/route.ts'

BackupFile $Root $apiGet $backupDir
BackupFile $Root $apiResolve $backupDir

$LApiGet = @(
'// ECO — points/get (best-effort dynamic model) — v0.1',
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
'    "ecoPoints",',
'    "ecoCriticalPoints",',
'  ];',
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
'  if (!id) return NextResponse.json({ ok: false, error: "missing_id" }, { status: 400 });',
'',
'  const mm = getPointModel();',
'  if (!mm?.model) return NextResponse.json({ ok: false, error: "model_not_ready" }, { status: 503 });',
'',
'  try {',
'    const item = await mm.model.findUnique({ where: { id } });',
'    if (!item) return NextResponse.json({ ok: false, error: "not_found" }, { status: 404 });',
'    return NextResponse.json({ ok: true, item, model: mm.key });',
'  } catch (e) {',
'    const msg = asMsg(e);',
'    if (looksLikeMissingTable(msg)) {',
'      return NextResponse.json({ ok: false, error: "db_not_ready", detail: msg }, { status: 503 });',
'    }',
'    return NextResponse.json({ ok: false, error: "db_error", detail: msg }, { status: 500 });',
'  }',
'}',
''
) -join "`n"

$LApiResolve = @(
'// ECO — points/resolve (manual resolve with proof) — v0.1',
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
'    "ecoPoints",',
'    "ecoCriticalPoints",',
'  ];',
'  for (const k of candidates) {',
'    const m = pc?.[k];',
'    if (m && typeof m.update === "function" && typeof m.findUnique === "function") return { key: k, model: m as any };',
'  }',
'  return null;',
'}',
'',
'function normStatus(v: any) {',
'  return String(v || "").trim().toUpperCase();',
'}',
'',
'export async function POST(req: Request) {',
'  const body = (await req.json().catch(() => null)) as any;',
'  const id = String(body?.id || body?.pointId || "").trim();',
'  const proofUrl = String(body?.proofUrl || body?.afterUrl || "").trim();',
'  const proofNote = String(body?.proofNote || body?.note || "").trim();',
'  const mutiraoId = String(body?.mutiraoId || "").trim();',
'  if (!id) return NextResponse.json({ ok: false, error: "missing_id" }, { status: 400 });',
'  if (!proofUrl && !proofNote) return NextResponse.json({ ok: false, error: "missing_proof" }, { status: 400 });',
'',
'  const mm = getPointModel();',
'  if (!mm?.model) return NextResponse.json({ ok: false, error: "model_not_ready" }, { status: 503 });',
'',
'  try {',
'    const existing = await mm.model.findUnique({ where: { id } });',
'    if (!existing) return NextResponse.json({ ok: false, error: "not_found" }, { status: 404 });',
'',
'    const oldMeta = (existing && existing.meta && typeof existing.meta === "object") ? existing.meta : {};',
'    const newMeta: any = {',
'      ...oldMeta,',
'      status: "RESOLVED",',
'      proofUrl: proofUrl || oldMeta.proofUrl || oldMeta.afterUrl || "",',
'      proofNote: proofNote || oldMeta.proofNote || "",',
'      resolvedAt: new Date().toISOString(),',
'      resolvedBy: "manual",',
'    };',
'    if (mutiraoId) newMeta.mutiraoId = mutiraoId;',
'',
'    const data: any = { meta: newMeta };',
'',
'    // best-effort: set top-level fields if they exist',
'    if (Object.prototype.hasOwnProperty.call(existing, "status")) data.status = "RESOLVED";',
'    if (Object.prototype.hasOwnProperty.call(existing, "state")) data.state = "RESOLVED";',
'',
'    if (proofUrl) {',
'      if (Object.prototype.hasOwnProperty.call(existing, "proofUrl")) data.proofUrl = proofUrl;',
'      if (Object.prototype.hasOwnProperty.call(existing, "afterUrl")) data.afterUrl = proofUrl;',
'      if (Object.prototype.hasOwnProperty.call(existing, "resolvedProofUrl")) data.resolvedProofUrl = proofUrl;',
'      if (Object.prototype.hasOwnProperty.call(existing, "resolvedAfterUrl")) data.resolvedAfterUrl = proofUrl;',
'    }',
'    if (proofNote) {',
'      if (Object.prototype.hasOwnProperty.call(existing, "proofNote")) data.proofNote = proofNote;',
'      if (Object.prototype.hasOwnProperty.call(existing, "resolvedNote")) data.resolvedNote = proofNote;',
'      if (Object.prototype.hasOwnProperty.call(existing, "resolutionNote")) data.resolutionNote = proofNote;',
'    }',
'',
'    const item = await mm.model.update({ where: { id }, data });',
'    return NextResponse.json({ ok: true, item, model: mm.key });',
'  } catch (e) {',
'    const msg = asMsg(e);',
'    if (looksLikeMissingTable(msg)) {',
'      return NextResponse.json({ ok: false, error: "db_not_ready", detail: msg }, { status: 503 });',
'    }',
'    return NextResponse.json({ ok: false, error: "db_error", detail: msg }, { status: 500 });',
'  }',
'}',
''
) -join "`n"

WriteUtf8NoBom $apiGet $LApiGet
WriteUtf8NoBom $apiResolve $LApiResolve
Write-Host "[PATCH] wrote APIs: points/get + points/resolve"

# ---------- write Resolver UI ----------
$resolverDir = Join-Path $srcApp ("eco/" + $base + "/[id]/resolver")
$pageFile = Join-Path $resolverDir "page.tsx"
$clientFile = Join-Path $resolverDir "PointResolveClient.tsx"

BackupFile $Root $pageFile $backupDir
BackupFile $Root $clientFile $backupDir

$LPage = @(
'// ECO — resolver ponto manualmente — v0.1',
'',
'import { PointResolveClient } from "./PointResolveClient";',
'',
'export const runtime = "nodejs";',
'export const dynamic = "force-dynamic";',
'',
'export default async function Page({ params }: any) {',
'  const p = await (params as any);',
'  const id = String(p?.id || "");',
'  return (',
'    <main style={{ padding: 16, maxWidth: 980, margin: "0 auto" }}>',
'      <h1 style={{ margin: "0 0 8px 0" }}>Resolver ponto (prova)</h1>',
'      <p style={{ margin: "0 0 14px 0", opacity: 0.85 }}>',
'        Use isso quando o ponto foi resolvido sem mutirão. Salva prova (foto) + nota e marca como RESOLVIDO.',
'      </p>',
'      <PointResolveClient id={id} />',
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
'type ApiResp = { ok: boolean; error?: string; detail?: any; item?: any; model?: string };',
'',
'function normStatus(v: any) {',
'  return String(v || "").trim().toUpperCase();',
'}',
'function isResolved(s: string) {',
'  const t = normStatus(s);',
'  return t === "RESOLVED" || t === "RESOLVIDO" || t === "DONE" || t === "CLOSED" || t === "FINALIZADO";',
'}',
'function pickStatus(p: any) {',
'  const m = (p && p.meta && typeof p.meta === "object") ? p.meta : null;',
'  return normStatus(p?.status || p?.state || m?.status || m?.state || "");',
'}',
'function pickTitle(p: any) {',
'  return String(p?.title || p?.name || p?.label || p?.kind || "Ponto crítico");',
'}',
'',
'async function apiGetPoint(id: string) {',
'  const r = await fetch("/api/eco/points/get?id=" + encodeURIComponent(id), { cache: "no-store" });',
'  return (await r.json().catch(() => ({ ok: false, error: "bad_json" }))) as ApiResp;',
'}',
'',
'async function apiUpload(file: File) {',
'  const fd = new FormData();',
'  fd.append("file", file);',
'  // best-effort: some implementations accept kind',
'  fd.append("kind", "proof");',
'  const r = await fetch("/api/eco/upload", { method: "POST", body: fd });',
'  const j = await r.json().catch(() => ({} as any));',
'  // suportar formatos diferentes',
'  const url = String((j && (j.url || j.fileUrl || j.publicUrl || (j.item && (j.item.url || j.item.fileUrl)))) || "").trim();',
'  if (!url) throw new Error("upload_sem_url");',
'  return url;',
'}',
'',
'async function apiResolve(id: string, proofUrl: string, proofNote: string) {',
'  const r = await fetch("/api/eco/points/resolve", {',
'    method: "POST",',
'    headers: { "Content-Type": "application/json" },',
'    body: JSON.stringify({ id, proofUrl, proofNote }),',
'  });',
'  return (await r.json().catch(() => ({ ok: false, error: "bad_json" }))) as ApiResp;',
'}',
'',
'export function PointResolveClient(props: { id: string }) {',
'  const id = String(props.id || "").trim();',
'  const [loading, setLoading] = useState(true);',
'  const [saving, setSaving] = useState(false);',
'  const [err, setErr] = useState<string>("");',
'  const [okMsg, setOkMsg] = useState<string>("");',
'  const [item, setItem] = useState<any>(null);',
'',
'  const [file, setFile] = useState<File | null>(null);',
'  const [note, setNote] = useState<string>("");',
'  const [proofUrl, setProofUrl] = useState<string>("");',
'',
'  const status = useMemo(() => pickStatus(item), [item]);',
'  const resolved = useMemo(() => isResolved(status), [status]);',
'',
'  useEffect(() => {',
'    let alive = true;',
'    (async () => {',
'      setLoading(true); setErr(""); setOkMsg("");',
'      try {',
'        const j = await apiGetPoint(id);',
'        if (!alive) return;',
'        if (!j.ok) throw new Error(j.error || "erro_get");',
'        setItem(j.item || null);',
'        // preload fields from meta if exist',
'        const m = (j.item && j.item.meta && typeof j.item.meta === "object") ? j.item.meta : null;',
'        const u = String((j.item && (j.item.proofUrl || j.item.afterUrl || j.item.resolvedProofUrl || j.item.resolvedAfterUrl)) || (m && (m.proofUrl || m.afterUrl || m.resolvedProofUrl || m.resolvedAfterUrl)) || "").trim();',
'        const n = String((j.item && (j.item.proofNote || j.item.resolvedNote || j.item.resolutionNote)) || (m && (m.proofNote || m.resolvedNote || m.resolutionNote)) || "").trim();',
'        if (u) setProofUrl(u);',
'        if (n) setNote(n);',
'      } catch (e: any) {',
'        setErr(String(e?.message || e));',
'      } finally {',
'        if (alive) setLoading(false);',
'      }',
'    })();',
'    return () => { alive = false; };',
'  }, [id]);',
'',
'  async function onSave() {',
'    setErr(""); setOkMsg("");',
'    if (!id) { setErr("id_invalido"); return; }',
'    if (!file && !proofUrl && !note.trim()) { setErr("Envie uma foto OU escreva uma nota."); return; }',
'    setSaving(true);',
'    try {',
'      let url = proofUrl;',
'      if (file) {',
'        url = await apiUpload(file);',
'        setProofUrl(url);',
'      }',
'      const j = await apiResolve(id, url, note);',
'      if (!j.ok) throw new Error(j.error || "erro_resolve");',
'      setItem(j.item || item);',
'      setOkMsg("Ponto marcado como RESOLVIDO.");',
'    } catch (e: any) {',
'      setErr(String(e?.message || e));',
'    } finally {',
'      setSaving(false);',
'    }',
'  }',
'',
'  if (!id) {',
'    return <div style={{ padding: 12, border: "1px solid #111", borderRadius: 14 }}>ID inválido.</div>;',
'  }',
'',
'  return (',
'    <section style={{ border: "1px solid #111", borderRadius: 16, padding: 12, background: "#fff" }}>',
'      {loading ? (',
'        <div style={{ opacity: 0.8 }}>Carregando…</div>',
'      ) : null}',
'',
'      {!loading ? (',
'        <div style={{ display: "grid", gap: 10 }}>',
'          <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: 10, flexWrap: "wrap" }}>',
'            <div>',
'              <div style={{ fontWeight: 900 }}>{pickTitle(item)}</div>',
'              <div style={{ fontSize: 13, opacity: 0.75 }}>ID: {id}</div>',
'            </div>',
'            <span',
'              style={{',
'                display: "inline-block",',
'                padding: "6px 10px",',
'                borderRadius: 999,',
'                border: "1px solid #111",',
'                fontWeight: 900,',
'                background: resolved ? "#B7FFB7" : "#FFDD00",',
'                color: "#111",',
'                textTransform: "uppercase",',
'                letterSpacing: 0.4,',
'                fontSize: 12,',
'              }}',
'            >',
'              {resolved ? "RESOLVIDO" : (status || "ABERTO")}',
'            </span>',
'          </div>',
'',
'          {proofUrl ? (',
'            <div style={{ display: "grid", gap: 6 }}>',
'              <div style={{ fontSize: 13, opacity: 0.8 }}>Prova atual</div>',
'              {/* eslint-disable-next-line @next/next/no-img-element */}',
'              <img src={proofUrl} alt="Prova" style={{ width: "100%", maxWidth: 520, borderRadius: 14, border: "1px solid #111" }} />',
'            </div>',
'          ) : null}',
'',
'          <div style={{ display: "grid", gap: 8 }}>',
'            <div style={{ fontWeight: 900 }}>Nova prova (foto)</div>',
'            <input type="file" accept="image/*" onChange={(e) => setFile((e.target.files && e.target.files[0]) ? e.target.files[0] : null)} />',
'            <div style={{ fontSize: 12, opacity: 0.75 }}>Se enviar, fazemos upload e salvamos como “prova (depois)”.</div>',
'          </div>',
'',
'          <div style={{ display: "grid", gap: 8 }}>',
'            <div style={{ fontWeight: 900 }}>Nota</div>',
'            <textarea value={note} onChange={(e) => setNote(e.target.value)} rows={4} style={{ width: "100%", padding: 10, borderRadius: 12, border: "1px solid #111" }} placeholder="Descreva o que foi feito, data, quem ajudou, riscos, etc." />',
'          </div>',
'',
'          {err ? (',
'            <div style={{ padding: 10, borderRadius: 12, border: "1px solid #111", background: "#fff2f2" }}>',
'              <b>Erro:</b> {err}',
'            </div>',
'          ) : null}',
'          {okMsg ? (',
'            <div style={{ padding: 10, borderRadius: 12, border: "1px solid #111", background: "#f0fff0" }}>',
'              {okMsg}',
'            </div>',
'          ) : null}',
'',
'          <div style={{ display: "flex", gap: 10, flexWrap: "wrap" }}>',
'            <button onClick={onSave} disabled={saving} style={{ padding: "10px 12px", borderRadius: 12, border: "1px solid #111", background: "#FFDD00", fontWeight: 900 }}>',
'              {saving ? "Salvando…" : "Marcar como RESOLVIDO"}',
'            </button>',
'            <a href="../" style={{ padding: "10px 12px", borderRadius: 12, border: "1px solid #111", textDecoration: "none", color: "#111" }}>',
'              Voltar ao ponto',
'            </a>',
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
Write-Host ('[PATCH] wrote resolver UI in eco/' + $base + '/[id]/resolver')

# ---------- patch point detail page: add link ./resolver ----------
$detailFile = $null
$detailScore = -1

$pages = Get-ChildItem -Path (Join-Path $srcApp 'eco') -Recurse -File -Filter 'page.tsx' -ErrorAction SilentlyContinue
foreach ($f in $pages) {
  $p = $f.FullName.ToLowerInvariant()
  if ($p -match "\\eco\\share\\") { continue }
  if (-not ($p -match "\\eco\\" + $base + "\\\[id\]\\page\.tsx$")) { continue }
  $raw = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction SilentlyContinue
  if (-not $raw) { continue }
  $lc = $raw.ToLowerInvariant()
  $sc = 0
  if ($lc.Contains("/api/eco/points")) { $sc += 60 }
  if ($lc.Contains("ponto")) { $sc += 10 }
  if ($lc.Contains("status")) { $sc += 6 }
  if ($sc -gt $detailScore) { $detailScore = $sc; $detailFile = $f.FullName }
}

if ($detailFile -and (Test-Path -LiteralPath $detailFile)) {
  $raw = Get-Content -LiteralPath $detailFile -Raw
  $nl = DetectNewline $raw

  if ($raw -match "href=\x27\./resolver\x27|href=\x22\./resolver\x22") {
    Write-Host "[SKIP] Detail page already has ./resolver link"
  } else {
    BackupFile $Root $detailFile $backupDir

    $block = @(
'      <div style={{ display: "flex", gap: 10, flexWrap: "wrap", margin: "10px 0" }}>',
'        <a',
'          href="./resolver"',
'          style={{',
'            padding: "10px 12px",',
'            borderRadius: 12,',
'            border: "1px solid #111",',
'            textDecoration: "none",',
'            color: "#111",',
'            background: "#FFDD00",',
'            fontWeight: 900,',
'          }}',
'        >',
'          Resolver ponto (prova)',
'        </a>',
'      </div>'
    ) -join $nl

    if ($raw -match "</h1>") {
      $raw2 = InsertAfter $raw "</h1>" ($block + $nl) $nl
    } else {
      $raw2 = InsertAfterMainOpen $raw ($block + $nl) $nl
    }

    WriteUtf8NoBom $detailFile $raw2
    Write-Host ('[PATCH] inserted resolver link into detail page: ' + $detailFile)
  }
} else {
  Write-Host "[WARN] Não consegui localizar a page.tsx do detalhe do ponto para inserir o link ./resolver."
}

# ---------- REPORT ----------
$rep = Join-Path $reportDir ('eco-step-79-resolve-point-manual-v0_1-' + $ts + '.md')
$repLines = @(
'# eco-step-79-resolve-point-manual-v0_1',
'',
'- Time: ' + $ts,
'- Backup: ' + $backupDir,
'- Base: eco/' + $base,
'',
'## Added',
'- src/app/api/eco/points/get/route.ts',
'- src/app/api/eco/points/resolve/route.ts',
'- src/app/eco/' + $base + '/[id]/resolver/page.tsx',
'- src/app/eco/' + $base + '/[id]/resolver/PointResolveClient.tsx',
'',
'## Behavior',
'- POST /api/eco/points/resolve marca RESOLVED + salva proofUrl/proofNote em meta (e top-level se existir).',
'',
'## Verify',
'1) Ctrl+C -> npm run dev',
'2) Abrir um ponto: /eco/' + $base + '/<ID>',
'3) Clicar "Resolver ponto (prova)" (ou abrir /eco/' + $base + '/<ID>/resolver)',
'4) Enviar foto e/ou nota -> "Marcar como RESOLVIDO"',
'5) Voltar ao ponto e ver: status/Prova/Nota (no bloco que já criamos no Passo 77)'
)
WriteUtf8NoBom $rep ($repLines -join "`n")
Write-Host ('[REPORT] ' + $rep)

Write-Host ""
Write-Host "[VERIFY] Ctrl+C -> npm run dev"
Write-Host ("[VERIFY] /eco/" + $base + "/<ID>/resolver -> enviar prova/nota -> salvar")