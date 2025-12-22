import { NextResponse } from "next/server";
import { prisma } from "../../../lib/prisma";
import { Prisma } from "@prisma/client";

function slugify(s: string) {
  return (s || "")
    .toLowerCase()
    .normalize("NFD").replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/(^-|-$)/g, "");
}

function pickForModel(modelName: string, input: any) {
  const dmmf = (Prisma as any)?.dmmf;
  const model = dmmf?.datamodel?.models?.find((m: any) => m.name === modelName);
  if (!model) return input ?? {};
  const allowed = new Set(
    (model.fields || [])
      .filter((f: any) => f.kind !== "object" && !f.isReadOnly)
      .map((f: any) => f.name)
  );
  const out: any = {};
  for (const [k, v] of Object.entries(input ?? {})) {
    if (allowed.has(k)) out[k] = v;
  }
  return out;
}

export async function GET() {
  try {
    const services = await prisma.service.findMany({ orderBy: { createdAt: "desc" } });
    return NextResponse.json({ services });
  } catch (e: any) {
    return NextResponse.json({ error: e?.message ?? "erro" }, { status: 500 });
  }
}

export async function POST(req: Request) {
  try {
    const body = await req.json().catch(() => ({}));
    const name = String(body?.name ?? "").trim();
    if (!name) return NextResponse.json({ error: "name obrigatório" }, { status: 400 });

    const kind = body?.kind ?? body?.tipo ?? body?.type ?? "OUTRO";
    const slug = body?.slug ? String(body.slug) : slugify(name);

    // manda vários sinônimos; o pickForModel filtra o que existe de verdade no schema
    const raw = {
      name,
      kind,
      slug,
      isActive: body?.isActive ?? true,
    };

    const data = pickForModel("Service", raw);
    const created = await prisma.service.create({ data });
    return NextResponse.json({ service: created }, { status: 201 });
  } catch (e: any) {
    return NextResponse.json({ error: e?.message ?? "erro" }, { status: 500 });
  }
}