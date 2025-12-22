import { NextResponse } from "next/server";
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

export async function GET(req: Request) {
  const url = new URL(req.url);
  const all = url.searchParams.get("all") === "1";

  const points = await prisma.point.findMany({
    where: all ? {} : { isActive: true },
    include: { service: true },
    orderBy: { createdAt: "desc" },
  });

  return NextResponse.json({ points });
}

export async function POST(req: Request) {
  const body: any = await req.json().catch(() => ({}));

  const point = await prisma.point.create({
    data: {
      serviceId: body.serviceId,
      title: body.title ?? body.name ?? "Ponto",
      name: body.name ?? body.title ?? "Ponto",
      materialKind: body.materialKind ?? "OUTRO",
      address: body.address ?? null,
      neighborhood: body.neighborhood ?? null,
      hours: body.hours ?? null,
      contact: body.contact ?? null,
      isActive: body.isActive ?? true,
    },
    include: { service: true },
  });

  return NextResponse.json({ point }, { status: 201 });
}