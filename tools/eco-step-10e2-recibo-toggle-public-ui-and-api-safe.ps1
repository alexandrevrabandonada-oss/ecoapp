$ErrorActionPreference = "Stop"

function EnsureDir([string]$p){
  if($p -and !(Test-Path -LiteralPath $p)){
    New-Item -ItemType Directory -Force -Path $p | Out-Null
  }
}
function WriteUtf8NoBom([string]$path, [string]$content){
  $dir = Split-Path -Parent $path
  if($dir){ EnsureDir $dir }
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
}
function BackupFile([string]$path){
  if(!(Test-Path -LiteralPath $path)){ return $null }
  EnsureDir "tools/_patch_backup"
  $ts = Get-Date -Format "yyyyMMdd-HHmmss"
  $safe = ($path -replace '[\\/:*?"<>|]', '_')
  $dst = "tools/_patch_backup/$ts-$safe"
  Copy-Item -Force -LiteralPath $path $dst
  return $dst
}
function NewReport([string]$name){
  EnsureDir "reports"
  $ts = Get-Date -Format "yyyyMMdd-HHmmss"
  return "reports/$ts-$name.md"
}

$rep = NewReport "eco-step-10e2-recibo-toggle-public-ui-and-api-safe"
$log = @()
$log += "# ECO — STEP 10e2 — Toggle público/privado no Recibo + API (safe here-strings)"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

# DIAG
$apiReceipts = "src/app/api/receipts/route.ts"
if(!(Test-Path -LiteralPath $apiReceipts)){ throw "Não achei src/app/api/receipts/route.ts" }

$pageFile = $null
$found = Get-ChildItem -Recurse -File -Path "src/app" -Filter "page.tsx" -ErrorAction SilentlyContinue |
  Where-Object { $_.FullName -match "\\recibo\\\[code\]\\page\.tsx$" } |
  Select-Object -First 1
if($found){ $pageFile = $found.FullName }
if(-not $pageFile){ $pageFile = "src/app/recibo/[code]/page.tsx" }

$targetDir  = Split-Path -Parent $pageFile
$clientFile = Join-Path $targetDir "recibo-client.tsx"

$log += "## DIAG"
$log += ("API receipts: {0}" -f $apiReceipts)
$log += ("Recibo page : {0}" -f $pageFile)
$log += ("Recibo client: {0}" -f $clientFile)
$log += ("Exists page? {0}" -f (Test-Path -LiteralPath $pageFile))
$log += ("Exists client? {0}" -f (Test-Path -LiteralPath $clientFile))
$log += ""

# BACKUP
$log += "## PATCH (backup)"
$log += ("Backup API: {0}" -f (BackupFile $apiReceipts))
if(Test-Path -LiteralPath $pageFile){ $log += ("Backup page: {0}" -f (BackupFile $pageFile)) }
if(Test-Path -LiteralPath $clientFile){ $log += ("Backup client: {0}" -f (BackupFile $clientFile)) }
$log += ""

# PATCH API (NÃO usa @' ... '@ aqui dentro; só @" ... "@)
$apiTs = @"
import { NextResponse } from "next/server";
import { Prisma, PrismaClient } from "@prisma/client";
import crypto from "crypto";

export const runtime = "nodejs";

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
  if (found.fieldNames.includes("request")) include.request = true;
  if (found.fieldNames.includes("pickupRequest")) include.pickupRequest = true;
  return include;
}
function getCodeField(found: { fieldNames: string[] }) {
  if (found.fieldNames.includes("shareCode")) return "shareCode";
  if (found.fieldNames.includes("code")) return "code";
  return null;
}
function getPublicField(found: { fieldNames: string[] }) {
  if (found.fieldNames.includes("public")) return "public";
  if (found.fieldNames.includes("isPublic")) return "isPublic";
  return null;
}
function pickReceiptData(found: { fieldNames: string[] }, body: any, code: string) {
  const data: Record<string, any> = {};
  if (found.fieldNames.includes("summary")) data.summary = body.summary ?? null;
  if (found.fieldNames.includes("items")) data.items = body.items ?? null;
  if (found.fieldNames.includes("operator")) data.operator = body.operator ?? null;

  const pubField = getPublicField(found);
  if (pubField) data[pubField] = !!body.public;

  const codeField = getCodeField(found);
  if (codeField) data[codeField] = code;

  return data;
}
function pickupDoneUpdate(found: { fieldNames: string[]; fields: any[] }) {
  if (!found.fieldNames.includes("status")) return {};
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
    try { return await delegate.findUnique({ where: { [codeField]: code }, include: receiptInclude(found) }); } catch {}
  }
  if (codeField && typeof delegate.findFirst === "function") {
    try { return await delegate.findFirst({ where: { [codeField]: code }, include: receiptInclude(found) }); } catch {}
  }

  if (typeof delegate.findUnique === "function") {
    try { return await delegate.findUnique({ where: { id: code }, include: receiptInclude(found) }); } catch {}
  }
  if (typeof delegate.findFirst === "function") {
    try { return await delegate.findFirst({ where: { id: code }, include: receiptInclude(found) }); } catch {}
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
      return NextResponse.json({ ok: true, receipt });
    }

    const args: any = { include: receiptInclude(found), take: 200 };
    if (found.fieldNames.includes("createdAt")) args.orderBy = { createdAt: "desc" };
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

    const hasRequestIdField = receiptFound.fieldNames.includes("requestId");
    const requestIdField = receiptFound.fields.find((f: any) => f.name === "requestId");
    const requestIdUnique = !!requestIdField?.isUnique;

    const dataBase = pickReceiptData(receiptFound, body, code);

    const createData: any = { ...dataBase };
    if (hasRequestIdField) createData.requestId = requestId;
    if (relationField) createData[relationField] = { connect: { id: requestId } };

    let existing: any = null;

    if (hasRequestIdField) {
      try { existing = await prismaAny[receiptFound.key].findUnique!({ where: { requestId } }); } catch {}
      if (!existing) {
        try { existing = await prismaAny[receiptFound.key].findFirst!({ where: { requestId } }); } catch {}
      }
    }

    if (!existing && relationField) {
      try { existing = await prismaAny[receiptFound.key].findFirst!({ where: { [relationField]: { id: requestId } } }); } catch {}
    }

    let receipt: any = null;

    if (existing) {
      receipt = await prismaAny[receiptFound.key].update!({ where: { id: existing.id }, data: { ...dataBase }, include: receiptInclude(receiptFound) });
    } else if (requestIdUnique && hasRequestIdField) {
      receipt = await prismaAny[receiptFound.key].upsert!({ where: { requestId }, update: { ...dataBase }, create: createData, include: receiptInclude(receiptFound) });
    } else {
      receipt = await prismaAny[receiptFound.key].create!({ data: createData, include: receiptInclude(receiptFound) });
    }

    const upd = pickupDoneUpdate(pickupFound);
    if (Object.keys(upd).length) {
      try { await prismaAny[pickupFound.key].update!({ where: { id: requestId }, data: upd }); } catch {}
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
"@

WriteUtf8NoBom $apiReceipts $apiTs
$log += "- OK: /api/receipts: GET ?code=... + PATCH (public) + POST (emitir)"
$log += ""

# PATCH UI
EnsureDir $targetDir

$pageTsx = @"
import Link from "next/link";
import ReciboClient from "./recibo-client";

export const runtime = "nodejs";

export default async function ReciboPage({ params }: { params: any }) {
  const p = await Promise.resolve(params);
  const code = p?.code as string;

  return (
    <main className="p-4 max-w-3xl mx-auto space-y-4">
      <header className="space-y-2">
        <div className="flex items-center justify-between gap-3 flex-wrap">
          <h1 className="text-2xl font-bold">Recibo ECO</h1>
          <Link className="underline text-sm" href="/recibos">← Voltar</Link>
        </div>
        <p className="text-xs opacity-70 break-all">code: {code}</p>
      </header>

      <ReciboClient code={code} />
    </main>
  );
}
"@

$clientTsx = @"
"use client";

import Link from "next/link";
import { useEffect, useState } from "react";

function prettify(v: any) {
  try { return JSON.stringify(v, null, 2); } catch { return String(v); }
}

export default function ReciboClient({ code }: { code: string }) {
  const [loading, setLoading] = useState(true);
  const [receipt, setReceipt] = useState<any>(null);
  const [err, setErr] = useState<string | null>(null);

  const [toggling, setToggling] = useState(false);
  const [toggleErr, setToggleErr] = useState<string | null>(null);

  async function load() {
    setLoading(true);
    setErr(null);
    try {
      const res = await fetch("/api/receipts?code=" + encodeURIComponent(code), { cache: "no-store" });
      const txt = await res.text();
      let json: any = null;
      try { json = JSON.parse(txt); } catch { json = { raw: txt }; }

      if (!res.ok) throw new Error(json?.error ?? ("GET /api/receipts?code falhou (" + res.status + ")"));
      setReceipt(json?.receipt ?? null);
    } catch (e: any) {
      setErr(e?.message ?? String(e));
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { if (code) load(); }, [code]);

  async function copyLink() {
    try {
      await navigator.clipboard.writeText(window.location.href);
      alert("Link copiado ✅");
    } catch {
      alert("Não consegui copiar automaticamente. Copie manualmente da barra do navegador.");
    }
  }

  function waHref() {
    const link = window.location.href;
    const text = "Recibo ECO: " + link;
    return "https://wa.me/?text=" + encodeURIComponent(text);
  }

  async function share() {
    const link = window.location.href;
    const payload: any = { title: "Recibo ECO", text: "Recibo ECO", url: link };
    if ((navigator as any).share) {
      try { await (navigator as any).share(payload); return; } catch {}
    }
    await copyLink();
  }

  async function togglePublic() {
    setToggling(true);
    setToggleErr(null);
    try {
      const current = !!(receipt?.public ?? receipt?.isPublic);
      const next = !current;

      const res = await fetch("/api/receipts", {
        method: "PATCH",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ code, public: next }),
      });

      const txt = await res.text();
      let json: any = null;
      try { json = JSON.parse(txt); } catch { json = { raw: txt }; }

      if (!res.ok) throw new Error(json?.error ?? ("PATCH /api/receipts falhou (" + res.status + ")"));
      setReceipt(json?.receipt ?? receipt);
      await load();
    } catch (e: any) {
      setToggleErr(e?.message ?? String(e));
    } finally {
      setToggling(false);
    }
  }

  const isPublic = !!(receipt?.public ?? receipt?.isPublic);

  return (
    <section className="space-y-4">
      <div className="rounded border p-3 space-y-3">
        <div className="flex items-center justify-between gap-2 flex-wrap">
          <h2 className="font-semibold">Status</h2>
          <span className={"text-xs px-2 py-1 rounded border " + (isPublic ? "bg-green-50" : "bg-yellow-50")}>
            {isPublic ? "Público" : "Privado"}
          </span>
        </div>

        <div className="flex flex-wrap gap-2">
          <button className="px-3 py-2 rounded border" onClick={copyLink}>Copiar link</button>
          <a className="px-3 py-2 rounded border" href={waHref()} target="_blank" rel="noreferrer">WhatsApp</a>
          <button className="px-3 py-2 rounded border" onClick={share}>Compartilhar</button>

          <button
            className="px-3 py-2 rounded bg-black text-white disabled:opacity-50"
            onClick={togglePublic}
            disabled={toggling || loading || !receipt}
            title="MVP: sem autenticação ainda"
          >
            {toggling ? "Atualizando…" : (isPublic ? "Tornar privado" : "Tornar público")}
          </button>

          <Link className="px-3 py-2 rounded border" href="/recibos">Voltar</Link>
        </div>

        {toggleErr && (
          <div className="text-sm">
            <p className="font-semibold text-red-600">Erro ao alternar público/privado</p>
            <pre className="whitespace-pre-wrap break-words">{toggleErr}</pre>
          </div>
        )}

        <p className="text-xs opacity-60">MVP: depois a gente trava isso por operador.</p>
      </div>

      <div className="rounded border p-3">
        <h2 className="font-semibold mb-2">Recibo</h2>

        {loading && <p className="text-sm opacity-70">Carregando…</p>}
        {err && (
          <div className="text-sm">
            <p className="font-semibold text-red-600">Erro ao carregar recibo</p>
            <pre className="whitespace-pre-wrap break-words">{err}</pre>
          </div>
        )}

        {!loading && !err && receipt && (
          <pre className="text-xs whitespace-pre-wrap break-words max-h-96 overflow-auto bg-black/5 p-2 rounded">
            {prettify(receipt)}
          </pre>
        )}

        {!loading && !err && !receipt && (
          <p className="text-sm opacity-70">Não encontrei recibo para esse code.</p>
        )}
      </div>
    </section>
  );
}
"@

WriteUtf8NoBom $pageFile $pageTsx
WriteUtf8NoBom $clientFile $clientTsx

$log += "- OK: /recibo/[code] refeito com toggle Público/Privado + share"
$log += ""

# REGISTRO
$log += "## Próximos passos"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1"
$log += "3) Abra /recibos -> Ver -> /recibo/[code] e teste o toggle Público/Privado"
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 10e2 aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) Abra /recibos -> Ver -> /recibo/[code] e teste o toggle Público/Privado" -ForegroundColor Yellow