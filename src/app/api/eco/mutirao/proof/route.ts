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
  const candidates = ["ecoMutirao", "mutirao", "ecoCleanup", "cleanup", "ecoMutiraoEvent", "mutiraoEvent"];
  for (const k of candidates) {
    const m = pc?.["k"];
    if (m && typeof m.findUnique === "function" && typeof m.update === "function") return { key: k, model: m as any };
  }
  return null;
}
function safeStr(v: any, max = 500) {
  const s = String(v || "").trim();
  if (!s) return "";
  return s.length > max ? (s.slice(0, max - 3) + "...") : s;
}

export async function POST(req: Request) {
  const body = (await req.json().catch(() => null)) as any;
  const id = safeStr(body?.id, 120);
  const afterUrl = safeStr(body?.afterUrl, 2000);
  const proofNote = safeStr(body?.proofNote, 800);
  if (!id) return NextResponse.json({ ok: false, error: "bad_id" }, { status: 400 });

  const mm = getMutiraoModel();
  if (!mm?.model) return NextResponse.json({ ok: false, error: "model_not_ready" }, { status: 503 });

  try {
    const item = await mm.model.findUnique({ where: { id } });
    if (!item) return NextResponse.json({ ok: false, error: "not_found" }, { status: 404 });

    const prevMeta = (item?.meta && typeof item.meta === "object") ? item.meta : {};
    const meta = {
      ...(prevMeta as any),
      afterUrl: afterUrl || (prevMeta as any)?.afterUrl || "",
      proofNote: proofNote || (prevMeta as any)?.proofNote || "",
      proofAt: new Date().toISOString(),
      proofKind: afterUrl ? "photo" : ((proofNote && proofNote.length) ? "note" : "none"),
    };

    // Tentativa 1: salvar no meta
    try {
      const updated = await mm.model.update({ where: { id }, data: { meta } });
      return NextResponse.json({ ok: true, item: updated, stored: "meta", model: mm.key });
    } catch (e1) {
      const msg1 = asMsg(e1);
      // Tentativa 2: caso o schema não tenha meta, não vamos quebrar a tela
      return NextResponse.json({ ok: false, error: "cannot_store_proof", detail: msg1, model: mm.key }, { status: 500 });
    }
  } catch (e) {
    const msg = asMsg(e);
    if (looksLikeMissingTable(msg)) return NextResponse.json({ ok: false, error: "db_not_ready", detail: msg }, { status: 503 });
    return NextResponse.json({ ok: false, error: "db_error", detail: msg }, { status: 500 });
  }
}
