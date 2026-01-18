param(
  [string]$Root = (Get-Location).Path
)

function EnsureDir([string]$p) { if (-not (Test-Path $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function WriteUtf8NoBom([string]$p, [string]$content) {
  EnsureDir (Split-Path -Parent $p)
  $enc = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($p, $content, $enc)
}
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
    Write-Host ("[BK] " + $rel + " -> " + (Split-Path -Leaf $dest))
  }
}
function Run([string]$cmd, [string]$wd) {
  Write-Host ("[RUN] " + $cmd)
  $pinfo = New-Object System.Diagnostics.ProcessStartInfo
  $pinfo.FileName = "pwsh"
  $pinfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -Command " + '"' + $cmd.Replace('"','\"') + '"'
  $pinfo.WorkingDirectory = $wd
  $pinfo.RedirectStandardOutput = $true
  $pinfo.RedirectStandardError = $true
  $pinfo.UseShellExecute = $false
  $p = New-Object System.Diagnostics.Process
  $p.StartInfo = $pinfo
  $null = $p.Start()
  $out = $p.StandardOutput.ReadToEnd()
  $err = $p.StandardError.ReadToEnd()
  $p.WaitForExit()
  return @{ Code = $p.ExitCode; Out = $out; Err = $err }
}

$ts = Get-Date -Format "yyyyMMdd-HHmmss"
$backupDir = Join-Path $Root ("tools/_patch_backup/" + $ts + "-eco-step-59-month-close-mvp-v0_1")
$reportDir = Join-Path $Root "reports"
EnsureDir $backupDir
EnsureDir $reportDir

Write-Host ("== eco-step-59-month-close-mvp-v0_1 == " + $ts)
Write-Host ("[DIAG] Root: " + $Root)

# Paths
$schema = Join-Path $Root "prisma/schema.prisma"
$prismaCmd = Join-Path $Root "node_modules/.bin/prisma.cmd"

$apiMonth = Join-Path $Root "src/app/api/eco/month-close/route.ts"
$apiMonthList = Join-Path $Root "src/app/api/eco/month-close/list/route.ts"
$apiMonthCard = Join-Path $Root "src/app/api/eco/month-close/card/route.tsx"

$pageTransp = Join-Path $Root "src/app/eco/transparencia/page.tsx"
$clientTransp = Join-Path $Root "src/app/eco/transparencia/TransparenciaClient.tsx"
$shareMonthPage = Join-Path $Root "src/app/eco/share/mes/[month]/page.tsx"

Write-Host ("[DIAG] Will write: " + $apiMonth)
Write-Host ("[DIAG] Will write: " + $apiMonthList)
Write-Host ("[DIAG] Will write: " + $apiMonthCard)
Write-Host ("[DIAG] Will write: " + $pageTransp)
Write-Host ("[DIAG] Will write: " + $clientTransp)

BackupFile $schema $backupDir
BackupFile $apiMonth $backupDir
BackupFile $apiMonthList $backupDir
BackupFile $apiMonthCard $backupDir
BackupFile $pageTransp $backupDir
BackupFile $clientTransp $backupDir
BackupFile $shareMonthPage $backupDir

# 1) Prisma model (append if missing)
if (-not (Test-Path $schema)) {
  throw ("[STOP] schema.prisma not found at " + $schema)
}

$raw = Get-Content -Raw -LiteralPath $schema
if ($null -eq $raw -or $raw.Length -lt 10) { throw "[STOP] schema.prisma read failed (empty)" }

if ($raw -notmatch "model\s+EcoMonthClose") {
  Write-Host "[PATCH] prisma/schema.prisma: adding model EcoMonthClose (append)"
  $add = @(
    "",
    "model EcoMonthClose {",
    "  id        String   @id @default(cuid())",
    "  month     String   @unique",
    "  summary   Json",
    "  createdAt DateTime @default(now())",
    "  updatedAt DateTime @updatedAt",
    "}",
    ""
  ) -join "`n"
  $raw2 = $raw.TrimEnd() + $add
  WriteUtf8NoBom $schema $raw2
} else {
  Write-Host "[DIAG] prisma/schema.prisma already has EcoMonthClose"
}

# 2) Write API routes
$LMonth = @(
'import { NextResponse } from "next/server";',
'import { prisma } from "@/lib/prisma";',
'',
'export const runtime = "nodejs";',
'export const dynamic = "force-dynamic";',
'',
'function safeMonth(input: string | null): string | null {',
'  const s = String(input || "").trim();',
'  if (/^\\d{4}-\\d{2}$/.test(s)) return s;',
'  return null;',
'}',
'',
'function asMsg(e: unknown) {',
'  if (e instanceof Error) return e.message;',
'  try { return String(e); } catch { return "unknown"; }',
'}',
'',
'function looksLikeMissingTable(msg: string) {',
'  const m = msg.toLowerCase();',
'  return m.includes("does not exist") || m.includes("no such table") || m.includes("p2021");',
'}',
'',
'function getMonthCloseModel() {',
'  const pc: any = prisma as any;',
'  return pc?.ecoMonthClose;',
'}',
'',
'function getDayCloseModel() {',
'  const pc: any = prisma as any;',
'  return pc?.ecoDayClose;',
'}',
'',
'function getTriagemModel() {',
'  const pc: any = prisma as any;',
'  const candidates = ["ecoTriagem", "triagem", "ecoSorting", "sorting"];',
'  for (const k of candidates) {',
'    const m = pc?.[k];',
'    if (m && typeof m.findMany === "function") return { key: k, model: m as any };',
'  }',
'  return null;',
'}',
'',
'function bump(obj: any, key: string, inc: number) {',
'  if (!obj[key]) obj[key] = 0;',
'  obj[key] += inc;',
'}',
'',
'function normalizeMaterial(s: string) {',
'  const t = String(s || "").toLowerCase();',
'  if (t.includes("papel")) return "papel";',
'  if (t.includes("plasti")) return "plastico";',
'  if (t.includes("metal")) return "metal";',
'  if (t.includes("vidro")) return "vidro";',
'  if (t.includes("oleo")) return "oleo";',
'  if (t.includes("org")) return "organico";',
'  if (t.includes("reje")) return "rejeito";',
'  return "outros";',
'}',
'',
'function monthRange(month: string) {',
'  const start = new Date(month + "-01T00:00:00-03:00");',
'  const next = new Date(start.getTime());',
'  next.setMonth(next.getMonth() + 1);',
'  const end = new Date(next.getTime() - 1);',
'  return { start, end };',
'}',
'',
'async function computeSummary(month: string) {',
'  const { start, end } = monthRange(month);',
'  const dc = getDayCloseModel();',
'  const tri = getTriagemModel();',
'',
'  const totals: any = { totalKg: 0, byMaterialKg: {}, days: 0, count: 0 };',
'  const meta: any = { computedAt: new Date().toISOString(), source: [] as string[] };',
'',
'  // Prefer DayClose (recibo forte) se existir',
'  if (dc && typeof dc.findMany === "function") {',
'    meta.source.push("dayClose");',
'    const rows = await dc.findMany({',
'      where: { day: { gte: month + "-01", lt: month + "-32" } },',
'      orderBy: { day: "asc" },',
'    });',
'    totals.days = rows.length;',
'    for (const r of rows) {',
'      const summary = (r && (r.summary as any)) || {};',
'      const t = (summary && (summary.totals as any)) || {};',
'      const kg = Number(t.totalKg || 0) || 0;',
'      totals.totalKg += kg;',
'      const by = (t.byMaterialKg as any) || {};',
'      if (by && typeof by === "object") {',
'        for (const k of Object.keys(by)) bump(totals.byMaterialKg, k, Number(by[k] || 0) || 0);',
'      }',
'    }',
'    return { month, totals, meta, notes: [], version: "v0" };',
'  }',
'',
'  meta.source.push("dayClose:missing");',
'',
'  // Fallback: soma direto da triagem',
'  if (tri) {',
'    meta.source.push("triagem:" + tri.key);',
'    const rows = await tri.model.findMany({ where: { createdAt: { gte: start, lte: end } } });',
'    totals.count = rows.length;',
'    for (const r of rows) {',
'      const kg = Number((r && (r.weightKg ?? r.kg ?? r.weight ?? 0)) || 0) || 0;',
'      const mat = normalizeMaterial(String((r && (r.material ?? r.kind ?? r.type ?? "")) || ""));',
'      totals.totalKg += kg;',
'      bump(totals.byMaterialKg, mat, kg);',
'    }',
'  } else {',
'    meta.source.push("triagem:missing");',
'  }',
'',
'  return { month, totals, meta, notes: [], version: "v0" };',
'}',
'',
'export async function GET(req: Request) {',
'  const { searchParams } = new URL(req.url);',
'  const month = safeMonth(searchParams.get("month") ?? searchParams.get("m"));',
'  const fresh = String(searchParams.get("fresh") || "").trim() === "1";',
'  if (!month) return NextResponse.json({ ok: false, error: "bad_month" }, { status: 400 });',
'',
'  const model = getMonthCloseModel();',
'  if (!model?.findUnique) return NextResponse.json({ ok: false, error: "model_not_ready" }, { status: 503 });',
'',
'  try {',
'    if (!fresh) {',
'      const row = await model.findUnique({ where: { month } });',
'      if (row) return NextResponse.json({ ok: true, item: row, cached: true });',
'    }',
'    const summary = await computeSummary(month);',
'    const item = await model.upsert({ where: { month }, update: { summary }, create: { month, summary } });',
'    return NextResponse.json({ ok: true, item, cached: false });',
'  } catch (e) {',
'    const msg = asMsg(e);',
'    if (looksLikeMissingTable(msg)) return NextResponse.json({ ok: false, error: "db_not_ready", detail: msg }, { status: 503 });',
'    return NextResponse.json({ ok: false, error: "db_error", detail: msg }, { status: 500 });',
'  }',
'}',
'',
'export async function POST(req: Request) {',
'  const body = (await req.json().catch(() => null)) as any;',
'  const month = safeMonth(body?.month ?? null);',
'  if (!month) return NextResponse.json({ ok: false, error: "bad_month" }, { status: 400 });',
'',
'  const model = getMonthCloseModel();',
'  if (!model?.upsert) return NextResponse.json({ ok: false, error: "model_not_ready" }, { status: 503 });',
'',
'  try {',
'    const summary = body?.summary ?? (await computeSummary(month));',
'    const item = await model.upsert({ where: { month }, update: { summary }, create: { month, summary } });',
'    return NextResponse.json({ ok: true, item });',
'  } catch (e) {',
'    const msg = asMsg(e);',
'    if (looksLikeMissingTable(msg)) return NextResponse.json({ ok: false, error: "db_not_ready", detail: msg }, { status: 503 });',
'    return NextResponse.json({ ok: false, error: "db_error", detail: msg }, { status: 500 });',
'  }',
'}',
''
)
WriteAllLinesUtf8NoBom $apiMonth $LMonth
Write-Host "[PATCH] wrote src/app/api/eco/month-close/route.ts"

$LMonthList = @(
'import { NextResponse } from "next/server";',
'import { prisma } from "@/lib/prisma";',
'',
'export const runtime = "nodejs";',
'export const dynamic = "force-dynamic";',
'',
'function clampInt(x: any, d: number) {',
'  const n = Number(x);',
'  if (!Number.isFinite(n) || n <= 0) return d;',
'  return Math.min(200, Math.floor(n));',
'}',
'',
'export async function GET(req: Request) {',
'  const { searchParams } = new URL(req.url);',
'  const limit = clampInt(searchParams.get("limit"), 24);',
'  const pc: any = prisma as any;',
'  const model = pc?.ecoMonthClose;',
'  if (!model?.findMany) return NextResponse.json({ ok: false, error: "model_not_ready" }, { status: 503 });',
'  try {',
'    const items = await model.findMany({ orderBy: { month: "desc" }, take: limit });',
'    return NextResponse.json({ ok: true, items });',
'  } catch (e: any) {',
'    return NextResponse.json({ ok: false, error: "db_error", detail: String(e?.message || e) }, { status: 500 });',
'  }',
'}',
''
)
WriteAllLinesUtf8NoBom $apiMonthList $LMonthList
Write-Host "[PATCH] wrote src/app/api/eco/month-close/list/route.ts"

$LMonthCard = @(
'import { ImageResponse } from "next/og";',
'import { prisma } from "@/lib/prisma";',
'',
'export const runtime = "nodejs";',
'export const dynamic = "force-dynamic";',
'',
'function safeMonth(input: string | null): string | null {',
'  const s = String(input || "").trim();',
'  if (/^\\d{4}-\\d{2}$/.test(s)) return s;',
'  return null;',
'}',
'',
'function fmtKg(n: any): string {',
'  const v = Number(n || 0) || 0;',
'  const s = Math.round(v * 10) / 10;',
'  return String(s).replace(".", ",") + " kg";',
'}',
'',
'function topMaterials(by: any): Array<{ k: string; v: number }> {',
'  const out: Array<{ k: string; v: number }> = [];',
'  if (by && typeof by === "object") {',
'    for (const k of Object.keys(by)) out.push({ k, v: Number(by[k] || 0) || 0 });',
'  }',
'  out.sort((a, b) => b.v - a.v);',
'  return out.slice(0, 5);',
'}',
'',
'function bump(obj: any, key: string, inc: number) {',
'  if (!obj[key]) obj[key] = 0;',
'  obj[key] += inc;',
'}',
'',
'function normalizeMaterial(s: string) {',
'  const t = String(s || "").toLowerCase();',
'  if (t.includes("papel")) return "papel";',
'  if (t.includes("plasti")) return "plastico";',
'  if (t.includes("metal")) return "metal";',
'  if (t.includes("vidro")) return "vidro";',
'  if (t.includes("oleo")) return "oleo";',
'  if (t.includes("org")) return "organico";',
'  if (t.includes("reje")) return "rejeito";',
'  return "outros";',
'}',
'',
'function monthRange(month: string) {',
'  const start = new Date(month + "-01T00:00:00-03:00");',
'  const next = new Date(start.getTime());',
'  next.setMonth(next.getMonth() + 1);',
'  const end = new Date(next.getTime() - 1);',
'  return { start, end };',
'}',
'',
'function getDayCloseModel() {',
'  const pc: any = prisma as any;',
'  return pc?.ecoDayClose;',
'}',
'',
'function getTriagemModel() {',
'  const pc: any = prisma as any;',
'  const candidates = ["ecoTriagem", "triagem", "ecoSorting", "sorting"];',
'  for (const k of candidates) {',
'    const m = pc?.[k];',
'    if (m && typeof m.findMany === "function") return { key: k, model: m as any };',
'  }',
'  return null;',
'}',
'',
'async function computeSummary(month: string) {',
'  const { start, end } = monthRange(month);',
'  const dc = getDayCloseModel();',
'  const tri = getTriagemModel();',
'  const totals: any = { totalKg: 0, byMaterialKg: {}, days: 0, count: 0 };',
'  const meta: any = { computedAt: new Date().toISOString(), source: [] as string[] };',
'',
'  if (dc && typeof dc.findMany === "function") {',
'    meta.source.push("dayClose");',
'    const rows = await dc.findMany({',
'      where: { day: { gte: month + "-01", lt: month + "-32" } },',
'      orderBy: { day: "asc" },',
'    });',
'    totals.days = rows.length;',
'    for (const r of rows) {',
'      const summary = (r && (r.summary as any)) || {};',
'      const t = (summary && (summary.totals as any)) || {};',
'      totals.totalKg += Number(t.totalKg || 0) || 0;',
'      const by = (t.byMaterialKg as any) || {};',
'      if (by && typeof by === "object") {',
'        for (const k of Object.keys(by)) bump(totals.byMaterialKg, k, Number(by[k] || 0) || 0);',
'      }',
'    }',
'    return { month, totals, meta, notes: [], version: "v0" };',
'  }',
'',
'  meta.source.push("dayClose:missing");',
'',
'  if (tri) {',
'    meta.source.push("triagem:" + tri.key);',
'    const rows = await tri.model.findMany({ where: { createdAt: { gte: start, lte: end } } });',
'    totals.count = rows.length;',
'    for (const r of rows) {',
'      const kg = Number((r && (r.weightKg ?? r.kg ?? r.weight ?? 0)) || 0) || 0;',
'      const mat = normalizeMaterial(String((r && (r.material ?? r.kind ?? r.type ?? "")) || ""));',
'      totals.totalKg += kg;',
'      bump(totals.byMaterialKg, mat, kg);',
'    }',
'  } else {',
'    meta.source.push("triagem:missing");',
'  }',
'  return { month, totals, meta, notes: [], version: "v0" };',
'}',
'',
'async function ensureMonthClose(month: string) {',
'  const pc: any = prisma as any;',
'  const model = pc?.ecoMonthClose;',
'  if (!model?.upsert) return null;',
'  const summary = await computeSummary(month);',
'  const item = await model.upsert({ where: { month }, update: { summary }, create: { month, summary } });',
'  return item;',
'}',
'',
'export async function GET(req: Request) {',
'  const { searchParams } = new URL(req.url);',
'  const month = safeMonth(searchParams.get("month") ?? searchParams.get("m"));',
'  const format = String(searchParams.get("format") || "3x4");',
'  if (!month) return new ImageResponse(<div style={{ display: "flex" }}>bad_month</div>, { width: 1080, height: 1350 });',
'',
'  const item = await ensureMonthClose(month);',
'  const summary: any = (item && (item.summary as any)) || {};',
'  const totals: any = (summary && (summary.totals as any)) || {};',
'  const totalKg = fmtKg(totals.totalKg || 0);',
'  const days = Number(totals.days || 0) || 0;',
'  const mats = topMaterials(totals.byMaterialKg || {});',
'',
'  const W = format === "1x1" ? 1080 : 1080;',
'  const H = format === "1x1" ? 1080 : 1350;',
'',
'  return new ImageResponse(',
'    (',
'      <div',
'        style={{',
'          width: W,',
'          height: H,',
'          display: "flex",',
'          flexDirection: "column",',
'          justifyContent: "space-between",',
'          padding: 60,',
'          background: "#0B0B0B",',
'          color: "#F7D500",',
'          fontFamily: "ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Arial",',
'        }}',
'      >',
'        <div style={{ display: "flex", flexDirection: "column", gap: 18 }}>',
'          <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>',
'            <div style={{ display: "flex", flexDirection: "column", gap: 6 }}>',
'              <div style={{ fontSize: 24, letterSpacing: 2, color: "#F7D500", opacity: 0.95 }}>ECO</div>',
'              <div style={{ fontSize: 46, fontWeight: 900, lineHeight: 1.05 }}>TRANSPARÊNCIA DO MÊS</div>',
'            </div>',
'            <div style={{ display: "flex", flexDirection: "column", alignItems: "flex-end", gap: 6 }}>',
'              <div style={{ fontSize: 22, opacity: 0.9 }}>MÊS</div>',
'              <div style={{ fontSize: 44, fontWeight: 900, color: "#F7D500" }}>{month}</div>',
'            </div>',
'          </div>',
'',
'          <div style={{ display: "flex", flexDirection: "column", gap: 10, background: "#111", border: "2px solid #F7D500", borderRadius: 18, padding: 22 }}>',
'            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline" }}>',
'              <div style={{ fontSize: 24, opacity: 0.9 }}>Total do mês</div>',
'              <div style={{ fontSize: 44, fontWeight: 900 }}>{totalKg}</div>',
'            </div>',
'            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline" }}>',
'              <div style={{ fontSize: 20, opacity: 0.85 }}>Dias fechados</div>',
'              <div style={{ fontSize: 26, fontWeight: 800, color: "#F7D500" }}>{String(days)}</div>',
'            </div>',
'          </div>',
'',
'          <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>',
'            <div style={{ fontSize: 22, fontWeight: 800, color: "#F7D500" }}>Por material (top 5)</div>',
'            <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>',
'              {mats.length ? mats.map((m) => (',
'                <div key={m.k} style={{ display: "flex", justifyContent: "space-between", gap: 16, borderBottom: "1px solid rgba(247,213,0,0.25)", paddingBottom: 6 }}>',
'                  <div style={{ display: "flex" , fontSize: 22, fontWeight: 800, color: "#F7D500" }}>{String(m.k).toUpperCase()}</div>',
'                  <div style={{ display: "flex" , fontSize: 22, fontWeight: 800, color: "#F7D500" }}>{fmtKg(m.v)}</div>',
'                </div>',
'              )) : (',
'                <div style={{ display: "flex", fontSize: 20, opacity: 0.8 }}>Sem dados ainda.</div>',
'              )}',
'            </div>',
'          </div>',
'        </div>',
'',
'        <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>',
'          <div style={{ display: "flex", gap: 12, flexWrap: "wrap" }}>',
'            <div style={{ display: "flex", padding: "10px 14px", borderRadius: 999, background: "#F7D500", color: "#111", fontWeight: 900 }}>RECIBO É LEI</div>',
'            <div style={{ display: "flex", padding: "10px 14px", borderRadius: 999, border: "2px solid #F7D500", color: "#F7D500", fontWeight: 900 }}>CUIDADO É COLETIVO</div>',
'            <div style={{ display: "flex", padding: "10px 14px", borderRadius: 999, border: "2px solid #F7D500", color: "#F7D500", fontWeight: 900 }}>TRABALHO DIGNO NO CENTRO</div>',
'          </div>',
'          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>',
'            <div style={{ display: "flex", fontSize: 18, opacity: 0.9 }}>#ECO — Escutar • Cuidar • Organizar</div>',
'            <div style={{ display: "flex", fontSize: 18, opacity: 0.8 }}>eco/share/mes/{month}</div>',
'          </div>',
'        </div>',
'      </div>',
'    ),',
'    { width: W, height: H }',
'  );',
'}',
''
)
WriteAllLinesUtf8NoBom $apiMonthCard $LMonthCard
Write-Host "[PATCH] wrote src/app/api/eco/month-close/card/route.tsx"

# 3) UI Transparência
$LPage = @(
'import TransparenciaClient from "./TransparenciaClient";',
'',
'export const dynamic = "force-dynamic";',
'',
'export default function Page() {',
'  return (',
'    <main style={{ padding: 16, maxWidth: 1100, margin: "0 auto" }}>',
'      <h1 style={{ margin: "0 0 8px 0" }}>Transparência (Mensal)</h1>',
'      <p style={{ margin: "0 0 14px 0", opacity: 0.85 }}>',
'        Fechamento mensal com cards prontos pra compartilhar.',
'      </p>',
'      <TransparenciaClient />',
'    </main>',
'  );',
'}',
''
)
WriteAllLinesUtf8NoBom $pageTransp $LPage
Write-Host "[PATCH] wrote src/app/eco/transparencia/page.tsx"

$LClient = @(
'"use client";',
'',
'import { useEffect, useMemo, useState } from "react";',
'',
'type AnyObj = Record<string, any>;',
'',
'function monthNow(): string {',
'  const d = new Date();',
'  const y = d.getFullYear();',
'  const m = String(d.getMonth() + 1).padStart(2, "0");',
'  return String(y) + "-" + m;',
'}',
'',
'async function jget(url: string): Promise<AnyObj> {',
'  const res = await fetch(url, { headers: { Accept: "application/json" }, cache: "no-store" });',
'  const data = await res.json().catch(() => ({}));',
'  if (!res.ok) return { ok: false, status: res.status, ...data };',
'  return data;',
'}',
'',
'export default function TransparenciaClient() {',
'  const [items, setItems] = useState<AnyObj[]>([]);',
'  const [status, setStatus] = useState<string>("carregando");',
'',
'  const listUrl = useMemo(() => "/api/eco/month-close/list?limit=24", []);',
'  const m0 = useMemo(() => monthNow(), []);',
'',
'  useEffect(() => {',
'    let alive = true;',
'    (async () => {',
'      setStatus("carregando");',
'      const d = await jget(listUrl);',
'      if (!alive) return;',
'      if (d && d.ok && Array.isArray(d.items)) {',
'        setItems(d.items);',
'        setStatus("ok");',
'      } else {',
'        setItems([]);',
'        setStatus("erro");',
'      }',
'    })();',
'    return () => { alive = false; };',
'  }, [listUrl]);',
'',
'  return (',
'    <section style={{ display: "grid", gap: 12 }}>',
'      <div style={{ display: "flex", gap: 10, flexWrap: "wrap", alignItems: "center" }}>',
'        <a href={"/eco/share/mes/" + m0} style={{ textDecoration: "none", padding: "8px 10px", borderRadius: 10, border: "1px solid #111", background: "#F7D500", color: "#111", fontWeight: 800 }}>',
'          Compartilhar mês atual ({m0})',
'        </a>',
'        <a href={"/api/eco/month-close?month=" + m0 + "&fresh=1"} target="_blank" rel="noreferrer" style={{ textDecoration: "none", padding: "8px 10px", borderRadius: 10, border: "1px solid #111" }}>',
'          Recalcular mês atual',
'        </a>',
'        <div style={{ opacity: 0.75 }}>status: {status} • itens: {items.length}</div>',
'      </div>',
'',
'      <div style={{ display: "grid", gap: 10 }}>',
'        {items.length ? items.map((it) => {',
'          const month = String(it.month || "");',
'          const sum = (it.summary || {}) as any;',
'          const totals = (sum.totals || {}) as any;',
'          const totalKg = totals.totalKg != null ? totals.totalKg : 0;',
'          return (',
'            <div key={month} style={{ display: "flex", justifyContent: "space-between", gap: 10, padding: 12, border: "1px solid #ddd", borderRadius: 12, alignItems: "center" }}>',
'              <div style={{ display: "grid", gap: 4 }}>',
'                <div style={{ fontWeight: 900 }}>{month}</div>',
'                <div style={{ opacity: 0.8 }}>totalKg: {String(totalKg)}</div>',
'              </div>',
'              <div style={{ display: "flex", gap: 8, flexWrap: "wrap", justifyContent: "flex-end" }}>',
'                <a href={"/eco/share/mes/" + month} style={{ textDecoration: "none", padding: "8px 10px", borderRadius: 10, border: "1px solid #111", background: "#F7D500", color: "#111", fontWeight: 800 }}>',
'                  Share',
'                </a>',
'                <a href={"/api/eco/month-close/card?format=3x4&month=" + month} target="_blank" rel="noreferrer" style={{ textDecoration: "none", padding: "8px 10px", borderRadius: 10, border: "1px solid #111" }}>',
'                  Card 3:4',
'                </a>',
'                <a href={"/api/eco/month-close/card?format=1x1&month=" + month} target="_blank" rel="noreferrer" style={{ textDecoration: "none", padding: "8px 10px", borderRadius: 10, border: "1px solid #111" }}>',
'                  Card 1:1',
'                </a>',
'              </div>',
'            </div>',
'          );',
'        }) : (',
'          <div style={{ padding: 12, border: "1px solid #ddd", borderRadius: 12, opacity: 0.8 }}>',
'            Sem fechamentos mensais ainda. Clique em “Compartilhar mês atual” para gerar o primeiro.',
'          </div>',
'        )}',
'      </div>',
'    </section>',
'  );',
'}',
''
)
WriteAllLinesUtf8NoBom $clientTransp $LClient
Write-Host "[PATCH] wrote src/app/eco/transparencia/TransparenciaClient.tsx"

# 4) Share month page (create if missing)
if (-not (Test-Path $shareMonthPage)) {
  $LShareMonthPage = @(
'import ShareMonthClient from "./ShareMonthClient";',
'',
'export const dynamic = "force-dynamic";',
'',
'export default async function Page({ params }: { params: { month: string } }) {',
'  return (',
'    <main style={{ padding: 16, maxWidth: 1100, margin: "0 auto" }}>',
'      <h1 style={{ margin: "0 0 8px 0" }}>Compartilhar mês: {params.month}</h1>',
'      <p style={{ margin: "0 0 14px 0", opacity: 0.85 }}>Card + legenda prontos para postar.</p>',
'      <ShareMonthClient month={params.month} />',
'    </main>',
'  );',
'}',
''
  )
  WriteAllLinesUtf8NoBom $shareMonthPage $LShareMonthPage
  Write-Host "[PATCH] created src/app/eco/share/mes/[month]/page.tsx"
} else {
  Write-Host "[DIAG] share month page already exists (skip)"
}

# 5) Prisma migrate/generate (best-effort)
if (-not (Test-Path $prismaCmd)) {
  Write-Host "[DIAG] prisma.cmd not found. Installing prisma + @prisma/client..."
  $r1 = Run "npm i -D prisma" $Root
  Write-Host $r1.Out
  if ($r1.Err) { Write-Host $r1.Err }
  $r2 = Run "npm i @prisma/client" $Root
  Write-Host $r2.Out
  if ($r2.Err) { Write-Host $r2.Err }
}

if (Test-Path $prismaCmd) {
  Write-Host "[RUN] prisma format"
  $rF = Run ("& '" + $prismaCmd + "' format") $Root
  Write-Host $rF.Out
  if ($rF.Err) { Write-Host $rF.Err }

  Write-Host "[RUN] prisma migrate dev (eco_month_close)"
  $rM = Run ("& '" + $prismaCmd + "' migrate dev --name eco_month_close") $Root
  Write-Host $rM.Out
  if ($rM.Err) { Write-Host $rM.Err }

  if ($rM.Code -ne 0) {
    Write-Host "[WARN] migrate dev failed. If it's DRIFT on SQLite dev.db: backup prisma/dev.db and run migrate reset --force, then migrate dev again."
  } else {
    Write-Host "[RUN] prisma generate"
    $rG = Run ("& '" + $prismaCmd + "' generate") $Root
    Write-Host $rG.Out
    if ($rG.Err) { Write-Host $rG.Err }
  }
} else {
  Write-Host "[WARN] prisma.cmd still missing; skipped migrate/generate."
}

# 6) Report
$rep = Join-Path $reportDir ("eco-step-59-month-close-mvp-v0_1-" + $ts + ".md")
$repLines = @(
"# eco-step-59-month-close-mvp-v0_1",
"",
"- Time: " + $ts,
"- Backup: " + $backupDir,
"",
"## Added",
"- Prisma model: EcoMonthClose (month unique, summary Json)",
"- API: /api/eco/month-close (GET/POST)",
"- API: /api/eco/month-close/list",
"- Card: /api/eco/month-close/card?format=3x4|1x1&month=YYYY-MM",
"- UI: /eco/transparencia (lista + atalhos)",
"",
"## Verify",
"1) Restart dev server",
"2) Open /eco/transparencia",
"3) Click 'Compartilhar mês atual' and open cards",
"4) Test: /api/eco/month-close?month=2025-12",
""
)
WriteAllLinesUtf8NoBom $rep $repLines
Write-Host ("[REPORT] " + $rep)

Write-Host ""
Write-Host "[VERIFY] Ctrl+C -> npm run dev"
Write-Host "[VERIFY] Abra /eco/transparencia e gere o mês atual (Share)."