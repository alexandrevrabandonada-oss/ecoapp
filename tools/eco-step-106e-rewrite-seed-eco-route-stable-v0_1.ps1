param([string]$Root = (Get-Location).Path)

$ts = Get-Date -Format "yyyyMMdd-HHmmss"
Write-Host ("== eco-step-106e-rewrite-seed-eco-route-stable-v0_1 == " + $ts)
Write-Host ("[DIAG] Root: " + $Root)

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
      EnsureDir $backupDir
      $rel = $p.Substring($root.Length).TrimStart('\','/')
      $dest = Join-Path $backupDir ($rel -replace '[\\/]', '__')
      Copy-Item -Force -LiteralPath $p -Destination $dest
      Write-Host ('[BK] ' + $rel + ' -> ' + (Split-Path -Leaf $dest))
    }
  }
}

$backupDir = Join-Path $Root ("tools/_patch_backup/" + $ts + "-eco-step-106e-seed-eco")
$reportDir = Join-Path $Root "reports"
EnsureDir $backupDir
EnsureDir $reportDir

$target = Join-Path $Root "src/app/api/dev/seed-eco/route.ts"
if (-not (Test-Path -LiteralPath $target)) { throw "[STOP] Nao achei: src/app/api/dev/seed-eco/route.ts" }
BackupFile $Root $target $backupDir

$lines = @(
'import { NextResponse } from "next/server";',
'import { prisma } from "@/lib/prisma";',
'',
'export const runtime = "nodejs";',
'export const dynamic = "force-dynamic";',
'',
'type TI = { cid: number; name: string; type: string; notnull: number; dflt_value: any; pk: number };',
'',
'function mkId(prefix: string) {',
'  return prefix + "-" + Math.random().toString(36).slice(2, 8) + "-" + Date.now().toString(36);',
'}',
'',
'async function qRaw(sql: string): Promise<any[]> {',
'  const fn = (prisma as any)["$queryRawUnsafe"];',
'  const rows = await fn.call(prisma, sql);',
'  return Array.isArray(rows) ? rows : [];',
'}',
'',
'async function listTables(): Promise<string[]> {',
'  const rows = await qRaw("SELECT name FROM sqlite_master WHERE type=''table''");',
'  return rows.map((r: any) => String(r?.name ?? "")).filter(Boolean);',
'}',
'',
'function pickTable(tables: string[], candidates: string[]): string | null {',
'  const m = new Map<string, string>();',
'  for (const t of tables) m.set(t.toLowerCase(), t);',
'  for (const c of candidates) {',
'    const hit = m.get(c.toLowerCase());',
'    if (hit) return hit;',
'  }',
'  return null;',
'}',
'',
'async function tableInfo(table: string): Promise<TI[]> {',
'  const safe = table.replaceAll("''", "''''");',
'  const rows = await qRaw("PRAGMA table_info(''" + safe + "'')");',
'  return (Array.isArray(rows) ? rows : []) as TI[];',
'}',
'',
'function normType(t: string) {',
'  return String(t || "").toUpperCase();',
'}',
'',
'function pickFk(cols: TI[]): string | null {',
'  const names = cols.map(c => c.name);',
'  const pref = ["pointId", "criticalPointId", "ecoCriticalPointId"];',
'  for (const p of pref) if (names.includes(p)) return p;',
'  const anyId = names.find(n => n !== "id" && /Id$/.test(n));',
'  return anyId || null;',
'}',
'',
'function valueFor(col: TI, i: number, pointId?: string) {',
'  const n = col.name;',
'  const t = normType(col.type);',
'',
'  if (n === "actor") return "dev";',
'  if (n === "status") return "OPEN";',
'  if (n === "kind") return "LIXO_ACUMULADO";',
'  if (n === "lat") return -22.520 + i * 0.0007;',
'  if (n === "lng") return -44.104 + i * 0.0007;',
'  if (n === "createdAt" || n === "updatedAt") return new Date();',
'  if ((n === "pointId" || n === "criticalPointId" || n === "ecoCriticalPointId") && pointId) return pointId;',
'',
'  if (t.includes("INT")) return 0;',
'  if (t.includes("REAL") || t.includes("FLOA") || t.includes("DOUB") || t.includes("DEC")) return 0;',
'  if (t.includes("BOOL")) return false;',
'  if (t.includes("DATE") || t.includes("TIME")) return new Date();',
'  return "seed";',
'}',
'',
'function buildData(cols: TI[], i: number, prefix: string, pointId?: string) {',
'  const data: any = {};',
'  const fk = pointId ? pickFk(cols) : null;',
'',
'  for (const c of cols) {',
'    // skip integer primary key (autoincrement)',
'    if (c.pk === 1 && normType(c.type).includes("INT")) continue;',
'',
'    // force ids when text pk, otherwise let db default',
'    if (c.name === "id" && !normType(c.type).includes("INT")) {',
'      data.id = mkId(prefix);',
'      continue;',
'    }',
'',
'    if (fk && c.name === fk && pointId) {',
'      data[c.name] = pointId;',
'      continue;',
'    }',
'',
'    if (c.notnull === 1 && (c.dflt_value === null || c.dflt_value === undefined)) {',
'      data[c.name] = valueFor(c, i, pointId);',
'    }',
'  }',
'',
'  // safety: guarantee actor is a string if present',
'  if ("actor" in data && typeof data.actor !== "string") data.actor = "dev";',
'  return data;',
'}',
'',
'export async function GET(req: Request) {',
'  if (process.env.NODE_ENV !== "development") {',
'    return NextResponse.json({ ok: false, error: "dev_only" }, { status: 404 });',
'  }',
'',
'  const { searchParams } = new URL(req.url);',
'  const n = Math.max(1, Math.min(30, Number(searchParams.get("n") || "3")));',
'  const doConfirm = Number(searchParams.get("confirm") || "0") > 0;',
'  const doSupport = Number(searchParams.get("support") || "0") > 0;',
'  const doReplicar = Number(searchParams.get("replicar") || searchParams.get("replicate") || "0") > 0;',
'',
'  const pc: any = prisma as any;',
'  const pointKey = ["ecoCriticalPoint", "ecoPoint", "criticalPoint", "point"].find(k => pc?.[k] && typeof pc[k].create === "function");',
'  if (!pointKey) return NextResponse.json({ ok: false, error: "point_model_not_found" }, { status: 500 });',
'',
'  const confirmKey = ["ecoCriticalPointConfirm", "ecoPointConfirm", "criticalPointConfirm", "pointConfirm"].find(k => pc?.[k] && typeof pc[k].create === "function");',
'  const supportKey = ["ecoPointSupport", "pointSupport"].find(k => pc?.[k] && typeof pc[k].create === "function");',
'  const replicarKey = ["ecoPointReplicate", "pointReplicate", "ecoPointReplicar"].find(k => pc?.[k] && typeof pc[k].create === "function");',
'',
'  const tables = await listTables();',
'  const pointTable = pickTable(tables, ["EcoCriticalPoint", "EcoPoint", "CriticalPoint", "Point", pointKey]);',
'  if (!pointTable) return NextResponse.json({ ok: false, error: "point_table_not_found", pointKey }, { status: 500 });',
'',
'  const pointCols = await tableInfo(pointTable);',
'  const confirmTable = confirmKey ? pickTable(tables, ["EcoCriticalPointConfirm", "EcoPointConfirm", "CriticalPointConfirm", "PointConfirm", confirmKey]) : null;',
'  const supportTable = supportKey ? pickTable(tables, ["EcoPointSupport", "PointSupport", supportKey]) : null;',
'  const replicarTable = replicarKey ? pickTable(tables, ["EcoPointReplicate", "PointReplicate", "EcoPointReplicar", replicarKey]) : null;',
'',
'  const confirmCols = doConfirm && confirmKey && confirmTable ? await tableInfo(confirmTable) : null;',
'  const supportCols = doSupport && supportKey && supportTable ? await tableInfo(supportTable) : null;',
'  const replicarCols = doReplicar && replicarKey && replicarTable ? await tableInfo(replicarTable) : null;',
'',
'  let createdPoints = 0;',
'  let createdConfirm = 0;',
'  let createdSupport = 0;',
'  let createdReplicar = 0;',
'  const createdIds: string[] = [];',
'',
'  for (let i = 0; i < n; i++) {',
'    const pData = buildData(pointCols, i, "p");',
'    const p = await pc[pointKey].create({ data: pData });',
'    const pid = String(p?.id ?? pData.id);',
'    createdIds.push(pid);',
'    createdPoints++;',
'',
'    if (doConfirm && confirmCols && confirmKey) {',
'      const cData = buildData(confirmCols, i, "c", pid);',
'      await pc[confirmKey].create({ data: cData });',
'      createdConfirm++;',
'    }',
'    if (doSupport && supportCols && supportKey) {',
'      const sData = buildData(supportCols, i, "s", pid);',
'      await pc[supportKey].create({ data: sData });',
'      createdSupport++;',
'    }',
'    if (doReplicar && replicarCols && replicarKey) {',
'      const rData = buildData(replicarCols, i, "r", pid);',
'      await pc[replicarKey].create({ data: rData });',
'      createdReplicar++;',
'    }',
'  }',
'',
'  return NextResponse.json({',
'    ok: true,',
'    created: { points: createdPoints, confirm: createdConfirm, support: createdSupport, replicar: createdReplicar },',
'    models: { pointKey, confirmKey, supportKey, replicarKey },',
'    tables: { pointTable, confirmTable, supportTable, replicarTable },',
'    sampleIds: createdIds.slice(0, 5),',
'  });',
'}',
''
)

$codeOut = ($lines -join "`n")
WriteUtf8NoBom $target $codeOut
Write-Host ("[PATCH] rewrote " + $target)

$rep = Join-Path $reportDir ("eco-step-106e-rewrite-seed-eco-route-stable-v0_1-" + $ts + ".md")
$repText = @(
"# eco-step-106e-rewrite-seed-eco-route-stable-v0_1",
"",
"- Time: " + $ts,
"- Backup: " + $backupDir,
"- Patched: src/app/api/dev/seed-eco/route.ts",
"",
"## What/Why",
"- Reescreve a rota de seed para NAO gerar valores invalidos (ex.: actor: String).",
"- Usa PRAGMA table_info + defaults seguros (actor='dev', status='OPEN', kind='LIXO_ACUMULADO').",
"",
"## Verify",
"1) Ctrl+C -> npm run dev",
"2) irm 'http://localhost:3000/api/dev/seed-eco?n=3&confirm=1&support=1' | ConvertTo-Json -Depth 80",
"3) irm 'http://localhost:3000/api/eco/points?limit=5' | ConvertTo-Json -Depth 100",
"4) abrir /eco/mural e /eco/mural/confirmados"
) -join "`n"
WriteUtf8NoBom $rep $repText
Write-Host ("[REPORT] " + $rep)

Write-Host ""
Write-Host "[VERIFY] rode:"
Write-Host "  irm 'http://localhost:3000/api/dev/seed-eco?n=3&confirm=1&support=1' | ConvertTo-Json -Depth 80"
Write-Host "  irm 'http://localhost:3000/api/eco/points?limit=5' | ConvertTo-Json -Depth 100"