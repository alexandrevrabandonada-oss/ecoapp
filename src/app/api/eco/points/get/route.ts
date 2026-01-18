// ECO — points/get (best-effort dynamic model) — v0.1

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
function getPointModel() {
  const pc: any = prisma as any;
  const candidates = [
    "ecoCriticalPoint",
    "criticalPoint",
    "ecoPoint",
    "point",
    "ecoPoints",
    "ecoCriticalPoints",
  ];
  for (const k of candidates) {
    const m = pc?.["k"];
    if (m && typeof m.findUnique === "function") return { key: k, model: m as any };
  }
  return null;
}

export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const id = String(searchParams.get("id") || searchParams.get("pointId") || "").trim();
  if (!id) return NextResponse.json({ ok: false, error: "missing_id" }, { status: 400 });

  const mm = getPointModel();
  if (!mm?.model) return NextResponse.json({ ok: false, error: "model_not_ready" }, { status: 503 });

  try {
    const item = await mm.model.findUnique({ where: { id } });
    if (!item) return NextResponse.json({ ok: false, error: "not_found" }, { status: 404 });
    return NextResponse.json({ ok: true, item, model: mm.key });
  } catch (e) {
    const msg = asMsg(e);
    if (looksLikeMissingTable(msg)) {
      return NextResponse.json({ ok: false, error: "db_not_ready", detail: msg }, { status: 503 });
    }
    return NextResponse.json({ ok: false, error: "db_error", detail: msg }, { status: 500 });
  }
}
