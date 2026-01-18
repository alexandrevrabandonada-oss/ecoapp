import { NextRequest, NextResponse } from "next/server";
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

function ecoGetToken(req: Request): string | null {
  const h = req.headers.get('x-eco-token') ?? req.headers.get('authorization') ?? '';
  if (h.startsWith('Bearer ')) return h.slice(7).trim();
  if (h && !h.includes(' ')) return h.trim();
  return null;
}

function ecoIsOperator(req: Request): boolean {
  const t = ecoGetToken(req);
  const op = process.env.ECO_OPERATOR_TOKEN ?? process.env.ECO_TOKEN ?? '';
  if (!op) return false;
  return !!t && t === op;
}

export async function PATCH(req: NextRequest, { params }: { params: Promise<{ code: string }> }) {
    const { code: codeParam } = await params;
if (!ecoIsOperator(req)) {
    return NextResponse.json({ error: 'forbidden' }, { status: 403 });
  }

  const code = String(codeParam || "");
  if (!code) return NextResponse.json({ error: 'missing_code' }, { status: 400 });

  let desired: boolean | null = null;
  try {
    const body = await req.json();
    if (typeof body?.public === 'boolean') desired = body.public;
  } catch {
    desired = null;
  }

  const current = await prisma.receipt.findFirst({
    where: { code: code },
    select: { id: true, code: true, public: true },
  });

  if (!current) return NextResponse.json({ error: 'not_found' }, { status: 404 });

  const curVal = Boolean((current as any).public);
  const nextVal = (desired === null) ? !curVal : desired;

  await prisma.receipt.updateMany({
    where: { code: code },
    data: { public: nextVal } as any,
  });

  return NextResponse.json({ code, public: nextVal });
}