import { NextResponse } from "next/server";
import { PrismaClient } from "@prisma/client";

export const runtime = "nodejs";

const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };
const prisma = globalForPrisma.prisma ?? new PrismaClient();
if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = prisma;

const CODE_FIELD = "code";
const PUBLIC_FIELD = "public";
const DATE_FIELD = "createdAt";

export async function GET(req: Request) {
  try {
    const u = new URL(req.url);
    const code = (u.searchParams.get("code") ?? "").trim();
    if (!code) return NextResponse.json({ ok: false, error: "missing_code" }, { status: 400 });

    const where: any = {};
    where[CODE_FIELD] = code;
    if (PUBLIC_FIELD) where[PUBLIC_FIELD] = true;

    const select: any = {};
    select[CODE_FIELD] = true;
    select[DATE_FIELD] = true;
    if (PUBLIC_FIELD) select[PUBLIC_FIELD] = true;

    const r: any = await (prisma as any).receipt.findFirst({ where, select });
    if (!r) return NextResponse.json({ ok: false, error: "not_found" }, { status: 404 });

    // se não existe campo public, este endpoint fica "sempre público".
    const isPublic = PUBLIC_FIELD ? Boolean(r[PUBLIC_FIELD]) : true;
    if (!isPublic) return NextResponse.json({ ok: false, error: "not_public" }, { status: 404 });

    return NextResponse.json({
      ok: true,
      receipt: {
        code: String(r[CODE_FIELD] ?? code),
        date: r[DATE_FIELD] ?? null,
        public: isPublic,
      },
    });
  } catch (e: any) {
    return NextResponse.json({ ok: false, error: "server_error", detail: String(e?.message ?? e) }, { status: 500 });
  }
}