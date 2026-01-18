// ECO — points/react — v0.1 (reacoes viram acoes; schema-agnostic)

import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

type Action = "confirm" | "support" | "call" | "gratitude" | "replicate";

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
    "ecoCriticalPoints",
    "ecoPoints",
  ];
  for (const k of candidates) {
    const m = pc?.["k"];
    if (m && typeof m.update === "function") return { key: k, model: m as any };
  }
  return null;
}
function safeAction(v: any): Action | null {
  const s = String(v || "").trim().toLowerCase();
  if (s === "confirm") return "confirm";
  if (s === "support") return "support";
  if (s === "call") return "call";
  if (s === "gratitude") return "gratitude";
  if (s === "replicate") return "replicate";
  return null;
}
function bump(obj: any, k: string, inc: number) {
  if (!obj || typeof obj !== "object") return;
  const cur = Number(obj[k] || 0) || 0;
  obj[k] = cur + inc;
}
function pickMeta(row: any) {
  const cands = ["meta", "data", "extra", "payload", "details"];
  for (const k of cands) {
    const v = row?.[k];
    if (v && typeof v === "object") return { key: k, val: v as any };
  }
  return { key: "meta", val: {} as any };
}
async function tryUpdateMeta(model: any, id: string, key: string, merged: any) {
  // tenta atualizar no primeiro campo que o schema aceitar
  const fields = [key, "meta", "data", "extra", "payload", "details"];
  for (const f of fields) {
    try {
      const data: any = {};
      data[f] = merged;
      const row = await model.update({ where: { id }, data });
      return { ok: true, row, field: f };
    } catch {
      // continua tentando
    }
  }
  return { ok: false, field: "", row: null };
}

export async function POST(req: Request) {
  const body = (await req.json().catch(() => null)) as any;
  const id = String(body?.id || "").trim();
  const action = safeAction(body?.action);
  const inc = Number(body?.inc || 1) || 1;
  if (!id) return NextResponse.json({ ok: false, error: "missing_id" }, { status: 400 });
  if (!action) return NextResponse.json({ ok: false, error: "bad_action" }, { status: 400 });

  const mm = getPointModel();
  if (!mm?.model) return NextResponse.json({ ok: false, error: "model_not_ready" }, { status: 503 });

  try {
    // pega o registro atual (best-effort)
    let row: any = null;
    try {
      if (typeof mm.model.findUnique === "function") row = await mm.model.findUnique({ where: { id } });
    } catch { row = null; }
    if (!row && typeof mm.model.findFirst === "function") {
      row = await mm.model.findFirst({ where: { id } });
    }
    if (!row) return NextResponse.json({ ok: false, error: "not_found" }, { status: 404 });

    const pm = pickMeta(row);
    const merged = { ...(pm.val || {}) };
    const rx = (merged.reactions && typeof merged.reactions === "object") ? merged.reactions : {};
    const nextRx: any = { ...rx };
    bump(nextRx, action, inc);
    merged.reactions = nextRx;
    merged.lastActionAt = new Date().toISOString();

    const up = await tryUpdateMeta(mm.model, id, pm.key, merged);
    if (!up.ok) return NextResponse.json({ ok: false, error: "update_failed" }, { status: 500 });

    return NextResponse.json({ ok: true, id, action, reactions: nextRx, field: up.field, model: mm.key });
  } catch (e) {
    const msg = asMsg(e);
    if (looksLikeMissingTable(msg)) return NextResponse.json({ ok: false, error: "db_not_ready", detail: msg }, { status: 503 });
    return NextResponse.json({ ok: false, error: "db_error", detail: msg }, { status: 500 });
  }
}
