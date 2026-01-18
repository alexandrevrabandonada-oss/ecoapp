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

$rep = NewReport "eco-step-07d-hotfix-pickup-requests-address"
$log = @()
$log += "# ECO — STEP 07d — Hotfix POST /api/pickup-requests (address compat)"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

$target = "src/app/api/pickup-requests/route.ts"
if(!(Test-Path -LiteralPath $target)){ throw "Não achei $target" }

$log += "## DIAG (model PickupRequest via Prisma.dmmf)"
try {
  $out = node -e "const {Prisma}=require('@prisma/client'); const m=Prisma.dmmf.datamodel.models.find(x=>x.name==='PickupRequest'); if(!m){console.log('NO_MODEL'); process.exit(0)}; console.log(m.fields.map(f=>f.name).join(','));"
  $log += ("fields: " + ($out | Out-String).Trim())
} catch {
  $log += ("node/prisma dmmf falhou: " + $_.Exception.Message)
}
$log += ""

$bak = BackupFile $target
$log += ("Backup: {0}" -f $bak)
$log += ""

# Reescreve route.ts com create robusto (sem template literals)
$lines = @(
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
'  findMany?: (args?: any) => Promise<any>;',
'  create?: (args?: any) => Promise<any>;',
'};',
'',
'function lowerCamel(s: string) {',
'  return s ? s.charAt(0).toLowerCase() + s.slice(1) : s;',
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
'function findPickupModel() {',
'  const modelName = "PickupRequest";',
'  const tried: string[] = [];',
'  const key = getDelegateKeyForModel(modelName);',
'  tried.push(modelName + " -> " + (key ?? "null"));',
'  const model = getModel(modelName);',
'  const fields = model?.fields ?? [];',
'  const fieldNames = fields.map((f) => f.name);',
'  return { key, modelName, fields, fieldNames, tried };',
'}',
'',
'function pickupInclude(found: { fieldNames: string[] }) {',
'  const include: Record<string, boolean> = {};',
'  if (found.fieldNames.includes("receipt")) include.receipt = true;',
'  return include;',
'}',
'',
'type CreateBody = {',
'  address?: string;',
'  notes?: string;',
'  name?: string;',
'  phone?: string;',
'  public?: boolean;',
'};',
'',
'function safeTrim(v: any) {',
'  return typeof v === "string" ? v.trim() : "";',
'}',
'',
'function buildCreateData(found: { fieldNames: string[] }, body: CreateBody) {',
'  const data: Record<string, any> = {};',
'',
'  const addr = safeTrim((body as any)?.address);',
'  const notes = safeTrim((body as any)?.notes);',
'',
'  // campos diretos comuns (se existirem no model)',
'  if (safeTrim((body as any)?.name) && found.fieldNames.includes("name")) data.name = safeTrim((body as any)?.name);',
'  if (safeTrim((body as any)?.phone) && found.fieldNames.includes("phone")) data.phone = safeTrim((body as any)?.phone);',
'',
'  if (typeof (body as any)?.public === "boolean" && found.fieldNames.includes("public")) data.public = !!(body as any)?.public;',
'',
'  // notes (se existir)',
'  if (notes && found.fieldNames.includes("notes")) data.notes = notes;',
'',
'  // address compat: tenta gravar em campo equivalente; se não existir, injeta no notes',
'  if (addr) {',
'    if (found.fieldNames.includes("address")) data.address = addr;',
'    else if (found.fieldNames.includes("location")) data.location = addr;',
'    else if (found.fieldNames.includes("place")) data.place = addr;',
'    else if (found.fieldNames.includes("where")) data.where = addr;',
'    else {',
'      if (found.fieldNames.includes("notes")) {',
'        const prefix = "Endereço: " + addr;',
'        data.notes = data.notes ? (prefix + "\\n" + String(data.notes)) : prefix;',
'      }',
'    }',
'  }',
'',
'  return data;',
'}',
'',
'export async function GET() {',
'  try {',
'    const found = findPickupModel();',
'    if (!found.key) {',
'      return NextResponse.json({ error: "pickup_delegate_missing", tried: found.tried }, { status: 500 });',
'    }',
'    const prismaAny = prisma as unknown as Record<string, AnyDelegate>;',
'    const delegate = prismaAny[found.key];',
'    const args: any = { take: 200, include: pickupInclude(found) };',
'    if (found.fieldNames.includes("createdAt")) args.orderBy = { createdAt: "desc" };',
'    const items = await delegate.findMany!(args);',
'    return NextResponse.json({ delegate: found.key, model: found.modelName, items });',
'  } catch (e) {',
'    const detail = e instanceof Error ? e.message : String(e);',
'    return NextResponse.json({ error: "pickup_list_failed", detail }, { status: 500 });',
'  }',
'}',
'',
'export async function POST(req: Request) {',
'  try {',
'    const body = (await req.json()) as CreateBody;',
'    const found = findPickupModel();',
'    if (!found.key) {',
'      return NextResponse.json({ error: "pickup_delegate_missing", tried: found.tried }, { status: 500 });',
'    }',
'',
'    const prismaAny = prisma as unknown as Record<string, AnyDelegate>;',
'    const delegate = prismaAny[found.key];',
'',
'    const data = buildCreateData(found, body);',
'    const include = pickupInclude(found);',
'',
'    try {',
'      const item = await delegate.create!({ data, include });',
'      return NextResponse.json({ ok: true, item });',
'    } catch (err) {',
'      // fallback: se por algum motivo ainda bater "Unknown argument `address`", remove e joga no notes',
'      const msg = err instanceof Error ? err.message : String(err);',
'      if (msg.includes("Unknown argument `address`") && (data as any).address) {',
'        const addr = String((data as any).address);',
'        delete (data as any).address;',
'        if (found.fieldNames.includes("notes")) {',
'          const prefix = "Endereço: " + addr;',
'          (data as any).notes = (data as any).notes ? (prefix + "\\n" + String((data as any).notes)) : prefix;',
'        }',
'        const item = await delegate.create!({ data, include });',
'        return NextResponse.json({ ok: true, item, warning: "address_field_missing_saved_in_notes" });',
'      }',
'      throw err;',
'    }',
'  } catch (e) {',
'    const detail = e instanceof Error ? e.message : String(e);',
'    return NextResponse.json({ error: "pickup_create_failed", detail }, { status: 500 });',
'  }',
'}'
)

WriteUtf8NoBom $target ($lines -join "`n")

$log += "## PATCH"
$log += "- OK: reescrito src/app/api/pickup-requests/route.ts com compat de address"
$log += ""

$log += "## VERIFY (rápido, se server estiver no ar)"
try {
  $base = "http://localhost:3000"
  $r1 = Invoke-WebRequest -Uri "$base/api/requests" -TimeoutSec 6 -SkipHttpErrorCheck
  $log += ("- GET /api/requests -> " + $r1.StatusCode)

  $payload = @{ address = "teste-endereco"; notes = "teste-nota" } | ConvertTo-Json
  $r2 = Invoke-WebRequest -Uri "$base/api/requests" -Method POST -ContentType "application/json" -Body $payload -TimeoutSec 6 -SkipHttpErrorCheck
  $log += ("- POST /api/requests -> " + $r2.StatusCode)
} catch {
  $log += ("- VERIFY skip/falhou (server off?): " + $_.Exception.Message)
}
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 07d aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) (Se preciso) reinicie o dev: CTRL+C e npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) Vá em /chamar (ou /chamar-coleta/novo) e crie um pedido com endereço" -ForegroundColor Yellow
Write-Host "4) Vá em /pedidos e feche/emitir recibo" -ForegroundColor Yellow