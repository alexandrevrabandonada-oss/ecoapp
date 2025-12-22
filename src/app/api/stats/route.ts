import { NextResponse } from "next/server";
import { PrismaClient } from "@prisma/client";
const prisma = new PrismaClient();

export async function GET() {
  const weighings = await prisma.weighing.findMany();
  const totalKg = weighings.reduce((a, w) => a + w.weightKg, 0);

  const byMaterial: Record<string, number> = {};
  for (const w of weighings) byMaterial[w.material] = (byMaterial[w.material] || 0) + w.weightKg;

  return NextResponse.json({ ok: true, totalKg, byMaterial });
}
