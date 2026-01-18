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

export async function GET(req: Request) {
  if (!ecoIsOperator(req)) {
    return NextResponse.json({ ok: false, error: "unauthorized" }, { status: 401 });
  }

  const items = await prisma.pickupRequest.findMany({
    orderBy: { createdAt: "desc" },
    take: 200,
    include: {
      receipt: { select: {  code: true, public: true } },
    },
  });

  return NextResponse.json({ ok: true, items });
}