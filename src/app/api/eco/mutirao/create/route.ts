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
function getMutiraoModel() { const pc: any = prisma as any; return pc?.ecoMutirao; }
function getPointModel() { const pc: any = prisma as any; return pc?.ecoCriticalPoint; }

export async function POST(req: Request) {
  const body = (await req.json().catch(() => null)) as any;
  const pointId = String(body?.pointId || "").trim();
  const startAtRaw = String(body?.startAt || "").trim();
  const durationMin = Math.max(15, Math.min(600, Number(body?.durationMin || 90) || 90));
  const title = body?.title != null ? String(body.title).slice(0, 120) : null;
  const note = body?.note != null ? String(body.note).slice(0, 600) : null;
  const checklist = body?.checklist ?? null;

  if (!pointId) return NextResponse.json({ ok: false, error: "bad_pointId" }, { status: 400 });
  const startAt = new Date(startAtRaw);
  if (!(startAt instanceof Date) || Number.isNaN(startAt.getTime())) {
    return NextResponse.json({ ok: false, error: "bad_startAt" }, { status: 400 });
  }

  const m = getMutiraoModel();
  const p = getPointModel();
  if (!m?.upsert || !p?.update) return NextResponse.json({ ok: false, error: "model_not_ready" }, { status: 503 });

  try {
    const item = await m.upsert({
      where: { pointId },
      update: { startAt, durationMin, title, note, checklist },
      create: { pointId, startAt, durationMin, title, note, checklist },
    });
    await p.update({ where: { id: pointId }, data: { status: "MUTIRAO" } }).catch(() => null);
    return NextResponse.json({ ok: true, item });
  } catch (e) {
    const msg = asMsg(e);
    if (looksLikeMissingTable(msg)) return NextResponse.json({ ok: false, error: "db_not_ready", detail: msg }, { status: 503 });
    return NextResponse.json({ ok: false, error: "db_error", detail: msg }, { status: 500 });
  }
}

