// ECO — points/resolve (manual resolve with proof) — v0.1

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
    if (m && typeof m.update === "function" && typeof m.findUnique === "function") return { key: k, model: m as any };
  }
  return null;
}

// eslint-disable-next-line @typescript-eslint/no-unused-vars
function normStatus(v: any) {
  return String(v || "").trim().toUpperCase();
}

export async function POST(req: Request) {
  const body = (await req.json().catch(() => null)) as any;
  const id = String(body?.id || body?.pointId || "").trim();
  const proofUrl = String(body?.proofUrl || body?.afterUrl || "").trim();
  const proofNote = String(body?.proofNote || body?.note || "").trim();
  const mutiraoId = String(body?.mutiraoId || "").trim();
  if (!id) return NextResponse.json({ ok: false, error: "missing_id" }, { status: 400 });
  if (!proofUrl && !proofNote) return NextResponse.json({ ok: false, error: "missing_proof" }, { status: 400 });

  const mm = getPointModel();
  if (!mm?.model) return NextResponse.json({ ok: false, error: "model_not_ready" }, { status: 503 });

  try {
    const existing = await mm.model.findUnique({ where: { id } });
    if (!existing) return NextResponse.json({ ok: false, error: "not_found" }, { status: 404 });

    const oldMeta = (existing && existing.meta && typeof existing.meta === "object") ? existing.meta : {};
    const newMeta: any = {
      ...oldMeta,
      status: "RESOLVED",
      proofUrl: proofUrl || oldMeta.proofUrl || oldMeta.afterUrl || "",
      proofNote: proofNote || oldMeta.proofNote || "",
      resolvedAt: new Date().toISOString(),
      resolvedBy: "manual",
    };
    if (mutiraoId) newMeta.mutiraoId = mutiraoId;

    const data: any = { meta: newMeta };

    // best-effort: set top-level fields if they exist
    if (Object.prototype.hasOwnProperty.call(existing, "status")) data.status = "RESOLVED";
    if (Object.prototype.hasOwnProperty.call(existing, "state")) data.state = "RESOLVED";

    if (proofUrl) {
      if (Object.prototype.hasOwnProperty.call(existing, "proofUrl")) data.proofUrl = proofUrl;
      if (Object.prototype.hasOwnProperty.call(existing, "afterUrl")) data.afterUrl = proofUrl;
      if (Object.prototype.hasOwnProperty.call(existing, "resolvedProofUrl")) data.resolvedProofUrl = proofUrl;
      if (Object.prototype.hasOwnProperty.call(existing, "resolvedAfterUrl")) data.resolvedAfterUrl = proofUrl;
    }
    if (proofNote) {
      if (Object.prototype.hasOwnProperty.call(existing, "proofNote")) data.proofNote = proofNote;
      if (Object.prototype.hasOwnProperty.call(existing, "resolvedNote")) data.resolvedNote = proofNote;
      if (Object.prototype.hasOwnProperty.call(existing, "resolutionNote")) data.resolutionNote = proofNote;
    }

    const item = await mm.model.update({ where: { id }, data });
    return NextResponse.json({ ok: true, item, model: mm.key });
  } catch (e) {
    const msg = asMsg(e);
    if (looksLikeMissingTable(msg)) {
      return NextResponse.json({ ok: false, error: "db_not_ready", detail: msg }, { status: 503 });
    }
    return NextResponse.json({ ok: false, error: "db_error", detail: msg }, { status: 500 });
  }
}
