// ECO — day-close/compute — step 54b: safeDay robust

import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

function safeDay(input: string | null): string | null {
  const raw = String(input ?? "").trim();
  if (!raw) return null;
  const norm = raw.replace(/[‐-‒–—―]/g, "-").replace(/\//g, "-");
  const m = norm.match(/^(\d{4})-(\d{2})-(\d{2})(?:$|[T\s])/);
  if (!m) return null;
  const mo = Number(m[2]);
  const d = Number(m[3]);
  if (mo < 1 || mo > 12) return null;
  if (d < 1 || d > 31) return null;
  return m[1] + "-" + m[2] + "-" + m[3];
}

function asMsg(e: unknown) {
  if (e instanceof Error) return e.message;
  try { return String(e); } catch { return "unknown"; }
}

function looksLikeMissingTable(msg: string) {
  const m = msg.toLowerCase();
  return m.includes("does not exist") || m.includes("no such table") || m.includes("p2021");
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

function dayRange(day: string) {
  const start = new Date(day + "T00:00:00-03:00");
  const end = new Date(day + "T23:59:59.999-03:00");
  return { start, end };
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
  if (t.includes("org")) return "organico";
  if (t.includes("reje")) return "rejeito";
  return "outros";
}

async function computeSummary(day: string) {
  const { start, end } = dayRange(day);
  const tri = getTriagemModel();

  const totals: any = { totalKg: 0, byMaterialKg: {}, count: 0 };
  const meta: any = { computedAt: new Date().toISOString(), source: [] as string[] };

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

  return { day, totals, meta, notes: [], version: "v0" };
}

export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const qDay = searchParams.get("day");
  const qD = searchParams.get("d");
  const qDate = searchParams.get("date");
  const day = safeDay(qDay ?? qD ?? qDate);

  if (!day) {
    return NextResponse.json(
      { ok: false, error: "bad_day", got: { day: qDay, d: qD, date: qDate }, hint: "use ?day=YYYY-MM-DD" },
      { status: 400 }
    );
  }

  try {
    const summary = await computeSummary(day);
    return NextResponse.json({ ok: true, summary });
  } catch (e) {
    const msg = asMsg(e);
    if (looksLikeMissingTable(msg)) {
      return NextResponse.json({ ok: false, error: "db_not_ready", detail: msg }, { status: 503 });
    }
    return NextResponse.json({ ok: false, error: "db_error", detail: msg }, { status: 500 });
  }
}

