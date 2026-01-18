import { NextResponse } from "next/server";
import { PrismaClient } from "@prisma/client";

export const runtime = "nodejs";

const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };
const prisma = globalForPrisma.prisma ?? new PrismaClient();
if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = prisma;

function ecoGetToken(req: Request): string | null {
  const h = req.headers.get("x-eco-token") ?? req.headers.get("authorization") ?? "";
  if (!h) return null;
  if (h.startsWith("Bearer ")) return h.slice(7).trim();
  if (h && !h.includes(" ")) return h.trim();
  return null;
}

function ecoIsOperator(req: Request): boolean {
  const token = ecoGetToken(req);
  const expected = process.env["ECO_OPERATOR_TOKEN"] ?? "";
  if (!expected) return true;
  if (!token) return false;
  return token === expected;
}

type BulkBody = {
  ids: string[];
  status?: "NEW" | "IN_ROUTE" | "DONE" | "CANCELED";
  routeDay?: string | null;
};

export async function PATCH(req: Request) {
  if (!ecoIsOperator(req)) {
    return NextResponse.json({ ok: false, error: "unauthorized" }, { status: 401 });
  }

  const body = (await req.json().catch(() => null)) as BulkBody | null;
  const ids = body?.ids ?? [];
  if (!Array.isArray(ids) || ids.length === 0) {
    return NextResponse.json({ ok: false, error: "ids_required" }, { status: 400 });
  }

  const data: any = {};
  if (body?.status) data.status = body.status;
  if (body && ("routeDay" in body)) data.routeDay = (body as any).routeDay;

  if (body?.status === "DONE") {
    data.collectedAt = new Date();
  }

  const r = await prisma.pickupRequest.updateMany({
    where: { id: { in: ids } },
    data,
  });

  return NextResponse.json({ ok: true, updated: r.count });
}