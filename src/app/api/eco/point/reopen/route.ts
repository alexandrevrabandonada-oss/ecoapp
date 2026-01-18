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
  const candidates = ["ecoPoint", "ecoCriticalPoint", "criticalPoint", "ecoPonto", "ponto", "ecoPontoCritico"];
  for (const k of candidates) {
    const m = pc?.["k"];
    if (m && typeof m.update === "function") return { key: k, model: m as any };
  }
  return null;
}

export async function POST(req: Request) {
  const body = (await req.json().catch(() => null)) as any;
  const id = String(body?.id || body?.pointId || "").trim();
  const note = String(body?.note || "").trim();
  const evidenceUrl = String(body?.evidenceUrl || "").trim();

  if (!id) return NextResponse.json({ ok: false, error: "bad_id" }, { status: 400 });

  // anti-reincidência: evidência OU relato bem completo
  if (evidenceUrl.length < 6 && note.length < 20) {
    return NextResponse.json({ ok: false, error: "missing_new_evidence", hint: "Envie evidência (foto/url) OU relato >= 20 chars.", got: { evidenceUrlLen: evidenceUrl.length, noteLen: note.length } }, { status: 400 });
  }

  const pm = getPointModel();
  if (!pm?.model) return NextResponse.json({ ok: false, error: "model_not_ready" }, { status: 503 });

  const stamp = new Date().toISOString();
  const metaObj = { reopenedAt: stamp, reopenNote: note, reopenEvidenceUrl: evidenceUrl };

  try {
    // tentativa 1: gravar em meta (se existir)
    try {
      const item = await pm.model.update({ where: { id }, data: { status: "OPEN", meta: metaObj } });
      return NextResponse.json({ ok: true, item, meta: { pointModel: pm.key, mode: "status+meta" } });
    } catch (e) {
    void e;
      // ignore -> fallback
    }

    // tentativa 2: status + notes/evidence (se existir)
    try {
      const item = await pm.model.update({ where: { id }, data: { status: "OPEN", reopenNote: note, reopenEvidenceUrl: evidenceUrl, reopenedAt: new Date(stamp) } });
      return NextResponse.json({ ok: true, item, meta: { pointModel: pm.key, mode: "status+fields" } });
    } catch (e) {
    void e;
      // ignore -> fallback
    }

    // fallback final: só status
    const item = await pm.model.update({ where: { id }, data: { status: "OPEN" } });
    return NextResponse.json({ ok: true, item, meta: { pointModel: pm.key, mode: "status_only" } });
  } catch (e) {
    const msg = asMsg(e);
    if (looksLikeMissingTable(msg)) return NextResponse.json({ ok: false, error: "db_not_ready", detail: msg }, { status: 503 });
    return NextResponse.json({ ok: false, error: "db_error", detail: msg }, { status: 500 });
  }
}
