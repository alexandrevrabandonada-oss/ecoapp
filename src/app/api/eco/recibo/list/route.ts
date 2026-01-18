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

function getModel(candidates: string[]) {
  const pc: any = prisma as any;
  for (const k of candidates) {
    const m = pc?.["k"];
    if (m && typeof m.findMany === "function") return { key: k, model: m as any };
  }
  return null;
}

function clampLimit(v: any) {
  const n = Number(v || 30);
  if (!Number.isFinite(n)) return 30;
  return Math.max(1, Math.min(200, Math.floor(n)));
}

export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const limit = clampLimit(searchParams.get("limit"));

  const dayClose = getModel(["ecoDayClose", "dayClose", "ecoDayclose"]);
  const mutirao  = getModel(["ecoMutirao", "mutirao", "ecoMutiroes", "ecoMutirões"]);

  const out: any = { ok: true, limit, sources: {}, dayCloses: [], mutiroes: [] };

  try {
    if (dayClose) {
      out.sources.dayClose = dayClose.key;
      const rows = await dayClose.model.findMany({
        orderBy: { day: "desc" },
        take: limit,
      });
      out.dayCloses = rows || [];
    } else {
      out.sources.dayClose = "missing";
    }

    if (mutirao) {
      out.sources.mutirao = mutirao.key;
      const rows = await mutirao.model.findMany({
        where: { status: "DONE" },
        orderBy: { startAt: "desc" },
        take: limit,
        include: { point: true },
      });
      out.mutiroes = rows || [];
    } else {
      out.sources.mutirao = "missing";
    }

    return NextResponse.json(out);
  } catch (e) {
    const msg = asMsg(e);
    if (looksLikeMissingTable(msg)) {
      return NextResponse.json({ ok: false, error: "db_not_ready", detail: msg }, { status: 503 });
    }
    return NextResponse.json({ ok: false, error: "db_error", detail: msg }, { status: 500 });
  }
}
