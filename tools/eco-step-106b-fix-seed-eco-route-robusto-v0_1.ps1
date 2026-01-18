param([string]$Root = (Get-Location).Path)

$ts = Get-Date -Format "yyyyMMdd-HHmmss"
Write-Host ("== eco-step-106b-fix-seed-eco-route-robusto-v0_1 == " + $ts)
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
      $rel = $p.Substring($root.Length).TrimStart('\','/')
      $dest = Join-Path $backupDir ($rel -replace '[\\/]', '__')
      Copy-Item -Force -LiteralPath $p -Destination $dest
      Write-Host ('[BK] ' + $rel + ' -> ' + (Split-Path -Leaf $dest))
    }
  }
}

$backupDir = Join-Path $Root ("tools/_patch_backup/" + $ts + "-eco-step-106b-fix-seed-eco-route-robusto-v0_1")
$reportDir = Join-Path $Root "reports"
EnsureDir $backupDir
EnsureDir $reportDir

$target = Join-Path $Root "src/app/api/dev/seed-eco/route.ts"
if (-not (Test-Path -LiteralPath $target)) { throw "[STOP] Nao achei: src/app/api/dev/seed-eco/route.ts" }

BackupFile $Root $target $backupDir

$L = @()
$L += 'import { NextResponse } from "next/server";'
$L += 'import { prisma } from "@/lib/prisma";'
$L += 'import { randomUUID } from "crypto";'
$L += ''
$L += 'export const runtime = "nodejs";'
$L += 'export const dynamic = "force-dynamic";'
$L += ''
$L += 'type TI = { cid: number; name: string; type: string; notnull: number; dflt_value: any; pk: number };'
$L += ''
$L += 'function toInt(v: string | null, def: number) {'
$L += '  const n = Number(v);'
$L += '  return Number.isFinite(n) ? n : def;'
$L += '}'
$L += ''
$L += 'function pickModel(pc: any, candidates: string[]) {'
$L += '  for (const k of candidates) {'
$L += '    const v = (pc as any)?.[k];'
$L += '    if (v) return { key: k, model: v };'
$L += '  }'
$L += '  return { key: "", model: null as any };'
$L += '}'
$L += ''
$L += 'function guessTableNameFromDelegateKey(key: string) {'
$L += '  if (!key) return "";'
$L += '  return key.charAt(0).toUpperCase() + key.slice(1);'
$L += '}'
$L += ''
$L += 'async function listTables(): Promise<string[]> {'
$L += '  try {'
$L += '    const rows = await prisma.$queryRawUnsafe<any[]>("SELECT name FROM sqlite_master WHERE type=''table''");'
$L += '    if (!Array.isArray(rows)) return [];'
$L += '    return rows.map((r: any) => String(r?.name || "")).filter(Boolean);'
$L += '  } catch {'
$L += '    return [];'
$L += '  }'
$L += '}'
$L += ''
$L += 'async function tableInfo(table: string): Promise<TI[]> {'
$L += '  const q = "PRAGMA table_info(\\"" + table + "\\")";'
$L += '  const rows = await prisma.$queryRawUnsafe<any[]>(q);'
$L += '  return (Array.isArray(rows) ? rows : []) as TI[];'
$L += '}'
$L += ''
$L += 'async function findTableForDelegateKey(delegateKey: string): Promise<string | null> {'
$L += '  const guess = guessTableNameFromDelegateKey(delegateKey);'
$L += '  if (guess) {'
$L += '    try {'
$L += '      const info = await tableInfo(guess);'
$L += '      if (info.length > 0) return guess;'
$L += '    } catch {}'
$L += '  }'
$L += '  const tables = await listTables();'
$L += '  const gl = guess.toLowerCase();'
$L += '  let hit = tables.find(t => t.toLowerCase() === gl);'
$L += '  if (hit) return hit;'
$L += '  hit = tables.find(t => t.toLowerCase().includes(gl));'
$L += '  return hit || null;'
$L += '}'
$L += ''
$L += 'function isNullish(v: any) {'
$L += '  return v === null || typeof v === "undefined";'
$L += '}'
$L += ''
$L += 'function coerceByType(colType: string, v: any) {'
$L += '  const t = String(colType || "").toUpperCase();'
$L += '  if (t.includes("INT")) return Number.isFinite(Number(v)) ? Number(v) : 1;'
$L += '  if (t.includes("REAL") || t.includes("FLOA") || t.includes("DOUB")) return Number.isFinite(Number(v)) ? Number(v) : 0;'
$L += '  return v;'
$L += '}'
$L += ''
$L += 'function fillFor(name: string, colType: string, i: number) {'
$L += '  const n = name.toLowerCase();'
$L += '  if (n === "id") return randomUUID();'
$L += '  if (n.endsWith("id")) return randomUUID();'
$L += '  if (n.includes("bairro") || n.includes("neigh")) return "Centro";'
$L += '  if (n.includes("title") || n.includes("titulo") || n.includes("nome")) return "Ponto critico (seed #" + String(i + 1) + ")";'
$L += '  if (n.includes("desc") || n.includes("descricao")) return "Exemplo para testes (seed).";'
$L += '  if (n === "lat" || n.includes("latitude")) return -22.52 + (i * 0.001);'
$L += '  if (n === "lng" || n.includes("longitude")) return -44.10 + (i * 0.001);'
$L += '  if (n.includes("status")) return "OPEN";'
$L += '  if (n.includes("cidade") || n.includes("city")) return "Volta Redonda";'
$L += '  if (n.includes("endereco") || n.includes("address")) return "Volta Redonda";'
$L += '  if (n.includes("source") || n.includes("origem")) return "seed";'
$L += '  if (n.includes("tipo") || n.includes("kind") || n.includes("category") || n.includes("categoria")) return "OUTRO";'
$L += '  if (n.includes("createdat") || n.includes("created_at")) return new Date();'
$L += '  if (n.includes("updatedat") || n.includes("updated_at")) return new Date();'
$L += '  return coerceByType(colType, "seed");'
$L += '}'
$L += ''
$L += 'function buildData(info: TI[], overrides: Record<string, any>, i: number) {'
$L += '  const data: Record<string, any> = {};'
$L += '  for (const r of info) {'
$L += '    const name = String((r as any)?.name || "");'
$L += '    if (!name) continue;'
$L += '    const notnull = Number((r as any)?.notnull || 0);'
$L += '    const pk = Number((r as any)?.pk || 0);'
$L += '    const dflt = (r as any)?.dflt_value;'
$L += '    const needs = ((notnull === 1) || (pk === 1)) && isNullish(dflt);'
$L += '    if (!needs) continue;'
$L += '    if (Object.prototype.hasOwnProperty.call(overrides, name)) {'
$L += '      data[name] = overrides[name];'
$L += '    } else {'
$L += '      data[name] = fillFor(name, String((r as any)?.type || ""), i);'
$L += '    }'
$L += '  }'
$L += '  return data;'
$L += '}'
$L += ''
$L += 'function findFkName(info: TI[]) {'
$L += '  const names = info.map(r => String((r as any)?.name || "")).filter(Boolean);'
$L += '  const preferred = ["pointId", "criticalPointId", "ecoCriticalPointId", "ecoPointId"];'
$L += '  for (const p of preferred) {'
$L += '    if (names.includes(p)) return p;'
$L += '  }'
$L += '  const hit = names.find(n => n.toLowerCase().endsWith("pointid"));'
$L += '  return hit || "";'
$L += '}'
$L += ''
$L += 'export async function GET(req: Request) {'
$L += '  const url = new URL(req.url);'
$L += '  const n = Math.max(1, Math.min(50, toInt(url.searchParams.get("n"), 3)));'
$L += '  const wantConfirm = toInt(url.searchParams.get("confirm"), 1) > 0;'
$L += '  const wantSupport = toInt(url.searchParams.get("support"), 0) > 0;'
$L += '  const wantReplicar = toInt(url.searchParams.get("replicar"), 0) > 0;'
$L += ''
$L += '  const pc: any = prisma as any;'
$L += ''
$L += '  const pointPick = pickModel(pc, ["ecoCriticalPoint", "criticalPoint", "ecoPoint", "point"]);'
$L += '  const confirmPick = pickModel(pc, ["ecoCriticalPointConfirm", "criticalPointConfirm", "ecoPointConfirm", "pointConfirm"]);'
$L += '  const supportPick = pickModel(pc, ["ecoPointSupport", "pointSupport"]);'
$L += '  const replicarPick = pickModel(pc, ["ecoPointReplicate", "pointReplicate", "ecoPointReplicar", "pointReplicar"]);'
$L += ''
$L += '  if (!pointPick.model) {'
$L += '    return NextResponse.json({ ok: false, error: "point_model_not_found", meta: { candidates: ["ecoCriticalPoint","criticalPoint","ecoPoint","point"] } }, { status: 500 });'
$L += '  }'
$L += ''
$L += '  const pointTable = await findTableForDelegateKey(pointPick.key);'
$L += '  if (!pointTable) {'
$L += '    return NextResponse.json({ ok: false, error: "point_table_not_found", meta: { pointKey: pointPick.key } }, { status: 500 });'
$L += '  }'
$L += ''
$L += '  const pInfo = await tableInfo(pointTable);'
$L += ''
$L += '  let cInfo: TI[] = [];'
$L += '  let cFk = "";'
$L += '  if (wantConfirm && confirmPick.model) {'
$L += '    const cTable = await findTableForDelegateKey(confirmPick.key);'
$L += '    if (cTable) {'
$L += '      cInfo = await tableInfo(cTable);'
$L += '      cFk = findFkName(cInfo);'
$L += '    }'
$L += '  }'
$L += ''
$L += '  let sInfo: TI[] = [];'
$L += '  let sFk = "";'
$L += '  if (wantSupport && supportPick.model) {'
$L += '    const sTable = await findTableForDelegateKey(supportPick.key);'
$L += '    if (sTable) {'
$L += '      sInfo = await tableInfo(sTable);'
$L += '      sFk = findFkName(sInfo);'
$L += '    }'
$L += '  }'
$L += ''
$L += '  let rInfo: TI[] = [];'
$L += '  let rFk = "";'
$L += '  if (wantReplicar && replicarPick.model) {'
$L += '    const rTable = await findTableForDelegateKey(replicarPick.key);'
$L += '    if (rTable) {'
$L += '      rInfo = await tableInfo(rTable);'
$L += '      rFk = findFkName(rInfo);'
$L += '    }'
$L += '  }'
$L += ''
$L += '  const created: any[] = [];'
$L += '  const made: any = { points: 0, confirms: 0, supports: 0, replicar: 0 };'
$L += ''
$L += '  for (let i = 0; i < n; i++) {'
$L += '    const pData = buildData(pInfo, {}, i);'
$L += '    const p = await pointPick.model.create({ data: pData as any });'
$L += '    created.push(p);'
$L += '    made.points++;'
$L += ''
$L += '    const pid = String((p as any)?.id || "");'
$L += ''
$L += '    if (wantConfirm && confirmPick.model && cInfo.length > 0 && cFk && pid) {'
$L += '      const o: any = {};'
$L += '      o[cFk] = pid;'
$L += '      const cData = buildData(cInfo, o, i);'
$L += '      await confirmPick.model.create({ data: cData as any });'
$L += '      made.confirms++;'
$L += '    }'
$L += ''
$L += '    if (wantSupport && supportPick.model && sInfo.length > 0 && sFk && pid) {'
$L += '      const o: any = {};'
$L += '      o[sFk] = pid;'
$L += '      const sData = buildData(sInfo, o, i);'
$L += '      await supportPick.model.create({ data: sData as any });'
$L += '      made.supports++;'
$L += '    }'
$L += ''
$L += '    if (wantReplicar && replicarPick.model && rInfo.length > 0 && rFk && pid) {'
$L += '      const o: any = {};'
$L += '      o[rFk] = pid;'
$L += '      const rData = buildData(rInfo, o, i);'
$L += '      await replicarPick.model.create({ data: rData as any });'
$L += '      made.replicar++;'
$L += '    }'
$L += '  }'
$L += ''
$L += '  return NextResponse.json({ ok: true, error: null, made, meta: { pointKey: pointPick.key, confirmKey: confirmPick.key, supportKey: supportPick.key, replicarKey: replicarPick.key, pointTable }, items: created });'
$L += '}'
$L += ''

WriteUtf8NoBom $target ($L -join "`n")
Write-Host ("[PATCH] rewrote " + $target)

$rep = Join-Path $reportDir ("eco-step-106b-fix-seed-eco-route-robusto-v0_1-" + $ts + ".md")
$repText = @(
"# eco-step-106b-fix-seed-eco-route-robusto-v0_1",
"",
"- Time: $ts",
"- Backup: $backupDir",
"- Patched: src/app/api/dev/seed-eco/route.ts",
"",
"## Why",
"- O seed antigo quebrava com `model_block_not_found` (parser fragil de schema).",
"- Este seed detecta models via Prisma + descobre colunas via PRAGMA table_info (SQLite).",
"",
"## Verify",
"1) npm run dev",
"2) irm 'http://localhost:3000/api/dev/seed-eco?n=3&confirm=1&support=1' | ConvertTo-Json -Depth 50",
"3) irm 'http://localhost:3000/api/eco/points?limit=5' | ConvertTo-Json -Depth 80",
"4) /eco/mural e /eco/mural/confirmados"
) -join "`n"
WriteUtf8NoBom $rep $repText
Write-Host ("[REPORT] " + $rep)

Write-Host ""
Write-Host "[VERIFY] rode:"
Write-Host "  irm 'http://localhost:3000/api/dev/seed-eco?n=3&confirm=1&support=1' | ConvertTo-Json -Depth 60"
Write-Host "  irm 'http://localhost:3000/api/eco/points?limit=5' | ConvertTo-Json -Depth 80"