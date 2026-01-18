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
function getPointModel() { const pc: any = prisma as any; return pc?.ecoCriticalPoint; }
function getConfirmModel() { const pc: any = prisma as any; return pc?.ecoCriticalPointConfirm; }

export async function POST(req: Request) {
  const body = (await req.json().catch(() => null)) as any;
  const pointId = String(body?.pointId || "").trim();
  const actor = String(body?.actor || "anon").trim().slice(0, 80);
  if (!pointId) return NextResponse.json({ ok: false, error: "bad_pointId" }, { status: 400 });

  const model = getPointModel();
  const cm = getConfirmModel();
  if (!model?.update || !cm?.create) return NextResponse.json({ ok: false, error: "model_not_ready" }, { status: 503 });

  try {
    const created = await cm.create({ data: { pointId, actor } }).then(() => true).catch(() => false);
    if (created) {
      const item = await model.update({ where: { id: pointId }, data: { confirmCount: { increment: 1 } } });
      return NextResponse.json({ ok: true, item, confirmed: true });
    } else {
      const item = await model.findUnique({ where: { id: pointId } });
      return NextResponse.json({ ok: true, item, confirmed: false });
    }
  } catch (e) {
    const msg = asMsg(e);
    if (looksLikeMissingTable(msg)) return NextResponse.json({ ok: false, error: "db_not_ready", detail: msg }, { status: 503 });
    return NextResponse.json({ ok: false, error: "db_error", detail: msg }, { status: 500 });
  }
}

