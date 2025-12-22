import { NextResponse } from "next/server";
import { PrismaClient, ServiceKind } from "@prisma/client";
const prisma = new PrismaClient();

export async function POST(req: Request) {
  const key = req.headers.get("x-admin-key");
  if (!key || key !== process.env.ADMIN_KEY) {
    return NextResponse.json({ ok: false, error: "unauthorized" }, { status: 401 });
  }

  const existing = await prisma.service.findUnique({ where: { slug: "coleta-seletiva" } });
  if (existing) return NextResponse.json({ ok: true, message: "already seeded" });

  const service = await prisma.service.create({
    data: {
      kind: ServiceKind.COLETA,
      name: "Coleta Seletiva Popular",
      slug: "coleta-seletiva",
      points: {
        create: {
          name: "Ponto Piloto",
          slug: "ponto-piloto",
          address: "Defina o endereço do ponto",
          city: "Volta Redonda",
          isActive: true,
        },
      },
    },
    include: { points: true },
  });

  return NextResponse.json({ ok: true, service });
}
