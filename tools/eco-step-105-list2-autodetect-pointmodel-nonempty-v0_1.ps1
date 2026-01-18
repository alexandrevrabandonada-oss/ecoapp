param([string]$Root = (Get-Location).Path)

$ts = Get-Date -Format "yyyyMMdd-HHmmss"
Write-Host ("== eco-step-105-list2-autodetect-pointmodel-nonempty-v0_1 == " + $ts)
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

$backupDir = Join-Path $Root ("tools/_patch_backup/" + $ts + "-eco-step-105-list2-autodetect-pointmodel-nonempty-v0_1")
$reportDir = Join-Path $Root "reports"
EnsureDir $backupDir
EnsureDir $reportDir

$apiList2  = Join-Path $Root "src/app/api/eco/points/list2/route.ts"
if (-not (Test-Path -LiteralPath $apiList2)) { throw "[STOP] Nao achei: src/app/api/eco/points/list2/route.ts" }
BackupFile $Root $apiList2 $backupDir

$L = @(
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
'async function safeCount(m: AnyObj): Promise<number> {',
'  try {',
'    if (m && typeof m.count === "function") {',
'      const n = await m.count();',
'      return Number.isFinite(Number(n)) ? Number(n) : 0;',
'    }',
'    if (m && typeof m.findMany === "function") {',
'      const one = await m.findMany({ take: 1, select: { id: true } });',
'      return Array.isArray(one) ? one.length : 0;',
'    }',
'  } catch {',
'    // ignore',
'  }',
'  return 0;',
'}',
'',
'async function pickBestPointModel(pc: AnyObj) {',
'  const names = ["ecoCriticalPoint","EcoCriticalPoint","ecoPoint","EcoPoint","criticalPoint","point"];',
'  // choose first existing with count>0; if none, choose first existing',
'  let fallback: { name: string; model: AnyObj } | null = null;',
'  for (const nm of names) {',
'    const m = (pc as any)?.[nm];',
'    if (!m) continue;',
'    if (!fallback) fallback = { name: nm, model: m };',
'    const n = await safeCount(m);',
'    if (n > 0) return { name: nm, model: m, total: n };',
'  }',
'  if (fallback) return { ...fallback, total: 0 };',
'  return { name: "", model: null as any, total: 0 };',
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
'      if (msg.includes("Invalid value for argument `by`") || msg.includes("ScalarFieldEnum")) {',
'        continue;',
'      }',
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
'  const pointSel = await pickBestPointModel(pc);',
'  const pointModel = pointSel.model;',
'  const pointModelName = pointSel.name;',
'',
'  const confirmPick = pickModel(pc, "ecoCriticalPointConfirm", ["EcoCriticalPointConfirm","ecoCriticalPointConfirm","ecoPointConfirm","pointConfirm","criticalPointConfirm"]);',
'  const supportPick = pickModel(pc, "ecoPointSupport", ["EcoPointSupport","ecoPointSupport","pointSupport"]);',
'  const replicPick  = pickModel(pc, "ecoPointReplicate", ["EcoPointReplicar","ecoPointReplicar","ecoPointReplicate","EcoPointReplicate","pointReplicar","pointReplicate"]);',
'',
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
'      // try createdAt desc, fallback to id desc',
'      try {',
'        items = await (pointModel as any).findMany({ take: limit, orderBy: { createdAt: "desc" } });',
'      } catch {',
'        items = await (pointModel as any).findMany({ take: limit, orderBy: { id: "desc" } });',
'      }',
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
'      pointTotalGuess: pointSel.total,',
'      confirmModel: confirmPick.name,',
'      supportModel: supportPick.name,',
'      replicarModel: replicPick.name,',
'      by: { confirm: confirmRes.by, support: supportRes.by, replicar: replicRes.by },',
'    },',
'  });',
'}',
''
)

WriteAllLinesUtf8NoBom $apiList2 $L
Write-Host ("[PATCH] updated " + $apiList2 + " (auto-detect non-empty point model)")

$rep = Join-Path $reportDir ("eco-step-105-list2-autodetect-pointmodel-nonempty-v0_1-" + $ts + ".md")
$repText = @(
"# eco-step-105-list2-autodetect-pointmodel-nonempty-v0_1",
"",
"- Time: " + $ts,
"- Backup: " + $backupDir,
"",
"## Changes",
"- Updated: src/app/api/eco/points/list2/route.ts",
"  - pickBestPointModel(): escolhe o primeiro model existente com count>0 (fallback p/ primeiro existente)",
"  - findMany: tenta orderBy createdAt desc e cai p/ id desc",
"  - meta.pointTotalGuess para depurar",
"",
"## Verify",
"1) Ctrl+C -> npm run dev",
"2) irm http://localhost:3000/api/eco/points?limit=5 | ConvertTo-Json -Depth 40",
"3) confira meta.pointModel e se items veio >0",
""
) -join "`n"
WriteUtf8NoBom $rep $repText
Write-Host ("[REPORT] " + $rep)

Write-Host ""
Write-Host "[VERIFY] Ctrl+C -> npm run dev"
Write-Host "[VERIFY] irm http://localhost:3000/api/eco/points?limit=5 | ConvertTo-Json -Depth 40"