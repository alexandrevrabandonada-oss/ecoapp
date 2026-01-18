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

$rep = NewReport "eco-step-10-recibo-public-toggle-qrcode"
$log = @()
$log += "# ECO — STEP 10 — Toggle público no recibo + QR Code"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

$apiFile  = "src/app/api/receipts/[code]/route.ts"
$pageFile = "src/app/recibo/[code]/page.tsx"

if(!(Test-Path -LiteralPath $apiFile)){ throw "Não achei $apiFile (STEP 09 deveria ter criado)." }
if(!(Test-Path -LiteralPath $pageFile)){ throw "Não achei $pageFile (STEP 09 deveria ter criado)." }

$log += "## DIAG (antes)"
$log += ("api exists?  " + (Test-Path -LiteralPath $apiFile))
$log += ("page exists? " + (Test-Path -LiteralPath $pageFile))
$log += ""

$log += "## BACKUPS"
$log += ("Backup api : " + (BackupFile $apiFile))
$log += ("Backup page: " + (BackupFile $pageFile))
$log += ""

# --- PATCH 1: API PATCH /api/receipts/[code] ---
# Vamos reescrever o arquivo inteiro mantendo o GET e adicionando PATCH.
$apiLines = @(
'import { NextResponse } from "next/server";',
'import { Prisma, PrismaClient } from "@prisma/client";',
'',
'export const runtime = "nodejs";',
'',
'const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };',
'const prisma = globalForPrisma.prisma ?? new PrismaClient();',
'if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = prisma;',
'',
'type AnyDelegate = {',
'  findFirst?: (args?: any) => Promise<any>;',
'  update?: (args?: any) => Promise<any>;',
'};',
'',
'function lowerCamel(s: string) {',
'  return s ? s.charAt(0).toLowerCase() + s.slice(1) : s;',
'}',
'',
'function getModelNames() {',
'  return Prisma.dmmf.datamodel.models.map((m) => m.name);',
'}',
'',
'function getModel(name: string) {',
'  return Prisma.dmmf.datamodel.models.find((m) => m.name === name) ?? null;',
'}',
'',
'function getDelegateKeyForModel(modelName: string) {',
'  const prismaAny = prisma as unknown as Record<string, AnyDelegate>;',
'  const keys = [lowerCamel(modelName), modelName];',
'  for (const key of keys) {',
'    const d = prismaAny[key];',
'    if (d) return key;',
'  }',
'  return null;',
'}',
'',
'function findReceiptModel() {',
'  const modelNames = getModelNames();',
'  const receiptModels = modelNames.filter((n) => /(receipt|recibo)/i.test(n));',
'  const preferred = Array.from(new Set(["Receipt", "EcoReceipt", ...receiptModels]));',
'  const tried: string[] = [];',
'',
'  for (const modelName of preferred) {',
'    const key = getDelegateKeyForModel(modelName);',
'    tried.push(modelName + " -> " + (key ?? "null"));',
'    if (!key) continue;',
'',
'    const prismaAny = prisma as unknown as Record<string, AnyDelegate>;',
'    const d = prismaAny[key];',
'    if (d && typeof d.findFirst === "function") {',
'      const model = getModel(modelName);',
'      const fields = model?.fields ?? [];',
'      return { key, modelName, fields, fieldNames: fields.map((f) => f.name), tried, modelNames };',
'    }',
'  }',
'',
'  return { key: null as string | null, modelName: null as string | null, fields: [], fieldNames: [], tried, modelNames };',
'}',
'',
'function receiptInclude(found: { fieldNames: string[] }) {',
'  const include: Record<string, boolean> = {};',
'  if (found.fieldNames.includes("request")) include.request = true;',
'  if (found.fieldNames.includes("pickupRequest")) include.pickupRequest = true;',
'  return include;',
'}',
'',
'function codeWhere(found: { fieldNames: string[] }, code: string) {',
'  const ors: any[] = [];',
'  if (found.fieldNames.includes("shareCode")) ors.push({ shareCode: code });',
'  if (found.fieldNames.includes("code")) ors.push({ code: code });',
'  if (found.fieldNames.includes("id")) ors.push({ id: code });',
'  return ors;',
'}',
'',
'export async function GET(_req: Request, ctx: any) {',
'  try {',
'    const code = String(ctx?.params?.code ?? "").trim();',
'    if (!code) return NextResponse.json({ error: "missing_code" }, { status: 400 });',
'',
'    const found = findReceiptModel();',
'    if (!found.key) {',
'      return NextResponse.json({ error: "receipt_delegate_missing", modelNames: found.modelNames, tried: found.tried }, { status: 500 });',
'    }',
'',
'    const prismaAny = prisma as unknown as Record<string, AnyDelegate>;',
'    const delegate = prismaAny[found.key];',
'',
'    const ors = codeWhere(found, code);',
'    if (!ors.length) {',
'      return NextResponse.json({ error: "no_code_fields", fieldNames: found.fieldNames }, { status: 500 });',
'    }',
'',
'    const item = await delegate.findFirst!({ where: { OR: ors }, include: receiptInclude(found) });',
'    if (!item) return NextResponse.json({ error: "not_found", code }, { status: 404 });',
'',
'    return NextResponse.json({ ok: true, delegate: found.key, model: found.modelName, item });',
'  } catch (e) {',
'    const detail = e instanceof Error ? e.message : String(e);',
'    return NextResponse.json({ error: "receipt_get_failed", detail }, { status: 500 });',
'  }',
'}',
'',
'type PatchBody = { public?: boolean };',
'',
'export async function PATCH(req: Request, ctx: any) {',
'  try {',
'    const code = String(ctx?.params?.code ?? "").trim();',
'    if (!code) return NextResponse.json({ error: "missing_code" }, { status: 400 });',
'',
'    const body = (await req.json()) as PatchBody;',
'    if (typeof body?.public !== "boolean") {',
'      return NextResponse.json({ error: "missing_public_boolean" }, { status: 400 });',
'    }',
'',
'    const found = findReceiptModel();',
'    if (!found.key) {',
'      return NextResponse.json({ error: "receipt_delegate_missing", modelNames: found.modelNames, tried: found.tried }, { status: 500 });',
'    }',
'',
'    if (!found.fieldNames.includes("public")) {',
'      return NextResponse.json({ error: "field_public_not_supported", fieldNames: found.fieldNames }, { status: 400 });',
'    }',
'',
'    const prismaAny = prisma as unknown as Record<string, AnyDelegate>;',
'    const delegate = prismaAny[found.key];',
'',
'    const ors = codeWhere(found, code);',
'    if (!ors.length) {',
'      return NextResponse.json({ error: "no_code_fields", fieldNames: found.fieldNames }, { status: 500 });',
'    }',
'',
'    const existing = await delegate.findFirst!({ where: { OR: ors } });',
'    if (!existing) return NextResponse.json({ error: "not_found", code }, { status: 404 });',
'',
'    if (typeof delegate.update !== "function") {',
'      return NextResponse.json({ error: "delegate_update_missing", delegate: found.key }, { status: 500 });',
'    }',
'',
'    const updated = await delegate.update!({',
'      where: { id: existing.id },',
'      data: { public: body.public },',
'      include: receiptInclude(found),',
'    });',
'',
'    return NextResponse.json({ ok: true, item: updated });',
'  } catch (e) {',
'    const detail = e instanceof Error ? e.message : String(e);',
'    return NextResponse.json({ error: "receipt_patch_failed", detail }, { status: 500 });',
'  }',
'}'
) -join "`n"

WriteUtf8NoBom $apiFile $apiLines
$log += "- OK: $apiFile reescrito com GET+PATCH (toggle public)"

# --- PATCH 2: Page adiciona QR + botão toggle ---
# Página atual é server; vamos ajustar pra:
# - buscar item
# - derivar public atual
# - renderizar QR (img svg)
# - renderizar botões que chamam PATCH via fetch no client (inline script client component simples)

$pageLines = @(
'import Link from "next/link";',
'import { headers } from "next/headers";',
'import ReciboClient from "./recibo-client";',
'',
'export const runtime = "nodejs";',
'',
'async function originFromHeaders() {',
'  const h = await headers();',
'  const proto = h.get("x-forwarded-proto") ?? "http";',
'  const host = h.get("x-forwarded-host") ?? h.get("host") ?? "localhost:3000";',
'  return proto + "://" + host;',
'}',
'',
'function prettify(v: any) {',
'  try { return JSON.stringify(v, null, 2); } catch { return String(v); }',
'}',
'',
'function getCodeFromItem(item: any) {',
'  return item?.shareCode ?? item?.code ?? item?.id ?? "";',
'}',
'',
'export default async function ReciboPage({ params }: { params: any }) {',
'  const p = await Promise.resolve(params);',
'  const code = String(p?.code ?? "");',
'  const origin = await originFromHeaders();',
'',
'  const apiUrl = origin + "/api/receipts/" + encodeURIComponent(code);',
'  const res = await fetch(apiUrl, { cache: "no-store" });',
'  const txt = await res.text();',
'  let json: any = null;',
'  try { json = JSON.parse(txt); } catch { json = { raw: txt }; }',
'',
'  if (!res.ok) {',
'    return (',
'      <main className="p-4 max-w-3xl mx-auto space-y-4">',
'        <header className="space-y-2">',
'          <h1 className="text-2xl font-bold">Recibo</h1>',
'          <div className="flex gap-3 flex-wrap">',
'            <Link className="underline" href="/recibos">← Voltar</Link>',
'            <span className="text-sm opacity-70">code: {code}</span>',
'          </div>',
'        </header>',
'        <div className="rounded border p-3">',
'          <p className="font-semibold text-red-600">Não consegui carregar o recibo</p>',
'          <pre className="text-xs whitespace-pre-wrap break-words">{prettify(json)}</pre>',
'        </div>',
'      </main>',
'    );',
'  }',
'',
'  const item = json?.item ?? null;',
'  const realCode = getCodeFromItem(item) || code;',
'  const isPublic = !!item?.public;',
'',
'  const pageUrl = origin + "/recibo/" + encodeURIComponent(realCode);',
'  const qr = "https://chart.googleapis.com/chart?cht=qr&chs=220x220&chld=L|0&choe=UTF-8&chl=" + encodeURIComponent(pageUrl);',
'',
'  return (',
'    <main className="p-4 max-w-3xl mx-auto space-y-4">',
'      <header className="space-y-2">',
'        <h1 className="text-2xl font-bold">Recibo ECO</h1>',
'        <div className="flex gap-3 flex-wrap items-center">',
'          <Link className="underline" href="/recibos">← Todos os recibos</Link>',
'          <span className="text-sm opacity-70">code: {realCode}</span>',
'          <span className={"text-xs px-2 py-1 rounded border " + (isPublic ? "bg-green-50" : "bg-yellow-50")}>',
'            {isPublic ? "PÚBLICO" : "PRIVADO"}',
'          </span>',
'        </div>',
'      </header>',
'',
'      <div className="rounded border p-3 space-y-3">',
'        <ReciboClient code={realCode} />',
'',
'        <form',
'          className="flex flex-wrap gap-2 items-center"',
'          action={async () => {',
'            "use server";',
'          }}',
'        >',
'          {/* botões client-side via inline */}',
'          <div id="__eco_public_toggle" data-code={realCode} data-public={isPublic ? "1" : "0"} />',
'        </form>',
'',
'        <div className="flex gap-4 items-center flex-wrap">',
'          <div className="rounded border p-2 bg-white">',
'            {/* QR via Google Chart (SVG/PNG) */}',
'            <img src={qr} alt="QR Code do recibo" width={220} height={220} />',
'          </div>',
'          <div className="text-xs opacity-70 max-w-sm">',
'            <p className="font-semibold">QR Code</p>',
'            <p>Aponte a câmera para abrir este recibo.</p>',
'            <p className="break-all mt-2">{pageUrl}</p>',
'          </div>',
'        </div>',
'      </div>',
'',
'      <div className="rounded border p-3">',
'        <h2 className="font-semibold mb-2">Detalhes</h2>',
'        <pre className="text-xs whitespace-pre-wrap break-words max-h-[520px] overflow-auto bg-black/5 p-2 rounded">',
'          {prettify(item)}',
'        </pre>',
'      </div>',
'',
'      {/* Script simples client-side para toggle */}',
'      <script',
'        dangerouslySetInnerHTML={{',
'          __html: `(() => {',
'            const el = document.getElementById("__eco_public_toggle");',
'            if (!el) return;',
'            const code = el.getAttribute("data-code");',
'            const isPublic = el.getAttribute("data-public") === "1";',
'',
'            const wrap = document.createElement("div");',
'            wrap.className = "flex flex-wrap gap-2 items-center";',
'',
'            const btn = document.createElement("button");',
'            btn.type = "button";',
'            btn.className = "px-3 py-2 rounded " + (isPublic ? "border" : "bg-black text-white");',
'            btn.textContent = isPublic ? "Tornar privado" : "Tornar público";',
'',
'            const msg = document.createElement("span");',
'            msg.className = "text-xs opacity-70";',
'            msg.textContent = "Atualiza o campo public (se o modelo suportar).";',
'',
'            btn.addEventListener("click", async () => {',
'              btn.disabled = true;',
'              btn.textContent = "Salvando...";',
'              try {',
'                const res = await fetch("/api/receipts/" + encodeURIComponent(code), {',
'                  method: "PATCH",',
'                  headers: { "content-type": "application/json" },',
'                  body: JSON.stringify({ public: !isPublic }),',
'                });',
'                const txt = await res.text();',
'                let json = null;',
'                try { json = JSON.parse(txt); } catch { json = { raw: txt }; }',
'                if (!res.ok) {',
'                  alert("Falhou: " + (json && (json.error || json.detail) ? (json.error || json.detail) : res.status));',
'                } else {',
'                  location.reload();',
'                }',
'              } catch (e) {',
'                alert("Erro: " + (e && e.message ? e.message : String(e)));',
'              } finally {',
'                btn.disabled = false;',
'              }',
'            });',
'',
'            wrap.appendChild(btn);',
'            wrap.appendChild(msg);',
'            el.replaceWith(wrap);',
'          })();`',
'        }}',
'      />',
'    </main>',
'  );',
'}'
) -join "`n"

WriteUtf8NoBom $pageFile $pageLines
$log += "- OK: $pageFile atualizado (badge público/privado + QR + toggle)"

$log += ""
$log += "## VERIFY"
$log += ("api exists?  " + (Test-Path -LiteralPath $apiFile))
$log += ("page exists? " + (Test-Path -LiteralPath $pageFile))
$log += ""

$log += "## Próximos passos"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1"
$log += "3) Abra /recibo/[code] e clique Tornar público/privado"
$log += "4) Verifique se o badge muda e se o QR abre o recibo"
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 10 aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) Abra /recibo/[code] e clique Tornar público/privado" -ForegroundColor Yellow
Write-Host "4) Teste QR Code abrindo o link do recibo" -ForegroundColor Yellow