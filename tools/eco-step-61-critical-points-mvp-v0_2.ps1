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

$ts = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupDir = Join-Path $Root ('tools/_patch_backup/' + $ts + '-eco-step-61-critical-points-mvp-v0_2')
$reportDir = Join-Path $Root 'reports'
EnsureDir $backupDir
EnsureDir $reportDir

Write-Host ('== eco-step-61-critical-points-mvp-v0_2 == ' + $ts)
Write-Host ('[DIAG] Root: ' + $Root)

$schema = Join-Path $Root 'prisma/schema.prisma'
$prismaCmd = Join-Path $Root 'node_modules/.bin/prisma.cmd'

$apiCreate  = Join-Path $Root 'src/app/api/eco/critical/create/route.ts'
$apiList    = Join-Path $Root 'src/app/api/eco/critical/list/route.ts'
$apiConfirm = Join-Path $Root 'src/app/api/eco/critical/confirm/route.ts'

$page   = Join-Path $Root 'src/app/eco/pontos/page.tsx'
$client = Join-Path $Root 'src/app/eco/pontos/PontosClient.tsx'

Write-Host ('[DIAG] Will patch: ' + $schema)
Write-Host ('[DIAG] Will write: ' + $apiCreate)
Write-Host ('[DIAG] Will write: ' + $apiList)
Write-Host ('[DIAG] Will write: ' + $apiConfirm)
Write-Host ('[DIAG] Will write: ' + $page)
Write-Host ('[DIAG] Will write: ' + $client)

BackupFile $schema $backupDir
BackupFile $apiCreate $backupDir
BackupFile $apiList $backupDir
BackupFile $apiConfirm $backupDir
BackupFile $page $backupDir
BackupFile $client $backupDir

if (-not (Test-Path $schema)) { throw ('[STOP] schema.prisma not found at ' + $schema) }
$raw = Get-Content -Raw -LiteralPath $schema
if ($null -eq $raw -or $raw.Length -lt 10) { throw '[STOP] schema.prisma read failed (empty)' }

$needEnum    = ($raw -notmatch 'enum\s+EcoCriticalKind')
$needPoint   = ($raw -notmatch 'model\s+EcoCriticalPoint\b')
$needConfirm = ($raw -notmatch 'model\s+EcoCriticalPointConfirm\b')

if ($needEnum -or $needPoint -or $needConfirm) {
  Write-Host '[PATCH] prisma/schema.prisma: adding EcoCriticalKind + EcoCriticalPoint (+Confirm) (append)'
  $addLines = @()
  $addLines += ''
  if ($needEnum) {
    $addLines += 'enum EcoCriticalKind {'
    $addLines += '  LIXO_ACUMULADO'
    $addLines += '  ENTULHO_VOLUMOSO'
    $addLines += '  QUEIMADA_FUMACA'
    $addLines += '  ESGOTO_VAZAMENTO'
    $addLines += '  OLEO_QUIMICO'
    $addLines += '  SENSIVEL_INDUSTRIAL'
    $addLines += '  OUTRO'
    $addLines += '}'
    $addLines += ''
  }
  if ($needPoint) {
    $addLines += 'model EcoCriticalPoint {'
    $addLines += '  id           String         @id @default(cuid())'
    $addLines += '  kind         EcoCriticalKind'
    $addLines += '  lat          Float'
    $addLines += '  lng          Float'
    $addLines += '  note         String?'
    $addLines += '  photoUrl     String?'
    $addLines += '  actor        String?        // opcional (anon/guest)'
    $addLines += '  confirmCount Int            @default(0)'
    $addLines += '  status       String         @default("OPEN") // OPEN|RESOLVED|MUTIRAO'
    $addLines += '  createdAt    DateTime       @default(now())'
    $addLines += '  updatedAt    DateTime       @updatedAt'
    $addLines += '  confirms     EcoCriticalPointConfirm[]'
    $addLines += '}'
    $addLines += ''
  }
  if ($needConfirm) {
    $addLines += 'model EcoCriticalPointConfirm {'
    $addLines += '  id        String           @id @default(cuid())'
    $addLines += '  pointId   String'
    $addLines += '  actor     String'
    $addLines += '  createdAt DateTime         @default(now())'
    $addLines += '  point     EcoCriticalPoint @relation(fields: [pointId], references: [id], onDelete: Cascade)'
    $addLines += '  @@unique([pointId, actor])'
    $addLines += '  @@index([pointId])'
    $addLines += '}'
    $addLines += ''
  }

  $raw2 = $raw.TrimEnd() + ($addLines -join "`n") + "`n"
  $enc = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($schema, $raw2, $enc)
} else {
  Write-Host '[DIAG] schema already has EcoCritical* (skip)'
}

# API: create (dedupe)
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
'function getPointModel() { const pc: any = prisma as any; return pc?.ecoCriticalPoint; }',
'',
'function num(x: any): number | null {',
'  const n = Number(x);',
'  if (!Number.isFinite(n)) return null;',
'  return n;',
'}',
'function validLatLng(lat: number, lng: number) {',
'  if (lat < -90 || lat > 90) return false;',
'  if (lng < -180 || lng > 180) return false;',
'  return true;',
'}',
'function haversineMeters(aLat: number, aLng: number, bLat: number, bLng: number) {',
'  const R = 6371000;',
'  const toRad = (d: number) => (d * Math.PI) / 180;',
'  const dLat = toRad(bLat - aLat);',
'  const dLng = toRad(bLng - aLng);',
'  const s1 = Math.sin(dLat / 2);',
'  const s2 = Math.sin(dLng / 2);',
'  const aa = s1 * s1 + Math.cos(toRad(aLat)) * Math.cos(toRad(bLat)) * s2 * s2;',
'  const c = 2 * Math.atan2(Math.sqrt(aa), Math.sqrt(1 - aa));',
'  return R * c;',
'}',
'',
'export async function POST(req: Request) {',
'  const model = getPointModel();',
'  if (!model?.create) return NextResponse.json({ ok: false, error: "model_not_ready" }, { status: 503 });',
'  const body = (await req.json().catch(() => null)) as any;',
'',
'  const kind = String(body?.kind || "OUTRO").trim();',
'  const lat0 = num(body?.lat);',
'  const lng0 = num(body?.lng);',
'  const note = body?.note != null ? String(body.note).slice(0, 500) : null;',
'  const photoUrl = body?.photoUrl != null ? String(body.photoUrl).slice(0, 800) : null;',
'  const actor = body?.actor != null ? String(body.actor).slice(0, 80) : null;',
'  const radiusM = Math.max(30, Math.min(500, Number(body?.radiusM || 120) || 120));',
'  const windowH = Math.max(1, Math.min(168, Number(body?.windowH || 72) || 72));',
'',
'  if (lat0 == null || lng0 == null) return NextResponse.json({ ok: false, error: "bad_latlng" }, { status: 400 });',
'  if (!validLatLng(lat0, lng0)) return NextResponse.json({ ok: false, error: "bad_latlng" }, { status: 400 });',
'',
'  try {',
'    const since = new Date(Date.now() - windowH * 60 * 60 * 1000);',
'    const recent = await model.findMany({ where: { createdAt: { gte: since }, status: "OPEN" }, orderBy: { createdAt: "desc" }, take: 200 });',
'    let dupe: any = null;',
'    for (const p of recent) {',
'      const d = haversineMeters(lat0, lng0, Number(p.lat), Number(p.lng));',
'      if (d <= radiusM) { dupe = p; break; }',
'    }',
'    if (dupe) {',
'      return NextResponse.json({ ok: true, item: dupe, deduped: true, radiusM, windowH });',
'    }',
'',
'    const item = await model.create({',
'      data: { kind, lat: lat0, lng: lng0, note, photoUrl, actor }',
'    });',
'    return NextResponse.json({ ok: true, item, deduped: false, radiusM, windowH });',
'  } catch (e) {',
'    const msg = asMsg(e);',
'    if (looksLikeMissingTable(msg)) return NextResponse.json({ ok: false, error: "db_not_ready", detail: msg }, { status: 503 });',
'    return NextResponse.json({ ok: false, error: "db_error", detail: msg }, { status: 500 });',
'  }',
'}',
''
)
WriteAllLinesUtf8NoBom $apiCreate $LCreate
Write-Host '[PATCH] wrote src/app/api/eco/critical/create/route.ts'

# API: list
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
'function getPointModel() { const pc: any = prisma as any; return pc?.ecoCriticalPoint; }',
'',
'export async function GET(req: Request) {',
'  const { searchParams } = new URL(req.url);',
'  const limit = clampInt(searchParams.get("limit"), 80);',
'  const kind = searchParams.get("kind");',
'  const status = searchParams.get("status") || "OPEN";',
'  const model = getPointModel();',
'  if (!model?.findMany) return NextResponse.json({ ok: false, error: "model_not_ready" }, { status: 503 });',
'',
'  try {',
'    const where: any = { status };',
'    if (kind) where.kind = String(kind);',
'    const items = await model.findMany({ where, orderBy: { createdAt: "desc" }, take: limit });',
'    return NextResponse.json({ ok: true, items });',
'  } catch (e: any) {',
'    return NextResponse.json({ ok: false, error: "db_error", detail: String(e?.message || e) }, { status: 500 });',
'  }',
'}',
''
)
WriteAllLinesUtf8NoBom $apiList $LList
Write-Host '[PATCH] wrote src/app/api/eco/critical/list/route.ts'

# API: confirm
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
'function getPointModel() { const pc: any = prisma as any; return pc?.ecoCriticalPoint; }',
'function getConfirmModel() { const pc: any = prisma as any; return pc?.ecoCriticalPointConfirm; }',
'',
'export async function POST(req: Request) {',
'  const body = (await req.json().catch(() => null)) as any;',
'  const pointId = String(body?.pointId || "").trim();',
'  const actor = String(body?.actor || "anon").trim().slice(0, 80);',
'  if (!pointId) return NextResponse.json({ ok: false, error: "bad_pointId" }, { status: 400 });',
'',
'  const model = getPointModel();',
'  const cm = getConfirmModel();',
'  if (!model?.update || !cm?.create) return NextResponse.json({ ok: false, error: "model_not_ready" }, { status: 503 });',
'',
'  try {',
'    const created = await cm.create({ data: { pointId, actor } }).then(() => true).catch(() => false);',
'    if (created) {',
'      const item = await model.update({ where: { id: pointId }, data: { confirmCount: { increment: 1 } } });',
'      return NextResponse.json({ ok: true, item, confirmed: true });',
'    } else {',
'      const item = await model.findUnique({ where: { id: pointId } });',
'      return NextResponse.json({ ok: true, item, confirmed: false });',
'    }',
'  } catch (e) {',
'    const msg = asMsg(e);',
'    if (looksLikeMissingTable(msg)) return NextResponse.json({ ok: false, error: "db_not_ready", detail: msg }, { status: 503 });',
'    return NextResponse.json({ ok: false, error: "db_error", detail: msg }, { status: 500 });',
'  }',
'}',
''
)
WriteAllLinesUtf8NoBom $apiConfirm $LConfirm
Write-Host '[PATCH] wrote src/app/api/eco/critical/confirm/route.ts'

# UI
$LPage = @(
'import PontosClient from "./PontosClient";',
'',
'export const dynamic = "force-dynamic";',
'',
'export default function Page() {',
'  return (',
'    <main style={{ padding: 16, maxWidth: 1100, margin: "0 auto" }}>',
'      <h1 style={{ margin: "0 0 8px 0" }}>Pontos críticos (Mapa da Vergonha)</h1>',
'      <p style={{ margin: "0 0 14px 0", opacity: 0.85 }}>',
'        Marque pontos de abandono (lixo, entulho, fumaça, vazamento). Sem caça às bruxas: prova leve + confirmação coletiva.',
'      </p>',
'      <PontosClient />',
'    </main>',
'  );',
'}',
''
)
WriteAllLinesUtf8NoBom $page $LPage
Write-Host '[PATCH] wrote src/app/eco/pontos/page.tsx'

$LClient = @(
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
'  const listUrl = useMemo(() => "/api/eco/critical/list?limit=120&status=OPEN", []);',
'',
'  async function refresh() {',
'    setStatus("carregando");',
'    const d = await jget(listUrl);',
'    if (d && d.ok && Array.isArray(d.items)) { setItems(d.items); setStatus("ok"); }',
'    else { setItems([]); setStatus("erro"); }',
'  }',
'  useEffect(() => { refresh(); }, []);',
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
'  return (',
'    <section style={{ display: "grid", gap: 12 }}>',
'      <div style={{ display: "grid", gap: 10, padding: 12, border: "1px solid #ddd", borderRadius: 12 }}>',
'        <div style={{ display: "flex", gap: 8, flexWrap: "wrap", alignItems: "center" }}>',
'          <div style={{ fontWeight: 900 }}>Marcar ponto</div>',
'          <button onClick={useGeo} style={{ padding: "8px 10px", borderRadius: 10, border: "1px solid #111", background: "#F7D500", color: "#111", fontWeight: 800, cursor: "pointer" }}>',
'            Usar minha localização',
'          </button>',
'          <button onClick={refresh} style={{ padding: "8px 10px", borderRadius: 10, border: "1px solid #111", background: "#fff", cursor: "pointer" }}>',
'            Atualizar lista',
'          </button>',
'          <div style={{ opacity: 0.7 }}>status: {status} • itens: {items.length}</div>',
'        </div>',
'',
'        <div style={{ display: "grid", gap: 8 }}>',
'          <label style={{ display: "grid", gap: 4 }}>',
'            <span>Tipo</span>',
'            <select value={kind} onChange={(e) => setKind(e.target.value)} style={{ padding: 10, borderRadius: 10, border: "1px solid #ccc" }}>',
'              {KINDS.map(([k, label]) => (<option key={k} value={k}>{label}</option>))}',
'            </select>',
'          </label>',
'          <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>',
'            <label style={{ display: "grid", gap: 4, flex: "1 1 160px" }}>',
'              <span>Lat</span>',
'              <input value={lat} onChange={(e) => setLat(e.target.value)} placeholder="-22.5" style={{ padding: 10, borderRadius: 10, border: "1px solid #ccc" }} />',
'            </label>',
'            <label style={{ display: "grid", gap: 4, flex: "1 1 160px" }}>',
'              <span>Lng</span>',
'              <input value={lng} onChange={(e) => setLng(e.target.value)} placeholder="-44.1" style={{ padding: 10, borderRadius: 10, border: "1px solid #ccc" }} />',
'            </label>',
'          </div>',
'          <label style={{ display: "grid", gap: 4 }}>',
'            <span>Observação (opcional)</span>',
'            <textarea value={note} onChange={(e) => setNote(e.target.value)} rows={3} placeholder="Ex.: na esquina tal, perto de..." style={{ padding: 10, borderRadius: 10, border: "1px solid #ccc" }} />',
'          </label>',
'          <button onClick={createPoint} style={{ padding: "10px 12px", borderRadius: 12, border: "1px solid #111", background: "#111", color: "#F7D500", fontWeight: 900, cursor: "pointer" }}>',
'            Criar ponto',
'          </button>',
'          {msg ? <div style={{ padding: 10, borderRadius: 10, background: "#fff7cc", border: "1px solid #f0d000" }}>{msg}</div> : null}',
'        </div>',
'      </div>',
'',
'      <div style={{ display: "grid", gap: 10 }}>',
'        {items.length ? items.map((it) => {',
'          const latN = Number(it.lat);',
'          const lngN = Number(it.lng);',
'          const maps = Number.isFinite(latN) && Number.isFinite(lngN) ? gmaps(latN, lngN) : "#";',
'          return (',
'            <div key={String(it.id)} style={{ display: "flex", justifyContent: "space-between", gap: 10, padding: 12, border: "1px solid #ddd", borderRadius: 12, alignItems: "center" }}>',
'              <div style={{ display: "grid", gap: 4 }}>',
'                <div style={{ fontWeight: 900 }}>{String(it.kind || "OUTRO")}</div>',
'                <div style={{ opacity: 0.85 }}>{it.note ? String(it.note) : "—"}</div>',
'                <div style={{ opacity: 0.7, fontSize: 12 }}>confirm: {String(it.confirmCount || 0)} • {it.createdAt ? String(it.createdAt) : ""}</div>',
'              </div>',
'              <div style={{ display: "flex", gap: 8, flexWrap: "wrap", justifyContent: "flex-end" }}>',
'                <a href={maps} target="_blank" rel="noreferrer" style={{ textDecoration: "none", padding: "8px 10px", borderRadius: 10, border: "1px solid #111" }}>',
'                  Ver no mapa',
'                </a>',
'                <button onClick={() => confirm(String(it.id))} style={{ padding: "8px 10px", borderRadius: 10, border: "1px solid #111", background: "#F7D500", color: "#111", fontWeight: 900, cursor: "pointer" }}>',
'                  Eu vi também',
'                </button>',
'              </div>',
'            </div>',
'          );',
'        }) : (',
'          <div style={{ padding: 12, border: "1px solid #ddd", borderRadius: 12, opacity: 0.8 }}>',
'            Nenhum ponto ainda. Crie o primeiro (prova leve) e confirme em dupla.',
'          </div>',
'        )}',
'      </div>',
'    </section>',
'  );',
'}',
''
)
WriteAllLinesUtf8NoBom $client $LClient
Write-Host '[PATCH] wrote src/app/eco/pontos/PontosClient.tsx'

# Prisma: install if missing, then format/migrate/generate
if (-not (Test-Path $prismaCmd)) {
  Write-Host '[DIAG] prisma.cmd not found. Installing prisma + @prisma/client...'
  npm i -D prisma
  npm i @prisma/client
}

if (Test-Path $prismaCmd) {
  & $prismaCmd format
  & $prismaCmd migrate dev --name eco_critical_points
  if ($LASTEXITCODE -ne 0) {
    Write-Host '[WARN] migrate dev failed. If it is DRIFT on SQLite dev.db: backup prisma/dev.db and run migrate reset --force, then migrate dev again.'
  } else {
    & $prismaCmd generate
  }
} else {
  Write-Host '[WARN] prisma.cmd still missing; skipped migrate/generate.'
}

$rep = Join-Path $reportDir ('eco-step-61-critical-points-mvp-v0_2-' + $ts + '.md')
$repLines = @(
'# eco-step-61-critical-points-mvp-v0_2',
'',
'- Time: ' + $ts,
'- Backup: ' + $backupDir,
'',
'## Added',
'- Prisma: EcoCriticalKind + EcoCriticalPoint + EcoCriticalPointConfirm',
'- API: POST /api/eco/critical/create (dedupe)',
'- API: GET  /api/eco/critical/list',
'- API: POST /api/eco/critical/confirm',
'- UI: /eco/pontos (form + list + confirm)',
'',
'## Verify',
'1) Restart dev server',
'2) Open /eco/pontos',
'3) Use geo, create point, confirm point',
'4) Check /api/eco/critical/list',
''
)
WriteAllLinesUtf8NoBom $rep $repLines
Write-Host ('[REPORT] ' + $rep)

Write-Host ''
Write-Host '[VERIFY] Ctrl+C -> npm run dev'
Write-Host '[VERIFY] Abra /eco/pontos e teste criar + confirmar.'