import { NextResponse } from "next/server";
import { PrismaClient, MaterialKind } from "@prisma/client";
import { z } from "zod";
const prisma = new PrismaClient();

const Body = z.object({
  pointSlug: z.string().min(1),
  material: z.nativeEnum(MaterialKind),
  weightKg: z.number().positive(),
  notes: z.string().max(280).optional(),
});

export async function POST(req: Request) {
  const key = req.headers.get("x-admin-key");
  if (!key || key !== process.env.ADMIN_KEY) {
    return NextResponse.json({ ok: false, error: "unauthorized" }, { status: 401 });
  }

  const json = await req.json().catch(() => null);
  const parsed = Body.safeParse(json);
  if (!parsed.success) return NextResponse.json({ ok: false, error: parsed.error.flatten() }, { status: 400 });

  const point = await prisma.point.findUnique({ where: { slug: parsed.data.pointSlug } });
  if (!point) return NextResponse.json({ ok: false, error: "point_not_found" }, { status: 404 });

  const weighing = await prisma.weighing.create({
    data: {
      pointId: point.id,
      material: parsed.data.material,
      weightKg: parsed.data.weightKg,
      notes: parsed.data.notes,
    },
  });

  return NextResponse.json({ ok: true, weighing });
}
