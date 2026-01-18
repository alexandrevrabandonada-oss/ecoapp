// ECO — day-close/list (history) — step 55

import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

function asMsg(e: unknown) {
  if (e instanceof Error) return e.message;
  try { return String(e); } catch { return "unknown"; }
}

function looksLikeMissingTable(msg: string) {
  const m = msg.toLowerCase();
  return m.includes("does not exist") || m.includes("no such table") || m.includes("p2021");
}

function getDayCloseModel() {
  const pc: any = prisma as any;
  return pc?.ecoDayClose;
}

function clamp(n: number, a: number, b: number) {
  return Math.max(a, Math.min(b, n));
}

export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const raw = String(searchParams.get("limit") ?? "30").trim();
  const limit = clamp(Number(raw) || 30, 1, 200);

  const model = getDayCloseModel();
  if (!model?.findMany) {
    return NextResponse.json({ ok: false, error: "model_not_ready" }, { status: 503 });
  }

  try {
    const items = await model.findMany({
      orderBy: { day: "desc" },
      take: limit,
    });
    return NextResponse.json({ ok: true, items, limit });
  } catch (e) {
    const msg = asMsg(e);
    if (looksLikeMissingTable(msg)) {
      return NextResponse.json({ ok: false, error: "db_not_ready", detail: msg }, { status: 503 });
    }
    return NextResponse.json({ ok: false, error: "db_error", detail: msg }, { status: 500 });
  }
}

