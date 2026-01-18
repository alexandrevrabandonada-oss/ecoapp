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
function getMutiraoModel() {
  const pc: any = prisma as any;
  const candidates = ["ecoMutirao", "mutirao", "ecoMutiroes", "mutiroes"];
  for (const k of candidates) {
    const m = pc?.["k"];
    if (m && typeof m.update === "function") return { key: k, model: m as any };
  }
  return null;
}
function cleanUrl(v: any) {
  const s = String(v || "").trim();
  if (!s) return null;
  return s.slice(0, 500);
}

export async function POST(req: Request) {
  const body = (await req.json().catch(() => null)) as any;
  const id = String(body?.id || "").trim();
  if (!id) return NextResponse.json({ ok: false, error: "bad_id" }, { status: 400 });

  const m = getMutiraoModel();
  if (!m?.model) return NextResponse.json({ ok: false, error: "model_not_ready" }, { status: 503 });

  const beforeUrl = cleanUrl(body?.beforeUrl);
  const afterUrl = cleanUrl(body?.afterUrl);
  const checklist = body?.checklist && typeof body.checklist === "object" ? body.checklist : null;

  try {
    const data: any = {};
    if (beforeUrl) data.beforeUrl = beforeUrl;
    if (afterUrl) data.afterUrl = afterUrl;
    if (checklist) data.checklist = checklist;

    const item = await m.model.update({ where: { id }, data, include: { point: true } });
    return NextResponse.json({ ok: true, item, meta: { mutiraoModel: m.key } });
  } catch (e) {
    const msg = asMsg(e);
    if (looksLikeMissingTable(msg)) {
      return NextResponse.json({ ok: false, error: "db_not_ready", detail: msg }, { status: 503 });
    }
    return NextResponse.json({ ok: false, error: "db_error", detail: msg }, { status: 500 });
  }
}
