import { NextResponse } from "next/server";
import { PrismaClient } from "@prisma/client";

const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };
const prisma = globalForPrisma.prisma ?? new PrismaClient();
if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = prisma;

export const dynamic = "force-dynamic";

export async function GET(_: Request, ctx: { params: Promise<{ id: string }> | { id: string } }) {
  const p = (ctx.params as any);
  const id = (typeof (p?.then) === "function") ? (await p).id : p.id;

  const point = await prisma.point.findUnique({
    where: { id },
    include: { service: true },
  });

  if (!point) return NextResponse.json({ ok: false, error: "Not found" }, { status: 404 });
  return NextResponse.json({ ok: true, point });
}

export async function PATCH(req: Request, ctx: { params: Promise<{ id: string }> | { id: string } }) {
  const p = (ctx.params as any);
  const id = (typeof (p?.then) === "function") ? (await p).id : p.id;

  const body: any = await req.json().catch(() => ({}));

  const data: any = {};
  if (typeof body.title === "string") { data.title = body.title.trim(); data.name = body.title.trim(); }
  if (typeof body.name === "string" && !data.title) { data.name = body.name.trim(); }
  if (typeof body.materialKind === "string") data.materialKind = body.materialKind;
  if (typeof body.address === "string") data.address = body.address.trim();
  if (typeof body.contact === "string") data.contact = body.contact.trim();
  if (typeof body.isActive === "boolean") data.isActive = body.isActive;
  if (typeof body.serviceId === "string" && body.serviceId) data.serviceId = body.serviceId;

  const updated = await prisma.point.update({
    where: { id },
    data,
    include: { service: true },
  });

  return NextResponse.json({ ok: true, point: updated });
}