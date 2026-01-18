import { NextResponse } from "next/server";
import { Prisma, PrismaClient } from "@prisma/client";

export const runtime = "nodejs";

const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };
const prisma = globalForPrisma.prisma ?? new PrismaClient();
if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = prisma;

type AnyDelegate = {
  findFirst?: (args?: any) => Promise<any>;
  update?: (args?: any) => Promise<any>;
};

function lowerCamel(s: string) {
  return s ? s.charAt(0).toLowerCase() + s.slice(1) : s;
}

function getModelNames() {
  return Prisma.dmmf.datamodel.models.map((m) => m.name);
}

function getModel(name: string) {
  return Prisma.dmmf.datamodel.models.find((m) => m.name === name) ?? null;
}

function getDelegateKeyForModel(modelName: string) {
  const prismaAny = prisma as unknown as Record<string, AnyDelegate>;
  const keys = [lowerCamel(modelName), modelName];
  for (const key of keys) {
    const d = prismaAny[key];
    if (d) return key;
  }
  return null;
}

function findReceiptModel() {
  const modelNames = getModelNames();
  const receiptModels = modelNames.filter((n) => /(receipt|recibo)/i.test(n));
  const preferred = Array.from(new Set(["Receipt", "EcoReceipt", ...receiptModels]));
  const tried: string[] = [];

  for (const modelName of preferred) {
    const key = getDelegateKeyForModel(modelName);
    tried.push(modelName + " -> " + (key ?? "null"));
    if (!key) continue;

    const prismaAny = prisma as unknown as Record<string, AnyDelegate>;
    const d = prismaAny[key];
    if (d && typeof d.findFirst === "function") {
      const model = getModel(modelName);
      const fields = model?.fields ?? [];
      return { key, modelName, fields, fieldNames: fields.map((f) => f.name), tried, modelNames };
    }
  }

  return { key: null as string | null, modelName: null as string | null, fields: [], fieldNames: [], tried, modelNames };
}

function receiptInclude(found: { fieldNames: string[] }) {
  const include: Record<string, boolean> = {};
  if ((found.fieldNames as any).includes("request")) include.request = true;
  if ((found.fieldNames as any).includes("pickupRequest")) include.pickupRequest = true;
  return include;
}

function codeWhere(found: { fieldNames: string[] }, code: string) {
  const ors: any[] = [];
  if ((found.fieldNames as any).includes("shareCode")) ors.push({ shareCode: code });
  if ((found.fieldNames as any).includes("code")) ors.push({ code: code });
  if ((found.fieldNames as any).includes("id")) ors.push({ id: code });
  return ors;
}

export async function GET(_req: Request, ctx: any) {
  try {
    const code = String(ctx?.params?.code ?? "").trim();
    if (!code) return NextResponse.json({ error: "missing_code" }, { status: 400 });

    const found = findReceiptModel();
    if (!found.key) {
      return NextResponse.json({ error: "receipt_delegate_missing", modelNames: found.modelNames, tried: found.tried }, { status: 500 });
    }

    const prismaAny = prisma as unknown as Record<string, AnyDelegate>;
    const delegate = prismaAny[found.key];

    const ors = codeWhere(found, code);
    if (!ors.length) {
      return NextResponse.json({ error: "no_code_fields", fieldNames: found.fieldNames }, { status: 500 });
    }

    const item = await delegate.findFirst!({ where: { OR: ors }, include: receiptInclude(found) });
    if (!item) return NextResponse.json({ error: "not_found", code }, { status: 404 });

    return NextResponse.json({ ok: true, delegate: found.key, model: found.modelName, item });
  } catch (e) {
    const detail = e instanceof Error ? e.message : String(e);
    return NextResponse.json({ error: "receipt_get_failed", detail }, { status: 500 });
  }
}

type PatchBody = { public?: boolean };

export async function PATCH(req: Request, ctx: any) {
  try {
    const code = String(ctx?.params?.code ?? "").trim();
    if (!code) return NextResponse.json({ error: "missing_code" }, { status: 400 });

    const body = (await req.json()) as PatchBody;
    if (typeof body?.public !== "boolean") {
      return NextResponse.json({ error: "missing_public_boolean" }, { status: 400 });
    }

    const found = findReceiptModel();
    if (!found.key) {
      return NextResponse.json({ error: "receipt_delegate_missing", modelNames: found.modelNames, tried: found.tried }, { status: 500 });
    }

    if (!(found.fieldNames as any).includes("public")) {
      return NextResponse.json({ error: "field_public_not_supported", fieldNames: found.fieldNames }, { status: 400 });
    }

    const prismaAny = prisma as unknown as Record<string, AnyDelegate>;
    const delegate = prismaAny[found.key];

    const ors = codeWhere(found, code);
    if (!ors.length) {
      return NextResponse.json({ error: "no_code_fields", fieldNames: found.fieldNames }, { status: 500 });
    }

    const existing = await delegate.findFirst!({ where: { OR: ors } });
    if (!existing) return NextResponse.json({ error: "not_found", code }, { status: 404 });

    if (typeof delegate.update !== "function") {
      return NextResponse.json({ error: "delegate_update_missing", delegate: found.key }, { status: 500 });
    }

    const updated = await delegate.update!({
      where: { id: existing.id },
      data: { public: body.public },
      include: receiptInclude(found),
    });

    return NextResponse.json({ ok: true, item: updated });
  } catch (e) {
    const detail = e instanceof Error ? e.message : String(e);
    return NextResponse.json({ error: "receipt_patch_failed", detail }, { status: 500 });
  }
}