import { NextResponse } from "next/server";
import { Prisma, PrismaClient } from "@prisma/client";

export const runtime = "nodejs";

const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };
const prisma = globalForPrisma.prisma ?? new PrismaClient();
if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = prisma;

function lowerCamel(s: string) {
  return s ? s.charAt(0).toLowerCase() + s.slice(1) : s;
}

function getReceiptDelegateKey() {
  const prismaAny = prisma as unknown as Record<string, any>;
  const modelNames = Prisma.dmmf.datamodel.models.map((m) => m.name);

  const receiptModels = modelNames.filter((n) => /(receipt|recibo)/i.test(n));
  const preferred = ["EcoReceipt", ...receiptModels];

  const tried: string[] = [];
  for (const modelName of preferred) {
    const keys = [lowerCamel(modelName), modelName];
    for (const key of keys) {
      tried.push(key);
      const d = prismaAny[key];
      if (d && typeof d.findUnique === "function") return { key, modelName, tried, modelNames };
    }
  }

  return { key: null as string | null, modelName: null as string | null, tried, modelNames };
}

type Ctx = { params: { code: string } | Promise<{ code: string }> };

export async function GET(_req: Request, ctx: Ctx) {
  try {
    const { code } = await Promise.resolve(ctx.params);

    const found = getReceiptDelegateKey();
    if (!found.key) {
      return NextResponse.json(
        { error: "receipt_delegate_missing", modelNames: found.modelNames, tried: found.tried },
        { status: 500 }
      );
    }

    const prismaAny = prisma as unknown as Record<string, any>;
    const item = await prismaAny[found.key].findUnique({
      where: { shareCode: code },
      include: { request: true },
    });

    if (!item) return NextResponse.json({ error: "not found" }, { status: 404 });
    return NextResponse.json({ delegate: found.key, model: found.modelName, item });
  } catch (e) {
    const detail = e instanceof Error ? e.message : String(e);
    return NextResponse.json({ error: "receipt_get_failed", detail }, { status: 500 });
  }
}