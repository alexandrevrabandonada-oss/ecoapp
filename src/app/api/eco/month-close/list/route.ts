import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

function clampInt(x: any, d: number) {
  const n = Number(x);
  if (!Number.isFinite(n) || n <= 0) return d;
  return Math.min(200, Math.floor(n));
}

export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const limit = clampInt(searchParams.get("limit"), 24);
  const pc: any = prisma as any;
  const model = pc?.ecoMonthClose;
  if (!model?.findMany) return NextResponse.json({ ok: false, error: "model_not_ready" }, { status: 503 });
  try {
    const items = await model.findMany({ orderBy: { month: "desc" }, take: limit });
    return NextResponse.json({ ok: true, items });
  } catch (e: any) {
    return NextResponse.json({ ok: false, error: "db_error", detail: String(e?.message || e) }, { status: 500 });
  }
}

