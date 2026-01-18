import { NextResponse } from "next/server";
import { Prisma, PrismaClient } from "@prisma/client";
import crypto from "crypto";

export const runtime = "nodejs";

function requireOperatorToken(req: Request, body: any) {
  const required = process.env.ECO_OPERATOR_TOKEN;
  if (!required) return { ok: true as const };

  const headerToken = req.headers.get("x-eco-token");
  const token =
    (typeof body?.operatorToken === "string" && body.operatorToken.trim())
      ? body.operatorToken.trim()
      : (headerToken || "");

  if (!token || token !== required) {
    return { ok: false as const, res: NextResponse.json({ error: "unauthorized" }, { status: 401 }) };
  }
  return { ok: true as const };
}


const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };
const prisma = globalForPrisma.prisma ?? new PrismaClient();
if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = prisma;

type AnyDelegate = {
  findMany?: (args?: any) => Promise<any>;
  findUnique?: (args?: any) => Promise<any>;
  findFirst?: (args?: any) => Promise<any>;
  create?: (args?: any) => Promise<any>;
  update?: (args?: any) => Promise<any>;
  upsert?: (args?: any) => Promise<any>;
};

function lowerCamel(s: string) {
  return s ? s.charAt(0).toLowerCase() + s.slice(1) : s;
}
function uniq<T>(arr: T[]) {
  return Array.from(new Set(arr));
}
function genCode() {
  return crypto.randomBytes(8).toString("hex").slice(0, 10);
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
  const preferred = uniq(["Receipt", "EcoReceipt", ...receiptModels]);

  const tried: string[] = [];
  for (const modelName of preferred) {
    const key = getDelegateKeyForModel(modelName);
    tried.push(modelName + " -> " + (key ?? "null"));
    if (!key) continue;

    const prismaAny = prisma as unknown as Record<string, AnyDelegate>;
    const d = prismaAny[key];
    if (d && typeof d.findMany === "function") {
      const model = getModel(modelName);
      const fields = model?.fields ?? [];
      return { key, modelName, fields, fieldNames: fields.map((f) => f.name), tried, modelNames };
    }
  }
  return { key: null as string | null, modelName: null as string | null, fields: [], fieldNames: [], tried, modelNames };
}
function findPickupModel() {
  const modelName = "PickupRequest";
  const tried: string[] = [];
  const key = getDelegateKeyForModel(modelName);
  tried.push(modelName + " -> " + (key ?? "null"));

  if (!key) return { key: null as string | null, modelName: null as string | null, fields: [], fieldNames: [], tried, modelNames: getModelNames() };

  const prismaAny = prisma as unknown as Record<string, AnyDelegate>;
  const d = prismaAny[key];
  if (d && typeof d.findUnique === "function") {
    const model = getModel(modelName);
    const fields = model?.fields ?? [];
    return { key, modelName, fields, fieldNames: fields.map((f) => f.name), tried, modelNames: getModelNames() };
  }
  return { key: null as string | null, modelName: null as string | null, fields: [], fieldNames: [], tried, modelNames: getModelNames() };
}
function receiptInclude(found: { fieldNames: string[] }) {
  const include: Record<string, boolean> = {};
  if ((found.fieldNames as any).includes("request")) include.request = true;
  if ((found.fieldNames as any).includes("pickupRequest")) include.pickupRequest = true;
  return include;
}
function getCodeField(found: { fieldNames: string[] }) {
  if ((found.fieldNames as any).includes("shareCode")) return "shareCode";
  if ((found.fieldNames as any).includes("code")) return "code";
  return null;
}
function getPublicField(found: { fieldNames: string[] }) {
  if ((found.fieldNames as any).includes("public")) return "public";
  if ((found.fieldNames as any).includes("isPublic")) return "isPublic";
  return null;
}
function pickReceiptData(found: { fieldNames: string[] }, body: any, code: string) {
  const data: Record<string, any> = {};
  if ((found.fieldNames as any).includes("summary")) data.summary = body.summary ?? null;
  if ((found.fieldNames as any).includes("items")) data.items = body.items ?? null;
  if ((found.fieldNames as any).includes("operator")) data.operator = body.operator ?? null;

  const pubField = getPublicField(found);
  if (pubField) data[pubField] = !!body.public;

  const codeField = getCodeField(found);
  if (codeField) data[codeField] = code;

  return data;
}
function pickupDoneUpdate(found: { fieldNames: string[]; fields: any[] }) {
  if (!(found.fieldNames as any).includes("status")) return {};
  const f = found.fields.find((x: any) => x.name === "status");
  if (!f) return {};

  if (f.kind === "enum") {
    const en = Prisma.dmmf.datamodel.enums.find((e) => e.name === f.type);
    const values = (en?.values ?? []).map((v) => v.name);
    const pick = ["DONE", "COMPLETED", "FINISHED", "CLOSED"].find((v) => values.includes(v));
    return pick ? { status: pick } : {};
  }

  if (f.kind === "scalar" && f.type === "String") return { status: "DONE" };
  return {};
}
async function findReceiptByCode(found: any, codeRaw: string) {
  const code = (codeRaw || "").trim();
  if (!code) return null;

  const prismaAny = prisma as unknown as Record<string, AnyDelegate>;
  const delegate = prismaAny[found.key];

  const codeField = getCodeField(found);
  if (codeField && typeof delegate.findUnique === "function") {
    try { return await delegate.findUnique({ where: { [codeField]: code }, include: receiptInclude(found) }); } catch { void 0; }
  }
  if (codeField && typeof delegate.findFirst === "function") {
    try { return await delegate.findFirst({ where: { [codeField]: code }, include: receiptInclude(found) }); } catch { void 0; }
  }

  if (typeof delegate.findUnique === "function") {
    try { return await delegate.findUnique({ where: { id: code }, include: receiptInclude(found) }); } catch { void 0; }
  }
  if (typeof delegate.findFirst === "function") {
    try { return await delegate.findFirst({ where: { id: code }, include: receiptInclude(found) }); } catch { void 0; }
  }

  return null;
}

export async function GET(req: Request) {
  try {
    const found = findReceiptModel();
    if (!found.key) {
      return NextResponse.json({ error: "receipt_delegate_missing", modelNames: found.modelNames, tried: found.tried }, { status: 500 });
    }

    const url = new URL(req.url);
    const code = url.searchParams.get("code") || url.searchParams.get("shareCode") || url.searchParams.get("id") || "";

    const prismaAny = prisma as unknown as Record<string, AnyDelegate>;
    const delegate = prismaAny[found.key];

    if (code) {
      const receipt = await findReceiptByCode(found, code);
      if (!receipt) return NextResponse.json({ error: "receipt_not_found", code }, { status: 404 });
      // ECO_RECEIPTS_PUBLIC_GUARD_V1
      // Se ECO_OPERATOR_TOKEN estiver setado:
      // - recibo público => retorna normal
      // - recibo privado => só retorna se token bater (header x-eco-token ou query ?token=)
      const isPublic = !!((receipt as any).public ?? (receipt as any).isPublic);
      const required = process.env.ECO_OPERATOR_TOKEN;

      if (!isPublic && required) {
        const u = new URL(req.url);
        const token =
          req.headers.get("x-eco-token") ||
          u.searchParams.get("token") ||
          u.searchParams.get("operatorToken") ||
          "";

        if (!token || token !== required) {
          // 404 para não revelar existência
          return NextResponse.json({ error: "receipt_not_found", code }, { status: 404 });
        }
      }
return NextResponse.json({ ok: true, receipt });
    }

    const args: any = { include: receiptInclude(found), take: 200 };
    if ((found.fieldNames as any).includes("createdAt")) args.orderBy = { createdAt: "desc" };
    const items = await delegate.findMany!(args);

    return NextResponse.json({ ok: true, items });
  } catch (e) {
    const detail = e instanceof Error ? e.message : String(e);
    return NextResponse.json({ error: "receipts_get_failed", detail }, { status: 500 });
  }
}

type IssueBody = {
  requestId: string;
  summary?: string | null;
  items?: string | null;
  operator?: string | null;
  public?: boolean;
  shareCode?: string | null;
};

export async function POST(req: Request) {
  try {
    const body = (await req.json()) as IssueBody;
    const auth = requireOperatorToken(req, body);
    if (!auth.ok) return auth.res;
    const requestId = body?.requestId?.trim();
    if (!requestId) return NextResponse.json({ error: "missing_requestId" }, { status: 400 });

    const receiptFound = findReceiptModel();
    if (!receiptFound.key || !receiptFound.modelName) {
      return NextResponse.json({ error: "receipt_delegate_missing", modelNames: receiptFound.modelNames, tried: receiptFound.tried }, { status: 500 });
    }

    const pickupFound = findPickupModel();
    if (!pickupFound.key) {
      return NextResponse.json({ error: "pickup_delegate_missing", modelNames: pickupFound.modelNames, tried: pickupFound.tried }, { status: 500 });
    }

    const prismaAny = prisma as unknown as Record<string, AnyDelegate>;
    const reqItem = await prismaAny[pickupFound.key].findUnique!({ where: { id: requestId } });
    if (!reqItem) return NextResponse.json({ error: "pickup_not_found", requestId }, { status: 404 });

    const code = (body.shareCode && body.shareCode.trim()) ? body.shareCode.trim() : genCode();

    const relationField =
      receiptFound.fields.find((f: any) => f.kind === "object" && f.type === "PickupRequest")?.name ?? null;

    const hasRequestIdField = (receiptFound.fieldNames as any).includes("requestId");
    const requestIdField = receiptFound.fields.find((f: any) => f.name === "requestId");
    const requestIdUnique = !!requestIdField?.isUnique;

    const dataBase = pickReceiptData(receiptFound, body, code);

    const createData: any = { ...dataBase };
    if (hasRequestIdField) createData.requestId = requestId;
    if (relationField) createData[relationField] = { connect: { id: requestId } };

    let existing: any = null;

    if (hasRequestIdField) {
      try { existing = await prismaAny[receiptFound.key].findUnique!({ where: { requestId } }); } catch { void 0; }
      if (!existing) {
        try { existing = await prismaAny[receiptFound.key].findFirst!({ where: { requestId } }); } catch { void 0; }
      }
    }

    if (!existing && relationField) {
      try { existing = await prismaAny[receiptFound.key].findFirst!({ where: { [relationField]: { id: requestId } } }); } catch { void 0; }
    }

    let receipt: any = null;

    if (existing) {
      receipt = await prismaAny[receiptFound.key].update!({ where: { id: existing.id }, data: { ...dataBase }, include: receiptInclude(receiptFound) });
    } else if (requestIdUnique && hasRequestIdField) {
      receipt = await prismaAny[receiptFound.key].upsert!({ where: { requestId }, update: { ...dataBase }, create: createData, include: receiptInclude(receiptFound) });
    } else {
      receipt = await prismaAny[receiptFound.key].create!({ data: createData, include: receiptInclude(receiptFound) });
    }

    const upd = pickupDoneUpdate(pickupFound as any);
    if (Object.keys(upd).length) {
      try { await prismaAny[pickupFound.key].update!({ where: { id: requestId }, data: upd }); } catch { void 0; }
    }

    return NextResponse.json({ ok: true, receipt, requestId });
  } catch (e) {
    const detail = e instanceof Error ? e.message : String(e);
    return NextResponse.json({ error: "receipt_issue_failed", detail }, { status: 500 });
  }
}

type PatchBody = { code: string; public: boolean };

export async function PATCH(req: Request) {
  try {
    const body = (await req.json()) as PatchBody;
    const auth = requireOperatorToken(req, body);
    if (!auth.ok) return auth.res;
    const code = (body?.code || "").trim();
    if (!code) return NextResponse.json({ error: "missing_code" }, { status: 400 });

    const found = findReceiptModel();
    if (!found.key) {
      return NextResponse.json({ error: "receipt_delegate_missing", modelNames: found.modelNames, tried: found.tried }, { status: 500 });
    }

    const pubField = getPublicField(found);
    if (!pubField) return NextResponse.json({ error: "receipt_public_field_missing" }, { status: 500 });

    const existing = await findReceiptByCode(found, code);
    if (!existing) return NextResponse.json({ error: "receipt_not_found", code }, { status: 404 });

    const prismaAny = prisma as unknown as Record<string, AnyDelegate>;
    const updated = await prismaAny[found.key].update!({
      where: { id: existing.id },
      data: { [pubField]: !!body.public },
      include: receiptInclude(found),
    });

    return NextResponse.json({ ok: true, receipt: updated, code, public: !!body.public });
  } catch (e) {
    const detail = e instanceof Error ? e.message : String(e);
    return NextResponse.json({ error: "receipt_patch_failed", detail }, { status: 500 });
  }
}