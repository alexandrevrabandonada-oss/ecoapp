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
  if ($after -lt 0) { $after = $pos + $needle.Length } else { $after = $after + $nl.Length }
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

# ---------- setup ----------
$backupDir = Join-Path $Root ('tools/_patch_backup/' + $ts + '-eco-step-80-share-point-card-v0_1')
$reportDir = Join-Path $Root 'reports'
EnsureDir $backupDir
EnsureDir $reportDir

Write-Host ('== eco-step-80-share-point-card-v0_1 == ' + $ts)
Write-Host ('[DIAG] Root: ' + $Root)

$srcApp = Join-Path $Root 'src/app'
if (-not (Test-Path -LiteralPath $srcApp)) { throw "[STOP] Nao achei src/app" }

# detect base folder: pontos vs points
$base = $null
$tryPontos = Join-Path $srcApp 'eco/pontos/[id]'
$tryPoints = Join-Path $srcApp 'eco/points/[id]'
if (Test-Path -LiteralPath $tryPontos) { $base = 'pontos' }
elseif (Test-Path -LiteralPath $tryPoints) { $base = 'points' }
else { $base = 'pontos' }

Write-Host ('[DIAG] Base folder selected: ' + $base)

# ---------- API: /api/eco/points/card ----------
$apiCard = Join-Path $srcApp 'api/eco/points/card/route.tsx'
BackupFile $Root $apiCard $backupDir

$LApi = @(
'// ECO — points/card (ImageResponse) — v0.1',
'',
'import { ImageResponse } from "next/og";',
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
'function normStatus(v: any) {',
'  return String(v || "").trim().toUpperCase();',
'}',
'function pickStatus(p: any) {',
'  const m = (p && p.meta && typeof p.meta === "object") ? p.meta : null;',
'  return normStatus(p?.status || p?.state || (m && (m.status || m.state)) || "");',
'}',
'function isResolved(s: string) {',
'  const t = normStatus(s);',
'  return t === "RESOLVED" || t === "RESOLVIDO" || t === "DONE" || t === "CLOSED" || t === "FINALIZADO";',
'}',
'function pickTitle(p: any) {',
'  return String(p?.title || p?.name || p?.label || p?.kind || "Ponto critico");',
'}',
'function pickNeighborhood(p: any) {',
'  const m = (p && p.meta && typeof p.meta === "object") ? p.meta : null;',
'  return String(p?.bairro || p?.neighborhood || (m && (m.bairro || m.neighborhood)) || "").trim();',
'}',
'function pickCity(p: any) {',
'  const m = (p && p.meta && typeof p.meta === "object") ? p.meta : null;',
'  return String(p?.cidade || p?.city || (m && (m.cidade || m.city)) || "Volta Redonda").trim();',
'}',
'function pickProof(p: any) {',
'  const m = (p && p.meta && typeof p.meta === "object") ? p.meta : null;',
'  const u = String(p?.proofUrl || p?.afterUrl || p?.resolvedProofUrl || p?.resolvedAfterUrl || (m && (m.proofUrl || m.afterUrl || m.resolvedProofUrl || m.resolvedAfterUrl)) || "").trim();',
'  const n = String(p?.proofNote || p?.resolvedNote || p?.resolutionNote || (m && (m.proofNote || m.resolvedNote || m.resolutionNote)) || "").trim();',
'  return { u, n };',
'}',
'function safeFormat(f: string) {',
'  const t = String(f || "").trim().toLowerCase();',
'  if (t === "1x1" || t === "square") return "1x1";',
'  return "3x4";',
'}',
'',
'export async function GET(req: Request) {',
'  const { searchParams } = new URL(req.url);',
'  const id = String(searchParams.get("id") || searchParams.get("pointId") || "").trim();',
'  const format = safeFormat(String(searchParams.get("format") || "3x4"));',
'  if (!id) return new Response("missing id", { status: 400 });',
'',
'  const mm = getPointModel();',
'  if (!mm?.model) return new Response("model_not_ready", { status: 503 });',
'',
'  try {',
'    const item = await mm.model.findUnique({ where: { id } });',
'    if (!item) return new Response("not_found", { status: 404 });',
'',
'    const status = pickStatus(item);',
'    const resolved = isResolved(status);',
'    const title = pickTitle(item);',
'    const bairro = pickNeighborhood(item);',
'    const city = pickCity(item);',
'    const pr = pickProof(item);',
'',
'    const W = format === "1x1" ? 1080 : 1080;',
'    const H = format === "1x1" ? 1080 : 1350;',
'',
'    const bg = "#F7F7F7";',
'    const yellow = "#FFDD00";',
'    const black = "#111111";',
'    const green = "#B7FFB7";',
'    const red = "#FF3B30";',
'',
'    const badgeBg = resolved ? green : yellow;',
'    const badgeText = black;',
'',
'    const small = format === "1x1";',
'',
'    return new ImageResponse(',
'      (',
'        <div',
'          style={{',
'            width: W,',
'            height: H,',
'            display: "flex",',
'            flexDirection: "column",',
'            background: bg,',
'            padding: 48,',
'            fontFamily: "ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Arial",',
'            color: black,',
'          }}',
'        >',
'          <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>',
'            <div style={{ display: "flex", alignItems: "center", gap: 12 }}>',
'              <div style={{ width: 14, height: 14, borderRadius: 999, background: yellow, border: "2px solid " + black }} />',
'              <div style={{ fontWeight: 900, fontSize: 34, letterSpacing: 0.6 }}>ECO</div>',
'              <div style={{ fontSize: 18, opacity: 0.8, fontWeight: 800 }}>PONTO CRITICO</div>',
'            </div>',
'            <div style={{ display: "flex", alignItems: "center", gap: 10 }}>',
'              <div',
'                style={{',
'                  display: "flex",',
'                  alignItems: "center",',
'                  padding: "10px 16px",',
'                  borderRadius: 999,',
'                  border: "2px solid " + black,',
'                  background: badgeBg,',
'                  color: badgeText,',
'                  fontWeight: 900,',
'                  fontSize: 18,',
'                  letterSpacing: 0.6,',
'                }}',
'              >',
'                {resolved ? "RESOLVIDO" : (status || "ABERTO")}',
'              </div>',
'            </div>',
'          </div>',
'',
'          <div style={{ height: 18 }} />',
'',
'          <div',
'            style={{',
'              display: "flex",',
'              flexDirection: "column",',
'              border: "2px solid " + black,',
'              borderRadius: 28,',
'              padding: 34,',
'              background: "#FFFFFF",',
'              boxShadow: "0 6px 0 " + black,',
'            }}',
'          >',
'            <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>',
'              <div style={{ fontSize: small ? 44 : 56, fontWeight: 950, lineHeight: 1.03 }}>',
'                {title}',
'              </div>',
'              <div style={{ display: "flex", gap: 10, flexWrap: "wrap", alignItems: "center" }}>',
'                <div style={{ display: "flex", alignItems: "center", gap: 10 }}>',
'                  <div style={{ width: 10, height: 10, borderRadius: 999, background: black }} />',
'                  <div style={{ fontSize: 20, fontWeight: 800, opacity: 0.85 }}>',
'                    {bairro ? (bairro + " - " + city) : city}',
'                  </div>',
'                </div>',
'                <div style={{ display: "flex", alignItems: "center", gap: 10, opacity: 0.85 }}>',
'                  <div style={{ width: 10, height: 10, borderRadius: 999, background: resolved ? green : red, border: "1px solid " + black }} />',
'                  <div style={{ fontSize: 18, fontWeight: 800 }}>',
'                    {resolved ? "Cuidado fez efeito" : "Precisa de cuidado"}',
'                  </div>',
'                </div>',
'              </div>',
'            </div>',
'',
'            <div style={{ height: 20 }} />',
'',
'            <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>',
'              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>',
'                <div style={{ display: "flex", gap: 10, alignItems: "center" }}>',
'                  <div style={{ fontWeight: 900, fontSize: 18, opacity: 0.85 }}>ID</div>',
'                  <div style={{ fontSize: 18, fontWeight: 900, letterSpacing: 0.4 }}>{id}</div>',
'                </div>',
'                <div style={{ display: "flex", gap: 10, alignItems: "center" }}>',
'                  <div style={{ fontSize: 14, fontWeight: 900, opacity: 0.75 }}>Recibo e lei</div>',
'                  <div style={{ width: 10, height: 10, borderRadius: 999, background: yellow, border: "2px solid " + black }} />',
'                </div>',
'              </div>',
'',
'              {(pr.u || pr.n) ? (',
'                <div style={{ display: "flex", flexDirection: "column", gap: 8, borderTop: "2px dashed " + black, paddingTop: 14 }}>',
'                  <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>',
'                    <div style={{ fontSize: 18, fontWeight: 950 }}>PROVA</div>',
'                    <div style={{ fontSize: 14, fontWeight: 900, opacity: 0.75 }}>{pr.u ? "foto" : "nota"}</div>',
'                  </div>',
'                  <div style={{ display: "flex", flexDirection: "column", gap: 6 }}>',
'                    {pr.n ? <div style={{ fontSize: 18, opacity: 0.9 }}>{pr.n.length > 120 ? (pr.n.slice(0, 117) + "...") : pr.n}</div> : null}',
'                    {pr.u ? <div style={{ fontSize: 14, opacity: 0.75 }}>comprovado</div> : null}',
'                  </div>',
'                </div>',
'              ) : (',
'                <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", borderTop: "2px dashed " + black, paddingTop: 14 }}>',
'                  <div style={{ fontSize: 18, fontWeight: 950 }}>SEM PROVA AINDA</div>',
'                  <div style={{ fontSize: 14, fontWeight: 900, opacity: 0.75 }}>poste e confirme</div>',
'                </div>',
'              )}',
'            </div>',
'          </div>',
'',
'          <div style={{ flex: 1, display: "flex" }} />',
'',
'          <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>',
'            <div style={{ display: "flex", flexDirection: "column", gap: 6 }}>',
'              <div style={{ fontSize: 18, fontWeight: 950 }}>CUIDADO E COLETIVO</div>',
'              <div style={{ fontSize: 14, opacity: 0.8, fontWeight: 800 }}>',
'                Recibo e lei. Cuidado e coletivo. Trabalho digno no centro.',
'              </div>',
'            </div>',
'            <div style={{ display: "flex", alignItems: "center", gap: 10 }}>',
'              <div style={{ width: 18, height: 18, borderRadius: 999, background: yellow, border: "2px solid " + black }} />',
'              <div style={{ fontWeight: 950, letterSpacing: 0.4, fontSize: 16 }}>#ECO</div>',
'            </div>',
'          </div>',
'        </div>',
'      ),',
'      { width: W, height: H }',
'    );',
'  } catch (e) {',
'    const msg = asMsg(e);',
'    if (looksLikeMissingTable(msg)) return new Response("db_not_ready", { status: 503 });',
'    return new Response("db_error", { status: 500 });',
'  }',
'}',
''
) -join "`n"

WriteUtf8NoBom $apiCard $LApi
Write-Host "[PATCH] wrote api/eco/points/card (route.tsx)"

# ---------- SHARE PAGE: /eco/share/ponto/[id] ----------
$shareDir = Join-Path $srcApp 'eco/share/ponto/[id]'
$pageFile = Join-Path $shareDir 'page.tsx'
$clientFile = Join-Path $shareDir 'SharePointClient.tsx'

BackupFile $Root $pageFile $backupDir
BackupFile $Root $clientFile $backupDir

$LPage = @(
'// ECO — compartilhar ponto — v0.1',
'',
'import { SharePointClient } from "./SharePointClient";',
'',
'export const runtime = "nodejs";',
'export const dynamic = "force-dynamic";',
'',
'export default async function Page({ params }: any) {',
'  const p = await (params as any);',
'  const id = String(p?.id || "");',
'  return (',
'    <main style={{ padding: 16, maxWidth: 1100, margin: "0 auto" }}>',
'      <h1 style={{ margin: "0 0 8px 0" }}>Compartilhar ponto: {id}</h1>',
'      <p style={{ margin: "0 0 14px 0", opacity: 0.85 }}>Card + legenda prontos para postar.</p>',
'      <SharePointClient id={id} />',
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
'function normStatus(v: any) { return String(v || "").trim().toUpperCase(); }',
'function isResolved(s: string) {',
'  const t = normStatus(s);',
'  return t === "RESOLVED" || t === "RESOLVIDO" || t === "DONE" || t === "CLOSED" || t === "FINALIZADO";',
'}',
'function pickStatus(p: any) {',
'  const m = (p && p.meta && typeof p.meta === "object") ? p.meta : null;',
'  return normStatus(p?.status || p?.state || (m && (m.status || m.state)) || "");',
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
'',
'async function apiGetPoint(id: string) {',
'  const r = await fetch("/api/eco/points/get?id=" + encodeURIComponent(id), { cache: "no-store" });',
'  return (await r.json().catch(() => ({ ok: false, error: "bad_json" }))) as ApiResp;',
'}',
'',
'function buildCaption(p: any, id: string, url: string) {',
'  const status = pickStatus(p);',
'  const resolved = isResolved(status);',
'  const title = pickTitle(p);',
'  const bairro = pickNeighborhood(p);',
'  const city = pickCity(p);',
'  const head = "ECO — Ponto critico";',
'  const line1 = title;',
'  const line2 = (bairro ? (bairro + " - " + city) : city) + " • " + (resolved ? "RESOLVIDO" : "ABERTO");',
'  const line3 = resolved ? "Cuidado coletivo funcionando. Prova registrada." : "Precisa de cuidado. Confirme, apoie, organize.";',
'  const line4 = url ? ("Ver: " + url) : "";',
'  const tags = "#ECO #ReciboECO #VoltaRedonda #JusticaAmbiental #EconomiaSolidaria";',
'  return [head, line1, line2, line3, line4, "", tags].filter(Boolean).join("\\n");',
'}',
'',
'export function SharePointClient(props: { id: string }) {',
'  const id = String(props.id || "").trim();',
'  const [loading, setLoading] = useState(true);',
'  const [err, setErr] = useState<string>("");',
'  const [item, setItem] = useState<any>(null);',
'  const [copied, setCopied] = useState<string>("");',
'  const [mounted, setMounted] = useState(false);',
'  const [origin, setOrigin] = useState("");',
'  const [cacheBust, setCacheBust] = useState("");',
'',
'  useEffect(() => {',
'    setMounted(true);',
'    try { setOrigin(window.location.origin || ""); } catch {}',
'    setCacheBust(String(Date.now()));',
'  }, []);',
'',
'  useEffect(() => {',
'    let alive = true;',
'    (async () => {',
'      setLoading(true); setErr(""); setCopied("");',
'      try {',
'        const j = await apiGetPoint(id);',
'        if (!alive) return;',
'        if (!j.ok) throw new Error(j.error || "erro_get");',
'        setItem(j.item || null);',
'      } catch (e: any) {',
'        setErr(String(e?.message || e));',
'      } finally {',
'        if (alive) setLoading(false);',
'      }',
'    })();',
'    return () => { alive = false; };',
'  }, [id]);',
'',
'  const sharePath = useMemo(() => ("/eco/share/ponto/" + encodeURIComponent(id)), [id]);',
'  const shareUrl = useMemo(() => (origin ? (origin + sharePath) : ""), [origin, sharePath]);',
'',
'  const card3x4 = useMemo(() => ("/api/eco/points/card?format=3x4&id=" + encodeURIComponent(id) + (cacheBust ? ("&v=" + cacheBust) : "")), [id, cacheBust]);',
'  const card1x1 = useMemo(() => ("/api/eco/points/card?format=1x1&id=" + encodeURIComponent(id) + (cacheBust ? ("&v=" + cacheBust) : "")), [id, cacheBust]);',
'',
'  const caption = useMemo(() => buildCaption(item, id, shareUrl), [item, id, shareUrl]);',
'',
'  const waHref = useMemo(() => {',
'    if (!mounted) return "";',
'    const text = encodeURIComponent(caption);',
'    return "https://wa.me/?text=" + text;',
'  }, [mounted, caption]);',
'',
'  async function copyText(t: string) {',
'    try {',
'      await navigator.clipboard.writeText(t);',
'      setCopied("copiado");',
'      setTimeout(() => setCopied(""), 1200);',
'    } catch {',
'      setCopied("falha ao copiar");',
'      setTimeout(() => setCopied(""), 1200);',
'    }',
'  }',
'',
'  if (!id) return <div style={{ padding: 12, border: "1px solid #111", borderRadius: 14 }}>ID invalido.</div>;',
'',
'  return (',
'    <section style={{ display: "grid", gap: 14 }}>',
'      <div style={{ display: "flex", gap: 12, flexWrap: "wrap" }}>',
'        <a href={"../.."} style={{ padding: "8px 10px", borderRadius: 10, border: "1px solid #111", textDecoration: "none", color: "#111" }}>Voltar</a>',
'        <a href={("/eco/" + (item ? "" : "") + "")} style={{ display: "none" }}>.</a>',
'        <a href={("/eco/" + ("" ))} style={{ display: "none" }}>.</a>',
'      </div>',
'',
'      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 14 }}>',
'        <div style={{ border: "1px solid #111", borderRadius: 16, padding: 12, background: "#fff" }}>',
'          <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: 10, flexWrap: "wrap" }}>',
'            <div>',
'              <div style={{ fontWeight: 900 }}>{item ? pickTitle(item) : "Ponto critico"}</div>',
'              <div style={{ fontSize: 13, opacity: 0.75 }}>ID: {id}</div>',
'            </div>',
'            <div style={{ padding: "6px 10px", borderRadius: 999, border: "1px solid #111", fontWeight: 900, background: isResolved(pickStatus(item)) ? "#B7FFB7" : "#FFDD00" }}>',
'              {pickStatus(item) ? (isResolved(pickStatus(item)) ? "RESOLVIDO" : pickStatus(item)) : "ABERTO"}',
'            </div>',
'          </div>',
'',
'          {loading ? <div style={{ marginTop: 10, opacity: 0.8 }}>Carregando…</div> : null}',
'          {err ? <div style={{ marginTop: 10, padding: 10, borderRadius: 12, border: "1px solid #111", background: "#fff2f2" }}><b>Erro:</b> {err}</div> : null}',
'',
'          <div style={{ marginTop: 12, display: "grid", gap: 10 }}>',
'            <div style={{ fontWeight: 900 }}>Card 3:4</div>',
'            {/* eslint-disable-next-line @next/next/no-img-element */}',
'            <img src={card3x4} alt="Card 3x4" style={{ width: "100%", borderRadius: 14, border: "1px solid #111" }} />',
'            <div style={{ display: "flex", gap: 10, flexWrap: "wrap" }}>',
'              <a href={card3x4} target="_blank" rel="noreferrer" style={{ padding: "8px 10px", borderRadius: 10, border: "1px solid #111", textDecoration: "none", color: "#111" }}>Abrir imagem</a>',
'              <a href={card1x1} target="_blank" rel="noreferrer" style={{ padding: "8px 10px", borderRadius: 10, border: "1px solid #111", textDecoration: "none", color: "#111" }}>Versao 1:1</a>',
'            </div>',
'          </div>',
'        </div>',
'',
'        <div style={{ border: "1px solid #111", borderRadius: 16, padding: 12, background: "#fff" }}>',
'          <div style={{ fontWeight: 900, marginBottom: 8 }}>Legenda</div>',
'          <textarea value={caption} readOnly rows={14} style={{ width: "100%", padding: 10, borderRadius: 12, border: "1px solid #111" }} />',
'',
'          <div style={{ display: "flex", gap: 10, flexWrap: "wrap", marginTop: 10 }}>',
'            <button onClick={() => copyText(caption)} style={{ padding: "10px 12px", borderRadius: 12, border: "1px solid #111", background: "#FFDD00", fontWeight: 900 }}>Copiar legenda</button>',
'            <button onClick={() => copyText(shareUrl || sharePath)} style={{ padding: "10px 12px", borderRadius: 12, border: "1px solid #111", background: "#fff", fontWeight: 900 }}>Copiar link</button>',
'            {mounted ? (',
'              <a href={waHref} target="_blank" rel="noreferrer" style={{ padding: "10px 12px", borderRadius: 12, border: "1px solid #111", textDecoration: "none", color: "#111", background: "#fff", fontWeight: 900 }}>',
'                WhatsApp',
'              </a>',
'            ) : (',
'              <span style={{ padding: "10px 12px", borderRadius: 12, border: "1px solid #111", opacity: 0.6, fontWeight: 900 }}>WhatsApp</span>',
'            )}',
'            {copied ? <span style={{ padding: "10px 12px", opacity: 0.8 }}>{copied}</span> : null}',
'          </div>',
'',
'          <div style={{ marginTop: 10, fontSize: 12, opacity: 0.75 }}>',
'            Dica: poste o card 3:4 no feed e a legenda nos comentarios / descricao. Se for resolvido, a prova aparece no card.',
'          </div>',
'        </div>',
'      </div>',
'    </section>',
'  );',
'}',
''
) -join "`n"

WriteUtf8NoBom $pageFile $LPage
WriteUtf8NoBom $clientFile $LClient
Write-Host "[PATCH] wrote /eco/share/ponto/[id]"

# ---------- patch point detail page: add link to share ----------
$detailFile = Join-Path $srcApp ("eco/" + $base + "/[id]/page.tsx")
if (Test-Path -LiteralPath $detailFile) {
  $raw = Get-Content -LiteralPath $detailFile -Raw
  $nl = DetectNewline $raw

  if ($raw -match "share/ponto" -or $raw -match "Compartilhar ponto") {
    Write-Host "[SKIP] detail already has share link"
  } else {
    BackupFile $Root $detailFile $backupDir

    $block = @(
'      <div style={{ display: "flex", gap: 10, flexWrap: "wrap", margin: "10px 0" }}>',
'        <a',
'          href={"/eco/share/ponto/" + encodeURIComponent(String(params?.id || id || ""))}',
'          style={{',
'            padding: "10px 12px",',
'            borderRadius: 12,',
'            border: "1px solid #111",',
'            textDecoration: "none",',
'            color: "#111",',
'            background: "#fff",',
'            fontWeight: 900,',
'          }}',
'        >',
'          Compartilhar ponto',
'        </a>',
'      </div>'
    ) -join $nl

    # best-effort: insert after existing resolver link block or after </h1>
    if ($raw -match "Resolver ponto \(prova\)" -and $raw -match "</div>") {
      $raw2 = InsertAfter $raw "Resolver ponto (prova)" ($nl + $block + $nl) $nl
      if ($raw2 -eq $raw) { $raw2 = InsertAfterMainOpen $raw ($block + $nl) $nl }
    } elseif ($raw -match "</h1>") {
      $raw2 = InsertAfter $raw "</h1>" ($block + $nl) $nl
    } else {
      $raw2 = InsertAfterMainOpen $raw ($block + $nl) $nl
    }

    WriteUtf8NoBom $detailFile $raw2
    Write-Host "[PATCH] inserted share link into point detail page"
  }
} else {
  Write-Host "[WARN] Nao achei o detalhe do ponto para inserir o link: $detailFile"
}

# ---------- REPORT ----------
$rep = Join-Path $reportDir ('eco-step-80-share-point-card-v0_1-' + $ts + '.md')
$repLines = @(
'# eco-step-80-share-point-card-v0_1',
'',
'- Time: ' + $ts,
'- Backup: ' + $backupDir,
'- Base: eco/' + $base,
'',
'## Added',
'- src/app/api/eco/points/card/route.tsx',
'- src/app/eco/share/ponto/[id]/page.tsx',
'- src/app/eco/share/ponto/[id]/SharePointClient.tsx',
'',
'## Verify',
'1) Ctrl+C -> npm run dev',
'2) Abra /eco/share/ponto/<ID>',
'3) Verifique o card 3:4 (sem erro de display flex) e 1:1',
'4) Copiar legenda/link e abrir WhatsApp',
'5) (Opcional) abrir /api/eco/points/card?format=3x4&id=<ID> direto'
)
WriteUtf8NoBom $rep ($repLines -join "`n")
Write-Host ('[REPORT] ' + $rep)

Write-Host ""
Write-Host "[VERIFY] Ctrl+C -> npm run dev"
Write-Host "[VERIFY] /eco/share/ponto/<ID>  (card + legenda + WhatsApp)"