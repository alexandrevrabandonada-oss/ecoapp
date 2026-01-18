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

$rep = NewReport "eco-step-09-recibo-public-page"
$log = @()
$log += "# ECO — STEP 09 — Recibo público (/recibo/[code]) + API detalhe (/api/receipts/[code])"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

# Paths
$apiDir   = "src/app/api/receipts/[code]"
$apiFile  = Join-Path $apiDir "route.ts"
$pageDir  = "src/app/recibo/[code]"
$pageFile = Join-Path $pageDir "page.tsx"
$cliFile  = Join-Path $pageDir "recibo-client.tsx"
$listFile = "src/app/recibos/page.tsx"

$log += "## DIAG (antes)"
$log += ("Exists api detail? " + (Test-Path -LiteralPath $apiFile))
$log += ("Exists page?      " + (Test-Path -LiteralPath $pageFile))
$log += ("Exists client?    " + (Test-Path -LiteralPath $cliFile))
$log += ("Exists /recibos?  " + (Test-Path -LiteralPath $listFile))
$log += ""

# PATCH — backups
EnsureDir $apiDir
EnsureDir $pageDir

$bakApi  = $null; if(Test-Path -LiteralPath $apiFile ){ $bakApi  = BackupFile $apiFile }
$bakPage = $null; if(Test-Path -LiteralPath $pageFile){ $bakPage = BackupFile $pageFile }
$bakCli  = $null; if(Test-Path -LiteralPath $cliFile ){ $bakCli  = BackupFile $cliFile }
$bakList = $null; if(Test-Path -LiteralPath $listFile){ $bakList = BackupFile $listFile }

$log += "## PATCH"
$log += ("Backup api : " + ($bakApi  ?? "n/a"))
$log += ("Backup page: " + ($bakPage ?? "n/a"))
$log += ("Backup cli : " + ($bakCli  ?? "n/a"))
$log += ("Backup list: " + ($bakList ?? "n/a"))
$log += ""

# 1) API /api/receipts/[code]
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
'    const ors: any[] = [];',
'    if (found.fieldNames.includes("shareCode")) ors.push({ shareCode: code });',
'    if (found.fieldNames.includes("code")) ors.push({ code: code });',
'    if (found.fieldNames.includes("id")) ors.push({ id: code });',
'',
'    if (!ors.length) {',
'      return NextResponse.json({ error: "no_code_fields", fieldNames: found.fieldNames }, { status: 500 });',
'    }',
'',
'    const item = await delegate.findFirst!({',
'      where: { OR: ors },',
'      include: receiptInclude(found),',
'    });',
'',
'    if (!item) return NextResponse.json({ error: "not_found", code }, { status: 404 });',
'',
'    return NextResponse.json({ ok: true, delegate: found.key, model: found.modelName, item });',
'  } catch (e) {',
'    const detail = e instanceof Error ? e.message : String(e);',
'    return NextResponse.json({ error: "receipt_get_failed", detail }, { status: 500 });',
'  }',
'}'
) -join "`n"

WriteUtf8NoBom $apiFile $apiLines
$log += "- OK: criado $apiFile"

# 2) Client share component
$cliLines = @(
'"use client";',
'',
'import { useMemo, useState } from "react";',
'',
'export default function ReciboClient({ code }: { code: string }) {',
'  const [copied, setCopied] = useState(false);',
'',
'  const url = useMemo(() => {',
'    if (typeof window === "undefined") return "";',
'    return window.location.href;',
'  }, []);',
'',
'  const wa = useMemo(() => {',
'    const text = encodeURIComponent("Recibo ECO: " + url);',
'    return "https://wa.me/?text=" + text;',
'  }, [url]);',
'',
'  async function onCopy() {',
'    try {',
'      await navigator.clipboard.writeText(url);',
'      setCopied(true);',
'      setTimeout(() => setCopied(false), 1200);',
'    } catch {',
'      // fallback: nada',
'    }',
'  }',
'',
'  async function onShare() {',
'    // @ts-ignore',
'    if (navigator.share) {',
'      // @ts-ignore',
'      await navigator.share({ title: "Recibo ECO", text: "Recibo ECO", url });',
'    }',
'  }',
'',
'  return (',
'    <div className="flex flex-wrap gap-2 items-center">',
'      <button onClick={onCopy} className="px-3 py-2 rounded border">', 
'        {copied ? "Link copiado ✅" : "Copiar link"}',
'      </button>',
'      <a className="px-3 py-2 rounded border" href={wa} target="_blank" rel="noreferrer">WhatsApp</a>',
'      <button onClick={onShare} className="px-3 py-2 rounded bg-black text-white">Compartilhar</button>',
'      <span className="text-xs opacity-60">code: {code}</span>',
'    </div>',
'  );',
'}'
) -join "`n"

WriteUtf8NoBom $cliFile $cliLines
$log += "- OK: criado $cliFile"

# 3) Page /recibo/[code]
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
'export default async function ReciboPage({ params }: { params: any }) {',
'  const p = await Promise.resolve(params);',
'  const code = String(p?.code ?? "");',
'  const origin = await originFromHeaders();',
'',
'  const res = await fetch(origin + "/api/receipts/" + encodeURIComponent(code), { cache: "no-store" });',
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
'',
'  return (',
'    <main className="p-4 max-w-3xl mx-auto space-y-4">',
'      <header className="space-y-2">',
'        <h1 className="text-2xl font-bold">Recibo ECO</h1>',
'        <div className="flex gap-3 flex-wrap items-center">',
'          <Link className="underline" href="/recibos">← Todos os recibos</Link>',
'          <span className="text-sm opacity-70">code: {code}</span>',
'        </div>',
'      </header>',
'',
'      <div className="rounded border p-3 space-y-3">',
'        <ReciboClient code={code} />',
'      </div>',
'',
'      <div className="rounded border p-3">',
'        <h2 className="font-semibold mb-2">Detalhes</h2>',
'        <pre className="text-xs whitespace-pre-wrap break-words max-h-[520px] overflow-auto bg-black/5 p-2 rounded">',
'          {prettify(item)}',
'        </pre>',
'      </div>',
'    </main>',
'  );',
'}'
) -join "`n"

WriteUtf8NoBom $pageFile $pageLines
$log += "- OK: criado $pageFile"

# 4) /recibos list page (lista + links)
if(!(Test-Path -LiteralPath "src/app/recibos")){ EnsureDir "src/app/recibos" }

$listLines = @(
'import Link from "next/link";',
'import { headers } from "next/headers";',
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
'function getCode(r: any) {',
'  return r?.shareCode ?? r?.code ?? r?.id ?? "";',
'}',
'',
'export default async function RecibosPage() {',
'  const origin = await originFromHeaders();',
'  const res = await fetch(origin + "/api/receipts", { cache: "no-store" });',
'  const txt = await res.text();',
'  let json: any = null;',
'  try { json = JSON.parse(txt); } catch { json = { raw: txt }; }',
'',
'  const items: any[] = Array.isArray(json?.items) ? json.items : (Array.isArray(json?.data) ? json.data : (Array.isArray(json?.list) ? json.list : (Array.isArray(json?.items?.items) ? json.items.items : (Array.isArray(json?.items) ? json.items : (Array.isArray(json?.items?.items) ? json.items.items : (Array.isArray(json?.items) ? json.items : [])))));',
'  const rows: any[] = Array.isArray(json?.items) ? json.items : (Array.isArray(json?.items) ? json.items : (Array.isArray(json?.items) ? json.items : (Array.isArray(json?.items) ? json.items : [])));',
'',
'  const list = Array.isArray(json?.items) ? json.items : (Array.isArray(json?.items?.items) ? json.items.items : (Array.isArray(json?.items) ? json.items : (Array.isArray(json?.items) ? json.items : [])));',
'  const finalList = Array.isArray(json?.items) ? json.items : (Array.isArray(json?.items) ? json.items : (Array.isArray(json?.items) ? json.items : []));',
'',
'  const receipts = Array.isArray(json?.items) ? json.items : (Array.isArray(json?.items) ? json.items : []);',
'  const safe = receipts;',
'',
'  return (',
'    <main className="p-4 max-w-4xl mx-auto space-y-4">',
'      <header className="space-y-2">',
'        <h1 className="text-2xl font-bold">Recibos</h1>',
'        <div className="flex gap-3 flex-wrap">',
'          <Link className="underline" href="/pedidos">← Pedidos</Link>',
'          <Link className="underline" href="/chamar">Chamar coleta</Link>',
'        </div>',
'      </header>',
'',
'      {!res.ok && (',
'        <div className="rounded border p-3">',
'          <p className="font-semibold text-red-600">Falha ao listar /api/receipts</p>',
'          <pre className="text-xs whitespace-pre-wrap break-words">{txt}</pre>',
'        </div>',
'      )}',
'',
'      {res.ok && safe.length === 0 && (',
'        <p className="text-sm opacity-70">Nenhum recibo ainda.</p>',
'      )}',
'',
'      {res.ok && safe.length > 0 && (',
'        <div className="rounded border overflow-hidden">',
'          <table className="w-full text-sm">',
'            <thead className="bg-black/5">',
'              <tr>',
'                <th className="text-left p-2">Code</th>',
'                <th className="text-left p-2">Resumo</th>',
'                <th className="text-left p-2">Ações</th>',
'              </tr>',
'            </thead>',
'            <tbody>',
'              {safe.map((r, idx) => {',
'                const code = getCode(r);',
'                return (',
'                  <tr key={String(code || idx)} className="border-t">',
'                    <td className="p-2 font-mono text-xs break-all">{code || "-"}</td>',
'                    <td className="p-2">{r?.summary ?? ""}</td>',
'                    <td className="p-2">',
'                      {code ? (',
'                        <Link className="underline" href={"/recibo/" + encodeURIComponent(code)}>Ver</Link>',
'                      ) : (',
'                        <span className="opacity-60">sem code</span>',
'                      )}',
'                    </td>',
'                  </tr>',
'                );',
'              })}',
'            </tbody>',
'          </table>',
'        </div>',
'      )}',
'    </main>',
'  );',
'}'
) -join "`n"

# OBS: como /api/receipts já retorna {items}, vamos simplificar de vez:
$listLines = @(
'import Link from "next/link";',
'import { headers } from "next/headers";',
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
'function getCode(r: any) {',
'  return r?.shareCode ?? r?.code ?? r?.id ?? "";',
'}',
'',
'export default async function RecibosPage() {',
'  const origin = await originFromHeaders();',
'  const res = await fetch(origin + "/api/receipts", { cache: "no-store" });',
'  const txt = await res.text();',
'  let json: any = null;',
'  try { json = JSON.parse(txt); } catch { json = { raw: txt }; }',
'',
'  const receipts: any[] = Array.isArray(json?.items) ? json.items : [];',
'',
'  return (',
'    <main className="p-4 max-w-4xl mx-auto space-y-4">',
'      <header className="space-y-2">',
'        <h1 className="text-2xl font-bold">Recibos</h1>',
'        <div className="flex gap-3 flex-wrap">',
'          <Link className="underline" href="/pedidos">← Pedidos</Link>',
'          <Link className="underline" href="/chamar">Chamar coleta</Link>',
'        </div>',
'      </header>',
'',
'      {!res.ok && (',
'        <div className="rounded border p-3">',
'          <p className="font-semibold text-red-600">Falha ao listar /api/receipts</p>',
'          <pre className="text-xs whitespace-pre-wrap break-words">{txt}</pre>',
'        </div>',
'      )}',
'',
'      {res.ok && receipts.length === 0 && (',
'        <p className="text-sm opacity-70">Nenhum recibo ainda.</p>',
'      )}',
'',
'      {res.ok && receipts.length > 0 && (',
'        <div className="rounded border overflow-hidden">',
'          <table className="w-full text-sm">',
'            <thead className="bg-black/5">',
'              <tr>',
'                <th className="text-left p-2">Code</th>',
'                <th className="text-left p-2">Resumo</th>',
'                <th className="text-left p-2">Ações</th>',
'              </tr>',
'            </thead>',
'            <tbody>',
'              {receipts.map((r, idx) => {',
'                const code = getCode(r);',
'                return (',
'                  <tr key={String(code || idx)} className="border-t">',
'                    <td className="p-2 font-mono text-xs break-all">{code || "-"}</td>',
'                    <td className="p-2">{r?.summary ?? ""}</td>',
'                    <td className="p-2">',
'                      {code ? (',
'                        <Link className="underline" href={"/recibo/" + encodeURIComponent(code)}>Ver</Link>',
'                      ) : (',
'                        <span className="opacity-60">sem code</span>',
'                      )}',
'                    </td>',
'                  </tr>',
'                );',
'              })}',
'            </tbody>',
'          </table>',
'        </div>',
'      )}',
'    </main>',
'  );',
'}'
) -join "`n"

WriteUtf8NoBom $listFile $listLines
$log += "- OK: reescrito $listFile (lista com links /recibo/[code])"

$log += ""
$log += "## DIAG (depois)"
$log += ("Exists api detail? " + (Test-Path -LiteralPath $apiFile))
$log += ("Exists page?      " + (Test-Path -LiteralPath $pageFile))
$log += ("Exists client?    " + (Test-Path -LiteralPath $cliFile))
$log += ("Exists /recibos?  " + (Test-Path -LiteralPath $listFile))
$log += ""

$log += "## Próximos passos"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1"
$log += "3) Abra /recibos e clique em 'Ver' para abrir /recibo/[code]"
$log += "4) Teste botões: Copiar link / WhatsApp / Compartilhar"
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 09 aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) Abra /recibos e clique em 'Ver' (vai pra /recibo/[code])" -ForegroundColor Yellow
Write-Host "4) No /recibo/[code], teste: Copiar link / WhatsApp / Compartilhar" -ForegroundColor Yellow