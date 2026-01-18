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
function pickStr(r: any, keys: string[]) {
  for (const k of keys) {
    const v = (r as any)?.[k];
    if (typeof v === "string" && v.trim()) return v.trim();
  }
  return "";
}
function pickNum(r: any, keys: string[]) {
  for (const k of keys) {
    const v = (r as any)?.[k];
    const n = Number(v);
    if (!Number.isNaN(n) && Number.isFinite(n)) return n;
  }
  return null;
}
function normalizeRow(r: any) {
  const lat = pickNum(r, ["lat","latitude","geoLat","locationLat"]);
  const lng = pickNum(r, ["lng","lon","longitude","geoLng","locationLng"]);
  const id = String((r as any)?.id || "");
  const status = normStatus((r as any)?.status);
  const category = pickStr(r, ["category","kind","type","categoria"]);
  const bairro = pickStr(r, ["bairro","neighborhood","area","regiao","region"]);
  const title = pickStr(r, ["title","name","titulo"]);
  const description = pickStr(r, ["description","desc","details","detalhes","note","notes","obs","observacao"]);
  const evidenceUrl = pickStr(r, ["evidenceUrl","photoUrl","imageUrl","url","beforeUrl","afterUrl"]);
  const createdAt = (r as any)?.createdAt ? new Date((r as any).createdAt).toISOString() : null;
  const updatedAt = (r as any)?.updatedAt ? new Date((r as any).updatedAt).toISOString() : null;
  const confirmations = pickNum(r, ["confirmations","confirmCount","votes","upvotes","confirmationsCount"]);
  return { id, status, category, bairro, title, description, evidenceUrl, lat, lng, createdAt, updatedAt, confirmations: confirmations ?? 0 };
}

export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const status = String(searchParams.get("status") || "ALL").trim().toUpperCase();
  const days = Math.max(1, Math.min(365, Number(searchParams.get("days") || 30) || 30));
  const q = String(searchParams.get("q") || "").trim().toLowerCase();
  const bairro = String(searchParams.get("bairro") || "").trim();
  const category = String(searchParams.get("category") || "").trim();

  const bbox = String(searchParams.get("bbox") || "").trim();
  let bb: any = null;
  if (bbox) {
    const parts = bbox.split(",").map((x) => Number(x.trim()));
    if (parts.length === 4 && parts.every((n) => Number.isFinite(n))) {
      bb = { minLat: parts[0], minLng: parts[1], maxLat: parts[2], maxLng: parts[3] };
    }
  }

  const pm = getPointModel();
  if (!pm?.model) return NextResponse.json({ ok: false, error: "model_not_ready" }, { status: 503 });

  const end = new Date();
  const start = new Date(end.getTime() - days * 24 * 60 * 60 * 1000);

  try {
    let rows: any[] = [];
    try {
      const where: any = {};
      where.AND = [];
      where.AND.push({ createdAt: { gte: start, lte: end } });
      if (status !== "ALL") where.AND.push({ status });
      if (bairro) where.AND.push({ bairro });
      if (category) where.AND.push({ category });
      if (bb) {
        where.AND.push({ lat: { gte: bb.minLat, lte: bb.maxLat } });
        where.AND.push({ lng: { gte: bb.minLng, lte: bb.maxLng } });
      }
      rows = await pm.model.findMany({ where, take: 5000, orderBy: { createdAt: "desc" } });
    } catch {
      rows = await pm.model.findMany({ take: 5000 }).catch(() => []);
    }

    const out: any[] = [];
    for (const r of rows) {
      const st = normStatus((r as any)?.status);
      const ca = (r as any)?.createdAt ? new Date((r as any).createdAt) : null;
      const ua = (r as any)?.updatedAt ? new Date((r as any).updatedAt) : null;
      const inWindow = (ca && ca >= start && ca <= end) || (ua && ua >= start && ua <= end) || (!ca && !ua);
      if (!inWindow) continue;
      if (status !== "ALL" && st !== status) continue;

      const b = pickStr(r, ["bairro","neighborhood","area","regiao","region"]);
      if (bairro && (!b || b.toLowerCase() !== bairro.toLowerCase())) continue;

      const c = pickStr(r, ["category","kind","type","categoria"]);
      if (category && (!c || c.toLowerCase() !== category.toLowerCase())) continue;

      const item = normalizeRow(r);
      if (bb && item.lat != null && item.lng != null) {
        if (item.lat < bb.minLat || item.lat > bb.maxLat || item.lng < bb.minLng || item.lng > bb.maxLng) continue;
      }

      if (q) {
        const hay = (item.category + " " + item.bairro + " " + item.title + " " + item.description).toLowerCase();
        if (!hay.includes(q)) continue;
      }

      out.push(item);
    }

    out.sort((a: any, b: any) => {
      const sa = String(a.status || "");
      const sb = String(b.status || "");
      if (sa === sb) {
        const ta = a.updatedAt || a.createdAt || "";
        const tb = b.updatedAt || b.createdAt || "";
        return tb.localeCompare(ta);
      }
      if (sa === "OPEN") return -1;
      if (sb === "OPEN") return 1;
      return sa.localeCompare(sb);
    });

    return NextResponse.json({ ok: true, items: out, meta: { pointModel: pm.key, days } });
  } catch (e) {
    const msg = asMsg(e);
    if (looksLikeMissingTable(msg)) return NextResponse.json({ ok: false, error: "db_not_ready", detail: msg }, { status: 503 });
    return NextResponse.json({ ok: false, error: "db_error", detail: msg }, { status: 500 });
  }
}
