param([string]$Root = (Get-Location).Path)

$ts = Get-Date -Format "yyyyMMdd-HHmmss"
Write-Host ("== eco-step-104-stabilize-points-api-list2-counts-support-prisma-v0_1 == " + $ts)
Write-Host ("[DIAG] Root: " + $Root)

$boot = Join-Path $Root "tools/_bootstrap.ps1"
if (Test-Path -LiteralPath $boot) { . $boot }

if (-not (Get-Command EnsureDir -ErrorAction SilentlyContinue)) {
  function EnsureDir([string]$p) { if (-not (Test-Path -LiteralPath $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null } }
}
if (-not (Get-Command WriteAllLinesUtf8NoBom -ErrorAction SilentlyContinue)) {
  function WriteAllLinesUtf8NoBom([string]$p, [string[]]$lines) {
    EnsureDir (Split-Path -Parent $p)
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllLines($p, $lines, $enc)
  }
}
if (-not (Get-Command WriteUtf8NoBom -ErrorAction SilentlyContinue)) {
  function WriteUtf8NoBom([string]$p, [string]$content) {
    EnsureDir (Split-Path -Parent $p)
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($p, $content, $enc)
  }
}
if (-not (Get-Command BackupFile -ErrorAction SilentlyContinue)) {
  function BackupFile([string]$root, [string]$p, [string]$backupDir) {
    if (Test-Path -LiteralPath $p) {
      $rel = $p.Substring($root.Length).TrimStart('\','/')
      $dest = Join-Path $backupDir ($rel -replace '[\\/]', '__')
      Copy-Item -Force -LiteralPath $p -Destination $dest
      Write-Host ('[BK] ' + $rel + ' -> ' + (Split-Path -Leaf $dest))
    }
  }
}

$backupDir = Join-Path $Root ("tools/_patch_backup/" + $ts + "-eco-step-104-stabilize-points-api-list2-counts-support-prisma-v0_1")
$reportDir = Join-Path $Root "reports"
EnsureDir $backupDir
EnsureDir $reportDir

# -------- Prisma schema: ensure EcoPointSupport + opposite relation on point model --------
$schema = Join-Path $Root "prisma/schema.prisma"
if (-not (Test-Path -LiteralPath $schema)) { throw "[STOP] Nao achei prisma/schema.prisma" }
BackupFile $Root $schema $backupDir

$schemaRaw = Get-Content -LiteralPath $schema -Raw -ErrorAction Stop

# detect point model (prefer EcoCriticalPoint)
$pointModel = $null
if ($schemaRaw -match '(?s)\bmodel\s+EcoCriticalPoint\s*\{') { $pointModel = "EcoCriticalPoint" }
elseif ($schemaRaw -match '(?s)\bmodel\s+EcoPoint\s*\{') { $pointModel = "EcoPoint" }

if (-not $pointModel) {
  Write-Host "[WARN] Nao detectei EcoCriticalPoint/EcoPoint no schema. Vou manter EcoPointSupport como EcoCriticalPoint (fallback)."
  $pointModel = "EcoCriticalPoint"
}

# Ensure EcoPointSupport model exists (if missing, append)
if ($schemaRaw -notmatch '(?s)\bmodel\s+EcoPointSupport\s*\{') {
  $append = @(
    "",
    "model EcoPointSupport {",
    "  id        String   @id @default(cuid())",
    "  createdAt DateTime @default(now())",
    "  pointId   String",
    "  point     " + $pointModel + " @relation(fields: [pointId], references: [id], onDelete: Cascade)",
    "",
    "  @@index([pointId])",
    "}"
  ) -join "`n"
  $schemaRaw = $schemaRaw.TrimEnd() + "`n" + $append + "`n"
  Write-Host "[PATCH] schema.prisma: appended model EcoPointSupport"
}

# Ensure opposite relation exists on point model: supports EcoPointSupport[]
# We'll insert line before closing brace of the point model block if not present.
if ($schemaRaw -match ("(?s)\bmodel\s+" + [regex]::Escape($pointModel) + "\s*\{(.*?)\n\}")) {
  $block = $Matches[0]
  if ($block -notmatch '\bsupports\s+EcoPointSupport\[\]') {
    # insert near end before final }
    $patchedBlock = $block -replace "\n\}\s*$", "`n  supports EcoPointSupport[]`n}`n"
    $schemaRaw = $schemaRaw.Replace($block, $patchedBlock)
    Write-Host ("[PATCH] schema.prisma: added supports EcoPointSupport[] to model " + $pointModel)
  } else {
    Write-Host ("[SKIP] schema.prisma: " + $pointModel + " already has supports EcoPointSupport[]")
  }
} else {
  Write-Host ("[WARN] Nao consegui isolar bloco do model " + $pointModel + " para inserir supports.")
}

WriteUtf8NoBom $schema $schemaRaw

# Run prisma format + migrate + generate (best-effort)
$prismaCmd = Join-Path $Root "node_modules/.bin/prisma.cmd"
if (-not (Test-Path -LiteralPath $prismaCmd)) {
  $prismaCmd = Join-Path $Root "node_modules\.bin\prisma.cmd"
}
if (Test-Path -LiteralPath $prismaCmd) {
  Write-Host ("[RUN] " + $prismaCmd + " format")
  & $prismaCmd format | Out-Host

  Write-Host ("[RUN] " + $prismaCmd + " migrate dev --name eco_point_support_fix")
  & $prismaCmd migrate dev --name eco_point_support_fix | Out-Host

  Write-Host ("[RUN] " + $prismaCmd + " generate")
  & $prismaCmd generate | Out-Host
} else {
  Write-Host "[WARN] prisma.cmd nao encontrado. Pulei migrate/generate."
}

# -------- API: /api/eco/points (compat) -> delegates to list2 --------
$apiPoints = Join-Path $Root "src/app/api/eco/points/route.ts"
$apiList2  = Join-Path $Root "src/app/api/eco/points/list2/route.ts"
EnsureDir (Split-Path -Parent $apiPoints)
EnsureDir (Split-Path -Parent $apiList2)

BackupFile $Root $apiPoints $backupDir
BackupFile $Root $apiList2  $backupDir

$LPoints = @(
'import { GET as GET_LIST2 } from "./list2/route";',
'',
'export const runtime = "nodejs";',
'export const dynamic = "force-dynamic";',
'',
'export async function GET(req: Request) {',
'  return GET_LIST2(req);',
'}',
''
)
WriteAllLinesUtf8NoBom $apiPoints $LPoints
Write-Host ("[PATCH] wrote " + $apiPoints + " (compat -> list2)")

# -------- Rewrite list2 route with robust model+field detection --------
$LList2 = @(
'import { NextResponse } from "next/server";',
'import { prisma } from "@/lib/prisma";',
'',
'export const runtime = "nodejs";',
'export const dynamic = "force-dynamic";',
'',
'type AnyObj = any;',
'',
'function pickModel(pc: AnyObj, prefer: string, candidates: string[]) {',
'  const first = (pc as any)?.[prefer];',
'  if (first) return { name: prefer, model: first };',
'  for (const k of candidates) {',
'    const m = (pc as any)?.[k];',
'    if (m) return { name: k, model: m };',
'  }',
'  return { name: "", model: null as any };',
'}',
'',
'async function groupCountByCandidates(model: AnyObj, byCandidates: string[]) {',
'  const map: Record<string, number> = {};',
'  if (!model || typeof model.groupBy !== "function") return { by: "", map, ok: false };',
'',
'  for (const by of byCandidates) {',
'    try {',
'      const rows = await (model as any).groupBy({',
'        by: [by],',
'        _count: { _all: true },',
'      });',
'      for (const r of rows as any[]) {',
'        const key = String((r as any)?.[by] ?? "");',
'        if (!key) continue;',
'        const n = Number((r as any)?._count?._all ?? 0) || 0;',
'        map[key] = n;',
'      }',
'      return { by, map, ok: true };',
'    } catch (e: any) {',
'      const msg = String(e?.message || e || "");',
'      // If it is a "wrong enum/by" error, keep trying next candidate',
'      if (msg.includes("Invalid value for argument `by`") || msg.includes("ScalarFieldEnum")) {',
'        continue;',
'      }',
'      // other errors: break',
'      break;',
'    }',
'  }',
'  return { by: "", map, ok: false };',
'}',
'',
'export async function GET(req: Request) {',
'  const url = new URL(req.url);',
'  const limit = Math.max(1, Math.min(400, Number(url.searchParams.get("limit") || 160) || 160));',
'  const pc: any = prisma as any;',
'',
'  const pointPick = pickModel(pc, "ecoCriticalPoint", ["EcoCriticalPoint","ecoCriticalPoint","criticalPoint","ecoPoint","point"]);',
'  const pointModel = pointPick.model;',
'  const pointModelName = pointPick.name;',
'',
'  // confirm/support/replicar models (best-effort)',
'  const confirmPick = pickModel(pc, "ecoCriticalPointConfirm", ["EcoCriticalPointConfirm","ecoCriticalPointConfirm","ecoPointConfirm","pointConfirm","criticalPointConfirm"]);',
'  const supportPick = pickModel(pc, "ecoPointSupport", ["EcoPointSupport","ecoPointSupport","pointSupport"]);',
'  const replicPick = pickModel(pc, "ecoPointReplicar", ["EcoPointReplicar","ecoPointReplicar","ecoPointReplicate","EcoPointReplicate","pointReplicar","pointReplicate"]);',
'',
'  // detect groupBy field names by trying common options',
'  const confirmRes = await groupCountByCandidates(confirmPick.model, ["pointId","criticalPointId","ecoCriticalPointId","ecoPointId"]);',
'  const supportRes = await groupCountByCandidates(supportPick.model, ["pointId","criticalPointId","ecoCriticalPointId","ecoPointId"]);',
'  const replicRes  = await groupCountByCandidates(replicPick.model,  ["pointId","criticalPointId","ecoCriticalPointId","ecoPointId"]);',
'',
'  let items: any[] = [];',
'  let err: string | null = null;',
'  if (!pointModel || typeof pointModel.findMany !== "function") {',
'    err = "point_model_not_found";',
'  } else {',
'    try {',
'      items = await (pointModel as any).findMany({',
'        take: limit,',
'        orderBy: { createdAt: "desc" },',
'      });',
'    } catch (e: any) {',
'      err = String(e?.message || e || "points_query_failed");',
'      items = [];',
'    }',
'  }',
'',
'  const withCounts = items.map((p: any) => {',
'    const id = String(p?.id ?? "");',
'    const counts = {',
'      confirm: (confirmRes.map[id] ?? 0),',
'      support: (supportRes.map[id] ?? 0),',
'      replicar: (replicRes.map[id] ?? 0),',
'    };',
'    return { ...p, counts };',
'  });',
'',
'  return NextResponse.json({',
'    ok: !err,',
'    error: err,',
'    items: withCounts,',
'    meta: {',
'      limit,',
'      pointModel: pointModelName,',
'      confirmModel: confirmPick.name,',
'      supportModel: supportPick.name,',
'      replicarModel: replicPick.name,',
'      by: { confirm: confirmRes.by, support: supportRes.by, replicar: replicRes.by },',
'    },',
'  });',
'}',
''
)

WriteAllLinesUtf8NoBom $apiList2 $LList2
Write-Host ("[PATCH] rewrote " + $apiList2)

# -------- REPORT --------
$rep = Join-Path $reportDir ("eco-step-104-stabilize-points-api-list2-counts-support-prisma-v0_1-" + $ts + ".md")
$repText = @(
"# eco-step-104-stabilize-points-api-list2-counts-support-prisma-v0_1",
"",
"- Time: " + $ts,
"- Backup: " + $backupDir,
"",
"## Changes",
"- schema.prisma: ensured EcoPointSupport exists + added opposite relation `supports EcoPointSupport[]` on point model (" + $pointModel + ")",
"- wrote /api/eco/points/route.ts (compat -> delegates to list2)",
"- rewrote /api/eco/points/list2/route.ts with robust model+groupBy field detection + counts {confirm,support,replicar}",
"",
"## Verify",
"1) Ctrl+C -> npm run dev",
"2) irm http://localhost:3000/api/eco/points?limit=5 | ConvertTo-Json -Depth 30",
"3) abrir /eco/mural e /eco/mural/confirmados (sem 404/500)",
"4) conferir meta.by no JSON (campo detectado do groupBy)",
""
) -join "`n"
WriteUtf8NoBom $rep $repText
Write-Host ("[REPORT] " + $rep)

Write-Host ""
Write-Host "[VERIFY] Ctrl+C -> npm run dev"
Write-Host "[VERIFY] irm http://localhost:3000/api/eco/points?limit=5 | ConvertTo-Json -Depth 30"
Write-Host "[VERIFY] /eco/mural e /eco/mural/confirmados"