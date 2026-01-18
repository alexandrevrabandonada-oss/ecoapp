import { NextRequest, NextResponse } from "next/server";
import { PrismaClient } from '@prisma/client';

export const runtime = 'nodejs';

const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };
const prisma = globalForPrisma.prisma ?? new PrismaClient();
if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma;

function eco29GetToken(req: Request): string | null {
  const h = req.headers.get('x-eco-token') ?? req.headers.get('authorization') ?? '';
  if (h.startsWith('Bearer ')) return h.slice(7).trim();
  if (h && !h.includes(' ')) return h.trim();
  return null;
}

function eco29AllowedTokens(): string[] {
  const raw = (process.env.ECO_OPERATOR_TOKENS ?? process.env.ECO_OPERATOR_TOKEN ?? process.env.ECO_TOKEN ?? '').trim();
  if (!raw) return [];
  return raw.split(',').map(s => s.trim()).filter(Boolean);
}

function eco29IsOperator(req: Request): boolean {
  const tok = eco29GetToken(req);
  if (!tok) return false;
  const allowed = eco29AllowedTokens();
  if (allowed.length === 0) return true; // dev fallback
  return allowed.includes(tok);
}

export async function PATCH(req: NextRequest, { params }: { params: Promise<{ _id: string }> }) {
    const { _id: _id } = await params;
try {
    if (!eco29IsOperator(req)) {
      return NextResponse.json({ ok: false, error: 'forbidden' }, { status: 403 });
    }
    const { _id: idParam } = await params;
const _id = String(idParam ?? "").trim();
    if (!_id) return NextResponse.json({ ok: false, error: 'missing id' }, { status: 400 });

    const body = await req.json().catch(() => ({} as any));
    const data: any = {};

    if (typeof body.status === 'string') data['status'] = body.status;


    if (Object.keys(data).length === 0) {
      return NextResponse.json({ ok: false, error: 'no changes' }, { status: 400 });
    }

    const updated = await (prisma as any).pickupRequest.update({
      where: { '_id': _id },
      data,
    });

    return NextResponse.json({ ok: true, item: updated });
  } catch (e: any) {
    return NextResponse.json({ ok: false, error: String(e?.message ?? e) }, { status: 500 });
  }
}
