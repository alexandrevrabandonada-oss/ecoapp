import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

function asMsg(e: unknown) {
  if (e instanceof Error) return e.message;
  try { return String(e); } catch { return "unknown"; }
}

function getPointModel() {
  const pc: any = prisma as any;
  const candidates = [
    "ecoPoint", "point", "ecoCriticalPoint", "criticalPoint", "ecoPonto", "ponto",
    "ecoPointCritical", "ecoPontoCritico", "ecoPointCritico",
  ];
  for (const k of candidates) {
    const m = pc?.["k"];
    if (m && typeof m.findMany === "function") return { key: k, model: m as any };
  }
  return null;
}

function getConfirmModel() {
  const pc: any = prisma as any;
  const candidates = [
    "ecoPointConfirm", "pointConfirm", "ecoPointConfirmation", "pointConfirmation",
    "ecoConfirm", "confirm", "ecoConfirmation", "confirmation",
  ];
  for (const k of candidates) {
    const m = pc?.["k"];
    if (m && (typeof m.groupBy === "function" || typeof m.findMany === "function")) return { key: k, model: m as any };
  }
  return null;
}

function pickId(p: any): string {
  return String(p?.id || p?.pointId || "");
}

function mergeCounts(p: any, confirmCount: number) {
  const prev = (p as any)?.counts && typeof (p as any).counts === "object" ? (p as any).counts : {};
  return { ...p, counts: { ...prev, confirm: confirmCount } };
}

async function tryFindManyPoint(model: any, where: any, orderBy: any) {
  // tenta com where+orderBy e cai pra versoes mais simples se o schema nao aceitar
  try { return await model.findMany({ where, orderBy }); } catch { void 0; }
  try { return await model.findMany({ where }); } catch { void 0; }
  try { return await model.findMany({ orderBy }); } catch { void 0; }
  return await model.findMany({});
}

async function buildConfirmMap(confirmModel: any) {
  const map: Record<string, number> = {};
  if (!confirmModel) return map;

  // 1) tenta groupBy(pointId)
  if (typeof confirmModel.groupBy === "function") {
    try {
      const rows = await confirmModel.groupBy({ by: ["pointId"], _count: { _all: true } });
      for (const r of rows || []) {
        const pid = String((r as any)?.pointId || "");
        const n = Number((r as any)?._count?._all || 0) || 0;
        if (pid) map[pid] = n;
      }
      return map;
    } catch { void 0; }
  }

  // 2) fallback: findMany + conta em JS (pode ser mais pesado, mas é MVP)
  if (typeof confirmModel.findMany === "function") {
    try {
      const rows = await confirmModel.findMany({});
      for (const r of rows || []) {
        const pid = String((r as any)?.pointId || (r as any)?.pontoId || "");
        if (!pid) continue;
        map[pid] = (map[pid] || 0) + 1;
      }
    } catch { void 0; }
  }

  return map;
}

export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const base = String(searchParams.get("base") || "pontos");

  const point = getPointModel();
  if (!point?.model) {
    return NextResponse.json({ ok: false, error: "point_model_not_ready" }, { status: 503 });
  }

  const confirm = getConfirmModel();
  const confirmMap = await buildConfirmMap(confirm?.model);

  // filtro best-effort: chamados/confirmados costumam ser OPEN
  const where: any = {};
  if (base === "chamados" || base === "confirmados") {
    where.status = "OPEN";
  }

  let items: any[] = [];
  try {
    // order best-effort
    items = await tryFindManyPoint(point.model, where, { createdAt: "desc" });
  } catch (e) {
    const msg = asMsg(e);
    return NextResponse.json({ ok: false, error: "db_error", detail: msg, model: point.key }, { status: 500 });
  }

  // anexa counts.confirm
  const out = (items || []).map((p: any) => {
    const id = pickId(p);
    const n = id ? (confirmMap[id] || 0) : 0;
    return mergeCounts(p, n);
  });

  return NextResponse.json({
    ok: true,
    items: out,
    meta: {
      base,
      pointModel: point.key,
      confirmModel: confirm ? confirm.key : null,
      withCounts: true,
    },
  });
}
