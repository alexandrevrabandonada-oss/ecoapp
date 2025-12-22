import { NextResponse } from "next/server";
import { Prisma, PrismaClient } from "@prisma/client";

export const runtime = "nodejs";

const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };
const prisma = globalForPrisma.prisma ?? new PrismaClient();
if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = prisma;

function lowerCamel(s: string) {
  return s ? s.charAt(0).toLowerCase() + s.slice(1) : s;
}

function pickupMeta() {
  const model = Prisma.dmmf.datamodel.models.find((m) => m.name === "PickupRequest");
  const fieldNames = (model?.fields ?? []).map((f) => f.name);
  return { fieldNames };
}

function pickupInclude() {
  const { fieldNames } = pickupMeta();
  const include: any = {};
  if (fieldNames.includes("receipt")) include.receipt = true;
  if (fieldNames.includes("ecoReceipt")) include.ecoReceipt = true;
  return include;
}

function getPickupDelegateKey() {
  const prismaAny = prisma as unknown as Record<string, any>;
  const modelName = "PickupRequest";
  const tried: string[] = [];

  const keys = [lowerCamel(modelName), modelName, "pickupRequests"];
  for (const key of keys) {
    tried.push(key);
    const d = prismaAny[key];
    if (d && typeof d.findUnique === "function") return { key, tried };
  }

  return { key: null as string | null, tried };
}

type Ctx = { params: { id: string } | Promise<{ id: string }> };

export async function GET(_req: Request, ctx: Ctx) {
  try {
    const { id } = await Promise.resolve(ctx.params);

    const found = getPickupDelegateKey();
    if (!found.key) {
      return NextResponse.json(
        { error: "pickup_delegate_missing", tried: found.tried },
        { status: 500 }
      );
    }

    const prismaAny = prisma as unknown as Record<string, any>;
    const item = await prismaAny[found.key].findUnique({
      where: { id },
      include: pickupInclude(),
    });

    if (!item) return NextResponse.json({ error: "not_found" }, { status: 404 });
    return NextResponse.json({ delegate: found.key, item });
  } catch (e) {
    const detail = e instanceof Error ? e.message : String(e);
    return NextResponse.json({ error: "pickup_get_failed", detail }, { status: 500 });
  }
}

export async function PATCH(req: Request, ctx: Ctx) {
  try {
    const { id } = await Promise.resolve(ctx.params);

    const found = getPickupDelegateKey();
    if (!found.key) {
      return NextResponse.json(
        { error: "pickup_delegate_missing", tried: found.tried },
        { status: 500 }
      );
    }

    const body = (await req.json().catch(() => ({}))) as any;
    const data: any = {};

    if (typeof body?.status === "string" && body.status) data.status = body.status;
    if (typeof body?.name === "string") data.name = body.name;
    if (typeof body?.phone === "string") data.phone = body.phone;
    if (typeof body?.address === "string") data.address = body.address;
    if (typeof body?.notes === "string") data.notes = body.notes;

    const prismaAny = prisma as unknown as Record<string, any>;
    const item = await prismaAny[found.key].update({
      where: { id },
      data,
      include: pickupInclude(),
    });

    return NextResponse.json({ delegate: found.key, item });
  } catch (e) {
    const detail = e instanceof Error ? e.message : String(e);
    return NextResponse.json({ error: "pickup_patch_failed", detail }, { status: 500 });
  }
}