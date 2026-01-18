
  
import { NextResponse } from "next/server";
import { Prisma, PrismaClient } from "@prisma/client";
const _ECO_TOKEN_HEADER = "x-eco-token";



function _ecoStripReceiptForAnon(receipt: any, isOp: boolean) {
  if (!receipt) return receipt;
  const isPublic = !!(receipt.public ?? receipt.isPublic);
  if (isOp || isPublic) return receipt;

  const r: any = { ...receipt };
  if ("shareCode" in r) r.shareCode = null;
  if ("code" in r) r.code = null;
  return r;
}
export const runtime = "nodejs";

 // ECO_HELPER_WITH_RECEIPT_START
 function ecoWithReceipt(args: any) {
   const a: any = args ?? {};
   const f = "receipt";
   const receiptPick: any = { select: { code: true, public: true } };
   if (a?.select?.[f] || a?.include?.[f]) return a;
   if (a.select) return { ...a, select: { ...a.select, [f]: receiptPick } };
   return { ...a, include: { ...(a.include ?? {}), [f]: receiptPick } };
 }
 // ECO_HELPER_WITH_RECEIPT_END

 // ECO_HELPER_OPERATOR_START
 function ecoGetToken(req: Request): string | null {
   const h = req.headers.get("x-eco-token") ?? req.headers.get("authorization") ?? "";
   if (h.startsWith("Bearer ")) return h.slice(7).trim();
   if (h && !h.includes(" ")) return h.trim();
   return null;
 }
 function ecoIsOperator(req: Request): boolean {
   const expected = (process.env.ECO_OPERATOR_TOKEN ?? "").trim();
   if (!expected) return false;
   const got = ecoGetToken(req);
   if (!got) return false;
   return got === expected;
 }
 // ECO_HELPER_OPERATOR_END

const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };
const prisma = globalForPrisma.prisma ?? new PrismaClient();
if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = prisma;

type AnyDelegate = {
  findMany?: (args?: any) => Promise<any>;
  create?: (args?: any) => Promise<any>;
};

function lowerCamel(s: string) {
  return s ? s.charAt(0).toLowerCase() + s.slice(1) : s;
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

function findPickupModel() {
  const modelName = "PickupRequest";
  const tried: string[] = [];
  const key = getDelegateKeyForModel(modelName);
  tried.push(modelName + " -> " + (key ?? "null"));
  const model = getModel(modelName);
  const fields = model?.fields ?? [];
  const fieldNames = fields.map((f) => f.name);
  return { key, modelName, fields, fieldNames, tried };
}

function pickupInclude(found: { fieldNames: string[] }) {
  const include: Record<string, boolean> = {};
  if ((found.fieldNames as any).includes("receipt")) include.receipt = true;
  return include;
}

type CreateBody = {
  address?: string;
  notes?: string;
  name?: string;
  phone?: string;
  public?: boolean;
};

function safeTrim(v: any) {
  return typeof v === "string" ? v.trim() : "";
}

function buildCreateData(found: { fieldNames: string[] }, body: CreateBody) {
  const data: Record<string, any> = {};

  const addr = safeTrim((body as any)?.address);
  const notes = safeTrim((body as any)?.notes);

  // campos diretos comuns (se existirem no model)
  if (safeTrim((body as any)?.name) && (found.fieldNames as any).includes("name")) data.name = safeTrim((body as any)?.name);
  if (safeTrim((body as any)?.phone) && (found.fieldNames as any).includes("phone")) data.phone = safeTrim((body as any)?.phone);

  if (typeof (body as any)?.public === "boolean" && (found.fieldNames as any).includes("public")) data.public = !!(body as any)?.public;

  // notes (se existir)
  if (notes && (found.fieldNames as any).includes("notes")) data.notes = notes;

  // address compat: tenta gravar em campo equivalente; se não existir, injeta no notes
  if (addr) {
    if ((found.fieldNames as any).includes("address")) data.address = addr;
    else if ((found.fieldNames as any).includes("location")) data.location = addr;
    else if ((found.fieldNames as any).includes("place")) data.place = addr;
    else if ((found.fieldNames as any).includes("where")) data.where = addr;
    else {
      if ((found.fieldNames as any).includes("notes")) {
        const prefix = "Endereço: " + addr;
        data.notes = data.notes ? (prefix + "\\n" + String(data.notes)) : prefix;
      }
    }
  }

  return data;
}

export async function GET(req: Request) {
  
  try {
    const found = findPickupModel();
    if (!found.key) {

 return NextResponse.json({ error: "pickup_delegate_missing", tried: found.tried }, { status: 500 });
    }
    const prismaAny = prisma as unknown as Record<string, AnyDelegate>;
    const delegate = prismaAny[found.key];
    const args: any = { take: 200, include: pickupInclude(found) };
    if ((found.fieldNames as any).includes("createdAt")) args.orderBy = { createdAt: "desc" };
    const items = await delegate.findMany!(ecoWithReceipt(args));
      // ECO_PICKUP_RECEIPT_PRIVACY_START
           const __eco_isOp = ecoIsOperator(req);
           if (!__eco_isOp) {
             const __rf = "receipt";
             const __pf = "public";
             for (const it of (items as any[])) {
               const r = (it as any)?.[__rf];
               if (r && __pf && (r as any)?.[__pf] !== true) {
                 (it as any)[__rf] = null;
               }
               if (r && !__pf) {
                 (it as any)[__rf] = null;
               }
             }
           }
           // ECO_PICKUP_RECEIPT_PRIVACY_END


    return NextResponse.json({ delegate: found.key, model: found.modelName, items });
  } catch (e) {
    const detail = e instanceof Error ? e.message : String(e);
    return NextResponse.json({ error: "pickup_list_failed", detail }, { status: 500 });
  }
}

export async function POST(req: Request) {
  try {
    const body = (await req.json()) as CreateBody;
    const found = findPickupModel();
    if (!found.key) {
      return NextResponse.json({ error: "pickup_delegate_missing", tried: found.tried }, { status: 500 });
    }

    const prismaAny = prisma as unknown as Record<string, AnyDelegate>;
    const delegate = prismaAny[found.key];

    const data = buildCreateData(found, body);
    const include = pickupInclude(found);

    try {
      const item = await delegate.create!({ data, include });
      return NextResponse.json({ ok: true, item });
    } catch (err) {
      // fallback: se por algum motivo ainda bater "Unknown argument `address`", remove e joga no notes
      const msg = err instanceof Error ? err.message : String(err);
      if (msg.includes("Unknown argument `address`") && (data as any).address) {
        const addr = String((data as any).address);
        delete (data as any).address;
        if ((found.fieldNames as any).includes("notes")) {
          const prefix = "Endereço: " + addr;
          (data as any).notes = (data as any).notes ? (prefix + "\\n" + String((data as any).notes)) : prefix;
        }
        const item = await delegate.create!({ data, include });
        return NextResponse.json({ ok: true, item, warning: "address_field_missing_saved_in_notes" });
      }
      throw err;
    }
  } catch (e) {
    const detail = e instanceof Error ? e.message : String(e);
    return NextResponse.json({ error: "pickup_create_failed", detail }, { status: 500 });
  }
}