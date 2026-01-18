param([string]$Root = (Get-Location).Path, [string]$BaseUrl = "http://localhost:3000")

$ts = Get-Date -Format "yyyyMMdd-HHmmss"
Write-Host ("== eco-step-106-seed-eco-pontos-dev-v0_1 == " + $ts)
Write-Host ("[DIAG] Root: " + $Root)
Write-Host ("[DIAG] BaseUrl: " + $BaseUrl)

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

$backupDir = Join-Path $Root ("tools/_patch_backup/" + $ts + "-eco-step-106-seed-eco-pontos-dev-v0_1")
$reportDir = Join-Path $Root "reports"
EnsureDir $backupDir
EnsureDir $reportDir

$seedRoute = Join-Path $Root "src/app/api/dev/seed-eco/route.ts"
BackupFile $Root $seedRoute $backupDir

$L = @(
'import { NextResponse } from "next/server";',
'import { prisma } from "@/lib/prisma";',
'import { promises as fs } from "fs";',
'import path from "path";',
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
'async function readSchema(): Promise<string> {',
'  const p = path.join(process.cwd(), "prisma", "schema.prisma");',
'  return await fs.readFile(p, "utf8");',
'}',
'',
'function findBlock(schema: string, kind: "model" | "enum", wantLowerNames: string[]) {',
'  const lines = schema.split(/\\r?\\n/);',
'  for (let i = 0; i < lines.length; i++) {',
'    const m = lines[i].match(/^\\s*(model|enum)\\s+(\\w+)\\s*\\{\\s*$/);',
'    if (!m) continue;',
'    const k = m[1] as any;',
'    const name = m[2];',
'    if (k !== kind) continue;',
'    if (!wantLowerNames.includes(String(name).toLowerCase())) continue;',
'',
'    // collect until matching "}" at column 0-ish',
'    const body: string[] = [];',
'    i++;',
'    for (; i < lines.length; i++) {',
'      const ln = lines[i];',
'      if (ln.match(/^\\s*\\}\\s*$/)) break;',
'      body.push(ln);',
'    }',
'    return { name, body: body.join("\\n") };',
'  }',
'  return { name: "", body: "" };',
'}',
'',
'function parseFields(modelBody: string) {',
'  const scalarSet = new Set(["String","Int","Float","Boolean","DateTime","Json","BigInt","Bytes","Decimal"]);',
'  const fields: { name: string; typ: string; optional: boolean; hasDefault: boolean; isList: boolean; isRelation: boolean; isEnum: boolean; }[] = [];',
'  const lines = modelBody.split(/\\r?\\n/);',
'  for (const raw of lines) {',
'    const line = raw.replace(/#.*/, "").trim();',
'    if (!line) continue;',
'    if (line.startsWith("@@")) continue;',
'    // field: name type ...',
'    const parts = line.split(/\\s+/);',
'    if (parts.length < 2) continue;',
'    const fname = parts[0];',
'    let t = parts[1];',
'    const hasDefault = line.includes("@default") || line.includes("@updatedAt");',
'    const isList = t.endsWith("[]");',
'    const optional = t.endsWith("?");',
'    t = t.replace(/[\\[\\]\\?]/g, "");',
'',
'    const isScalar = scalarSet.has(t);',
'    const isRelation = line.includes("@relation") || (!isScalar && !line.includes("@default") && line.includes(t) && (t[0] === t[0].toUpperCase()));',
'    // enum detection is handled by checking enum blocks later',
'    fields.push({ name: fname, typ: t, optional, hasDefault, isList, isRelation, isEnum: false });',
'  }',
'  return fields;',
'}',
'',
'function parseEnumFirst(schema: string, enumName: string): string | null {',
'  const blk = findBlock(schema, "enum", [enumName.toLowerCase()]);',
'  if (!blk.name) return null;',
'  const lines = blk.body.split(/\\r?\\n/).map(s => s.replace(/#.*/, "").trim()).filter(Boolean);',
'  for (const ln of lines) {',
'    const m = ln.match(/^([A-Za-z0-9_]+)\\b/);',
'    if (m) return m[1];',
'  }',
'  return null;',
'}',
'',
'function valueFor(fieldName: string, typ: string, idx: number, enumFirst: string | null) {',
'  const n = fieldName.toLowerCase();',
'  if (enumFirst) return enumFirst;',
'  if (typ === "String") {',
'    if (n.includes("bairro")) return "Vila Santa Cecília";',
'    if (n.includes("city") || n.includes("cidade")) return "Volta Redonda";',
'    if (n.includes("title") || n.includes("titulo") || n === "name" || n.includes("nome")) return "[seed] Ponto crítico " + (idx + 1);',
'    if (n.includes("desc") || n.includes("descricao") || n.includes("description")) return "[seed] Acúmulo de lixo/entulho — validar UI e contagens";',
'    if (n.includes("address") || n.includes("endereco") || n.includes("local")) return "Praça (seed)";',
'    if (n.includes("status")) return "OPEN";',
'    if (n.includes("type") || n.includes("kind") || n.includes("categoria")) return "LIXO";',
'    if (n.includes("note") || n.includes("obs")) return "seed";',
'    return "seed";',
'  }',
'  if (typ === "Int" || typ === "BigInt") {',
'    if (n.includes("severity") || n.includes("gravidade")) return 2;',
'    return idx + 1;',
'  }',
'  if (typ === "Float" || typ === "Decimal") {',
'    // coordenadas aproximadas VR',
'    if (n === "lat" || n.includes("latitude")) return -22.520 + (idx * 0.001);',
'    if (n === "lng" || n.includes("longitude")) return -44.105 - (idx * 0.001);',
'    return 0;',
'  }',
'  if (typ === "Boolean") return false;',
'  if (typ === "DateTime") return new Date();',
'  if (typ === "Json") return {};',
'  return null;',
'}',
'',
'function buildCreateData(schema: string, modelName: string, idx: number, forcePointId: string | null) {',
'  const blk = findBlock(schema, "model", [modelName.toLowerCase()]);',
'  if (!blk.name) return { ok: false, error: "model_block_not_found", data: {} as any };',
'  const fields = parseFields(blk.body);',
'',
'  // detect enums: typ not scalar and has enum block',
'  for (const f of fields) {',
'    if (f.isList || f.isRelation) continue;',
'    if (["String","Int","Float","Boolean","DateTime","Json","BigInt","Bytes","Decimal"].includes(f.typ)) continue;',
'    const ev = parseEnumFirst(schema, f.typ);',
'    if (ev) {',
'      f.isEnum = true;',
'    }',
'  }',
'',
'  const data: any = {};',
'  // choose pointId-like field if provided',
'  if (forcePointId) {',
'    const idField = fields.find(f => !f.isList && !f.isRelation && f.typ === "String" && ["pointid","criticalpointid","ecocriticalpointid","ecopointid"].includes(f.name.toLowerCase()));',
'    if (idField) data[idField.name] = forcePointId;',
'  }',
'',
'  for (const f of fields) {',
'    if (f.isList) continue;',
'    if (f.isRelation) continue;',
'    // skip auto id with default',
'    const isIdLike = (f.name.toLowerCase() === "id");',
'    if (isIdLike && f.hasDefault) continue;',
'    // required if not optional and no default and not already set',
'    const required = (!f.optional && !f.hasDefault);',
'    if (!required) continue;',
'    if (data[f.name] !== undefined) continue;',
'',
'    const enumFirst = f.isEnum ? parseEnumFirst(schema, f.typ) : null;',
'    const v = valueFor(f.name, f.typ, idx, enumFirst);',
'    if (v !== null && v !== undefined) data[f.name] = v;',
'  }',
'',
'  // also fill some common optional fields if they exist (nice UI), but only if not set',
'  for (const f of fields) {',
'    if (f.isList || f.isRelation) continue;',
'    if (data[f.name] !== undefined) continue;',
'    if (f.typ !== "String" && f.typ !== "Float") continue;',
'    const lower = f.name.toLowerCase();',
'    if (f.typ === "Float" && (lower === "lat" || lower === "lng" || lower.includes("latitude") || lower.includes("longitude"))) {',
'      data[f.name] = valueFor(f.name, f.typ, idx, null);',
'    }',
'    if (f.typ === "String" && (lower.includes("bairro") || lower.includes("title") || lower.includes("titulo") || lower.includes("desc") || lower.includes("descricao") || lower.includes("status"))) {',
'      data[f.name] = valueFor(f.name, f.typ, idx, null);',
'    }',
'  }',
'',
'  return { ok: true, error: null as any, data };',
'}',
'',
'export async function GET(req: Request) {',
'  if (process.env.NODE_ENV === "production") {',
'    return NextResponse.json({ ok: false, error: "disabled_in_production" }, { status: 403 });',
'  }',
'',
'  const url = new URL(req.url);',
'  const n = Math.max(1, Math.min(10, Number(url.searchParams.get("n") || 3) || 3));',
'  const doConfirm = String(url.searchParams.get("confirm") || "1") === "1";',
'  const doSupport = String(url.searchParams.get("support") || "1") === "1";',
'  const doReplicar = String(url.searchParams.get("replicar") || "0") === "1";',
'',
'  const schema = await readSchema();',
'  const pc: any = prisma as any;',
'',
'  // point model: choose first existing from list',
'  const pointPick = pickModel(pc, "ecoCriticalPoint", ["EcoCriticalPoint","ecoCriticalPoint","ecoPoint","EcoPoint","criticalPoint","point"]);',
'  if (!pointPick.model) return NextResponse.json({ ok: false, error: "point_model_not_found" }, { status: 500 });',
'',
'  const confirmPick = pickModel(pc, "ecoCriticalPointConfirm", ["EcoCriticalPointConfirm","ecoCriticalPointConfirm","ecoPointConfirm","pointConfirm","criticalPointConfirm"]);',
'  const supportPick = pickModel(pc, "ecoPointSupport", ["EcoPointSupport","ecoPointSupport","pointSupport"]);',
'  const replicPick  = pickModel(pc, "ecoPointReplicate", ["EcoPointReplicar","ecoPointReplicar","ecoPointReplicate","EcoPointReplicate","pointReplicar","pointReplicate"]);',
'',
'  const created: any[] = [];',
'  const actions: any[] = [];',
'',
'  for (let i = 0; i < n; i++) {',
'    const built = buildCreateData(schema, pointPick.name, i, null);',
'    if (!built.ok) return NextResponse.json({ ok: false, error: built.error }, { status: 500 });',
'    const row = await pointPick.model.create({ data: built.data });',
'    created.push({ id: row?.id, model: pointPick.name });',
'  }',
'',
'  // add 1 confirm on point #1',
'  if (doConfirm && created[0]?.id && confirmPick.model) {',
'    const built = buildCreateData(schema, confirmPick.name, 0, String(created[0].id));',
'    try {',
'      const r = await confirmPick.model.create({ data: built.data });',
'      actions.push({ kind: "confirm", id: r?.id, by: confirmPick.name });',
'    } catch (e: any) {',
'      actions.push({ kind: "confirm", error: String(e?.message || e) });',
'    }',
'  }',
'',
'  // add 1 support on point #2',
'  if (doSupport && created[1]?.id && supportPick.model) {',
'    const built = buildCreateData(schema, supportPick.name, 0, String(created[1].id));',
'    try {',
'      const r = await supportPick.model.create({ data: built.data });',
'      actions.push({ kind: "support", id: r?.id, by: supportPick.name });',
'    } catch (e: any) {',
'      actions.push({ kind: "support", error: String(e?.message || e) });',
'    }',
'  }',
'',
'  // optional replicar on point #3',
'  if (doReplicar && created[2]?.id && replicPick.model) {',
'    const built = buildCreateData(schema, replicPick.name, 0, String(created[2].id));',
'    try {',
'      const r = await replicPick.model.create({ data: built.data });',
'      actions.push({ kind: "replicar", id: r?.id, by: replicPick.name });',
'    } catch (e: any) {',
'      actions.push({ kind: "replicar", error: String(e?.message || e) });',
'    }',
'  }',
'',
'  return NextResponse.json({',
'    ok: true,',
'    created,',
'    actions,',
'    meta: { pointModel: pointPick.name, confirmModel: confirmPick.name, supportModel: supportPick.name, replicarModel: replicPick.name }',
'  });',
'}',
''
)

WriteAllLinesUtf8NoBom $seedRoute $L
Write-Host ("[PATCH] wrote " + $seedRoute)

$rep = Join-Path $reportDir ("eco-step-106-seed-eco-pontos-dev-v0_1-" + $ts + ".md")
$repText = @(
"# eco-step-106-seed-eco-pontos-dev-v0_1",
"",
"- Time: " + $ts,
"- Backup: " + $backupDir,
"",
"## Changes",
"- Added dev seed route: src/app/api/dev/seed-eco/route.ts",
"  - cria 3 pontos no model detectado (default ecoCriticalPoint)",
"  - cria 1 confirm no ponto #1 e 1 support no ponto #2",
"",
"## Verify",
"1) npm run dev",
"2) GET " + $BaseUrl + "/api/dev/seed-eco?n=3&confirm=1&support=1",
"3) GET " + $BaseUrl + "/api/eco/points?limit=5",
"4) /eco/mural e /eco/mural/confirmados",
""
) -join "`n"
WriteUtf8NoBom $rep $repText
Write-Host ("[REPORT] " + $rep)

Write-Host ""
Write-Host ("[RUN] Seed: " + $BaseUrl + "/api/dev/seed-eco?n=3&confirm=1&support=1")
try {
  irm ($BaseUrl + "/api/dev/seed-eco?n=3&confirm=1&support=1") -Headers @{Accept="application/json"} | ConvertTo-Json -Depth 30
} catch {
  Write-Host ("[WARN] Seed call failed (maybe dev server not running). Start npm run dev then call:")
  Write-Host ("irm '" + $BaseUrl + "/api/dev/seed-eco?n=3&confirm=1&support=1' | ConvertTo-Json -Depth 30")
}

Write-Host ""
Write-Host "[VERIFY] irm http://localhost:3000/api/eco/points?limit=5 | ConvertTo-Json -Depth 60"