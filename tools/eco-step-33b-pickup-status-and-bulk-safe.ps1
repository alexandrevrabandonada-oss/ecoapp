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
function FindFirst([string]$root, [string]$pattern){
  if(!(Test-Path -LiteralPath $root)){ return $null }
  $f = Get-ChildItem -Recurse -File -Path $root -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -match $pattern } |
    Select-Object -First 1
  if($f){ return $f.FullName }
  return $null
}
function FindAll([string]$root, [string]$pattern){
  if(!(Test-Path -LiteralPath $root)){ return @() }
  return @(Get-ChildItem -Recurse -File -Path $root -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -match $pattern } |
    Select-Object -ExpandProperty FullName)
}

function GetEnvTokenName(){
  $cands = @(
    "ECO_OPERATOR_TOKEN",
    "ECO_PEDIDOS_TOKEN",
    "ECO_TOKEN",
    "PEDIDOS_TOKEN"
  )

  $envFiles = @(".env.local",".env",".env.development.local",".env.development")
  foreach($f in $envFiles){
    if(Test-Path -LiteralPath $f){
      $txt = Get-Content -LiteralPath $f -Raw
      foreach($c in $cands){
        if($txt -match ("(?m)^\s*" + [regex]::Escape($c) + "\s*=")){
          return $c
        }
      }
    }
  }

  foreach($c in $cands){
    $v = [Environment]::GetEnvironmentVariable($c)
    if($v){ return $c }
  }

  return "ECO_OPERATOR_TOKEN"
}

function EnsureEnumPickupStatus([string[]]$lines){
  if(($lines -join "`n") -match "(?m)^\s*enum\s+PickupStatus\s*\{"){
    return $lines
  }

  $enumBlock = @"
enum PickupStatus {
  NEW
  IN_ROUTE
  DONE
  CANCELED
}
"@

  return @($lines + "" + $enumBlock)
}

function EnsurePickupRequestFields([string[]]$lines){
  $start = -1
  for($i=0; $i -lt $lines.Count; $i++){
    if($lines[$i] -match "^\s*model\s+PickupRequest\s*\{"){ $start = $i; break }
  }
  if($start -lt 0){ return ,$lines }

  $end = -1
  for($j=$start+1; $j -lt $lines.Count; $j++){
    if($lines[$j] -match "^\s*\}\s*$"){ $end = $j; break }
  }
  if($end -lt 0){ return ,$lines }

  $block = $lines[$start..$end]

  $hasStatus = ($block | Where-Object { $_ -match "^\s*status\s+" } | Select-Object -First 1)
  $hasRouteDay = ($block | Where-Object { $_ -match "^\s*routeDay\s+" } | Select-Object -First 1)
  $hasCollectedAt = ($block | Where-Object { $_ -match "^\s*collectedAt\s+" } | Select-Object -First 1)

  $insert = @()
  if(-not $hasStatus){
    $insert += "  status     PickupStatus @default(NEW)"
  }
  if(-not $hasRouteDay){
    $insert += "  routeDay   String?"
  }
  if(-not $hasCollectedAt){
    $insert += "  collectedAt DateTime?"
  }

  if($insert.Count -eq 0){
    return ,$lines
  }

  $out = @()
  $out += $lines[0..($end-1)]
  $out += ""
  $out += "  // ECO_STEP33_STATUS_ROUTE_START"
  foreach($l in $insert){ $out += $l }
  $out += "  // ECO_STEP33_STATUS_ROUTE_END"
  $out += $lines[$end..($lines.Count-1)]
  return ,$out
}

$rep = NewReport "eco-step-33b-pickup-status-and-bulk-safe"
$log = @()
$log += "# ECO — STEP 33b — Status/RouteDay + APIs triage/bulk (PowerShell-safe)"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

$schema = "prisma/schema.prisma"
if(!(Test-Path -LiteralPath $schema)){ $schema = FindFirst "." "\\prisma\\schema\.prisma$" }
if(!(Test-Path -LiteralPath $schema)){
  $log += "## ERRO"
  $log += "Não achei prisma/schema.prisma"
  WriteUtf8NoBom $rep ($log -join "`n")
  throw "Não achei schema.prisma"
}

$tokenEnv = GetEnvTokenName

$log += "## DIAG"
$log += ("schema: {0}" -f $schema)
$log += ("Operator token env: {0}" -f $tokenEnv)
$log += ""

# --- Prisma patch
$log += "## PATCH — Prisma"
$bkSchema = BackupFile $schema
$log += ("Backup schema: {0}" -f $bkSchema)

$lines = Get-Content -LiteralPath $schema
$lines2 = EnsureEnumPickupStatus $lines
$lines3 = EnsurePickupRequestFields $lines2

if(($lines3 -join "`n") -ne ($lines -join "`n")){
  WriteUtf8NoBom $schema ($lines3 -join "`n")
  $log += "- OK: schema atualizado (PickupStatus + campos em PickupRequest)."
} else {
  $log += "- INFO: schema já tinha enum/campos (skip)."
}

# --- Detect Receipt fields (best-effort)
$schemaTxt = Get-Content -LiteralPath $schema -Raw

$receiptCodeField = "code"
if($schemaTxt -match "(?m)^\s*model\s+Receipt\s*\{"){
  if($schemaTxt -match "(?m)^\s*shareCode\s+"){
    $receiptCodeField = "shareCode"
  } elseif($schemaTxt -match "(?m)^\s*publicCode\s+"){
    $receiptCodeField = "publicCode"
  } elseif($schemaTxt -match "(?m)^\s*code\s+"){
    $receiptCodeField = "code"
  } else {
    $receiptCodeField = "id"
  }
}

$receiptPublicField = $null
if($schemaTxt -match "(?m)^\s*public\s+Boolean"){ $receiptPublicField = "public" }
elseif($schemaTxt -match "(?m)^\s*isPublic\s+Boolean"){ $receiptPublicField = "isPublic" }

# IMPORTANT: montar string sem interpolação com ":" logo após variável
$receiptSelect = (" " + $receiptCodeField + ": true")
if($receiptPublicField){
  $receiptSelect = ($receiptSelect + ", " + $receiptPublicField + ": true")
}

$log += ""
$log += "Receipt select: " + $receiptSelect
$log += ""

# --- API routes
$log += "## PATCH — API triage/bulk"

$triagePath = "src/app/api/pickup-requests/triage/route.ts"
EnsureDir (Split-Path -Parent $triagePath)
BackupFile $triagePath | Out-Null

$triageTs = @"
import { NextResponse } from "next/server";
import { PrismaClient } from "@prisma/client";

export const runtime = "nodejs";

const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };
const prisma = globalForPrisma.prisma ?? new PrismaClient();
if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = prisma;

function ecoGetToken(req: Request): string | null {
  const h = req.headers.get("x-eco-token") ?? req.headers.get("authorization") ?? "";
  if (!h) return null;
  if (h.startsWith("Bearer ")) return h.slice(7).trim();
  if (h && !h.includes(" ")) return h.trim();
  return null;
}

function ecoIsOperator(req: Request): boolean {
  const token = ecoGetToken(req);
  const expected = process.env["__TOKEN_ENV__"] ?? "";
  if (!expected) return true;
  if (!token) return false;
  return token === expected;
}

export async function GET(req: Request) {
  if (!ecoIsOperator(req)) {
    return NextResponse.json({ ok: false, error: "unauthorized" }, { status: 401 });
  }

  const items = await prisma.pickupRequest.findMany({
    orderBy: { createdAt: "desc" },
    take: 200,
    include: {
      receipt: { select: { __RECEIPT_SELECT__ } },
    },
  });

  return NextResponse.json({ ok: true, items });
}
"@
$triageTs = $triageTs.Replace("__TOKEN_ENV__", $tokenEnv).Replace("__RECEIPT_SELECT__", $receiptSelect)
WriteUtf8NoBom $triagePath $triageTs
$log += ("- OK: criado {0}" -f $triagePath)

$bulkPath = "src/app/api/pickup-requests/bulk/route.ts"
EnsureDir (Split-Path -Parent $bulkPath)
BackupFile $bulkPath | Out-Null

$bulkTs = @"
import { NextResponse } from "next/server";
import { PrismaClient } from "@prisma/client";

export const runtime = "nodejs";

const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };
const prisma = globalForPrisma.prisma ?? new PrismaClient();
if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = prisma;

function ecoGetToken(req: Request): string | null {
  const h = req.headers.get("x-eco-token") ?? req.headers.get("authorization") ?? "";
  if (!h) return null;
  if (h.startsWith("Bearer ")) return h.slice(7).trim();
  if (h && !h.includes(" ")) return h.trim();
  return null;
}

function ecoIsOperator(req: Request): boolean {
  const token = ecoGetToken(req);
  const expected = process.env["__TOKEN_ENV__"] ?? "";
  if (!expected) return true;
  if (!token) return false;
  return token === expected;
}

type BulkBody = {
  ids: string[];
  status?: "NEW" | "IN_ROUTE" | "DONE" | "CANCELED";
  routeDay?: string | null;
};

export async function PATCH(req: Request) {
  if (!ecoIsOperator(req)) {
    return NextResponse.json({ ok: false, error: "unauthorized" }, { status: 401 });
  }

  const body = (await req.json().catch(() => null)) as BulkBody | null;
  const ids = body?.ids ?? [];
  if (!Array.isArray(ids) || ids.length === 0) {
    return NextResponse.json({ ok: false, error: "ids_required" }, { status: 400 });
  }

  const data: any = {};
  if (body?.status) data.status = body.status;
  if (body && ("routeDay" in body)) data.routeDay = (body as any).routeDay;

  if (body?.status === "DONE") {
    data.collectedAt = new Date();
  }

  const r = await prisma.pickupRequest.updateMany({
    where: { id: { in: ids } },
    data,
  });

  return NextResponse.json({ ok: true, updated: r.count });
}
"@
$bulkTs = $bulkTs.Replace("__TOKEN_ENV__", $tokenEnv)
WriteUtf8NoBom $bulkPath $bulkTs
$log += ("- OK: criado {0}" -f $bulkPath)

# --- best-effort swap fetch in /operador/triagem
$log += ""
$log += "## PATCH — /operador/triagem (best-effort)"

$triageFiles = FindAll "src/app/operador/triagem" "\.tsx$"
$didSwap = $false
foreach($f in $triageFiles){
  $txt = Get-Content -LiteralPath $f -Raw
  if($txt -match "/api/pickup-requests"){
    $bk = BackupFile $f
    $txt2 = $txt.Replace("/api/pickup-requests", "/api/pickup-requests/triage")
    WriteUtf8NoBom $f $txt2
    $log += ("- OK: troquei fetch em {0} (backup {1})" -f $f, $bk)
    $didSwap = $true
    break
  }
}
if(-not $didSwap){
  $log += "- WARN: não encontrei fetch /api/pickup-requests dentro de src/app/operador/triagem (skip)."
}

# --- VERIFY prisma sync + generate
$log += ""
$log += "## VERIFY"

$hasMigrationsDir = (Test-Path -LiteralPath "prisma/migrations")

try {
  if($hasMigrationsDir){
    $log += "- Rodando: npx prisma migrate dev --name eco_step33_pickup_status_route"
    npx prisma migrate dev --name eco_step33_pickup_status_route | Out-Host
  } else {
    $log += "- Rodando: npx prisma db push"
    npx prisma db push | Out-Host
  }
} catch {
  $log += "- WARN: Prisma sync falhou. Veja o erro acima e rode manualmente."
}

try {
  $log += "- Rodando: npx prisma generate"
  npx prisma generate | Out-Host
} catch {
  $log += "- WARN: prisma generate falhou."
}

$log += ""
$log += "Próximos:"
$log += "1) Reinicie o dev: npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1"
$log += "3) Teste /operador/triagem"
$log += "4) APIs novas:"
$log += "   - GET   /api/pickup-requests/triage"
$log += "   - PATCH /api/pickup-requests/bulk  { ids:[], status, routeDay }"
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 33b aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) Teste /operador/triagem" -ForegroundColor Yellow
Write-Host "4) (API) bulk pronto p/ próximo tijolo de UI" -ForegroundColor Yellow