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
function getPointModel() { const pc: any = prisma as any; return pc?.ecoCriticalPoint; }

function num(x: any): number | null {
  const n = Number(x);
  if (!Number.isFinite(n)) return null;
  return n;
}
function validLatLng(lat: number, lng: number) {
  if (lat < -90 || lat > 90) return false;
  if (lng < -180 || lng > 180) return false;
  return true;
}
function haversineMeters(aLat: number, aLng: number, bLat: number, bLng: number) {
  const R = 6371000;
  const toRad = (d: number) => (d * Math.PI) / 180;
  const dLat = toRad(bLat - aLat);
  const dLng = toRad(bLng - aLng);
  const s1 = Math.sin(dLat / 2);
  const s2 = Math.sin(dLng / 2);
  const aa = s1 * s1 + Math.cos(toRad(aLat)) * Math.cos(toRad(bLat)) * s2 * s2;
  const c = 2 * Math.atan2(Math.sqrt(aa), Math.sqrt(1 - aa));
  return R * c;
}

export async function POST(req: Request) {
  const model = getPointModel();
  if (!model?.create) return NextResponse.json({ ok: false, error: "model_not_ready" }, { status: 503 });
  const body = (await req.json().catch(() => null)) as any;

  const kind = String(body?.kind || "OUTRO").trim();
  const lat0 = num(body?.lat);
  const lng0 = num(body?.lng);
  const note = body?.note != null ? String(body.note).slice(0, 500) : null;
  const photoUrl = body?.photoUrl != null ? String(body.photoUrl).slice(0, 800) : null;
  const actor = body?.actor != null ? String(body.actor).slice(0, 80) : null;
  const radiusM = Math.max(30, Math.min(500, Number(body?.radiusM || 120) || 120));
  const windowH = Math.max(1, Math.min(168, Number(body?.windowH || 72) || 72));

  if (lat0 == null || lng0 == null) return NextResponse.json({ ok: false, error: "bad_latlng" }, { status: 400 });
  if (!validLatLng(lat0, lng0)) return NextResponse.json({ ok: false, error: "bad_latlng" }, { status: 400 });

  try {
    const since = new Date(Date.now() - windowH * 60 * 60 * 1000);
    const recent = await model.findMany({ where: { createdAt: { gte: since }, status: "OPEN" }, orderBy: { createdAt: "desc" }, take: 200 });
    let dupe: any = null;
    for (const p of recent) {
      const d = haversineMeters(lat0, lng0, Number(p.lat), Number(p.lng));
      if (d <= radiusM) { dupe = p; break; }
    }
    if (dupe) {
      return NextResponse.json({ ok: true, item: dupe, deduped: true, radiusM, windowH });
    }

    const item = await model.create({
      data: { kind, lat: lat0, lng: lng0, note, photoUrl, actor }
    });
    return NextResponse.json({ ok: true, item, deduped: false, radiusM, windowH });
  } catch (e) {
    const msg = asMsg(e);
    if (looksLikeMissingTable(msg)) return NextResponse.json({ ok: false, error: "db_not_ready", detail: msg }, { status: 503 });
    return NextResponse.json({ ok: false, error: "db_error", detail: msg }, { status: 500 });
  }
}

