import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

function clampInt(x: any, d: number) {
  const n = Number(x);
  if (!Number.isFinite(n) || n <= 0) return d;
  return Math.min(500, Math.floor(n));
}
function parseDate(s: string | null): Date | null {
  const t = String(s || "").trim();
  if (!t) return null;
  const d = new Date(t);
  if (Number.isNaN(d.getTime())) return null;
  return d;
}
function getMutiraoModel() { const pc: any = prisma as any; return pc?.ecoMutirao; }

export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const limit = clampInt(searchParams.get("limit"), 80);
  const from = parseDate(searchParams.get("from"));
  const to = parseDate(searchParams.get("to"));
  const status = searchParams.get("status");

  const m = getMutiraoModel();
  if (!m?.findMany) return NextResponse.json({ ok: false, error: "model_not_ready" }, { status: 503 });

  const now = Date.now();
  const defaultFrom = new Date(now - 30 * 24 * 60 * 60 * 1000);
  const defaultTo = new Date(now + 365 * 24 * 60 * 60 * 1000);
  const start = from || defaultFrom;
  const end = to || defaultTo;

  try {
    const where: any = { startAt: { gte: start, lte: end } };
    if (status) where.status = String(status);
    const items = await m.findMany({
      where,
      orderBy: { startAt: "asc" },
      take: limit,
      include: { point: true },
    });
    return NextResponse.json({ ok: true, items, range: { from: start.toISOString(), to: end.toISOString() } });
  } catch (e: any) {
    return NextResponse.json({ ok: false, error: "db_error", detail: String(e?.message || e) }, { status: 500 });
  }
}

