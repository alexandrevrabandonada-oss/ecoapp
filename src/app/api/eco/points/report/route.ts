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
    if (m && typeof m.create === "function" && typeof m.findMany === "function") return { key: k, model: m as any };
  }
  return null;
}
function safeStr(v: any, maxLen: number) {
  const s = String(v || "").trim();
  if (!s) return "";
  return s.length > maxLen ? s.slice(0, maxLen) : s;
}
function safeNum(v: any) {
  const n = Number(v);
  if (!Number.isFinite(n)) return null;
  return n;
}
function clamp(n: number, a: number, b: number) { return Math.max(a, Math.min(b, n)); }
function toRad(x: number) { return (x * Math.PI) / 180; }
function haversineMeters(aLat: number, aLng: number, bLat: number, bLng: number) {
  const R = 6371000;
  const dLat = toRad(bLat - aLat);
  const dLng = toRad(bLng - aLng);
  const s1 = Math.sin(dLat / 2);
  const s2 = Math.sin(dLng / 2);
  const aa = s1 * s1 + Math.cos(toRad(aLat)) * Math.cos(toRad(bLat)) * s2 * s2;
  const c = 2 * Math.atan2(Math.sqrt(aa), Math.sqrt(1 - aa));
  return R * c;
}

export async function POST(req: Request) {
  const body = (await req.json().catch(() => null)) as any;
  const category = safeStr(body?.category || body?.kind || body?.type || "", 60);
  const bairro = safeStr(body?.bairro || body?.neighborhood || "", 80);
  const description = safeStr(body?.description || body?.note || body?.details || "", 500);
  const title = safeStr(body?.title || body?.name || "", 120);
  const evidenceUrl = safeStr(body?.evidenceUrl || body?.photoUrl || "", 400);

  const lat0 = safeNum(body?.lat ?? body?.latitude);
  const lng0 = safeNum(body?.lng ?? body?.lon ?? body?.longitude);
  const radiusM = clamp(Number(body?.radiusM || 80) || 80, 20, 300);
  const windowHours = clamp(Number(body?.windowHours || 24) || 24, 1, 168);

  if (!category) return NextResponse.json({ ok: false, error: "bad_category" }, { status: 400 });
  if (lat0 == null || lng0 == null) return NextResponse.json({ ok: false, error: "bad_geo", hint: "Envie lat/lng." }, { status: 400 });
  if (lat0 < -90 || lat0 > 90 || lng0 < -180 || lng0 > 180) return NextResponse.json({ ok: false, error: "bad_geo_range" }, { status: 400 });
  if (!description && !title) return NextResponse.json({ ok: false, error: "missing_text", hint: "Envie description ou title." }, { status: 400 });

  const pm = getPointModel();
  if (!pm?.model) return NextResponse.json({ ok: false, error: "model_not_ready" }, { status: 503 });

  const now = new Date();
  const start = new Date(now.getTime() - windowHours * 60 * 60 * 1000);

  const dLat = radiusM / 111320;
  const dLng = radiusM / (111320 * Math.max(0.2, Math.cos(toRad(lat0))));
  const minLat = lat0 - dLat;
  const maxLat = lat0 + dLat;
  const minLng = lng0 - dLng;
  const maxLng = lng0 + dLng;

  try {
    let candidates: any[] = [];
    try {
      candidates = await pm.model.findMany({
        where: {
          AND: [
            { createdAt: { gte: start, lte: now } },
            { lat: { gte: minLat, lte: maxLat } },
            { lng: { gte: minLng, lte: maxLng } },
          ],
        },
        take: 200,
        orderBy: { createdAt: "desc" },
      });
    } catch {
      candidates = await pm.model.findMany({ take: 500 }).catch(() => []);
    }

    let best: any = null;
    let bestDist = 1e18;
    for (const r of candidates) {
      const lat = Number((r as any)?.lat ?? (r as any)?.latitude);
      const lng = Number((r as any)?.lng ?? (r as any)?.lon ?? (r as any)?.longitude);
      if (!Number.isFinite(lat) || !Number.isFinite(lng)) continue;
      const ca = (r as any)?.createdAt ? new Date((r as any).createdAt) : null;
      if (ca && (ca < start || ca > now)) continue;
      const dist = haversineMeters(lat0, lng0, lat, lng);
      if (dist <= radiusM && dist < bestDist) { best = r; bestDist = dist; }
    }

    if (best) {
      try {
        await fetch(new URL("/api/eco/points/confirm", req.url).toString(), {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ id: String((best as any).id || "") }),
        });
      } catch { void 0; }
      return NextResponse.json({ ok: true, deduped: true, radiusM, windowHours, item: best, meta: { pointModel: pm.key, distanceM: Math.round(bestDist) } });
    }

    const baseData: any = {
      status: "OPEN",
      category,
      bairro: bairro || undefined,
      title: title || undefined,
      description: description || undefined,
      evidenceUrl: evidenceUrl || undefined,
      lat: lat0,
      lng: lng0,
    };

    try {
      const item = await pm.model.create({ data: baseData });
      return NextResponse.json({ ok: true, deduped: false, item, meta: { pointModel: pm.key, mode: "baseData" } });
    } catch (_e) {
      void _e;
      try {
        const data2: any = { status: "OPEN", category, bairro: bairro || undefined, description: description || undefined, lat: lat0, lng: lng0 };
        const item = await pm.model.create({ data: data2 });
        return NextResponse.json({ ok: true, deduped: false, item, meta: { pointModel: pm.key, mode: "fallback2" } });
      } catch (_e) {
        void _e;
        const data3: any = { status: "OPEN", category, lat: lat0, lng: lng0 };
        const item = await pm.model.create({ data: data3 });
        return NextResponse.json({ ok: true, deduped: false, item, meta: { pointModel: pm.key, mode: "fallback3" } });
      }
    }
  } catch (_e) {
    void _e;
    const msg = asMsg(_e);
    if (looksLikeMissingTable(msg)) return NextResponse.json({ ok: false, error: "db_not_ready", detail: msg }, { status: 503 });
    return NextResponse.json({ ok: false, error: "db_error", detail: msg }, { status: 500 });
  }
}
