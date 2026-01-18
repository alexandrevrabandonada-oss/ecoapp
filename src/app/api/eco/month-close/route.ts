import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

function safeMonth(input: string | null): string | null {
  const s = String(input || "").trim();
  if (/^\\d{4}-\\d{2}$/.test(s)) return s;
  return null;
}

function asMsg(e: unknown) {
  if (e instanceof Error) return e.message;
  try { return String(e); } catch { return "unknown"; }
}

function looksLikeMissingTable(msg: string) {
  const m = msg.toLowerCase();
  return m.includes("does not exist") || m.includes("no such table") || m.includes("p2021");
}

function getMonthCloseModel() {
  const pc: any = prisma as any;
  return pc?.ecoMonthClose;
}

function getDayCloseModel() {
  const pc: any = prisma as any;
  return pc?.ecoDayClose;
}

function getTriagemModel() {
  const pc: any = prisma as any;
  const candidates = ["ecoTriagem", "triagem", "ecoSorting", "sorting"];
  for (const k of candidates) {
    const m = pc?.["k"];
    if (m && typeof m.findMany === "function") return { key: k, model: m as any };
  }
  return null;
}

function bump(obj: any, key: string, inc: number) {
  if (!obj[key]) obj[key] = 0;
  obj[key] += inc;
}

function normalizeMaterial(s: string) {
  const t = String(s || "").toLowerCase();
  if (t.includes("papel")) return "papel";
  if (t.includes("plasti")) return "plastico";
  if (t.includes("metal")) return "metal";
  if (t.includes("vidro")) return "vidro";
  if (t.includes("oleo")) return "oleo";
  if (t.includes("org")) return "organico";
  if (t.includes("reje")) return "rejeito";
  return "outros";
}

function monthRange(month: string) {
  const start = new Date(month + "-01T00:00:00-03:00");
  const next = new Date(start.getTime());
  next.setMonth(next.getMonth() + 1);
  const end = new Date(next.getTime() - 1);
  return { start, end };
}

async function computeSummary(month: string) {
  const { start, end } = monthRange(month);
  const dc = getDayCloseModel();
  const tri = getTriagemModel();

  const totals: any = { totalKg: 0, byMaterialKg: {}, days: 0, count: 0 };
  const meta: any = { computedAt: new Date().toISOString(), source: [] as string[] };

  // Prefer DayClose (recibo forte) se existir
  if (dc && typeof dc.findMany === "function") {
    meta.source.push("dayClose");
    const rows = await dc.findMany({
      where: { day: { gte: month + "-01", lt: month + "-32" } },
      orderBy: { day: "asc" },
    });
    totals.days = rows.length;
    for (const r of rows) {
      const summary = (r && (r.summary as any)) || {};
      const t = (summary && (summary.totals as any)) || {};
      const kg = Number(t.totalKg || 0) || 0;
      totals.totalKg += kg;
      const by = (t.byMaterialKg as any) || {};
      if (by && typeof by === "object") {
        for (const k of Object.keys(by)) bump(totals.byMaterialKg, k, Number(by[k] || 0) || 0);
      }
    }
    return { month, totals, meta, notes: [], version: "v0" };
  }

  meta.source.push("dayClose:missing");

  // Fallback: soma direto da triagem
  if (tri) {
    meta.source.push("triagem:" + tri.key);
    const rows = await tri.model.findMany({ where: { createdAt: { gte: start, lte: end } } });
    totals.count = rows.length;
    for (const r of rows) {
      const kg = Number((r && (r.weightKg ?? r.kg ?? r.weight ?? 0)) || 0) || 0;
      const mat = normalizeMaterial(String((r && (r.material ?? r.kind ?? r.type ?? "")) || ""));
      totals.totalKg += kg;
      bump(totals.byMaterialKg, mat, kg);
    }
  } else {
    meta.source.push("triagem:missing");
  }

  return { month, totals, meta, notes: [], version: "v0" };
}

export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const month = safeMonth(searchParams.get("month") ?? searchParams.get("m"));
  const fresh = String(searchParams.get("fresh") || "").trim() === "1";
  if (!month) return NextResponse.json({ ok: false, error: "bad_month" }, { status: 400 });

  const model = getMonthCloseModel();
  if (!model?.findUnique) return NextResponse.json({ ok: false, error: "model_not_ready" }, { status: 503 });

  try {
    if (!fresh) {
      const row = await model.findUnique({ where: { month } });
      if (row) return NextResponse.json({ ok: true, item: row, cached: true });
    }
    const summary = await computeSummary(month);
    const item = await model.upsert({ where: { month }, update: { summary }, create: { month, summary } });
    return NextResponse.json({ ok: true, item, cached: false });
  } catch (e) {
    const msg = asMsg(e);
    if (looksLikeMissingTable(msg)) return NextResponse.json({ ok: false, error: "db_not_ready", detail: msg }, { status: 503 });
    return NextResponse.json({ ok: false, error: "db_error", detail: msg }, { status: 500 });
  }
}

export async function POST(req: Request) {
  const body = (await req.json().catch(() => null)) as any;
  const month = safeMonth(body?.month ?? null);
  if (!month) return NextResponse.json({ ok: false, error: "bad_month" }, { status: 400 });

  const model = getMonthCloseModel();
  if (!model?.upsert) return NextResponse.json({ ok: false, error: "model_not_ready" }, { status: 503 });

  try {
    const summary = body?.summary ?? (await computeSummary(month));
    const item = await model.upsert({ where: { month }, update: { summary }, create: { month, summary } });
    return NextResponse.json({ ok: true, item });
  } catch (e) {
    const msg = asMsg(e);
    if (looksLikeMissingTable(msg)) return NextResponse.json({ ok: false, error: "db_not_ready", detail: msg }, { status: 503 });
    return NextResponse.json({ ok: false, error: "db_error", detail: msg }, { status: 500 });
  }
}

