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

function ReadText([string]$p){
  if(!(Test-Path -LiteralPath $p)){ return "" }
  return (Get-Content -LiteralPath $p -Raw)
}

$rep = NewReport "eco-step-05-emitir-recibo-por-pedido"
$log = @()
$log += "# ECO — STEP 05 — Emitir Recibo por Pedido"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ("Node: {0}" -f (node -v 2>$null))
$log += ("npm : {0}" -f (npm -v 2>$null))
$log += ""

# =========================
# DIAG
# =========================
$schemaPath = "prisma/schema.prisma"
if(Test-Path -LiteralPath $schemaPath){
  $schema = Get-Content -LiteralPath $schemaPath -Raw
  $hasReceipt  = ($schema -match 'model\s+Receipt\s*\{')
  $hasEcoReceipt = ($schema -match 'model\s+EcoReceipt\s*\{')
  $log += "## DIAG"
  $log += "- schema tem Receipt? **$hasReceipt**"
  $log += "- schema tem EcoReceipt? **$hasEcoReceipt**"
  $log += ""
} else {
  $log += "## DIAG"
  $log += "- schema não encontrado (skip)"
  $log += ""
}

# =========================
# PATCH 1 — API /api/receipts (GET + POST emitir)
# =========================
$apiReceipts = "src/app/api/receipts/route.ts"
EnsureDir (Split-Path -Parent $apiReceipts)

if(Test-Path -LiteralPath $apiReceipts){
  $b = BackupFile $apiReceipts
  if($b){ $log += ("- Backup {0}: {1}" -f $apiReceipts, $b) }
}

WriteUtf8NoBom $apiReceipts @"
import { NextResponse } from "next/server";
import { Prisma, PrismaClient } from "@prisma/client";
import crypto from "crypto";

export const runtime = "nodejs";

const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };
const prisma = globalForPrisma.prisma ?? new PrismaClient();
if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = prisma;

function lowerCamel(s: string) {
  return s ? s.charAt(0).toLowerCase() + s.slice(1) : s;
}

function uniq<T>(arr: T[]) {
  return Array.from(new Set(arr));
}

function genShareCode() {
  // 10 hex chars (curto, ok p/ dev). Pode trocar depois por algo mais “humano”.
  return crypto.randomBytes(8).toString("hex").slice(0, 10);
}

function getModelNames() {
  return Prisma.dmmf.datamodel.models.map((m) => m.name);
}

function getModel(name: string) {
  return Prisma.dmmf.datamodel.models.find((m) => m.name === name) ?? null;
}

function getDelegateKeyForModel(modelName: string) {
  const prismaAny = prisma as unknown as Record<string, any>;
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
  // Preferir Receipt primeiro (porque já existia no teu schema antes do EcoReceipt aparecer)
  const preferred = uniq(["Receipt", "EcoReceipt", ...receiptModels]);

  const tried: string[] = [];
  for (const modelName of preferred) {
    const key = getDelegateKeyForModel(modelName);
    tried.push(`${modelName} -> ${key ?? "null"}`);
    if (!key) continue;

    const prismaAny = prisma as unknown as Record<string, any>;
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
  const modelNames = getModelNames();
  const preferred = ["PickupRequest"];
  const tried: string[] = [];

  for (const modelName of preferred) {
    const key = getDelegateKeyForModel(modelName);
    tried.push(`${modelName} -> ${key ?? "null"}`);
    if (!key) continue;

    const prismaAny = prisma as unknown as Record<string, any>;
    const d = prismaAny[key];
    if (d && typeof d.findUnique === "function") {
      const model = getModel(modelName);
      const fields = model?.fields ?? [];
      return { key, modelName, fields, fieldNames: fields.map((f) => f.name), tried, modelNames };
    }
  }

  return { key: null as string | null, modelName: null as string | null, fields: [], fieldNames: [], tried, modelNames };
}

function receiptInclude(found: { fieldNames: string[] }) {
  const include: any = {};
  if (found.fieldNames.includes("request")) include.request = true;
  if (found.fieldNames.includes("pickupRequest")) include.pickupRequest = true;
  return include;
}

function pickupUpdateDone(found: { fieldNames: string[] }) {
  if (found.fieldNames.includes("status")) {
    return { status: "DONE" };
  }
  return {};
}

export async function GET() {
  try {
    const found = findReceiptModel();
    if (!found.key) {
      return NextResponse.json(
        { error: "receipt_delegate_missing", modelNames: found.modelNames, tried: found.tried },
        { status: 500 }
      );
    }

    const prismaAny = prisma as unknown as Record<string, any>;
    const items = await prismaAny[found.key].findMany({
      include: receiptInclude(found),
      orderBy: { createdAt: "desc" },
      take: 200,
    });

    return NextResponse.json({ delegate: found.key, model: found.modelName, items });
  } catch (e) {
    const detail = e instanceof Error ? e.message : String(e);
    return NextResponse.json({ error: "receipts_list_failed", detail }, { status: 500 });
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
    if (!requestId) {
      return NextResponse.json({ error: "missing_requestId" }, { status: 400 });
    }

    const receiptFound = findReceiptModel();
    if (!receiptFound.key || !receiptFound.modelName) {
      return NextResponse.json(
        { error: "receipt_delegate_missing", modelNames: receiptFound.modelNames, tried: receiptFound.tried },
        { status: 500 }
      );
    }

    const pickupFound = findPickupModel();
    if (!pickupFound.key) {
      return NextResponse.json(
        { error: "pickup_delegate_missing", modelNames: pickupFound.modelNames, tried: pickupFound.tried },
        { status: 500 }
      );
    }

    const prismaAny = prisma as unknown as Record<string, any>;

    // garantir que o pedido existe
    const reqItem = await prismaAny[pickupFound.key].findUnique({ where: { id: requestId } });
    if (!reqItem) return NextResponse.json({ error: "pickup_not_found", requestId }, { status: 404 });

    const shareCode = (body.shareCode && body.shareCode.trim()) ? body.shareCode.trim() : genShareCode();

    // descobrir relação do recibo -> pedido
    const relationField =
      receiptFound.fields.find((f: any) => f.kind === "object" && f.type === "PickupRequest")?.name ?? null;

    const hasRequestIdField = receiptFound.fieldNames.includes("requestId");
    const requestIdField = receiptFound.fields.find((f: any) => f.name === "requestId");
    const requestIdUnique = !!requestIdField?.isUnique;

    const dataBase: any = {
      summary: body.summary ?? null,
      items: body.items ?? null,
      operator: body.operator ?? null,
      public: !!body.public,
      shareCode,
    };

    // montar create payload
    const createData: any = { ...dataBase };
    if (hasRequestIdField) createData.requestId = requestId;
    if (relationField) createData[relationField] = { connect: { id: requestId } };

    // primeiro tenta achar existente por requestId (se existir campo)
    let existing: any = null;
    if (hasRequestIdField) {
      if (typeof prismaAny[receiptFound.key].findUnique === "function") {
        try { existing = await prismaAny[receiptFound.key].findUnique({ where: { requestId } }); } catch {}
      }
      if (!existing && typeof prismaAny[receiptFound.key].findFirst === "function") {
        try { existing = await prismaAny[receiptFound.key].findFirst({ where: { requestId } }); } catch {}
      }
    }

    // se não achou por requestId, tenta por relação (se tiver)
    if (!existing && relationField && typeof prismaAny[receiptFound.key].findFirst === "function") {
      try {
        existing = await prismaAny[receiptFound.key].findFirst({ where: { [relationField]: { id: requestId } } });
      } catch {}
    }

    let receipt: any = null;

    if (existing && typeof prismaAny[receiptFound.key].update === "function") {
      receipt = await prismaAny[receiptFound.key].update({
        where: { id: existing.id },
        data: { ...dataBase },
        include: receiptInclude(receiptFound),
      });
    } else if (requestIdUnique && typeof prismaAny[receiptFound.key].upsert === "function" && hasRequestIdField) {
      receipt = await prismaAny[receiptFound.key].upsert({
        where: { requestId },
        update: { ...dataBase },
        create: createData,
        include: receiptInclude(receiptFound),
      });
    } else if (typeof prismaAny[receiptFound.key].create === "function") {
      receipt = await prismaAny[receiptFound.key].create({
        data: createData,
        include: receiptInclude(receiptFound),
      });
    } else {
      return NextResponse.json({ error: "receipt_delegate_no_create", delegate: receiptFound.key }, { status: 500 });
    }

    // marcar pedido como DONE (se tiver status)
    if (typeof prismaAny[pickupFound.key].update === "function") {
      const upd = pickupUpdateDone(pickupFound);
      if (Object.keys(upd).length) {
        await prismaAny[pickupFound.key].update({ where: { id: requestId }, data: upd });
      }
    }

    return NextResponse.json({
      ok: true,
      receipt,
      requestId,
      receiptDelegate: receiptFound.key,
      receiptModel: receiptFound.modelName,
      pickupDelegate: pickupFound.key,
    });
  } catch (e) {
    const detail = e instanceof Error ? e.message : String(e);
    return NextResponse.json({ error: "receipt_issue_failed", detail }, { status: 500 });
  }
}
"@

$log += "## PATCH"
$log += "- OK: src/app/api/receipts/route.ts atualizado (GET + POST emitir)"
$log += ""

# =========================
# PATCH 2 — Página operador: /pedidos/fechar/[id]
# =========================
$dirFechar = "src/app/pedidos/fechar/[id]"
EnsureDir $dirFechar

$page = Join-Path $dirFechar "page.tsx"
$client = Join-Path $dirFechar "fechar-client.tsx"

if(Test-Path -LiteralPath $page){
  $b = BackupFile $page
  if($b){ $log += ("- Backup {0}: {1}" -f $page, $b) }
}
if(Test-Path -LiteralPath $client){
  $b = BackupFile $client
  if($b){ $log += ("- Backup {0}: {1}" -f $client, $b) }
}

WriteUtf8NoBom $page @"
import FecharPedidoClient from ""./fechar-client"";

type Params = { id: string } | Promise<{ id: string }>;

export default async function Page({ params }: { params: Params }) {
  const { id } = await Promise.resolve(params as any);
  return <FecharPedidoClient id={id} />;
}
"@

WriteUtf8NoBom $client @"
""use client"";

import { useEffect, useMemo, useState } from ""react"";

type AnyObj = Record<string, any>;

export default function FecharPedidoClient({ id }: { id: string }) {
  const [loading, setLoading] = useState(true);
  const [reqItem, setReqItem] = useState<AnyObj | null>(null);
  const [err, setErr] = useState<string | null>(null);

  const [summary, setSummary] = useState<string>("""");
  const [items, setItems] = useState<string>("""");
  const [operator, setOperator] = useState<string>("""");
  const [isPublic, setIsPublic] = useState<boolean>(false);

  const [issuing, setIssuing] = useState(false);
  const [issued, setIssued] = useState<AnyObj | null>(null);

  const shareCode = useMemo(() => {
    const r = issued?.receipt;
    if (!r) return null;
    return r.shareCode ?? r.code ?? r.share_code ?? null;
  }, [issued]);

  useEffect(() => {
    let alive = true;
    (async () => {
      try {
        setLoading(true);
        setErr(null);
        const res = await fetch(`/api/pickup-requests/${id}`, { cache: ""no-store"" });
        const json = (await res.json()) as any;
        const item = (json && typeof json === ""object"" && ""item"" in json) ? json.item : json;
        if (alive) setReqItem(item ?? null);
      } catch (e: any) {
        if (alive) setErr(e?.message ?? String(e));
      } finally {
        if (alive) setLoading(false);
      }
    })();
    return () => { alive = false; };
  }, [id]);

  async function issue() {
    try {
      setIssuing(true);
      setIssued(null);
      setErr(null);

      const body = {
        requestId: id,
        summary: summary || null,
        items: items || null,
        operator: operator || null,
        public: isPublic,
      };

      const res = await fetch(`/api/receipts`, {
        method: ""POST"",
        headers: { ""Content-Type"": ""application/json"" },
        body: JSON.stringify(body),
      });

      const json = await res.json();
      if (!res.ok) throw new Error(JSON.stringify(json));

      setIssued(json);
    } catch (e: any) {
      setErr(e?.message ?? String(e));
    } finally {
      setIssuing(false);
    }
  }

  function copy(text: string) {
    navigator.clipboard?.writeText(text).catch(() => {});
  }

  return (
    <div style={{ padding: 16, maxWidth: 860, margin: ""0 auto"" }}>
      <h1 style={{ fontSize: 22, fontWeight: 800 }}>Fechar pedido + emitir recibo</h1>
      <p style={{ opacity: 0.8, marginTop: 6 }}>
        Pedido: <b>{id}</b>
      </p>

      {loading && <p>Carregando pedido…</p>}
      {err && (
        <pre style={{ whiteSpace: ""pre-wrap"", background: ""#111"", color: ""#fff"", padding: 12, borderRadius: 8 }}>
          {err}
        </pre>
      )}

      {reqItem && (
        <div style={{ border: ""1px solid #333"", borderRadius: 10, padding: 12, marginTop: 12 }}>
          <div style={{ fontWeight: 700, marginBottom: 8 }}>Resumo do pedido</div>
          <pre style={{ whiteSpace: ""pre-wrap"", margin: 0, opacity: 0.9 }}>
            {JSON.stringify(reqItem, null, 2)}
          </pre>
        </div>
      )}

      <div style={{ display: ""grid"", gap: 10, marginTop: 14 }}>
        <label>
          <div style={{ fontWeight: 700 }}>Resumo do recibo</div>
          <input
            value={summary}
            onChange={(e) => setSummary(e.target.value)}
            placeholder=""ex.: Coleta no bairro X, 2 sacos, óleo 1L…""
            style={{ width: ""100%"", padding: 10, borderRadius: 8, border: ""1px solid #333"" }}
          />
        </label>

        <label>
          <div style={{ fontWeight: 700 }}>Itens (livre)</div>
          <textarea
            value={items}
            onChange={(e) => setItems(e.target.value)}
            placeholder=""ex.: Papel: 1 saco | Plástico: 1 saco | Óleo: 1L""
            rows={4}
            style={{ width: ""100%"", padding: 10, borderRadius: 8, border: ""1px solid #333"" }}
          />
        </label>

        <label>
          <div style={{ fontWeight: 700 }}>Operador (opcional)</div>
          <input
            value={operator}
            onChange={(e) => setOperator(e.target.value)}
            placeholder=""ex.: Cooperativa X / Fulano""
            style={{ width: ""100%"", padding: 10, borderRadius: 8, border: ""1px solid #333"" }}
          />
        </label>

        <label style={{ display: ""flex"", alignItems: ""center"", gap: 10 }}>
          <input type=""checkbox"" checked={isPublic} onChange={(e) => setIsPublic(e.target.checked)} />
          <div><b>Público</b> (libera link compartilhável)</div>
        </label>

        <button
          onClick={issue}
          disabled={issuing}
          style={{
            padding: 12,
            borderRadius: 10,
            border: ""1px solid #333"",
            fontWeight: 900,
            cursor: issuing ? ""not-allowed"" : ""pointer"",
          }}
        >
          {issuing ? ""Emitindo…"" : ""Gerar Recibo""}
        </button>
      </div>

      {issued && (
        <div style={{ border: ""1px solid #333"", borderRadius: 10, padding: 12, marginTop: 12 }}>
          <div style={{ fontWeight: 800, marginBottom: 8 }}>Recibo emitido ✅</div>

          {shareCode && (
            <div style={{ display: ""grid"", gap: 8, marginBottom: 10 }}>
              <div>
                Link:{" "}
                <a href={`/recibo/${shareCode}`} target=""_blank"" rel=""noreferrer"">
                  /recibo/{shareCode}
                </a>
              </div>
              <div style={{ display: ""flex"", gap: 8, flexWrap: ""wrap"" }}>
                <button onClick={() => copy(`${location.origin}/recibo/${shareCode}`)} style={{ padding: 10, borderRadius: 8, border: ""1px solid #333"" }}>
                  Copiar link
                </button>
                <button onClick={() => copy(shareCode)} style={{ padding: 10, borderRadius: 8, border: ""1px solid #333"" }}>
                  Copiar código
                </button>
              </div>
            </div>
          )}

          <pre style={{ whiteSpace: ""pre-wrap"", margin: 0, opacity: 0.9 }}>
            {JSON.stringify(issued, null, 2)}
          </pre>
        </div>
      )}
    </div>
  );
}
"@

$log += "- OK: criada página /pedidos/fechar/[id]"
$log += ""

# =========================
# VERIFY (leve)
# =========================
$log += "## VERIFY"
$log += "- Arquivos existem? apiReceipts=$(Test-Path -LiteralPath $apiReceipts) | fecharPage=$(Test-Path -LiteralPath $page) | fecharClient=$(Test-Path -LiteralPath $client)"
$log += ""
$log += "## Próximos passos"
$log += "1) Reinicie o dev: npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1"
$log += "3) Teste: abra /pedidos e pegue um id, ou acesse direto /pedidos/fechar/SEU_ID"

WriteUtf8NoBom $rep ($log -join "`n")
Write-Host ("✅ STEP 05 aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) Abra /pedidos/fechar/[id] (id de um pedido existente)" -ForegroundColor Yellow