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

$backupDir = Join-Path $Root ('tools/_patch_backup/' + $ts + '-eco-step-73-mutirao-share-card-v0_1')
$reportDir = Join-Path $Root 'reports'
EnsureDir $backupDir
EnsureDir $reportDir

Write-Host ('== eco-step-73-mutirao-share-card-v0_1 == ' + $ts)
Write-Host ('[DIAG] Root: ' + $Root)

$api = Join-Path $Root 'src/app/api/eco/mutirao/card/route.tsx'
$page = Join-Path $Root 'src/app/eco/share/mutirao/[id]/page.tsx'
$client = Join-Path $Root 'src/app/eco/share/mutirao/[id]/ShareMutiraoClient.tsx'

BackupFile $Root $api $backupDir
BackupFile $Root $page $backupDir
BackupFile $Root $client $backupDir

# --- API CARD (next/og) ---
$LApi = @(
'import { ImageResponse } from "next/og";',
'import { prisma } from "@/lib/prisma";',
'',
'export const runtime = "edge";',
'export const dynamic = "force-dynamic";',
'',
'function pickStr(o: any, keys: string[]) {',
'  for (const k of keys) {',
'    const v = o?.[k];',
'    if (typeof v === "string" && v.trim()) return v.trim();',
'  }',
'  return "";',
'}',
'function findMeta(o: any) {',
'  const m = o?.meta;',
'  if (m && typeof m === "object") return m;',
'  return null;',
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
'function safeFmt(s: any) {',
'  const t = String(s || "").trim();',
'  return t.length > 120 ? (t.slice(0, 117) + "...") : t;',
'}',
'function fmtStatus(s: any) {',
'  const t = String(s || "").toUpperCase().trim();',
'  if (!t) return "MUTIRÃO";',
'  if (t.includes("FINISH") || t === "DONE" || t === "RESOLVED") return "FINALIZADO";',
'  if (t.includes("OPEN") || t.includes("PLAN")) return "ABERTO";',
'  return t;',
'}',
'function boxStyle(bg: string, br: string) {',
'  return {',
'    background: bg,',
'    border: "2px solid " + br,',
'    borderRadius: 22,',
'    padding: 22,',
'    display: "flex",',
'    flexDirection: "column",',
'  } as const;',
'}',
'',
'export async function GET(req: Request) {',
'  const { searchParams } = new URL(req.url);',
'  const id = String(searchParams.get("id") || searchParams.get("mutiraoId") || "").trim();',
'  const format = String(searchParams.get("format") || "3x4").trim();',
'  if (!id) return new Response("bad_id", { status: 400 });',
'',
'  const mm = getMutiraoModel();',
'  if (!mm?.model) return new Response("model_not_ready", { status: 503 });',
'',
'  const item = await mm.model.findUnique({ where: { id } });',
'  if (!item) return new Response("not_found", { status: 404 });',
'',
'  const meta = findMeta(item) || {};',
'  const title = safeFmt(pickStr(item, ["title","name","titulo"]) || "Mutirão");',
'  const bairro = safeFmt(pickStr(item, ["bairro","neighborhood","area","regiao","region"]) || "");',
'  const status = fmtStatus(item?.status);',
'  const proofNote = safeFmt(pickStr(item, ["proofNote","note","obs"]) || (meta as any).proofNote || "");',
'  const beforeUrl = String((item as any).beforeUrl || (meta as any).beforeUrl || "").trim();',
'  const afterUrl  = String((item as any).afterUrl  || (meta as any).afterUrl  || "").trim();',
'',
'  const isSquare = format === "1x1";',
'  const W = isSquare ? 1080 : 1080;',
'  const H = isSquare ? 1080 : 1350;',
'',
'  const topTag = "ECO • MUTIRÃO";',
'  const stamp = "RECIBO É LEI";',
'  const subStamp = "ESCUTAR • CUIDAR • ORGANIZAR";',
'',
'  const photo = afterUrl || beforeUrl;',
'',
'  const header = (',
'    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", width: "100%" }}>',
'      <div style={{ display: "flex", flexDirection: "column" }}>',
'        <div style={{ fontSize: 26, fontWeight: 900, letterSpacing: 1 }}>{topTag}</div>',
'        <div style={{ fontSize: 18, opacity: 0.9 }}>{bairro ? ("Bairro: " + bairro) : "Volta Redonda"}</div>',
'      </div>',
'      <div style={{ display: "flex" }}>',
'        <div style={{',
'          display: "flex",',
'          padding: "10px 14px",',
'          borderRadius: 999,',
'          border: "2px solid #111",',
'          background: "#FFDD00",',
'          fontWeight: 900,',
'          fontSize: 18,',
'        }}>{status}</div>',
'      </div>',
'    </div>',
'  );',
'',
'  const body = (',
'    <div style={{ display: "flex", flexDirection: "column", gap: 16, width: "100%" }}>',
'      <div style={{ fontSize: isSquare ? 54 : 60, fontWeight: 1000, lineHeight: 1.05 }}>{title}</div>',
'      {proofNote ? <div style={{ fontSize: 24, opacity: 0.92, lineHeight: 1.25 }}>Prova: {proofNote}</div> : <div style={{ fontSize: 22, opacity: 0.7 }}>Cuidado coletivo em prática.</div>}',
'      {photo ? (',
'        <div style={{ display: "flex", width: "100%", borderRadius: 22, overflow: "hidden", border: "2px solid #111" }}>',
'          {/* eslint-disable-next-line @next/next/no-img-element */}',
'          <img src={photo} alt="prova" style={{ width: "100%", height: isSquare ? 460 : 560, objectFit: "cover" }} />',
'        </div>',
'      ) : null}',
'    </div>',
'  );',
'',
'  const footer = (',
'    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-end", width: "100%" }}>',
'      <div style={{ display: "flex", flexDirection: "column", gap: 6 }}>',
'        <div style={{ display: "flex", padding: "10px 14px", borderRadius: 999, border: "2px solid #111", background: "#111", color: "#fff", fontWeight: 900 }}>{stamp}</div>',
'        <div style={{ fontSize: 16, opacity: 0.85 }}>{subStamp}</div>',
'      </div>',
'      <div style={{ display: "flex", flexDirection: "column", alignItems: "flex-end", gap: 6 }}>',
'        <div style={{ fontSize: 14, opacity: 0.8 }}>eco/share/mutirao/{id}</div>',
'        <div style={{ fontSize: 14, opacity: 0.8 }}>@VR_ABANDONADA</div>',
'      </div>',
'    </div>',
'  );',
'',
'  return new ImageResponse(',
'    (',
'      <div style={{',
'        width: W,',
'        height: H,',
'        display: "flex",',
'        flexDirection: "column",',
'        padding: 26,',
'        background: "#F5F5F5",',
'        color: "#111",',
'        fontFamily: "Arial",',
'      }}>',
'        <div style={{ ...boxStyle("#FFFFFF", "#111"), gap: 18, flex: 1 }}>',
'          {header}',
'          <div style={{ display: "flex", flexDirection: "column", gap: 18, flex: 1 }}>',
'            {body}',
'          </div>',
'          {footer}',
'        </div>',
'      </div>',
'    ),',
'    { width: W, height: H }',
'  );',
'}',
''
)
EnsureDir (Split-Path -Parent $api)
WriteUtf8NoBom $api ($LApi -join "`n")
Write-Host "[PATCH] wrote /api/eco/mutirao/card"

# --- Share page + client ---
$LPage = @(
'import ShareMutiraoClient from "./ShareMutiraoClient";',
'',
'export default async function Page({ params }: any) {',
'  const p: any = await (params as any);',
'  const id = String(p?.id || "");',
'  return (',
'    <main style={{ padding: 16, maxWidth: 1100, margin: "0 auto" }}>',
'      <h1 style={{ margin: "0 0 8px 0" }}>Compartilhar mutirão: {id}</h1>',
'      <p style={{ margin: "0 0 14px 0", opacity: 0.85 }}>Card + legenda prontos para postar.</p>',
'      <ShareMutiraoClient id={id} />',
'    </main>',
'  );',
'}',
''
)
EnsureDir (Split-Path -Parent $page)
WriteUtf8NoBom $page ($LPage -join "`n")
Write-Host "[PATCH] wrote /eco/share/mutirao/[id]/page.tsx"

$LClient = @(
'"use client";',
'',
'import { useMemo, useState } from "react";',
'',
'function enc(s: string) { return encodeURIComponent(s); }',
'',
'export default function ShareMutiraoClient({ id }: { id: string }) {',
'  const [copied, setCopied] = useState(false);',
'',
'  const base = useMemo(() => {',
'    if (typeof window === "undefined") return "";',
'    return window.location.origin;',
'  }, []);',
'',
'  const shareUrl = useMemo(() => (base ? (base + "/eco/share/mutirao/" + enc(id)) : ("/eco/share/mutirao/" + enc(id))), [base, id]);',
'  const card34 = useMemo(() => ("/api/eco/mutirao/card?format=3x4&id=" + enc(id)), [id]);',
'  const card11 = useMemo(() => ("/api/eco/mutirao/card?format=1x1&id=" + enc(id)), [id]);',
'',
'  const legend = useMemo(() => {',
'    const parts: string[] = [];',
'    parts.push("ECO — Mutirão (prova do cuidado)");',
'    parts.push("");',
'    parts.push("Mutirão: " + id);',
'    parts.push("Recibo é lei. Cuidado é coletivo.");',
'    parts.push("");',
'    parts.push("Link: " + shareUrl);',
'    return parts.join("\\n");',
'  }, [id, shareUrl]);',
'',
'  const wa = useMemo(() => {',
'    return "https://wa.me/?text=" + enc(legend);',
'  }, [legend]);',
'',
'  async function copyLink() {',
'    setCopied(false);',
'    try {',
'      await navigator.clipboard.writeText(shareUrl);',
'      setCopied(true);',
'      setTimeout(() => setCopied(false), 1200);',
'    } catch {',
'      // ignore',
'    }',
'  }',
'  async function copyLegend() {',
'    setCopied(false);',
'    try {',
'      await navigator.clipboard.writeText(legend);',
'      setCopied(true);',
'      setTimeout(() => setCopied(false), 1200);',
'    } catch {',
'      // ignore',
'    }',
'  }',
'',
'  return (',
'    <section style={{ display: "grid", gap: 12 }}>',
'      <div style={{ display: "flex", gap: 10, flexWrap: "wrap" }}>',
'        <button onClick={() => void copyLink()} style={{ padding: "10px 12px", borderRadius: 12, border: "1px solid #111", background: "#111", color: "#fff" }}>',
'          Copiar link',
'        </button>',
'        <button onClick={() => void copyLegend()} style={{ padding: "10px 12px", borderRadius: 12, border: "1px solid #111", background: "#fff", color: "#111" }}>',
'          Copiar legenda',
'        </button>',
'        <a href={wa} target="_blank" rel="noreferrer" style={{ padding: "10px 12px", borderRadius: 12, border: "1px solid #111", textDecoration: "none", color: "#111", background: "#FFDD00", fontWeight: 900 }}>',
'          WhatsApp',
'        </a>',
'        {copied ? <span style={{ alignSelf: "center", opacity: 0.85 }}>Copiado ✅</span> : null}',
'      </div>',
'',
'      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>',
'        <div style={{ padding: 12, border: "1px solid #e5e5e5", borderRadius: 12, background: "#fff" }}>',
'          <div style={{ fontWeight: 900, marginBottom: 8 }}>Card 3x4</div>',
'          <a href={card34} target="_blank" rel="noreferrer" style={{ display: "inline-block", textDecoration: "none", border: "1px solid #111", padding: "10px 12px", borderRadius: 12, color: "#111" }}>Abrir PNG</a>',
'          <div style={{ marginTop: 10, borderRadius: 12, overflow: "hidden", border: "1px solid #ddd" }}>',
'            <img src={card34} alt="card 3x4" style={{ width: "100%", height: "auto", display: "block" }} />',
'          </div>',
'        </div>',
'        <div style={{ padding: 12, border: "1px solid #e5e5e5", borderRadius: 12, background: "#fff" }}>',
'          <div style={{ fontWeight: 900, marginBottom: 8 }}>Card 1x1</div>',
'          <a href={card11} target="_blank" rel="noreferrer" style={{ display: "inline-block", textDecoration: "none", border: "1px solid #111", padding: "10px 12px", borderRadius: 12, color: "#111" }}>Abrir PNG</a>',
'          <div style={{ marginTop: 10, borderRadius: 12, overflow: "hidden", border: "1px solid #ddd" }}>',
'            <img src={card11} alt="card 1x1" style={{ width: "100%", height: "auto", display: "block" }} />',
'          </div>',
'        </div>',
'      </div>',
'',
'      <div style={{ padding: 12, border: "1px solid #e5e5e5", borderRadius: 12, background: "#fff" }}>',
'        <div style={{ fontWeight: 900, marginBottom: 8 }}>Legenda</div>',
'        <pre style={{ margin: 0, whiteSpace: "pre-wrap", fontFamily: "ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace", fontSize: 13, lineHeight: 1.35 }}>{legend}</pre>',
'      </div>',
'    </section>',
'  );',
'}',
''
)
EnsureDir (Split-Path -Parent $client)
WriteUtf8NoBom $client ($LClient -join "`n")
Write-Host "[PATCH] wrote ShareMutiraoClient.tsx"

# REPORT
$rep = Join-Path $reportDir ('eco-step-73-mutirao-share-card-v0_1-' + $ts + '.md')
$repLines = @(
"# eco-step-73-mutirao-share-card-v0_1",
"",
"- Time: " + $ts,
"- Backup: " + $backupDir,
"",
"## Added",
"- src/app/api/eco/mutirao/card/route.tsx",
"- src/app/eco/share/mutirao/[id]/page.tsx",
"- src/app/eco/share/mutirao/[id]/ShareMutiraoClient.tsx",
"",
"## Verify",
"1) Ctrl+C -> npm run dev",
"2) Abrir /eco/share/mutirao/<id>",
"3) Deve renderizar previews 3x4 e 1x1 sem erro 'display flex'",
"4) WhatsApp abre com legenda + link"
)
WriteUtf8NoBom $rep ($repLines -join "`n")
Write-Host ('[REPORT] ' + $rep)

Write-Host ""
Write-Host "[VERIFY] Ctrl+C -> npm run dev"
Write-Host "[VERIFY] /eco/share/mutirao/<id>"