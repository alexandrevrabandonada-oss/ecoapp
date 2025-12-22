$ErrorActionPreference = "Stop"

function EnsureDir([string]$p){
  if($p -and !(Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null }
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

function Run([string]$cmd, [string[]]$args){
  & $cmd @args
  if($LASTEXITCODE -ne 0){
    throw ("Command failed: {0} {1}" -f $cmd, ($args -join " "))
  }
}

function RunPrisma([string[]]$args){
  # preferir bin local (Windows)
  $local = "node_modules\.bin\prisma.cmd"
  if(Test-Path -LiteralPath $local){
    & $local @args
    if($LASTEXITCODE -eq 0){ return }
    throw ("Prisma failed via {0} (exit {1})" -f $local, $LASTEXITCODE)
  }

  # fallback: npm exec
  try{
    $cmdArgs = @("exec","--","prisma") + $args
    & npm @cmdArgs
    if($LASTEXITCODE -eq 0){ return }
  } catch {}

  # fallback: npx (se existir)
  try{
    & npx prisma @args
    if($LASTEXITCODE -eq 0){ return }
  } catch {}

  throw "Não consegui rodar Prisma (tentei prisma.cmd, npm exec, npx)."
}

$rep = NewReport "eco-fix-v4f-pickup-requests-without-npx"
$log = @()
$log += "# ECO — FIX v4f — Pickup Requests + Prisma sem npx"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ("Node: {0}" -f (node -v 2>$null))
$log += ("npm : {0}" -f (npm -v 2>$null))
$log += ("prisma.cmd exists: {0}" -f (Test-Path -LiteralPath "node_modules\.bin\prisma.cmd"))
$log += ""

# =========================
# PATCH 1 — schema: remover duplicidade receipt EcoReceipt?
# =========================
$schemaPath = "prisma/schema.prisma"
if(!(Test-Path -LiteralPath $schemaPath)){ throw "Não achei prisma/schema.prisma" }
$schemaRaw = Get-Content -LiteralPath $schemaPath -Raw

$rx = [regex]::new('(?ms)model\s+PickupRequest\s*\{.*?\r?\n\}')
$m = $rx.Match($schemaRaw)
if(!$m.Success){ throw "Não achei model PickupRequest no schema" }

$block = $m.Value
$lines = $block -split "`r?`n"

$log += "## DIAG schema (antes) — receipt/ecoReceipt"
$log += '```'
foreach($ln in $lines){
  if($ln -match '^\s*(receipt|ecoReceipt)\b'){ $log += $ln }
}
$log += '```'
$log += ""

# regras:
# - manter receipt Receipt? (se existir)
# - transformar receipt EcoReceipt? em ecoReceipt EcoReceipt? (ou remover se ecoReceipt já existir)
$hasEcoReceipt = $false
foreach($ln in $lines){
  if($ln -match '^\s*ecoReceipt\s+EcoReceipt\?\s*$'){ $hasEcoReceipt = $true }
}

$new = New-Object System.Collections.Generic.List[string]
$changed = $false
foreach($ln in $lines){
  if($ln -match '^\s*receipt\s+EcoReceipt\?\s*$'){
    if($hasEcoReceipt){
      $changed = $true
      continue
    } else {
      $new.Add("  ecoReceipt EcoReceipt?")
      $hasEcoReceipt = $true
      $changed = $true
      continue
    }
  }
  $new.Add($ln)
}

if($changed){
  $bak = BackupFile $schemaPath
  if($bak){ $log += ("Backup: {0}" -f $bak) }

  $block2 = ($new -join "`r`n")
  $schemaFixed = $schemaRaw.Replace($block, $block2)
  WriteUtf8NoBom $schemaPath $schemaFixed
  $log += "OK: schema corrigido (receipt EcoReceipt? -> ecoReceipt OU removido)"
} else {
  $log += "NOCHANGE: não encontrei 'receipt EcoReceipt?' para corrigir"
}

$log += ""
$log += "## VERIFY Prisma (sem npx)"
RunPrisma @("validate","--schema=prisma/schema.prisma")
RunPrisma @("generate","--schema=prisma/schema.prisma")
RunPrisma @("db","push","--schema=prisma/schema.prisma")
$log += "OK: prisma validate/generate/db push"

# =========================
# PATCH 2 — reescrever pickup-requests APIs (delegate correto + include dinâmico)
# =========================
$log += ""
$log += "## PATCH api/pickup-requests (rewrite seguro)"

$apiList = "src/app/api/pickup-requests/route.ts"
EnsureDir (Split-Path -Parent $apiList)
if(Test-Path -LiteralPath $apiList){
  $b = BackupFile $apiList
  if($b){ $log += ("Backup: {0}" -f $b) }
}

WriteUtf8NoBom $apiList @"
import { NextResponse } from "next/server";
import { Prisma, PrismaClient } from "@prisma/client";

export const runtime = "nodejs";

const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };
const prisma = globalForPrisma.prisma ?? new PrismaClient();
if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = prisma;

function lowerCamel(s: string) {
  return s ? s.charAt(0).toLowerCase() + s.slice(1) : s;
}

function pickupMeta() {
  const model = Prisma.dmmf.datamodel.models.find((m) => m.name === "PickupRequest");
  const fieldNames = (model?.fields ?? []).map((f) => f.name);
  return { fieldNames };
}

function pickupInclude() {
  const { fieldNames } = pickupMeta();
  const include: any = {};
  if (fieldNames.includes("receipt")) include.receipt = true;
  if (fieldNames.includes("ecoReceipt")) include.ecoReceipt = true;
  return include;
}

function getPickupDelegateKey() {
  const prismaAny = prisma as unknown as Record<string, any>;
  const modelName = "PickupRequest";
  const tried: string[] = [];

  const keys = [
    lowerCamel(modelName), // pickupRequest (correto no Prisma)
    modelName,             // PickupRequest (não costuma existir, mas tentamos)
    "pickupRequests",      // caso alguém tenha errado no passado
  ];

  for (const key of keys) {
    tried.push(key);
    const d = prismaAny[key];
    if (d && typeof d.findMany === "function") return { key, tried };
  }

  return { key: null as string | null, tried };
}

export async function GET() {
  try {
    const found = getPickupDelegateKey();
    if (!found.key) {
      return NextResponse.json(
        { error: "pickup_delegate_missing", tried: found.tried },
        { status: 500 }
      );
    }

    const prismaAny = prisma as unknown as Record<string, any>;
    const items = await prismaAny[found.key].findMany({
      include: pickupInclude(),
      orderBy: { createdAt: "desc" },
      take: 200,
    });

    return NextResponse.json({ delegate: found.key, items });
  } catch (e) {
    const detail = e instanceof Error ? e.message : String(e);
    return NextResponse.json({ error: "pickup_list_failed", detail }, { status: 500 });
  }
}

export async function POST(req: Request) {
  try {
    const found = getPickupDelegateKey();
    if (!found.key) {
      return NextResponse.json(
        { error: "pickup_delegate_missing", tried: found.tried },
        { status: 500 }
      );
    }

    const body = (await req.json().catch(() => ({}))) as any;
    const data: any = {};

    if (typeof body?.status === "string" && body.status) data.status = body.status;
    if (typeof body?.name === "string") data.name = body.name;
    if (typeof body?.phone === "string") data.phone = body.phone;
    if (typeof body?.address === "string") data.address = body.address;
    if (typeof body?.notes === "string") data.notes = body.notes;

    const prismaAny = prisma as unknown as Record<string, any>;
    const item = await prismaAny[found.key].create({
      data,
      include: pickupInclude(),
    });

    return NextResponse.json({ delegate: found.key, item }, { status: 201 });
  } catch (e) {
    const detail = e instanceof Error ? e.message : String(e);
    return NextResponse.json({ error: "pickup_create_failed", detail }, { status: 500 });
  }
}
"@

$apiById = "src/app/api/pickup-requests/[id]/route.ts"
EnsureDir (Split-Path -Parent $apiById)
if(Test-Path -LiteralPath $apiById){
  $b = BackupFile $apiById
  if($b){ $log += ("Backup: {0}" -f $b) }
}

WriteUtf8NoBom $apiById @"
import { NextResponse } from "next/server";
import { Prisma, PrismaClient } from "@prisma/client";

export const runtime = "nodejs";

const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };
const prisma = globalForPrisma.prisma ?? new PrismaClient();
if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = prisma;

function lowerCamel(s: string) {
  return s ? s.charAt(0).toLowerCase() + s.slice(1) : s;
}

function pickupMeta() {
  const model = Prisma.dmmf.datamodel.models.find((m) => m.name === "PickupRequest");
  const fieldNames = (model?.fields ?? []).map((f) => f.name);
  return { fieldNames };
}

function pickupInclude() {
  const { fieldNames } = pickupMeta();
  const include: any = {};
  if (fieldNames.includes("receipt")) include.receipt = true;
  if (fieldNames.includes("ecoReceipt")) include.ecoReceipt = true;
  return include;
}

function getPickupDelegateKey() {
  const prismaAny = prisma as unknown as Record<string, any>;
  const modelName = "PickupRequest";
  const tried: string[] = [];

  const keys = [lowerCamel(modelName), modelName, "pickupRequests"];
  for (const key of keys) {
    tried.push(key);
    const d = prismaAny[key];
    if (d && typeof d.findUnique === "function") return { key, tried };
  }

  return { key: null as string | null, tried };
}

type Ctx = { params: { id: string } | Promise<{ id: string }> };

export async function GET(_req: Request, ctx: Ctx) {
  try {
    const { id } = await Promise.resolve(ctx.params);

    const found = getPickupDelegateKey();
    if (!found.key) {
      return NextResponse.json(
        { error: "pickup_delegate_missing", tried: found.tried },
        { status: 500 }
      );
    }

    const prismaAny = prisma as unknown as Record<string, any>;
    const item = await prismaAny[found.key].findUnique({
      where: { id },
      include: pickupInclude(),
    });

    if (!item) return NextResponse.json({ error: "not_found" }, { status: 404 });
    return NextResponse.json({ delegate: found.key, item });
  } catch (e) {
    const detail = e instanceof Error ? e.message : String(e);
    return NextResponse.json({ error: "pickup_get_failed", detail }, { status: 500 });
  }
}

export async function PATCH(req: Request, ctx: Ctx) {
  try {
    const { id } = await Promise.resolve(ctx.params);

    const found = getPickupDelegateKey();
    if (!found.key) {
      return NextResponse.json(
        { error: "pickup_delegate_missing", tried: found.tried },
        { status: 500 }
      );
    }

    const body = (await req.json().catch(() => ({}))) as any;
    const data: any = {};

    if (typeof body?.status === "string" && body.status) data.status = body.status;
    if (typeof body?.name === "string") data.name = body.name;
    if (typeof body?.phone === "string") data.phone = body.phone;
    if (typeof body?.address === "string") data.address = body.address;
    if (typeof body?.notes === "string") data.notes = body.notes;

    const prismaAny = prisma as unknown as Record<string, any>;
    const item = await prismaAny[found.key].update({
      where: { id },
      data,
      include: pickupInclude(),
    });

    return NextResponse.json({ delegate: found.key, item });
  } catch (e) {
    const detail = e instanceof Error ? e.message : String(e);
    return NextResponse.json({ error: "pickup_patch_failed", detail }, { status: 500 });
  }
}
"@

$log += "OK: rewrote pickup-requests routes"

WriteUtf8NoBom $rep ($log -join "`n")
Write-Host ("✅ FIX v4f aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host ""
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host ""
Write-Host "Se ainda falhar, rode:" -ForegroundColor Yellow
Write-Host "  irm http://localhost:3000/api/pickup-requests -SkipHttpErrorCheck | select -Expand Content" -ForegroundColor Yellow