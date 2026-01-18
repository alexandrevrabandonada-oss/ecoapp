param(
  [string]$Root = (Get-Location).Path
)

function EnsureDir([string]$p) { if (-not (Test-Path $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function ReadRaw([string]$p) { if (Test-Path $p) { return Get-Content -Raw -LiteralPath $p } return $null }

$ts = Get-Date -Format "yyyyMMdd-HHmmss"
$backupDir = Join-Path $Root ("tools/_patch_backup/" + $ts + "-eco-fix-day-close-parse-v0_1")
$reportDir = Join-Path $Root "reports"
EnsureDir $backupDir
EnsureDir $reportDir

$rt1 = Join-Path $Root "src/app/api/eco/day-close/route.ts"
$rt2 = Join-Path $Root "src/app/api/eco/day-close/compute/route.ts"

Write-Host ("[DIAG] Root: " + $Root)
Write-Host ("[DIAG] route.ts: " + $rt1)
Write-Host ("[DIAG] compute/route.ts: " + $rt2)

function BackupFile([string]$p) {
  if (Test-Path $p) {
    $name = Split-Path -Leaf $p
    Copy-Item -Force -LiteralPath $p -Destination (Join-Path $backupDir $name)
    Write-Host ("[BK] " + $name + " -> " + (Join-Path $backupDir $name))
  } else {
    Write-Host ("[BK] (missing) " + $p)
  }
}

BackupFile $rt1
BackupFile $rt2

$enc = New-Object System.Text.UTF8Encoding($false)

# ---------- src/app/api/eco/day-close/route.ts ----------
$lines1 = @(
'// ECO — day-close (cache + upsert) — fixed parse + safeDay regex',
'',
'import { NextResponse } from "next/server";',
'import { prisma } from "@/lib/prisma";',
'',
'export const runtime = "nodejs";',
'export const dynamic = "force-dynamic";',
'',
'function safeDay(input: string | null): string | null {',
'  const s = String(input ?? "").trim();',
'  // regex literal: use \\d? NÃO. Aqui é regex literal, então é \\d só em string. O correto é \\d? -> NÃO. É \\d em string, \\d em regex literal vira literal "\\d".',
'  if (/^\\d{4}-\\d{2}-\\d{2}$/.test(s)) return s;',
'  // ^^^ IMPORTANTE: a linha acima usa \\d propositalmente? NÃO. Vamos corrigir abaixo (linha sobrescrita).',
'  return null;',
'}',
'',
'// Corrige safeDay de verdade (mantém compat com patch anterior, mas garante o regex certo)',
'function safeDay2(input: string | null): string | null {',
'  const s = String(input ?? "").trim();',
'  if (/^\\d{4}-\\d{2}-\\d{2}$/.test(s)) return s;',
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
'function dayRange(day: string) {',
'  // Brasil -03:00 (sem depender de timezone do server)',
'  const start = new Date(day + "T00:00:00-03:00");',
'  const end = new Date(day + "T23:59:59.999-03:00");',
'  return { start, end };',
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
'  if (t.includes("org")) return "organico";',
'  if (t.includes("reje")) return "rejeito";',
'  return "outros";',
'}',
'',
'async function computeSummary(day: string) {',
'  const { start, end } = dayRange(day);',
'  const tri = getTriagemModel();',
'',
'  const totals: any = { totalKg: 0, byMaterialKg: {}, count: 0 };',
'  const meta: any = { computedAt: new Date().toISOString(), source: [] as string[] };',
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
'',
'  return { day, totals, meta, notes: [], version: "v0" };',
'}',
'',
'export async function GET(req: Request) {',
'  const { searchParams } = new URL(req.url);',
'  // aceita day, d, date',
'  const day = safeDay2(searchParams.get("day") ?? searchParams.get("d") ?? searchParams.get("date"));',
'  const fresh = String(searchParams.get("fresh") || "").trim() === "1";',
'  if (!day) return NextResponse.json({ ok: false, error: "bad_day" }, { status: 400 });',
'',
'  const model = getDayCloseModel();',
'  if (!model?.findUnique) {',
'    return NextResponse.json({ ok: false, error: "model_not_ready" }, { status: 503 });',
'  }',
'',
'  try {',
'    if (!fresh) {',
'      const row = await model.findUnique({ where: { day } });',
'      if (row) return NextResponse.json({ ok: true, item: row, cached: true });',
'    }',
'',
'    const summary = await computeSummary(day);',
'    const item = await model.upsert({',
'      where: { day },',
'      update: { summary },',
'      create: { day, summary },',
'    });',
'',
'    return NextResponse.json({ ok: true, item, cached: false });',
'  } catch (e) {',
'    const msg = asMsg(e);',
'    if (looksLikeMissingTable(msg)) {',
'      return NextResponse.json({ ok: false, error: "db_not_ready", detail: msg }, { status: 503 });',
'    }',
'    return NextResponse.json({ ok: false, error: "db_error", detail: msg }, { status: 500 });',
'  }',
'}',
'',
'export async function POST(req: Request) {',
'  const body = (await req.json().catch(() => null)) as any;',
'  const day = safeDay2(body?.day ?? null);',
'  if (!day) return NextResponse.json({ ok: false, error: "bad_day" }, { status: 400 });',
'',
'  const model = getDayCloseModel();',
'  if (!model?.upsert) {',
'    return NextResponse.json({ ok: false, error: "model_not_ready" }, { status: 503 });',
'  }',
'',
'  try {',
'    const summary = body?.summary ?? (await computeSummary(day));',
'    const item = await model.upsert({',
'      where: { day },',
'      update: { summary },',
'      create: { day, summary },',
'    });',
'    return NextResponse.json({ ok: true, item });',
'  } catch (e) {',
'    const msg = asMsg(e);',
'    if (looksLikeMissingTable(msg)) {',
'      return NextResponse.json({ ok: false, error: "db_not_ready", detail: msg }, { status: 503 });',
'    }',
'    return NextResponse.json({ ok: false, error: "db_error", detail: msg }, { status: 500 });',
'  }',
'}',
''
)

# Troca o safeDay “de verdade” para regex literal correta (sem \\d)
# (fazemos isso depois de montar o array para evitar risco de escape em geração)
for ($i=0; $i -lt $lines1.Count; $i++) {
  if ($lines1[$i] -eq '  if (/^\\d{4}-\\d{2}-\\d{2}$/.test(s)) return s;') {
    $lines1[$i] = '  if (/^\d{4}-\d{2}-\d{2}$/.test(s)) return s;'
  }
}

EnsureDir (Split-Path -Parent $rt1)
[System.IO.File]::WriteAllLines($rt1, $lines1, $enc)
Write-Host "[PATCH] wrote src/app/api/eco/day-close/route.ts"

# ---------- src/app/api/eco/day-close/compute/route.ts ----------
$lines2 = @(
'// ECO — day-close/compute (compute-only) — fixed safeDay regex',
'',
'import { NextResponse } from "next/server";',
'import { prisma } from "@/lib/prisma";',
'',
'export const runtime = "nodejs";',
'export const dynamic = "force-dynamic";',
'',
'function safeDay(input: string | null): string | null {',
'  const s = String(input ?? "").trim();',
'  if (/^\d{4}-\d{2}-\d{2}$/.test(s)) return s;',
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
'function dayRange(day: string) {',
'  const start = new Date(day + "T00:00:00-03:00");',
'  const end = new Date(day + "T23:59:59.999-03:00");',
'  return { start, end };',
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
'  if (t.includes("org")) return "organico";',
'  if (t.includes("reje")) return "rejeito";',
'  return "outros";',
'}',
'',
'async function computeSummary(day: string) {',
'  const { start, end } = dayRange(day);',
'  const tri = getTriagemModel();',
'',
'  const totals: any = { totalKg: 0, byMaterialKg: {}, count: 0 };',
'  const meta: any = { computedAt: new Date().toISOString(), source: [] as string[] };',
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
'',
'  return { day, totals, meta, notes: [], version: "v0" };',
'}',
'',
'export async function GET(req: Request) {',
'  const { searchParams } = new URL(req.url);',
'  const day = safeDay(searchParams.get("day") ?? searchParams.get("d") ?? searchParams.get("date"));',
'  if (!day) return NextResponse.json({ ok: false, error: "bad_day" }, { status: 400 });',
'',
'  try {',
'    const summary = await computeSummary(day);',
'    return NextResponse.json({ ok: true, summary });',
'  } catch (e) {',
'    const msg = asMsg(e);',
'    if (looksLikeMissingTable(msg)) {',
'      return NextResponse.json({ ok: false, error: "db_not_ready", detail: msg }, { status: 503 });',
'    }',
'    return NextResponse.json({ ok: false, error: "db_error", detail: msg }, { status: 500 });',
'  }',
'}',
''
)

EnsureDir (Split-Path -Parent $rt2)
[System.IO.File]::WriteAllLines($rt2, $lines2, $enc)
Write-Host "[PATCH] wrote src/app/api/eco/day-close/compute/route.ts"

# REPORT
$rep = Join-Path $reportDir ("eco-fix-day-close-parse-v0_1-" + $ts + ".md")
$repLines = @(
"# eco-fix-day-close-parse-v0_1",
"",
"- Time: " + $ts,
"- Backup: " + $backupDir,
"- Patched: ",
"  - " + $rt1,
"  - " + $rt2,
"",
"## Notes",
"- Reescreveu os dois routes multilinha pra eliminar parse error do Turbopack.",
"- safeDay agora aceita YYYY-MM-DD com regex literal correta (/^\\d.../).",
"- Query aceita day|d|date."
)
[System.IO.File]::WriteAllLines($rep, $repLines, $enc)
Write-Host ("[REPORT] " + $rep)

Write-Host ""
Write-Host "[NEXT] Reinicie o dev server e teste:"
Write-Host '  irm "http://localhost:3000/api/eco/day-close?day=2025-12-26" -Headers @{Accept="application/json"} | ConvertTo-Json -Depth 20'