$ErrorActionPreference = "Stop"

function Ensure-Dir([string]$p){
  if($p -and !(Test-Path $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null }
}

function WriteUtf8NoBom([string]$path, [string]$content){
  $dir = Split-Path -Parent $path
  if($dir){ Ensure-Dir $dir }
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
}

function Backup-File([string]$path){
  if(!(Test-Path $path)){ return $null }
  Ensure-Dir "tools/_patch_backup"
  $ts = Get-Date -Format "yyyyMMdd-HHmmss"
  $safe = ($path -replace '[\\/:*?"<>|]', '_')
  $dst = "tools/_patch_backup/$ts-$safe"
  Copy-Item -Force $path $dst
  return $dst
}

function New-Report([string]$name){
  Ensure-Dir "reports"
  $ts = Get-Date -Format "yyyyMMdd-HHmmss"
  return "reports/$ts-$name.md"
}

function Read-Text([string]$p){
  if(!(Test-Path $p)){ return "" }
  return (Get-Content $p -Raw)
}

function List-Prisma-Models {
  $p = "prisma/schema.prisma"
  if(!(Test-Path $p)){ return @() }
  $txt = Get-Content $p -Raw
  $ms = [regex]::Matches($txt, '^\s*model\s+([A-Za-z0-9_]+)\s*\{', 'Multiline')
  return ($ms | ForEach-Object { $_.Groups[1].Value }) | Sort-Object -Unique
}

$rep = New-Report "eco-receipts-delegate-fix-v3"
$log = @()
$log += "# ECO — FIX v3 — Receipts Prisma Delegate"
$log += ""
$log += "- Data: " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
$log += "- PWD : " + (Get-Location).Path
$log += "- Node: " + (node -v 2>$null)
$log += "- npm : " + (npm -v 2>$null)
$log += ""

# =========================
# DIAG (antes)
# =========================
$schemaPath = "prisma/schema.prisma"
if(!(Test-Path $schemaPath)){ throw "Não achei $schemaPath" }

$schemaRaw = Get-Content $schemaPath -Raw
$modelsBefore = List-Prisma-Models
$hasEcoReceipt = ($schemaRaw -match 'model\s+EcoReceipt\s*\{')

$log += "## DIAG (antes)"
$log += "- schema tem model EcoReceipt? **$hasEcoReceipt**"
$log += "- modelos no schema:"
$log += '```'
$log += ($modelsBefore -join "`n")
$log += '```'
$log += ""

# =========================
# PATCH 1 — Prisma schema (EcoReceipt + enum + receipt relation)
# =========================
$bak = Backup-File $schemaPath
if($bak){ $log += ("- Backup {0}: {1}" -f $schemaPath, $bak) }

$schema = $schemaRaw

if($schema -notmatch 'enum\s+PickupRequestStatus'){
  $schema += "`r`n`r`n// === ECO: PickupRequestStatus (v0) ===`r`nenum PickupRequestStatus {`r`n  OPEN`r`n  SCHEDULED`r`n  DONE`r`n  CANCELED`r`n}`r`n"
  $log += "- Prisma: enum PickupRequestStatus criado"
} else {
  $log += "- Prisma: enum PickupRequestStatus já existe (skip)"
}

if($schema -notmatch 'model\s+EcoReceipt\s*\{'){
  $schema += "`r`n`r`n// === ECO: EcoReceipt (Recibo) v0 ===`r`nmodel EcoReceipt {`r`n  id        String   @id @default(cuid())`r`n  createdAt DateTime @default(now())`r`n  updatedAt DateTime @updatedAt`r`n`r`n  shareCode String   @unique`r`n  public    Boolean  @default(false)`r`n`r`n  summary   String?`r`n  items     String?`r`n  operator  String?`r`n`r`n  requestId String   @unique`r`n  request   PickupRequest @relation(fields: [requestId], references: [id], onDelete: Cascade)`r`n}`r`n"
  $log += "- Prisma: model EcoReceipt criado"
} else {
  $log += "- Prisma: model EcoReceipt já existe (skip)"
}

$rx = [regex]'model\s+PickupRequest\s*\{([\s\S]*?)\r?\n\}'
$m = $rx.Match($schema)

if(!$m.Success){
  $schema += "`r`n`r`n// === ECO: PickupRequest (v0) ===`r`nmodel PickupRequest {`r`n  id        String              @id @default(cuid())`r`n  createdAt DateTime            @default(now())`r`n  updatedAt DateTime            @updatedAt`r`n`r`n  status    PickupRequestStatus  @default(OPEN)`r`n  name      String?`r`n  phone     String?`r`n  address   String?`r`n  notes     String?`r`n`r`n  receipt   EcoReceipt?`r`n}`r`n"
  $log += "- Prisma: model PickupRequest criado"
} else {
  $block = $m.Value

  if($block -notmatch '\bstatus\s+PickupRequestStatus\b'){
    if($block -match '\bstatus\s+String\??'){
      $block = [regex]::Replace($block, '\bstatus\s+String\??', 'status    PickupRequestStatus  @default(OPEN)')
      $log += "- Prisma: PickupRequest.status convertido p/ enum"
    } elseif($block -notmatch '\bstatus\b'){
      $block = $block -replace '\r?\n\s*updatedAt[^\r\n]*', ('$0' + "`r`n`r`n  status    PickupRequestStatus  @default(OPEN)")
      $log += "- Prisma: PickupRequest.status inserido"
    } else {
      $log += "- Prisma: PickupRequest.status existe (não alterei automaticamente)"
    }
  } else {
    $log += "- Prisma: PickupRequest.status já é enum (skip)"
  }

  if($block -notmatch '\breceipt\s+EcoReceipt\?'){
    $block = $block -replace '\r?\n\}', "`r`n  receipt   EcoReceipt?`r`n}"
    $log += "- Prisma: PickupRequest.receipt inserido"
  } else {
    $log += "- Prisma: PickupRequest.receipt já existe (skip)"
  }

  $schema = $schema.Replace($m.Value, $block)
}

WriteUtf8NoBom $schemaPath $schema
$log += "- OK: prisma/schema.prisma escrito"

# =========================
# VERIFY — Prisma
# =========================
$log += ""
$log += "## VERIFY — Prisma"
npx prisma generate --schema=prisma/schema.prisma | Out-Host
npx prisma db push --schema=prisma/schema.prisma | Out-Host

$modelsAfter = List-Prisma-Models
$log += "- modelos no schema (depois):"
$log += '```'
$log += ($modelsAfter -join "`n")
$log += '```'
$log += ""

# =========================
# PATCH 2 — API receipts usando Prisma.dmmf
# =========================
$apiReceipts = "src/app/api/receipts/route.ts"
Ensure-Dir (Split-Path -Parent $apiReceipts)
if(Test-Path $apiReceipts){
  $b = Backup-File $apiReceipts
  if($b){ $log += ("- Backup {0}: {1}" -f $apiReceipts, $b) }
}

WriteUtf8NoBom $apiReceipts @"
import { NextResponse } from "next/server";
import { Prisma, PrismaClient } from "@prisma/client";

export const runtime = "nodejs";

const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };
const prisma = globalForPrisma.prisma ?? new PrismaClient();
if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = prisma;

function lowerCamel(s: string) {
  return s ? s.charAt(0).toLowerCase() + s.slice(1) : s;
}

function getReceiptDelegateKey() {
  const prismaAny = prisma as unknown as Record<string, any>;
  const modelNames = Prisma.dmmf.datamodel.models.map((m) => m.name);

  const receiptModels = modelNames.filter((n) => /(receipt|recibo)/i.test(n));
  const preferred = ["EcoReceipt", ...receiptModels];

  const tried: string[] = [];
  for (const modelName of preferred) {
    const keys = [lowerCamel(modelName), modelName];
    for (const key of keys) {
      tried.push(key);
      const d = prismaAny[key];
      if (d && typeof d.findMany === "function") return { key, modelName, tried, modelNames };
    }
  }

  return { key: null as string | null, modelName: null as string | null, tried, modelNames };
}

export async function GET() {
  try {
    const found = getReceiptDelegateKey();
    if (!found.key) {
      return NextResponse.json(
        { error: "receipt_delegate_missing", modelNames: found.modelNames, tried: found.tried },
        { status: 500 }
      );
    }

    const prismaAny = prisma as unknown as Record<string, any>;
    const items = await prismaAny[found.key].findMany({
      include: { request: true },
      orderBy: { createdAt: "desc" },
      take: 200,
    });

    return NextResponse.json({ delegate: found.key, model: found.modelName, items });
  } catch (e) {
    const detail = e instanceof Error ? e.message : String(e);
    return NextResponse.json({ error: "receipts_list_failed", detail }, { status: 500 });
  }
}
"@
$log += "- OK: src/app/api/receipts/route.ts"

$apiReceiptByCode = "src/app/api/receipts/[code]/route.ts"
Ensure-Dir (Split-Path -Parent $apiReceiptByCode)
if(Test-Path $apiReceiptByCode){
  $b = Backup-File $apiReceiptByCode
  if($b){ $log += ("- Backup {0}: {1}" -f $apiReceiptByCode, $b) }
}

WriteUtf8NoBom $apiReceiptByCode @"
import { NextResponse } from "next/server";
import { Prisma, PrismaClient } from "@prisma/client";

export const runtime = "nodejs";

const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };
const prisma = globalForPrisma.prisma ?? new PrismaClient();
if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = prisma;

function lowerCamel(s: string) {
  return s ? s.charAt(0).toLowerCase() + s.slice(1) : s;
}

function getReceiptDelegateKey() {
  const prismaAny = prisma as unknown as Record<string, any>;
  const modelNames = Prisma.dmmf.datamodel.models.map((m) => m.name);

  const receiptModels = modelNames.filter((n) => /(receipt|recibo)/i.test(n));
  const preferred = ["EcoReceipt", ...receiptModels];

  const tried: string[] = [];
  for (const modelName of preferred) {
    const keys = [lowerCamel(modelName), modelName];
    for (const key of keys) {
      tried.push(key);
      const d = prismaAny[key];
      if (d && typeof d.findUnique === "function") return { key, modelName, tried, modelNames };
    }
  }

  return { key: null as string | null, modelName: null as string | null, tried, modelNames };
}

type Ctx = { params: { code: string } | Promise<{ code: string }> };

export async function GET(_req: Request, ctx: Ctx) {
  try {
    const { code } = await Promise.resolve(ctx.params);

    const found = getReceiptDelegateKey();
    if (!found.key) {
      return NextResponse.json(
        { error: "receipt_delegate_missing", modelNames: found.modelNames, tried: found.tried },
        { status: 500 }
      );
    }

    const prismaAny = prisma as unknown as Record<string, any>;
    const item = await prismaAny[found.key].findUnique({
      where: { shareCode: code },
      include: { request: true },
    });

    if (!item) return NextResponse.json({ error: "not found" }, { status: 404 });
    return NextResponse.json({ delegate: found.key, model: found.modelName, item });
  } catch (e) {
    const detail = e instanceof Error ? e.message : String(e);
    return NextResponse.json({ error: "receipt_get_failed", detail }, { status: 500 });
  }
}
"@
$log += "- OK: src/app/api/receipts/[code]/route.ts"

# =========================
# PATCH 3 — UI tolerante (array OU {items}/{item}) — sem @' interno
# =========================
$pageRecibos = "src/app/recibos/page.tsx"
if(Test-Path $pageRecibos){
  $b = Backup-File $pageRecibos
  if($b){ $log += ("- Backup {0}: {1}" -f $pageRecibos, $b) }
  $txt = Read-Text $pageRecibos

  if($txt -match 'setItems\(Array\.isArray\(json\)'){
    $replacement = @"
const anyJson = json as any;
const arr = Array.isArray(anyJson) ? anyJson : Array.isArray(anyJson?.items) ? anyJson.items : [];
setItems(arr as Receipt[]);
"@
    $txt2 = [regex]::Replace(
      $txt,
      'setItems\(Array\.isArray\(json\)\s*\?\s*\(json as Receipt\[\]\)\s*:\s*\[\]\);\s*',
      ($replacement + "`n")
    )
    if($txt2 -ne $txt){
      WriteUtf8NoBom $pageRecibos $txt2
      $log += "- OK: src/app/recibos/page.tsx (aceita {items})"
    } else {
      $log += "- SKIP: src/app/recibos/page.tsx (pattern não bateu)"
    }
  } else {
    $log += "- SKIP: src/app/recibos/page.tsx (não achei setItems(Array.isArray(json)))"
  }
}

$pageRecibo = "src/app/recibo/[code]/page.tsx"
if(Test-Path $pageRecibo){
  $b = Backup-File $pageRecibo
  if($b){ $log += ("- Backup {0}: {1}" -f $pageRecibo, $b) }
  $txt = Read-Text $pageRecibo

  if($txt -match 'const json = \(await res\.json\(\)\) as Receipt;'){
    $replacement = @"
const json = (await res.json()) as any;
const item = (json && typeof json === "object" && "item" in json) ? (json.item as Receipt) : (json as Receipt);
setItem(item);
"@
    $txt2 = [regex]::Replace(
      $txt,
      'const json = \(await res\.json\(\)\) as Receipt;\s*setItem\(json\);\s*',
      ($replacement + "`n")
    )
    if($txt2 -ne $txt){
      WriteUtf8NoBom $pageRecibo $txt2
      $log += "- OK: src/app/recibo/[code]/page.tsx (aceita {item})"
    } else {
      $log += "- SKIP: src/app/recibo/[code]/page.tsx (pattern não bateu)"
    }
  } else {
    $log += "- SKIP: src/app/recibo/[code]/page.tsx (não achei pattern do json as Receipt)"
  }
}

# =========================
# REGISTRO
# =========================
WriteUtf8NoBom $rep ($log -join "`n")
Write-Host "✅ FIX v3 aplicado. Report -> $rep" -ForegroundColor Green
Write-Host "" 
Write-Host "PRÓXIMO PASSO:" -ForegroundColor Yellow
Write-Host "1) Em outro terminal: npm run dev" -ForegroundColor Yellow
Write-Host "2) Depois rode o smoke:" -ForegroundColor Yellow
Write-Host "   pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "" 
Write-Host "Dica rápida (quando o dev estiver rodando):" -ForegroundColor DarkGray
Write-Host "  irm http://localhost:3000/api/receipts -SkipHttpErrorCheck | select -Expand Content" -ForegroundColor DarkGray