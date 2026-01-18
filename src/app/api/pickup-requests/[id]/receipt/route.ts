import { NextRequest, NextResponse } from "next/server";
import { PrismaClient } from "@prisma/client";
import crypto from "node:crypto";

export const runtime = "nodejs";

const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };
const prisma = globalForPrisma.prisma ?? new PrismaClient();
if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = prisma;

function ecoGetToken(req: Request): string | null {
  const h = req.headers.get("x-eco-token") ?? req.headers.get("authorization") ?? "";
  if (h.startsWith("Bearer ")) return h.slice(7).trim();
  if (h && !h.includes(" ")) return h.trim();
  return null;
}

function ecoIsOperator(req: Request): boolean {
  const t = ecoGetToken(req);
  if (!t) return false;
  const allow = (process.env.ECO_OPERATOR_TOKEN ?? process.env.ECO_TOKEN ?? "").trim();
  if (!allow) return false;
  return t === allow;
}

function ecoGenCode(): string {
  const raw = crypto.randomBytes(9).toString("base64url").replace(/[^a-zA-Z0-9]/g, "");
  return raw.slice(0, 10);
}

export async function POST(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
const { id: idParam } = await params;
const id = String(idParam ?? "");
try {
    if (!id) return NextResponse.json({ ok: false, error: "missing_id" }, { status: 400 });

    if (!ecoIsOperator(req)) {
      return NextResponse.json({ ok: false, error: "unauthorized" }, { status: 401 });
    }

    const existing = await prisma.pickupRequest.findUnique({
      where: { id },
      select: {
        id: true,
        receipt: { select: {
        code: true,
        public: true,
        } },
      },
    });

    if (!existing) return NextResponse.json({ ok: false, error: "not_found" }, { status: 404 });
    if (existing.receipt) {
      return NextResponse.json({ ok: true, receipt: existing.receipt }, { status: 200 });
    }

    const updated = await prisma.pickupRequest.update({
      where: { id },
      data: {
        receipt: {
          create: {
    code: ecoGenCode(),
    public: false,
          },
        },
      },
      select: {
        id: true,
        receipt: { select: {
        code: true,
        public: true,
        } },
      },
    });

    return NextResponse.json({ ok: true, receipt: updated.receipt }, { status: 200 });
  } catch (e: any) {
    console.error("issue receipt error", e);
    return NextResponse.json({ ok: false, error: "server_error" }, { status: 500 });
  }
}