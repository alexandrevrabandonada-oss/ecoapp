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

$rep = NewReport "eco-step-12c-fix-api-points-required-city"
$log = @()
$log += "# ECO — STEP 12c — Fix /api/points: city obrigatório"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

# localizar route.ts de /api/points
$apiPoints = "src/app/api/points/route.ts"
if(!(Test-Path -LiteralPath $apiPoints)){
  $found = Get-ChildItem -Recurse -File -Path "src/app" -Filter "route.ts" -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -match "\\api\\points\\route\.ts$" } |
    Select-Object -First 1
  if($found){ $apiPoints = $found.FullName }
}
if(!(Test-Path -LiteralPath $apiPoints)){
  throw "Não achei src/app/api/points/route.ts (nem via busca)."
}

$log += "## DIAG"
$log += ("API points: {0}" -f $apiPoints)
$log += ("Backup: {0}" -f (BackupFile $apiPoints))
$log += ""

$ts = @"
import { NextResponse } from "next/server";
import { PrismaClient } from "@prisma/client";
import crypto from "crypto";

export const runtime = "nodejs";

const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };
const prisma = globalForPrisma.prisma ?? new PrismaClient();
if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = prisma;

function slugify(input: string) {
  const s = (input || "").trim().toLowerCase();
  if (!s) return "";
  return s
    .normalize("NFD")
    .replace(/[\\u0300-\\u036f]/g, "")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/(^-|-\$)/g, "")
    .slice(0, 60);
}

function rand4() {
  return crypto.randomBytes(2).toString("hex");
}

async function ensureUniqueSlug(base: string) {
  const raw = slugify(base) || ("ponto-" + rand4());
  let slug = raw;
  for (let i = 0; i < 10; i++) {
    const exists = await prisma.point.findFirst({ where: { slug } }).catch(() => null);
    if (!exists) return slug;
    slug = raw + "-" + (i + 2);
  }
  return raw + "-" + rand4();
}

export async function GET() {
  try {
    const args: any = { include: { service: true }, take: 200 };
    try { (args as any).orderBy = { createdAt: "desc" }; } catch {}
    const items = await prisma.point.findMany(args);
    return NextResponse.json({ ok: true, items });
  } catch (e) {
    const detail = e instanceof Error ? e.message : String(e);
    return NextResponse.json({ error: "points_list_failed", detail }, { status: 500 });
  }
}

export async function POST(req: Request) {
  try {
    const body: any = await req.json().catch(() => ({}));

    const serviceId = typeof body?.serviceId === "string" ? body.serviceId.trim() : "";
    if (!serviceId) return NextResponse.json({ error: "missing_serviceId" }, { status: 400 });

    const title = typeof body?.title === "string" ? body.title.trim() : "";
    const name  = typeof body?.name === "string" ? body.name.trim() : "";
    const materialKind = typeof body?.materialKind === "string" ? body.materialKind.trim() : "";

    // ✅ city é obrigatório no seu schema: aceitar body.city ou usar default
    const city =
      (typeof body?.city === "string" && body.city.trim())
        ? body.city.trim()
        : (process.env.ECO_DEFAULT_CITY || "Volta Redonda");

    const base = title || name || materialKind || "ponto";
    const slug = await ensureUniqueSlug(base);

    const data: any = {
      serviceId,
      slug,
      city, // ✅ obrigatório
      title: title || base,
      name: name || title || base,
      materialKind: materialKind || null,
      address: typeof body?.address === "string" ? body.address : null,
      neighborhood: typeof body?.neighborhood === "string" ? body.neighborhood : null,
      hours: typeof body?.hours === "string" ? body.hours : null,
      contact: typeof body?.contact === "string" ? body.contact : null,
      isActive: typeof body?.isActive === "boolean" ? body.isActive : true,
    };

    Object.keys(data).forEach((k) => {
      if (data[k] === null) delete data[k];
    });

    const point = await prisma.point.create({
      data,
      include: { service: true },
    });

    return NextResponse.json({ ok: true, point });
  } catch (e) {
    const detail = e instanceof Error ? e.message : String(e);
    return NextResponse.json({ error: "points_create_failed", detail }, { status: 500 });
  }
}
"@

WriteUtf8NoBom $apiPoints $ts

$log += "## PATCH"
$log += "- OK: /api/points POST agora sempre envia city (body.city ou ECO_DEFAULT_CITY ou 'Volta Redonda')"
$log += "- OK: mantém slug auto + include service"
$log += ""

$log += "## Próximos passos"
$log += "1) (opcional) setar .env: ECO_DEFAULT_CITY=Volta Redonda"
$log += "2) npm run dev"
$log += "3) pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1"
$log += "4) /coleta/novo -> criar ponto (não pode mais dar 'Argument city is missing')"
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 12c aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) npm run dev" -ForegroundColor Yellow
Write-Host "2) pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) /coleta/novo -> criar ponto (city obrigatório resolvido)" -ForegroundColor Yellow