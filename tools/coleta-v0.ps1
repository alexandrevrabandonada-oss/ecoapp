$ErrorActionPreference = "Stop"

function Backup-File([string]$p) {
  if (Test-Path $p) {
    $ts = Get-Date -Format "yyyyMMdd-HHmmss"
    Copy-Item $p "$p.bak-$ts" -Force
  }
}

function Ensure-Dir([string]$p) {
  $dir = Split-Path $p -Parent
  if ($dir -and !(Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
}

Write-Host "== ECO / Coleta v0: Prisma singleton + API services + API points(POST) + UI /coleta ==" -ForegroundColor Cyan

# 0) garante schema aplicado
Write-Host ">> prisma db push + generate" -ForegroundColor Yellow
npx prisma db push --schema=prisma/schema.prisma
npx prisma generate --schema=prisma/schema.prisma

# 1) src/lib/prisma.ts (singleton)
$prismaLib = "src/lib/prisma.ts"
Ensure-Dir $prismaLib
Backup-File $prismaLib
@"
import { PrismaClient } from "@prisma/client";

const globalForPrisma = global as unknown as { prisma?: PrismaClient };

export const prisma =
  globalForPrisma.prisma ??
  new PrismaClient({
    log: process.env.NODE_ENV === "development" ? ["error", "warn"] : ["error"],
  });

if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = prisma;
"@ | Set-Content -Encoding UTF8 $prismaLib

# 2) /api/services (GET/POST)
$servicesRoute = "src/app/api/services/route.ts"
Ensure-Dir $servicesRoute
Backup-File $servicesRoute
@"
import { NextResponse } from "next/server";
import { prisma } from "../../../lib/prisma";

function slugify(s: string) {
  return (s ?? "")
    .toLowerCase()
    .normalize("NFD").replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/(^-|-$)/g, "");
}

export async function GET() {
  const services = await prisma.service.findMany({ orderBy: { createdAt: "desc" } });
  return NextResponse.json({ services });
}

export async function POST(req: Request) {
  try {
    const body = await req.json();
    const name = String(body?.name ?? "").trim();
    const kind = String(body?.kind ?? "COLETA").trim();
    if (!name) return NextResponse.json({ error: "NAME_REQUIRED" }, { status: 400 });

    const slug = slugify(String(body?.slug ?? name));
    const created = await prisma.service.create({
      data: { name, slug, kind: kind as any },
    });

    return NextResponse.json({ service: created });
  } catch (err: any) {
    return NextResponse.json(
      { error: "SERVICE_CREATE_ERROR", message: err?.message ?? String(err) },
      { status: 500 }
    );
  }
}
"@ | Set-Content -Encoding UTF8 $servicesRoute

# 3) /api/points (GET/POST) — POST “best effort” (pra não travar se o schema tiver campos extras)
$pointsRoute = "src/app/api/points/route.ts"
Ensure-Dir $pointsRoute
Backup-File $pointsRoute
@"
import { NextResponse } from "next/server";
import { prisma } from "../../../lib/prisma";

export async function GET() {
  try {
    const points = await prisma.point.findMany({
      where: { isActive: true },
      include: { service: true },
      orderBy: { createdAt: "desc" },
    });
    return NextResponse.json({ points });
  } catch (err: any) {
    return NextResponse.json(
      { points: [], error: "DB_ERROR", message: err?.message ?? String(err) },
      { status: 500 }
    );
  }
}

export async function POST(req: Request) {
  try {
    const body = await req.json();

    const name = String(body?.name ?? "").trim();
    if (!name) return NextResponse.json({ error: "NAME_REQUIRED" }, { status: 400 });

    const serviceSlug = String(body?.serviceSlug ?? "").trim();
    const serviceId = String(body?.serviceId ?? "").trim();

    let service: any = null;
    if (serviceId) service = await prisma.service.findUnique({ where: { id: serviceId } });
    if (!service && serviceSlug) service = await prisma.service.findUnique({ where: { slug: serviceSlug } });

    if (!service) {
      return NextResponse.json({ error: "SERVICE_REQUIRED" }, { status: 400 });
    }

    const materialKind = body?.materialKind ? String(body.materialKind).trim() : undefined;
    const address = body?.address ? String(body.address).trim() : undefined;
    const notes = body?.notes ? String(body.notes).trim() : undefined;

    // Tentativas (pra aguentar variações do schema)
    const attempts: any[] = [
      { name, isActive: true, service: { connect: { id: service.id } }, materialKind, address, notes },
      { name, isActive: true, serviceId: service.id, materialKind, address, notes },
      { title: name, isActive: true, service: { connect: { id: service.id } }, materialKind, address, notes },
      { title: name, isActive: true, serviceId: service.id, materialKind, address, notes },
    ];

    let created: any = null;
    let lastErr: any = null;

    for (const data of attempts) {
      try {
        // remove undefined
        Object.keys(data).forEach((k) => data[k] === undefined && delete data[k]);
        if (data.service?.connect?.id == null) delete data.service;
        created = await prisma.point.create({ data });
        break;
      } catch (e: any) {
        lastErr = e;
      }
    }

    if (!created) throw lastErr ?? new Error("POINT_CREATE_FAILED");

    return NextResponse.json({ point: created });
  } catch (err: any) {
    return NextResponse.json(
      { error: "POINT_CREATE_ERROR", message: err?.message ?? String(err) },
      { status: 500 }
    );
  }
}
"@ | Set-Content -Encoding UTF8 $pointsRoute

# 4) UI /coleta + /coleta/novo
$coletaPage = "src/app/coleta/page.tsx"
Ensure-Dir $coletaPage
Backup-File $coletaPage
@"
import Link from "next/link";

async function getPoints() {
  const res = await fetch("http://localhost:3000/api/points", { cache: "no-store" });
  const json = await res.json().catch(() => ({}));
  return { ok: res.ok, ...json };
}

export default async function ColetaPage() {
  const data: any = await getPoints();
  const points = Array.isArray(data?.points) ? data.points : [];

  return (
    <main style={{ padding: 24 }}>
      <div style={{ display: "flex", gap: 12, alignItems: "center", justifyContent: "space-between" }}>
        <h1 style={{ margin: 0 }}>Coleta</h1>
        <Link href="/coleta/novo">Cadastrar ponto</Link>
      </div>

      {!data?.ok && (
        <p style={{ marginTop: 12 }}>
          ⚠️ Erro ao carregar: <code>{String(data?.message ?? data?.error ?? "unknown")}</code>
        </p>
      )}

      {points.length === 0 ? (
        <p style={{ marginTop: 16 }}>Nenhum ponto cadastrado ainda. Bora criar o primeiro.</p>
      ) : (
        <ul style={{ marginTop: 16, paddingLeft: 18 }}>
          {points.map((p: any) => {
            const title = p?.name ?? p?.title ?? p?.label ?? p?.slug ?? p?.id;
            const serviceName = p?.service?.name ?? p?.service?.slug ?? "";
            const extra = p?.materialKind ?? p?.kind ?? "";
            return (
              <li key={p?.id ?? title}>
                <strong>{String(title)}</strong>
                {serviceName ? <span> — {String(serviceName)}</span> : null}
                {extra ? <span> • {String(extra)}</span> : null}
              </li>
            );
          })}
        </ul>
      )}
    </main>
  );
}
"@ | Set-Content -Encoding UTF8 $coletaPage

$coletaNovo = "src/app/coleta/novo/page.tsx"
Ensure-Dir $coletaNovo
Backup-File $coletaNovo
@"
"use client";

import { useEffect, useMemo, useState } from "react";

const MATERIALS = [
  "PAPEL","PAPELAO","PET","PLASTICO_MISTO","ALUMINIO","VIDRO","FERRO","ELETRONICOS","OUTRO"
];

export default function ColetaNovoPage() {
  const [services, setServices] = useState<any[]>([]);
  const [serviceSlug, setServiceSlug] = useState("");
  const [name, setName] = useState("");
  const [materialKind, setMaterialKind] = useState("PAPEL");
  const [address, setAddress] = useState("");
  const [notes, setNotes] = useState("");
  const [msg, setMsg] = useState<string>("");

  useEffect(() => {
    fetch("/api/services")
      .then(r => r.json())
      .then(j => setServices(Array.isArray(j?.services) ? j.services : []))
      .catch(() => setServices([]));
  }, []);

  const canSave = useMemo(() => name.trim() && serviceSlug.trim(), [name, serviceSlug]);

  async function onSave() {
    setMsg("");
    const res = await fetch("/api/points", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name, serviceSlug, materialKind, address, notes }),
    });
    const j = await res.json().catch(() => ({}));
    if (!res.ok) {
      setMsg("Erro: " + String(j?.message ?? j?.error ?? "unknown"));
      return;
    }
    setMsg("✅ Ponto criado! Volte em /coleta pra ver.");
    setName(""); setAddress(""); setNotes("");
  }

  async function onCreateService() {
    const n = prompt("Nome do serviço (ex: Coleta Solidária)")?.trim();
    if (!n) return;
    const kind = prompt("Kind (COLETA/REPARO/FEIRA/FORMACAO/DOACAO/OUTRO)", "COLETA")?.trim() || "COLETA";
    const res = await fetch("/api/services", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name: n, kind }),
    });
    const j = await res.json().catch(() => ({}));
    if (!res.ok) return setMsg("Erro criando serviço: " + String(j?.message ?? j?.error ?? "unknown"));
    const s = j?.service;
    setServices((prev) => [s, ...prev]);
    setServiceSlug(s?.slug ?? "");
    setMsg("✅ Serviço criado.");
  }

  return (
    <main style={{ padding: 24, maxWidth: 720 }}>
      <h1 style={{ marginTop: 0 }}>Cadastrar ponto</h1>

      <div style={{ display: "flex", gap: 12, alignItems: "center" }}>
        <label style={{ flex: 1 }}>
          Serviço
          <select value={serviceSlug} onChange={(e) => setServiceSlug(e.target.value)} style={{ width: "100%", padding: 8 }}>
            <option value="">-- selecione --</option>
            {services.map((s) => (
              <option key={s.id} value={s.slug}>
                {s.name} ({s.kind})
              </option>
            ))}
          </select>
        </label>
        <button onClick={onCreateService} type="button">+ Serviço</button>
      </div>

      <label style={{ display: "block", marginTop: 12 }}>
        Nome do ponto
        <input value={name} onChange={(e) => setName(e.target.value)} style={{ width: "100%", padding: 8 }} />
      </label>

      <label style={{ display: "block", marginTop: 12 }}>
        Material
        <select value={materialKind} onChange={(e) => setMaterialKind(e.target.value)} style={{ width: "100%", padding: 8 }}>
          {MATERIALS.map((m) => <option key={m} value={m}>{m}</option>)}
        </select>
      </label>

      <label style={{ display: "block", marginTop: 12 }}>
        Endereço (opcional)
        <input value={address} onChange={(e) => setAddress(e.target.value)} style={{ width: "100%", padding: 8 }} />
      </label>

      <label style={{ display: "block", marginTop: 12 }}>
        Observações (opcional)
        <textarea value={notes} onChange={(e) => setNotes(e.target.value)} style={{ width: "100%", padding: 8, minHeight: 90 }} />
      </label>

      <div style={{ display: "flex", gap: 12, marginTop: 16 }}>
        <button disabled={!canSave} onClick={onSave} type="button">Salvar</button>
        <a href="/coleta">Voltar</a>
      </div>

      {msg ? <p style={{ marginTop: 12 }}>{msg}</p> : null}
    </main>
  );
}
"@ | Set-Content -Encoding UTF8 $coletaNovo

Write-Host "✅ Coleta v0 aplicado. Suba:" -ForegroundColor Green
Write-Host "   npm run dev -- --webpack"
