param(
  [string]$Root = (Get-Location).Path
)

function EnsureDir([string]$p) { if (-not (Test-Path $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function WriteAllLinesUtf8NoBom([string]$p, [string[]]$lines) {
  EnsureDir (Split-Path -Parent $p)
  $enc = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllLines($p, $lines, $enc)
}
function BackupFile([string]$p, [string]$backupDir) {
  if (Test-Path $p) {
    $rel = $p.Substring($Root.Length).TrimStart('\','/')
    $dest = Join-Path $backupDir ($rel -replace '[\\/]', '__')
    Copy-Item -Force -LiteralPath $p -Destination $dest
    Write-Host ('[BK] ' + $rel + ' -> ' + (Split-Path -Leaf $dest))
  }
}

function InsertLinesBeforeModelClose([string]$raw, [string]$modelName, [string[]]$linesToInsert, [string]$sentinelRegex) {
  if ($raw -match $sentinelRegex) { return $raw } # already present
  $needle = "model " + $modelName
  $i = $raw.IndexOf($needle)
  if ($i -lt 0) { throw ("[STOP] model not found: " + $modelName) }

  $braceStart = $raw.IndexOf("{", $i)
  if ($braceStart -lt 0) { throw ("[STOP] '{' not found for model: " + $modelName) }

  $depth = 0
  $j = $braceStart
  while ($j -lt $raw.Length) {
    $ch = $raw[$j]
    if ($ch -eq "{") { $depth++ }
    elseif ($ch -eq "}") {
      $depth--
      if ($depth -eq 0) { break }
    }
    $j++
  }
  if ($j -ge $raw.Length) { throw ("[STOP] could not find closing brace for model: " + $modelName) }

  $insert = ($linesToInsert -join "`n") + "`n"
  return $raw.Substring(0, $j) + $insert + $raw.Substring($j)
}

$ts = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupDir = Join-Path $Root ('tools/_patch_backup/' + $ts + '-eco-step-62-mutirao-from-point-mvp-v0_1')
$reportDir = Join-Path $Root 'reports'
EnsureDir $backupDir
EnsureDir $reportDir

Write-Host ('== eco-step-62-mutirao-from-point-mvp-v0_1 == ' + $ts)
Write-Host ('[DIAG] Root: ' + $Root)

$schema = Join-Path $Root 'prisma/schema.prisma'
$prismaCmd = Join-Path $Root 'node_modules/.bin/prisma.cmd'

$apiCreate  = Join-Path $Root 'src/app/api/eco/mutirao/create/route.ts'
$apiList    = Join-Path $Root 'src/app/api/eco/mutirao/list/route.ts'

$page   = Join-Path $Root 'src/app/eco/mutiroes/page.tsx'
$client = Join-Path $Root 'src/app/eco/mutiroes/MutiroesClient.tsx'

$pontosClient = Join-Path $Root 'src/app/eco/pontos/PontosClient.tsx'

Write-Host ('[DIAG] Will patch: ' + $schema)
Write-Host ('[DIAG] Will patch: ' + $pontosClient)
Write-Host ('[DIAG] Will write: ' + $apiCreate)
Write-Host ('[DIAG] Will write: ' + $apiList)
Write-Host ('[DIAG] Will write: ' + $page)
Write-Host ('[DIAG] Will write: ' + $client)

BackupFile $schema $backupDir
BackupFile $pontosClient $backupDir
BackupFile $apiCreate $backupDir
BackupFile $apiList $backupDir
BackupFile $page $backupDir
BackupFile $client $backupDir

if (-not (Test-Path $schema)) { throw ('[STOP] schema.prisma not found at ' + $schema) }
$raw = Get-Content -Raw -LiteralPath $schema
if ($null -eq $raw -or $raw.Length -lt 10) { throw '[STOP] schema.prisma read failed (empty)' }

$needMutirao = ($raw -notmatch 'model\s+EcoMutirao\b')
$needFieldOnPoint = ($raw -notmatch 'model\s+EcoCriticalPoint\b') ? $false : ($raw -notmatch 'EcoCriticalPoint\s*\{[\s\S]*\bmutirao\b')

if ($needMutirao) {
  Write-Host '[PATCH] prisma/schema.prisma: append model EcoMutirao'
  $add = @()
  $add += ''
  $add += 'model EcoMutirao {'
  $add += '  id         String           @id @default(cuid())'
  $add += '  pointId    String           @unique'
  $add += '  title      String?'
  $add += '  note       String?'
  $add += '  startAt    DateTime'
  $add += '  durationMin Int            @default(90)'
  $add += '  status     String          @default("SCHEDULED") // SCHEDULED|DONE|CANCELLED'
  $add += '  beforeUrl  String?'
  $add += '  afterUrl   String?'
  $add += '  checklist  Json?'
  $add += '  createdAt  DateTime        @default(now())'
  $add += '  updatedAt  DateTime        @updatedAt'
  $add += '  point      EcoCriticalPoint @relation(fields: [pointId], references: [id], onDelete: Cascade)'
  $add += '  @@index([startAt])'
  $add += '}'
  $add += ''
  $raw = $raw.TrimEnd() + ($add -join "`n") + "`n"
}

# Ensure EcoCriticalPoint has back relation field (required by Prisma)
if ($raw -match 'model\s+EcoCriticalPoint\b') {
  if ($raw -notmatch '\bmutirao\s+EcoMutirao\?') {
    Write-Host '[PATCH] prisma/schema.prisma: add field EcoCriticalPoint.mutirao EcoMutirao?'
    $raw = InsertLinesBeforeModelClose $raw 'EcoCriticalPoint' @('  mutirao     EcoMutirao?') '\bmutirao\s+EcoMutirao\?'
  }
} else {
  Write-Host '[WARN] EcoCriticalPoint model not found; skipping relation insert.'
}

# Write schema back
$enc = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($schema, $raw, $enc)

# API: mutirao/create
$LCreate = @(
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
'function getMutiraoModel() { const pc: any = prisma as any; return pc?.ecoMutirao; }',
'function getPointModel() { const pc: any = prisma as any; return pc?.ecoCriticalPoint; }',
'',
'export async function POST(req: Request) {',
'  const body = (await req.json().catch(() => null)) as any;',
'  const pointId = String(body?.pointId || "").trim();',
'  const startAtRaw = String(body?.startAt || "").trim();',
'  const durationMin = Math.max(15, Math.min(600, Number(body?.durationMin || 90) || 90));',
'  const title = body?.title != null ? String(body.title).slice(0, 120) : null;',
'  const note = body?.note != null ? String(body.note).slice(0, 600) : null;',
'  const checklist = body?.checklist ?? null;',
'',
'  if (!pointId) return NextResponse.json({ ok: false, error: "bad_pointId" }, { status: 400 });',
'  const startAt = new Date(startAtRaw);',
'  if (!(startAt instanceof Date) || Number.isNaN(startAt.getTime())) {',
'    return NextResponse.json({ ok: false, error: "bad_startAt" }, { status: 400 });',
'  }',
'',
'  const m = getMutiraoModel();',
'  const p = getPointModel();',
'  if (!m?.upsert || !p?.update) return NextResponse.json({ ok: false, error: "model_not_ready" }, { status: 503 });',
'',
'  try {',
'    const item = await m.upsert({',
'      where: { pointId },',
'      update: { startAt, durationMin, title, note, checklist },',
'      create: { pointId, startAt, durationMin, title, note, checklist },',
'    });',
'    await p.update({ where: { id: pointId }, data: { status: "MUTIRAO" } }).catch(() => null);',
'    return NextResponse.json({ ok: true, item });',
'  } catch (e) {',
'    const msg = asMsg(e);',
'    if (looksLikeMissingTable(msg)) return NextResponse.json({ ok: false, error: "db_not_ready", detail: msg }, { status: 503 });',
'    return NextResponse.json({ ok: false, error: "db_error", detail: msg }, { status: 500 });',
'  }',
'}',
''
)
WriteAllLinesUtf8NoBom $apiCreate $LCreate
Write-Host '[PATCH] wrote src/app/api/eco/mutirao/create/route.ts'

# API: mutirao/list (include point)
$LList = @(
'import { NextResponse } from "next/server";',
'import { prisma } from "@/lib/prisma";',
'',
'export const runtime = "nodejs";',
'export const dynamic = "force-dynamic";',
'',
'function clampInt(x: any, d: number) {',
'  const n = Number(x);',
'  if (!Number.isFinite(n) || n <= 0) return d;',
'  return Math.min(500, Math.floor(n));',
'}',
'function parseDate(s: string | null): Date | null {',
'  const t = String(s || "").trim();',
'  if (!t) return null;',
'  const d = new Date(t);',
'  if (Number.isNaN(d.getTime())) return null;',
'  return d;',
'}',
'function getMutiraoModel() { const pc: any = prisma as any; return pc?.ecoMutirao; }',
'',
'export async function GET(req: Request) {',
'  const { searchParams } = new URL(req.url);',
'  const limit = clampInt(searchParams.get("limit"), 80);',
'  const from = parseDate(searchParams.get("from"));',
'  const to = parseDate(searchParams.get("to"));',
'  const status = searchParams.get("status");',
'',
'  const m = getMutiraoModel();',
'  if (!m?.findMany) return NextResponse.json({ ok: false, error: "model_not_ready" }, { status: 503 });',
'',
'  const now = Date.now();',
'  const defaultFrom = new Date(now - 30 * 24 * 60 * 60 * 1000);',
'  const defaultTo = new Date(now + 365 * 24 * 60 * 60 * 1000);',
'  const start = from || defaultFrom;',
'  const end = to || defaultTo;',
'',
'  try {',
'    const where: any = { startAt: { gte: start, lte: end } };',
'    if (status) where.status = String(status);',
'    const items = await m.findMany({',
'      where,',
'      orderBy: { startAt: "asc" },',
'      take: limit,',
'      include: { point: true },',
'    });',
'    return NextResponse.json({ ok: true, items, range: { from: start.toISOString(), to: end.toISOString() } });',
'  } catch (e: any) {',
'    return NextResponse.json({ ok: false, error: "db_error", detail: String(e?.message || e) }, { status: 500 });',
'  }',
'}',
''
)
WriteAllLinesUtf8NoBom $apiList $LList
Write-Host '[PATCH] wrote src/app/api/eco/mutirao/list/route.ts'

# Page: /eco/mutiroes
$LPage = @(
'import MutiroesClient from "./MutiroesClient";',
'',
'export const dynamic = "force-dynamic";',
'',
'export default function Page() {',
'  return (',
'    <main style={{ padding: 16, maxWidth: 1100, margin: "0 auto" }}>',
'      <h1 style={{ margin: "0 0 8px 0" }}>Mutirões (ciclo fechado)</h1>',
'      <p style={{ margin: "0 0 14px 0", opacity: 0.85 }}>',
'        Ponto crítico virou ação coletiva: data, duração, checklist e antes/depois. Recibo é lei.',
'      </p>',
'      <MutiroesClient />',
'    </main>',
'  );',
'}',
''
)
WriteAllLinesUtf8NoBom $page $LPage
Write-Host '[PATCH] wrote src/app/eco/mutiroes/page.tsx'

# Client: MutiroesClient
$LClient = @(
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
'',
'function fmt(dt: string) {',
'  try {',
'    const d = new Date(dt);',
'    return d.toLocaleString();',
'  } catch {',
'    return dt;',
'  }',
'}',
'function gmaps(lat: number, lng: number) {',
'  return "https://www.google.com/maps?q=" + encodeURIComponent(String(lat) + "," + String(lng));',
'}',
'',
'export default function MutiroesClient() {',
'  const [items, setItems] = useState<AnyObj[]>([]);',
'  const [status, setStatus] = useState<string>("carregando");',
'  const url = useMemo(() => "/api/eco/mutirao/list?limit=120", []);',
'',
'  async function refresh() {',
'    setStatus("carregando");',
'    const d = await jget(url);',
'    if (d && d.ok && Array.isArray(d.items)) { setItems(d.items); setStatus("ok"); }',
'    else { setItems([]); setStatus("erro"); }',
'  }',
'  useEffect(() => { refresh(); }, []);',
'',
'  return (',
'    <section style={{ display: "grid", gap: 10 }}>',
'      <div style={{ display: "flex", gap: 10, alignItems: "center", flexWrap: "wrap" }}>',
'        <button onClick={refresh} style={{ padding: "8px 10px", borderRadius: 10, border: "1px solid #111", background: "#F7D500", color: "#111", fontWeight: 900, cursor: "pointer" }}>',
'          Atualizar',
'        </button>',
'        <a href="/eco/pontos" style={{ textDecoration: "none", padding: "8px 10px", borderRadius: 10, border: "1px solid #111" }}>',
'          Voltar aos pontos',
'        </a>',
'        <div style={{ opacity: 0.7 }}>status: {status} • itens: {items.length}</div>',
'      </div>',
'',
'      {items.length ? items.map((it) => {',
'        const p = it.point || {};',
'        const lat = Number(p.lat);',
'        const lng = Number(p.lng);',
'        const maps = Number.isFinite(lat) && Number.isFinite(lng) ? gmaps(lat, lng) : "#";',
'        return (',
'          <div key={String(it.id)} style={{ display: "flex", justifyContent: "space-between", gap: 10, padding: 12, border: "1px solid #ddd", borderRadius: 12, alignItems: "center" }}>',
'            <div style={{ display: "grid", gap: 4 }}>',
'              <div style={{ fontWeight: 900 }}>{it.title ? String(it.title) : "Mutirão"}</div>',
'              <div style={{ opacity: 0.85 }}>🗓 {it.startAt ? fmt(String(it.startAt)) : ""} • ⏱ {String(it.durationMin || 90)} min • {String(it.status || "SCHEDULED")}</div>',
'              <div style={{ opacity: 0.8 }}>Ponto: {String(p.kind || "")} • confirmações: {String(p.confirmCount || 0)}</div>',
'              <div style={{ opacity: 0.75, fontSize: 12 }}>{p.note ? String(p.note) : "—"}</div>',
'            </div>',
'            <div style={{ display: "flex", gap: 8, flexWrap: "wrap", justifyContent: "flex-end" }}>',
'              <a href={maps} target="_blank" rel="noreferrer" style={{ textDecoration: "none", padding: "8px 10px", borderRadius: 10, border: "1px solid #111" }}>',
'                Ver no mapa',
'              </a>',
'            </div>',
'          </div>',
'        );',
'      }) : (',
'        <div style={{ padding: 12, border: "1px solid #ddd", borderRadius: 12, opacity: 0.8 }}>',
'          Nenhum mutirão ainda. Vá em /eco/pontos e clique em “Virar mutirão”.',
'        </div>',
'      )}',
'    </section>',
'  );',
'}',
''
)
WriteAllLinesUtf8NoBom $client $LClient
Write-Host '[PATCH] wrote src/app/eco/mutiroes/MutiroesClient.tsx'

# Patch PontosClient.tsx (rewrite with minimal diff by overwrite safe file)
if (-not (Test-Path $pontosClient)) { throw ('[STOP] PontosClient.tsx not found at ' + $pontosClient) }

$P = @(
'"use client";',
'',
'import { useEffect, useMemo, useState } from "react";',
'',
'type AnyObj = Record<string, any>;',
'',
'function uid() {',
'  const k = "eco_actor_v0";',
'  const cur = typeof window !== "undefined" ? window.localStorage.getItem(k) : null;',
'  if (cur) return cur;',
'  const v = "anon-" + Math.random().toString(16).slice(2) + "-" + Date.now().toString(16);',
'  if (typeof window !== "undefined") window.localStorage.setItem(k, v);',
'  return v;',
'}',
'',
'async function jpost(url: string, body: AnyObj): Promise<AnyObj> {',
'  const res = await fetch(url, { method: "POST", headers: { "Content-Type": "application/json", Accept: "application/json" }, body: JSON.stringify(body), cache: "no-store" });',
'  const data = await res.json().catch(() => ({}));',
'  if (!res.ok) return { ok: false, status: res.status, ...data };',
'  return data;',
'}',
'async function jget(url: string): Promise<AnyObj> {',
'  const res = await fetch(url, { headers: { Accept: "application/json" }, cache: "no-store" });',
'  const data = await res.json().catch(() => ({}));',
'  if (!res.ok) return { ok: false, status: res.status, ...data };',
'  return data;',
'}',
'',
'const KINDS = [',
'  ["LIXO_ACUMULADO", "Lixo acumulado"],',
'  ["ENTULHO_VOLUMOSO", "Entulho/volumoso"],',
'  ["QUEIMADA_FUMACA", "Queimada/fumaça"],',
'  ["ESGOTO_VAZAMENTO", "Esgoto/vazamento"],',
'  ["OLEO_QUIMICO", "Óleo/químico"],',
'  ["SENSIVEL_INDUSTRIAL", "Sensível/industrial"],',
'  ["OUTRO", "Outro"],',
'] as const;',
'',
'function gmaps(lat: number, lng: number) {',
'  return "https://www.google.com/maps?q=" + encodeURIComponent(String(lat) + "," + String(lng));',
'}',
'',
'export default function PontosClient() {',
'  const actor = useMemo(() => uid(), []);',
'  const [kind, setKind] = useState<string>("LIXO_ACUMULADO");',
'  const [note, setNote] = useState<string>("");',
'  const [lat, setLat] = useState<string>("");',
'  const [lng, setLng] = useState<string>("");',
'  const [msg, setMsg] = useState<string>("");',
'  const [items, setItems] = useState<AnyObj[]>([]);',
'  const [status, setStatus] = useState<string>("carregando");',
'  const [viewStatus, setViewStatus] = useState<string>("OPEN");',
'',
'  // mutirão quick-form',
'  const [mutiraoId, setMutiraoId] = useState<string | null>(null);',
'  const [mutiraoStart, setMutiraoStart] = useState<string>("");',
'  const [mutiraoDur, setMutiraoDur] = useState<string>("90");',
'',
'  const listUrl = useMemo(() => "/api/eco/critical/list?limit=120&status=" + encodeURIComponent(viewStatus), [viewStatus]);',
'',
'  async function refresh() {',
'    setStatus("carregando");',
'    const d = await jget(listUrl);',
'    if (d && d.ok && Array.isArray(d.items)) { setItems(d.items); setStatus("ok"); }',
'    else { setItems([]); setStatus("erro"); }',
'  }',
'  useEffect(() => { refresh(); }, [listUrl]);',
'',
'  async function useGeo() {',
'    setMsg("");',
'    if (!navigator.geolocation) { setMsg("Seu navegador não suporta geolocalização."); return; }',
'    navigator.geolocation.getCurrentPosition(',
'      (pos) => {',
'        setLat(String(pos.coords.latitude));',
'        setLng(String(pos.coords.longitude));',
'        setMsg("Local capturado.");',
'      },',
'      () => setMsg("Não consegui pegar sua localização. Tente preencher manualmente."),',
'      { enableHighAccuracy: true, timeout: 8000 }',
'    );',
'  }',
'',
'  async function createPoint() {',
'    setMsg("");',
'    const latN = Number(lat);',
'    const lngN = Number(lng);',
'    if (!Number.isFinite(latN) || !Number.isFinite(lngN)) { setMsg("Lat/Lng inválidos."); return; }',
'    const d = await jpost("/api/eco/critical/create", { kind, note: note.trim(), lat: latN, lng: lngN, actor });',
'    if (d && d.ok) {',
'      setMsg(d.deduped ? "Já existia ponto perto — usei o existente (dedupe)." : "Ponto criado.");',
'      setNote("");',
'      setViewStatus("OPEN");',
'      await refresh();',
'    } else {',
'      setMsg("Erro: " + String(d?.error || d?.detail || "unknown"));',
'    }',
'  }',
'',
'  async function confirm(id: string) {',
'    setMsg("");',
'    const d = await jpost("/api/eco/critical/confirm", { pointId: id, actor });',
'    if (d && d.ok) {',
'      setMsg(d.confirmed ? "Confirmado: eu vi também." : "Você já tinha confirmado antes.");',
'      await refresh();',
'    } else {',
'      setMsg("Erro ao confirmar: " + String(d?.error || d?.detail || "unknown"));',
'    }',
'  }',
'',
'  function openMutirao(id: string) {',
'    setMutiraoId(id);',
'    // prefill: amanhã 09:00 (local) sem Date.now() no SSR (isso roda em evento)',
'    try {',
'      const now = new Date();',
'      const d = new Date(now.getTime() + 24 * 60 * 60 * 1000);',
'      d.setHours(9, 0, 0, 0);',
'      const pad = (n: number) => String(n).padStart(2, "0");',
'      const v = d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate()) + "T" + pad(d.getHours()) + ":" + pad(d.getMinutes());',
'      setMutiraoStart(v);',
'    } catch {',
'      setMutiraoStart("");',
'    }',
'    setMutiraoDur("90");',
'  }',
'',
'  async function createMutirao(pointId: string) {',
'    setMsg("");',
'    if (!mutiraoStart) { setMsg("Escolha data/hora do mutirão."); return; }',
'    const start = new Date(mutiraoStart);',
'    if (Number.isNaN(start.getTime())) { setMsg("Data/hora inválida."); return; }',
'    const dur = Math.max(15, Math.min(600, Number(mutiraoDur || 90) || 90));',
'    const d = await jpost("/api/eco/mutirao/create", { pointId, startAt: start.toISOString(), durationMin: dur, note: null, title: "Mutirão" });',
'    if (d && d.ok) {',
'      setMsg("Mutirão criado. Ponto entrou em MUTIRAO.");',
'      setMutiraoId(null);',
'      setViewStatus("MUTIRAO");',
'      await refresh();',
'    } else {',
'      setMsg("Erro ao criar mutirão: " + String(d?.error || d?.detail || "unknown"));',
'    }',
'  }',
'',
'  return (',
'    <section style={{ display: "grid", gap: 12 }}>',
'      <div style={{ display: "flex", gap: 10, flexWrap: "wrap", alignItems: "center" }}>',
'        <a href="/eco/mutiroes" style={{ textDecoration: "none", padding: "8px 10px", borderRadius: 10, border: "1px solid #111" }}>',
'          Ver mutirões',
'        </a>',
'        <div style={{ opacity: 0.7 }}>lista: {viewStatus} • status: {status} • itens: {items.length}</div>',
'      </div>',
'',
'      <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>',
'        <button onClick={() => setViewStatus("OPEN")} style={{ padding: "8px 10px", borderRadius: 10, border: "1px solid #111", background: viewStatus === "OPEN" ? "#F7D500" : "#fff", fontWeight: 900, cursor: "pointer" }}>',
'          Pontos abertos',
'        </button>',
'        <button onClick={() => setViewStatus("MUTIRAO")} style={{ padding: "8px 10px", borderRadius: 10, border: "1px solid #111", background: viewStatus === "MUTIRAO" ? "#F7D500" : "#fff", fontWeight: 900, cursor: "pointer" }}>',
'          Viraram mutirão',
'        </button>',
'        <button onClick={refresh} style={{ padding: "8px 10px", borderRadius: 10, border: "1px solid #111", background: "#fff", cursor: "pointer" }}>',
'          Atualizar',
'        </button>',
'      </div>',
'',
'      <div style={{ display: "grid", gap: 10, padding: 12, border: "1px solid #ddd", borderRadius: 12 }}>',
'        <div style={{ display: "flex", gap: 8, flexWrap: "wrap", alignItems: "center" }}>',
'          <div style={{ fontWeight: 900 }}>Marcar ponto</div>',
'          <button onClick={useGeo} style={{ padding: "8px 10px", borderRadius: 10, border: "1px solid #111", background: "#F7D500", color: "#111", fontWeight: 800, cursor: "pointer" }}>',
'            Usar minha localização',
'          </button>',
'        </div>',
'',
'        <label style={{ display: "grid", gap: 4 }}>',
'          <span>Tipo</span>',
'          <select value={kind} onChange={(e) => setKind(e.target.value)} style={{ padding: 10, borderRadius: 10, border: "1px solid #ccc" }}>',
'            {KINDS.map(([k, label]) => (<option key={k} value={k}>{label}</option>))}',
'          </select>',
'        </label>',
'',
'        <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>',
'          <label style={{ display: "grid", gap: 4, flex: "1 1 160px" }}>',
'            <span>Lat</span>',
'            <input value={lat} onChange={(e) => setLat(e.target.value)} placeholder="-22.5" style={{ padding: 10, borderRadius: 10, border: "1px solid #ccc" }} />',
'          </label>',
'          <label style={{ display: "grid", gap: 4, flex: "1 1 160px" }}>',
'            <span>Lng</span>',
'            <input value={lng} onChange={(e) => setLng(e.target.value)} placeholder="-44.1" style={{ padding: 10, borderRadius: 10, border: "1px solid #ccc" }} />',
'          </label>',
'        </div>',
'',
'        <label style={{ display: "grid", gap: 4 }}>',
'          <span>Observação (opcional)</span>',
'          <textarea value={note} onChange={(e) => setNote(e.target.value)} rows={3} placeholder="Ex.: na esquina tal, perto de..." style={{ padding: 10, borderRadius: 10, border: "1px solid #ccc" }} />',
'        </label>',
'',
'        <button onClick={createPoint} style={{ padding: "10px 12px", borderRadius: 12, border: "1px solid #111", background: "#111", color: "#F7D500", fontWeight: 900, cursor: "pointer" }}>',
'          Criar ponto',
'        </button>',
'',
'        {msg ? <div style={{ padding: 10, borderRadius: 10, background: "#fff7cc", border: "1px solid #f0d000" }}>{msg}</div> : null}',
'      </div>',
'',
'      <div style={{ display: "grid", gap: 10 }}>',
'        {items.length ? items.map((it) => {',
'          const latN = Number(it.lat);',
'          const lngN = Number(it.lng);',
'          const maps = Number.isFinite(latN) && Number.isFinite(lngN) ? gmaps(latN, lngN) : "#";',
'          const id = String(it.id);',
'          const showMutirao = viewStatus === "OPEN";',
'          return (',
'            <div key={id} style={{ display: "grid", gap: 10, padding: 12, border: "1px solid #ddd", borderRadius: 12 }}>',
'              <div style={{ display: "flex", justifyContent: "space-between", gap: 10, alignItems: "center", flexWrap: "wrap" }}>',
'                <div style={{ display: "grid", gap: 4 }}>',
'                  <div style={{ fontWeight: 900 }}>{String(it.kind || "OUTRO")}</div>',
'                  <div style={{ opacity: 0.85 }}>{it.note ? String(it.note) : "—"}</div>',
'                  <div style={{ opacity: 0.7, fontSize: 12 }}>confirm: {String(it.confirmCount || 0)} • {it.createdAt ? String(it.createdAt) : ""}</div>',
'                </div>',
'                <div style={{ display: "flex", gap: 8, flexWrap: "wrap", justifyContent: "flex-end" }}>',
'                  <a href={maps} target="_blank" rel="noreferrer" style={{ textDecoration: "none", padding: "8px 10px", borderRadius: 10, border: "1px solid #111" }}>',
'                    Ver no mapa',
'                  </a>',
'                  <button onClick={() => confirm(id)} style={{ padding: "8px 10px", borderRadius: 10, border: "1px solid #111", background: "#F7D500", color: "#111", fontWeight: 900, cursor: "pointer" }}>',
'                    Eu vi também',
'                  </button>',
'                  {showMutirao ? (',
'                    <button onClick={() => openMutirao(id)} style={{ padding: "8px 10px", borderRadius: 10, border: "1px solid #111", background: "#111", color: "#F7D500", fontWeight: 900, cursor: "pointer" }}>',
'                      Virar mutirão',
'                    </button>',
'                  ) : null}',
'                </div>',
'              </div>',
'',
'              {showMutirao && mutiraoId === id ? (',
'                <div style={{ display: "flex", gap: 10, flexWrap: "wrap", alignItems: "center", padding: 10, borderRadius: 12, border: "1px dashed #999" }}>',
'                  <label style={{ display: "grid", gap: 4 }}>',
'                    <span>Data/hora</span>',
'                    <input type="datetime-local" value={mutiraoStart} onChange={(e) => setMutiraoStart(e.target.value)} style={{ padding: 10, borderRadius: 10, border: "1px solid #ccc" }} />',
'                  </label>',
'                  <label style={{ display: "grid", gap: 4 }}>',
'                    <span>Duração (min)</span>',
'                    <input value={mutiraoDur} onChange={(e) => setMutiraoDur(e.target.value)} style={{ padding: 10, borderRadius: 10, border: "1px solid #ccc", width: 120 }} />',
'                  </label>',
'                  <button onClick={() => createMutirao(id)} style={{ padding: "10px 12px", borderRadius: 12, border: "1px solid #111", background: "#F7D500", color: "#111", fontWeight: 900, cursor: "pointer" }}>',
'                    Criar mutirão',
'                  </button>',
'                  <button onClick={() => setMutiraoId(null)} style={{ padding: "10px 12px", borderRadius: 12, border: "1px solid #111", background: "#fff", cursor: "pointer" }}>',
'                    Cancelar',
'                  </button>',
'                </div>',
'              ) : null}',
'            </div>',
'          );',
'        }) : (',
'          <div style={{ padding: 12, border: "1px solid #ddd", borderRadius: 12, opacity: 0.8 }}>',
'            Nenhum item nessa lista ({viewStatus}).',
'          </div>',
'        )}',
'      </div>',
'    </section>',
'  );',
'}',
''
)
WriteAllLinesUtf8NoBom $pontosClient $P
Write-Host '[PATCH] wrote src/app/eco/pontos/PontosClient.tsx'

# Prisma: install if missing, then format/migrate/generate
if (-not (Test-Path $prismaCmd)) {
  Write-Host '[DIAG] prisma.cmd not found. Installing prisma + @prisma/client...'
  npm i -D prisma
  npm i @prisma/client
}

if (Test-Path $prismaCmd) {
  & $prismaCmd format
  & $prismaCmd migrate dev --name eco_mutirao_from_point
  if ($LASTEXITCODE -ne 0) {
    Write-Host '[WARN] migrate dev failed. If it is DRIFT on SQLite dev.db: backup prisma/dev.db and run migrate reset --force, then migrate dev again.'
  } else {
    & $prismaCmd generate
  }
} else {
  Write-Host '[WARN] prisma.cmd still missing; skipped migrate/generate.'
}

$rep = Join-Path $reportDir ('eco-step-62-mutirao-from-point-mvp-v0_1-' + $ts + '.md')
$repLines = @(
'# eco-step-62-mutirao-from-point-mvp-v0_1',
'',
'- Time: ' + $ts,
'- Backup: ' + $backupDir,
'',
'## Added',
'- Prisma: model EcoMutirao (+ relation field EcoCriticalPoint.mutirao)',
'- API: POST /api/eco/mutirao/create (upsert + set point.status=MUTIRAO)',
'- API: GET  /api/eco/mutirao/list (include point)',
'- UI: /eco/mutiroes',
'- UI: /eco/pontos updated (filter OPEN/MUTIRAO + quick mutirao form)',
'',
'## Verify',
'1) Restart dev server',
'2) Open /eco/pontos',
'3) Create a point, confirm it, then click "Virar mutirão" and create',
'4) Switch filter to "Viraram mutirão"',
'5) Open /eco/mutiroes',
'6) Check /api/eco/mutirao/list',
''
)
WriteAllLinesUtf8NoBom $rep $repLines
Write-Host ('[REPORT] ' + $rep)

Write-Host ''
Write-Host '[VERIFY] Ctrl+C -> npm run dev'
Write-Host '[VERIFY] Abra /eco/pontos, crie ponto, vire mutirão, confira /eco/mutiroes.'