param([string]$Root = (Get-Location).Path)

$ts = Get-Date -Format "yyyyMMdd-HHmmss"
Write-Host ("== eco-step-100d-rewrite-points-list2-route-v0_1 == " + $ts)
Write-Host ("[DIAG] Root: " + $Root)

# bootstrap (best effort)
$boot = Join-Path $Root "tools/_bootstrap.ps1"
if (Test-Path -LiteralPath $boot) { . $boot }

if (-not (Get-Command EnsureDir -ErrorAction SilentlyContinue)) {
  function EnsureDir([string]$p) { if (-not (Test-Path -LiteralPath $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null } }
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

$target = Join-Path $Root "src/app/api/eco/points/list2/route.ts"
$backupDir = Join-Path $Root ("tools/_patch_backup/" + $ts + "-eco-step-100d-rewrite-points-list2-route-v0_1")
$reportDir = Join-Path $Root "reports"
EnsureDir $backupDir
EnsureDir $reportDir
BackupFile $Root $target $backupDir

Write-Host ("[DIAG] Will rewrite: " + $target)

# Write route.ts as lines (avoid PS escaping issues)
$L = New-Object System.Collections.Generic.List[string]

$L.Add('import { NextResponse } from "next/server";')
$L.Add('import { prisma } from "@/lib/prisma";')
$L.Add('')
$L.Add('export const runtime = "nodejs";')
$L.Add('export const dynamic = "force-dynamic";')
$L.Add('')
$L.Add('type AnyObj = any;')
$L.Add('')
$L.Add('function safeInt(v: string | null, def: number): number {')
$L.Add('  const n = Number(v);')
$L.Add('  return Number.isFinite(n) && n > 0 ? Math.floor(n) : def;')
$L.Add('}')
$L.Add('')
$L.Add('function pickModel(pc: AnyObj, primary: string, alts: string[]): { name: string; model: AnyObj } | null {')
$L.Add('  if (!pc) return null;')
$L.Add('  if (pc[primary]) return { name: primary, model: pc[primary] };')
$L.Add('  for (const n of alts) {')
$L.Add('    if (pc[n]) return { name: n, model: pc[n] };')
$L.Add('  }')
$L.Add('  return null;')
$L.Add('}')
$L.Add('')
$L.Add('async function groupCountBy(model: AnyObj, candidates: string[]): Promise<{ field: string; map: Record<string, number> }> {')
$L.Add('  const map: Record<string, number> = {};')
$L.Add('  if (!model || typeof model.groupBy !== "function") return { field: "", map };')
$L.Add('  for (const field of candidates) {')
$L.Add('    try {')
$L.Add('      const rows = await model.groupBy({')
$L.Add('        by: [field] as any,')
$L.Add('        _count: { _all: true } as any,')
$L.Add('      } as any);')
$L.Add('      for (const r of rows as any[]) {')
$L.Add('        const k = String((r as any)[field] ?? "");')
$L.Add('        const n = Number((r as any)?._count?._all ?? 0);')
$L.Add('        if (k) map[k] = n;')
$L.Add('      }')
$L.Add('      return { field, map };')
$L.Add('    } catch (e) {')
$L.Add('      // try next candidate')
$L.Add('    }')
$L.Add('  }')
$L.Add('  return { field: "", map };')
$L.Add('}')
$L.Add('')
$L.Add('function normStatus(v: string | null): string | null {')
$L.Add('  if (!v) return null;')
$L.Add('  const s = String(v).trim().toUpperCase();')
$L.Add('  if (s === "OPEN" || s === "RESOLVED" || s === "MUTIRAO") return s;')
$L.Add('  return null;')
$L.Add('}')
$L.Add('')
$L.Add('export async function GET(req: Request) {')
$L.Add('  const url = new URL(req.url);')
$L.Add('  const limit = safeInt(url.searchParams.get("limit"), 160);')
$L.Add('  const status = normStatus(url.searchParams.get("status"));')
$L.Add('')
$L.Add('  const pc: AnyObj = prisma as any;')
$L.Add('')
$L.Add('  const pointPick = pickModel(pc, "ecoCriticalPoint", ["EcoCriticalPoint", "criticalPoint", "ecoPoint", "point"]);')
$L.Add('  if (!pointPick || !pointPick.model || typeof pointPick.model.findMany !== "function") {')
$L.Add('    return NextResponse.json({ ok: false, error: "point_model_not_found" }, { status: 500 });')
$L.Add('  }')
$L.Add('')
$L.Add('  const where: AnyObj = {};')
$L.Add('  if (status) where.status = status;')
$L.Add('')
$L.Add('  let items: AnyObj[] = [];')
$L.Add('  try {')
$L.Add('    items = await pointPick.model.findMany({ take: limit, where, orderBy: { createdAt: "desc" } } as any);')
$L.Add('  } catch (e) {')
$L.Add('    items = await pointPick.model.findMany({ take: limit, where } as any);')
$L.Add('  }')
$L.Add('')
$L.Add('  const confirmPick = pickModel(pc, "ecoCriticalPointConfirm", ["EcoCriticalPointConfirm", "ecoPointConfirm", "pointConfirm", "criticalPointConfirm"]);')
$L.Add('  const supportPick = pickModel(pc, "ecoPointSupport", ["EcoPointSupport", "pointSupport", "ecoCriticalPointSupport", "criticalPointSupport"]);')
$L.Add('')
$L.Add('  const fieldCandidates = ["pointId", "criticalPointId", "ecoCriticalPointId", "ecoPointId"];')
$L.Add('  const confirmCounts = await groupCountBy(confirmPick?.model, fieldCandidates);')
$L.Add('  const supportCounts = await groupCountBy(supportPick?.model, fieldCandidates);')
$L.Add('')
$L.Add('  const out = items.map((p: AnyObj) => {')
$L.Add('    const id = String(p?.id ?? "");')
$L.Add('    const prev = (p && typeof p === "object" ? (p as any).counts : null) || {};')
$L.Add('    const counts = {')
$L.Add('      ...prev,')
$L.Add('      confirm: confirmCounts.map[id] ?? prev.confirm ?? 0,')
$L.Add('      support: supportCounts.map[id] ?? prev.support ?? 0,')
$L.Add('    };')
$L.Add('    return { ...p, counts };')
$L.Add('  });')
$L.Add('')
$L.Add('  return NextResponse.json({')
$L.Add('    ok: true,')
$L.Add('    items: out,')
$L.Add('    meta: {')
$L.Add('      pointModel: pointPick.name,')
$L.Add('      confirmModel: confirmPick?.name ?? "",')
$L.Add('      confirmBy: confirmCounts.field,')
$L.Add('      supportModel: supportPick?.name ?? "",')
$L.Add('      supportBy: supportCounts.field,')
$L.Add('      limit,')
$L.Add('      status: status ?? "",')
$L.Add('    },')
$L.Add('  }, { headers: { "Cache-Control": "no-store" } });')
$L.Add('}')
$L.Add('')

WriteUtf8NoBom $target ($L -join "`n")
Write-Host ("[PATCH] rewrote " + $target)

$rep = Join-Path $reportDir ("eco-step-100d-rewrite-points-list2-route-v0_1-" + $ts + ".md")
$repText = @(
  '# eco-step-100d-rewrite-points-list2-route-v0_1',
  '',
  ('- Time: ' + $ts),
  ('- Backup: ' + $backupDir),
  '',
  '## Why',
  '- list2 estava quebrando com groupBy(by: ["criticalPointId"]) porque o campo real varia conforme o schema.',
  '- Tambem tivemos strings quebradas em multiplas linhas em patches anteriores.',
  '',
  '## What changed',
  '- Reescreveu src/app/api/eco/points/list2/route.ts com:',
  '  - pickModel dinamico (ecoCriticalPoint / ecoCriticalPointConfirm / ecoPointSupport etc)',
  '  - groupCountBy tenta pointId / criticalPointId / ecoCriticalPointId / ecoPointId e usa o primeiro que funcionar',
  '  - injeta counts.confirm e counts.support em cada item',
  '',
  '## Verify',
  '1) Ctrl+C -> npm run dev',
  '2) GET http://localhost:3000/api/eco/points/list2?limit=10 (status 200, meta.confirmBy nao vazio se existir confirm model)',
  '3) Abrir /eco/mural e /eco/mural/confirmados (sem 500)'
) -join "`n"
WriteUtf8NoBom $rep $repText
Write-Host ("[REPORT] " + $rep)

Write-Host ""
Write-Host "[VERIFY] Ctrl+C -> npm run dev"
Write-Host "[VERIFY] GET /api/eco/points/list2?limit=10"
Write-Host "[VERIFY] /eco/mural e /eco/mural/confirmados"