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
function safeStr(v: any, maxLen: number) {
  const s = String(v || "").trim();
  if (!s) return "";
  return s.length > maxLen ? s.slice(0, maxLen) : s;
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
function getPointModel() {
  const pc: any = prisma as any;
  const candidates = ["ecoPoint", "ecoCriticalPoint", "criticalPoint", "ecoPonto", "ponto", "ecoPontoCritico"];
  for (const k of candidates) {
    const m = pc?.["k"];
    if (m && typeof m.findUnique === "function" && typeof m.update === "function") return { key: k, model: m as any };
  }
  return null;
}
async function tryUpdate(model: any, id: string, data: any) {
  try {
    const item = await model.update({ where: { id }, data });
    return { ok: true, item, mode: Object.keys(data).join(",") };
  } catch {
    return { ok: false, item: null, mode: "" };
  }
}
function findLinkedPointId(mut: any): string {
  const keys = ["pointId","criticalPointId","ecoPointId","ecoCriticalPointId","pontoId","pontoCriticoId"];
  for (const k of keys) {
    const v = mut?.[k];
    if (typeof v === "string" && v.trim()) return v.trim();
  }
  const meta = mut?.meta;
  if (meta && typeof meta === "object") {
    for (const k of keys) {
      const v = (meta as any)?.[k];
      if (typeof v === "string" && v.trim()) return v.trim();
    }
  }
  return "";
}
async function resolvePoint(pm: any, pointId: string, proofNote: string, proofUrl: string, beforeUrl: string, afterUrl: string, nowIso: string) {
  if (!pm?.model || !pointId) return { ok: false, skipped: true };
  const cur = await pm.model.findUnique({ where: { id: pointId } });
  if (!cur) return { ok: false, notFound: true };

  // try: status + proof fields (if schema has them)
  let r = await tryUpdate(pm.model, pointId, { status: "RESOLVED", proofNote, resolvedAt: nowIso, proofUrl, beforeUrl, afterUrl });
  if (r.ok) return { ok: true, item: r.item, mode: "full:" + r.mode };

  const desc = proofNote ? ("[RESOLVIDO] " + proofNote) : "[RESOLVIDO]";
  r = await tryUpdate(pm.model, pointId, { status: "RESOLVED", description: desc });
  if (r.ok) return { ok: true, item: r.item, mode: "desc" };
  r = await tryUpdate(pm.model, pointId, { status: "RESOLVED", details: desc });
  if (r.ok) return { ok: true, item: r.item, mode: "details" };

  // meta blob
  try {
    const meta0 = (cur as any)?.meta;
    const meta = (meta0 && typeof meta0 === "object") ? meta0 : {};
    (meta as any).resolvedAt = nowIso;
    if (proofNote) (meta as any).proofNote = proofNote;
    if (proofUrl) (meta as any).proofUrl = proofUrl;
    if (beforeUrl) (meta as any).beforeUrl = beforeUrl;
    if (afterUrl) (meta as any).afterUrl = afterUrl;
    const item = await pm.model.update({ where: { id: pointId }, data: { status: "RESOLVED", meta } });
    return { ok: true, item, mode: "meta" };
  } catch { void 0; }

  r = await tryUpdate(pm.model, pointId, { status: "RESOLVED" });
  if (r.ok) return { ok: true, item: r.item, mode: "status_only" };

  return { ok: false, failed: true };
}

export async function POST(req: Request) {
  const body = (await req.json().catch(() => null)) as any;
  const id = String(body?.id || body?.mutiraoId || "").trim();
  if (!id) return NextResponse.json({ ok: false, error: "bad_id" }, { status: 400 });

  const proofNote = safeStr(body?.proofNote || body?.note || body?.obs || "", 800);
  const proofUrl  = safeStr(body?.proofUrl || body?.evidenceUrl || body?.photoUrl || "", 600);
  const beforeUrl = safeStr(body?.beforeUrl || body?.proofBeforeUrl || "", 600);
  const afterUrl  = safeStr(body?.afterUrl  || body?.proofAfterUrl  || "", 600);
  if (proofNote.trim().length < 6) return NextResponse.json({ ok: false, error: "bad_proof", hint: "proofNote >= 6 chars" }, { status: 400 });

  const mm = getMutiraoModel();
  if (!mm?.model) return NextResponse.json({ ok: false, error: "model_not_ready" }, { status: 503 });

  try {
    const cur = await mm.model.findUnique({ where: { id } });
    if (!cur) return NextResponse.json({ ok: false, error: "not_found" }, { status: 404 });

    const nowIso = new Date().toISOString();

    // try multiple shapes (fields may vary by schema)
    let upd = await tryUpdate(mm.model, id, { status: "FINISHED", finishedAt: nowIso, proofNote, proofUrl, beforeUrl, afterUrl });
    if (!upd.ok) upd = await tryUpdate(mm.model, id, { status: "DONE", finishedAt: nowIso, proofNote, proofUrl, beforeUrl, afterUrl });
    if (!upd.ok) upd = await tryUpdate(mm.model, id, { status: "RESOLVED", endedAt: nowIso, proofNote, proofUrl, beforeUrl, afterUrl });

    if (!upd.ok) {
      try {
        const meta0 = (cur as any)?.meta;
        const meta = (meta0 && typeof meta0 === "object") ? meta0 : {};
        (meta as any).finishedAt = nowIso;
        (meta as any).proofNote = proofNote;
        if (proofUrl) (meta as any).proofUrl = proofUrl;
        if (beforeUrl) (meta as any).beforeUrl = beforeUrl;
        if (afterUrl) (meta as any).afterUrl = afterUrl;
        const item = await mm.model.update({ where: { id }, data: { status: "RESOLVED", meta } });
        upd = { ok: true, item, mode: "meta" };
      } catch { void 0; }
    }
    if (!upd.ok) upd = await tryUpdate(mm.model, id, { status: "RESOLVED" });

    const mutiraoItem = upd.ok ? upd.item : cur;
    const pointId = safeStr(body?.pointId || "", 120) || findLinkedPointId(mutiraoItem);

    const pm = getPointModel();
    let pointRes: any = { ok: false, skipped: true };
    if (pointId && pm?.model) {
      pointRes = await resolvePoint(pm, pointId,proofNote, proofUrl, beforeUrl, afterUrl, nowIso);
    }

    return NextResponse.json({
      ok: true,
      mutirao: mutiraoItem,
      point: pointRes?.ok ? pointRes.item : null,
      meta: { mutiraoModel: mm.key, mutiraoMode: upd.mode || "unknown", pointId: null,pointMode: pointRes?.mode || "skip" }
    });
  } catch (e) {
    const msg = asMsg(e);
    if (looksLikeMissingTable(msg)) return NextResponse.json({ ok: false, error: "db_not_ready", detail: msg }, { status: 503 });
    return NextResponse.json({ ok: false, error: "db_error", detail: msg }, { status: 500 });
  }
}
