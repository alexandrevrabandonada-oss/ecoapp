import { NextResponse } from "next/server";
import { Prisma, PrismaClient } from "@prisma/client";

export const runtime = "nodejs";

// ECO PATCH: rewrite seguro do /api/points
const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };
const prisma = globalForPrisma.prisma ?? new PrismaClient();
if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = prisma;

type AnyDelegate = {
  findMany?: (args?: any) => Promise<any>;
  findUnique?: (args?: any) => Promise<any>;
  findFirst?: (args?: any) => Promise<any>;
  create?: (args?: any) => Promise<any>;
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
  for (const k of keys) {
    if ((prismaAny as any)[k]) return k;
  }
  return null;
}

function findPointModel() {
  const modelNames = getModelNames();
  const candidates = ["Point", "EcoPoint"].concat(modelNames.filter((n) => /point/i.test(n)));
  const tried: string[] = [];

  for (const modelName of candidates) {
    const key = getDelegateKeyForModel(modelName);
    tried.push(modelName + " -> " + (key ?? "null"));
    if (!key) continue;

    const prismaAny = prisma as unknown as Record<string, AnyDelegate>;
    const d = (prismaAny as any)[key];
    if (d && typeof d.findMany === "function" && typeof d.create === "function") {
      const model = getModel(modelName);
      const fields = model?.fields ?? [];
      return { key, modelName, fields, fieldNames: fields.map((f) => f.name), tried, modelNames };
    }
  }

  return { key: null as string | null, modelName: null as string | null, fields: [], fieldNames: [], tried, modelNames };
}

function pickString(v: any) {
  return typeof v === "string" && v.trim() ? v.trim() : "";
}

function slugify(raw: string) {
  const s = (raw || "").trim().toLowerCase();
  return s
    .normalize("NFD").replace(/[\\u0300-\\u036f]/g, "")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/(^-|-$)/g, "")
    .slice(0, 80);
}

function getEnumValues(enumName: string) {
  const en = Prisma.dmmf.datamodel.enums.find((e) => e.name === enumName);
  return (en?.values ?? []).map((v) => v.name);
}

function includeForPoint(found: { fieldNames: string[] }) {
  const include: Record<string, boolean> = {};
  if ((found.fieldNames as any).includes("service")) include.service = true;
  return include;
}

export async function GET() {
  try {
    const found = findPointModel();
    if (!found.key) {
      return NextResponse.json(
        { error: "points_delegate_missing", modelNames: found.modelNames, tried: found.tried },
        { status: 500 }
      );
    }

    const prismaAny = prisma as unknown as Record<string, AnyDelegate>;
    const delegate = (prismaAny as any)[found.key];

    const args: any = { take: 200, include: includeForPoint(found) };
    if ((found.fieldNames as any).includes("createdAt")) args.orderBy = { createdAt: "desc" };

    const items = await delegate.findMany!(args);
    return NextResponse.json({ ok: true, delegate: found.key, model: found.modelName, items });
  } catch (e) {
    const detail = e instanceof Error ? e.message : String(e);
    return NextResponse.json({ error: "points_list_failed", detail }, { status: 500 });
  }
}

export async function POST(req: Request) {
  try {
    const body = (await req.json().catch(() => ({}))) as any;

    const found = findPointModel();
    if (!found.key || !found.modelName) {
      return NextResponse.json(
        { error: "points_delegate_missing", modelNames: found.modelNames, tried: found.tried },
        { status: 500 }
      );
    }

    const model = getModel(found.modelName);
    const fields = model?.fields ?? [];

    const data: Record<string, any> = {};
    const missing: string[] = [];
    const invalidEnum: { field: string; value: string; allowed: string[] }[] = [];

    // helpers
    function setIfValue(k: string, v: any) {
      if (v === undefined || v === null) return;
      if (typeof v === "string" && !v.trim()) return;
      data[k] = v;
    }

    // 1) prefill (heurísticas) para campos comuns
    if ((found.fieldNames as any).includes("slug")) {
      const raw = pickString(body.slug) || pickString(body.title) || pickString(body.name) || pickString(body.materialKind) || pickString(body.material);
      setIfValue("slug", raw ? slugify(raw) : "");
    }

    if ((found.fieldNames as any).includes("city")) {
      const c = pickString(body.city) || pickString(process.env.ECO_DEFAULT_CITY) || "Volta Redonda";
      setIfValue("city", c);
    }

    if ((found.fieldNames as any).includes("title")) {
      const t = pickString(body.title) || pickString(body.name) || pickString(body.slug);
      setIfValue("title", t || "Ponto de coleta");
    }

    if ((found.fieldNames as any).includes("name")) {
      const n = pickString(body.name) || pickString(body.title) || pickString(body.slug);
      setIfValue("name", n || "Ponto de coleta");
    }

    if ((found.fieldNames as any).includes("isActive")) {
      const v = typeof body.isActive === "boolean" ? body.isActive : true;
      setIfValue("isActive", v);
    }

    // 2) mapear outros campos pelo nome (se vier no body)
    for (const f of fields as any[]) {
      const name = f.name as string;

      // ignore meta/ids
      if (name === "id" || name === "createdAt" || name === "updatedAt") continue;
      if (f.kind === "object") continue; // relations handled via include/foreign keys

      // se já setamos acima, não sobrescreve
      if (data[name] !== undefined) continue;

      // enums: validar
      if (f.kind === "enum") {
        let v = pickString(body[name]);
        // fallback conhecido
        if (!v && name === "materialKind") v = pickString(body.materialKind) || pickString(body.material);
        if (v) {
          const allowed = getEnumValues(f.type);
          if (allowed.length && !allowed.includes(v)) {
            invalidEnum.push({ field: name, value: v, allowed });
          } else {
            setIfValue(name, v);
          }
        }
        continue;
      }

      // scalars
      if (f.kind === "scalar") {
        const val = body[name];
        // boolean / number / string / json
        if (f.type === "Boolean") {
          if (typeof val === "boolean") setIfValue(name, val);
          continue;
        }
        if (f.type === "Int" || f.type === "Float" || f.type === "Decimal") {
          if (typeof val === "number" && !Number.isNaN(val)) setIfValue(name, val);
          continue;
        }
        if (f.type === "String") {
          const s = pickString(val);
          if (s) setIfValue(name, s);
          continue;
        }
        // Json ou outros: aceita como vier (se não for undefined)
        if (val !== undefined) setIfValue(name, val);
      }
    }

    // 3) remover vazios
    Object.keys(data).forEach((k) => {
      if (data[k] === undefined || data[k] === null) delete data[k];
      if (typeof data[k] === "string" && !data[k].trim()) delete data[k];
    });

    // 4) validar required (exceto id/createdAt/updatedAt)
    for (const f of fields as any[]) {
      const name = f.name as string;
      if (name === "id" || name === "createdAt" || name === "updatedAt") continue;
      if (f.kind === "object") continue;

      const required = !!f.isRequired;
      if (!required) continue;

      const v = data[name];
      if (v === undefined || v === null) {
        missing.push(name);
        continue;
      }
      if (typeof v === "string" && !v.trim()) {
        missing.push(name);
        continue;
      }
    }

    if (invalidEnum.length) {
      return NextResponse.json({ error: "invalid_enum_value", invalidEnum }, { status: 400 });
    }

    if (missing.length) {
      return NextResponse.json(
        { error: "missing_required_fields", missing, hint: "env opcional: ECO_DEFAULT_CITY (default Volta Redonda)" },
        { status: 400 }
      );
    }

    const prismaAny = prisma as unknown as Record<string, AnyDelegate>;
    const delegate = (prismaAny as any)[found.key];

    const point = await delegate.create!({
      data,
      include: includeForPoint(found),
    });

    return NextResponse.json({ ok: true, delegate: found.key, model: found.modelName, point });
  } catch (e) {
    const detail = e instanceof Error ? e.message : String(e);
    return NextResponse.json({ error: "points_create_failed", detail }, { status: 500 });
  }
}