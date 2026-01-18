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
    if (m && typeof m.findMany === "function") return { key: k, model: m as any };
  }
  return null;
}
function normStatus(v: any) {
  const t = String(v || "").trim().toUpperCase();
  if (!t) return "UNKNOWN";
  if (t === "ABERTO") return "OPEN";
  if (t === "RESOLVIDO") return "RESOLVED";
  if (t === "DONE") return "RESOLVED";
  return t;
}
function pickBairro(row: any) {
  return String(row?.bairro || row?.neighborhood || row?.area || row?.regiao || row?.region || "").trim();
}

export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const days = Math.max(1, Math.min(365, Number(searchParams.get("days") || 30) || 30));
  const bairro = String(searchParams.get("bairro") || "").trim();

  const pm = getPointModel();
  if (!pm?.model) return NextResponse.json({ ok: false, error: "model_not_ready" }, { status: 503 });

  const end = new Date();
  const start = new Date(end.getTime() - days * 24 * 60 * 60 * 1000);

  try {
    let rows: any[] = [];
    // Tentativa 1: filtra por createdAt (se existir)
    try {
      rows = await pm.model.findMany({
        where: { createdAt: { gte: start, lte: end } },
        take: 5000,
        orderBy: { createdAt: "desc" },
      });
    } catch {
      // fallback: traz (dev) e filtra no JS se conseguir
      rows = await pm.model.findMany({ take: 5000 }).catch(() => []);
    }

    // filtros JS (bairro + janela por createdAt/updatedAt se existirem)
    const out: any[] = [];
    for (const r of rows) {
      if (bairro) {
        const b = pickBairro(r);
        if (!b || b.toLowerCase() !== bairro.toLowerCase()) continue;
      }
      const ca = (r as any)?.createdAt ? new Date((r as any).createdAt) : null;
      const ua = (r as any)?.updatedAt ? new Date((r as any).updatedAt) : null;
      const inWindow = (ca && ca >= start && ca <= end) || (ua && ua >= start && ua <= end) || (!ca && !ua);
      if (!inWindow) continue;
      out.push(r);
    }

    const byStatus: Record<string, number> = {};
    let open = 0;
    let resolved = 0;
    for (const r of out) {
      const st = normStatus((r as any)?.status);
      byStatus[st] = (byStatus[st] || 0) + 1;
      if (st === "OPEN") open += 1;
      if (st === "RESOLVED") resolved += 1;
    }

    return NextResponse.json({
      ok: true,
      windowDays: days,
      start: start.toISOString(),
      end: end.toISOString(),
      bairro: bairro || null,
      totals: { total: out.length, open, resolved },
      byStatus,
      meta: { pointModel: pm.key, sample: out.slice(0, 1).map((x) => ({ id: (x as any)?.id, status: (x as any)?.status })) },
    });
  } catch (e) {
    const msg = asMsg(e);
    if (looksLikeMissingTable(msg)) return NextResponse.json({ ok: false, error: "db_not_ready", detail: msg }, { status: 503 });
    return NextResponse.json({ ok: false, error: "db_error", detail: msg }, { status: 500 });
  }
}
