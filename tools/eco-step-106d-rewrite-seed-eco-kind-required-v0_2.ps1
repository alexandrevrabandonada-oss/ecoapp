param([string]$Root = (Get-Location).Path)

$ts = Get-Date -Format "yyyyMMdd-HHmmss"
Write-Host ("== eco-step-106d-rewrite-seed-eco-kind-required-v0_2 == " + $ts)
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

$backupDir = Join-Path $Root ("tools/_patch_backup/" + $ts + "-eco-step-106d-v0_2")
$reportDir = Join-Path $Root "reports"
EnsureDir $backupDir
EnsureDir $reportDir

$schemaPath = Join-Path $Root "prisma/schema.prisma"
if (-not (Test-Path -LiteralPath $schemaPath)) { throw "[STOP] Nao achei prisma/schema.prisma" }
$schema = Get-Content -LiteralPath $schemaPath -Raw

function GetModelName {
  param([string]$s)
  $cands = @('EcoCriticalPoint','CriticalPoint','EcoPoint','Point')
  foreach ($m in $cands) {
    if ([regex]::IsMatch($s, "(?s)model\s+$m\s*\{")) { return $m }
  }
  return $null
}
function GetFieldType {
  param([string]$s, [string]$modelName, [string]$fieldName)
  $mm = [regex]::Match($s, "(?s)model\s+$modelName\s*\{(.*?)\n\}")
  if (-not $mm.Success) { return $null }
  $body = $mm.Groups[1].Value
  $rx = "(?m)^\s*" + [regex]::Escape($fieldName) + "\s+([A-Za-z0-9_\[\]\?]+)"
  $fm = [regex]::Match($body, $rx)
  if (-not $fm.Success) { return $null }
  $t = $fm.Groups[1].Value.Trim()
  $t = $t -replace '\?$', ''
  $t = $t -replace '\[\]$', ''
  return $t
}
function GetEnumFirstValue {
  param([string]$s, [string]$enumName)
  $em = [regex]::Match($s, "(?s)enum\s+$enumName\s*\{(.*?)\}")
  if (-not $em.Success) { return $null }
  $lines = $em.Groups[1].Value -split "`n"
  foreach ($ln in $lines) {
    $t = $ln.Trim()
    if (-not $t) { continue }
    if ($t.StartsWith("//")) { continue }
    $tok = ($t -split '\s+')[0].Trim()
    if ($tok -match '^[A-Za-z0-9_]+$') { return $tok }
  }
  return $null
}

$modelName = GetModelName -s $schema
if (-not $modelName) { $modelName = 'EcoCriticalPoint' }

$kindType = GetFieldType -s $schema -modelName $modelName -fieldName 'kind'
$statusType = GetFieldType -s $schema -modelName $modelName -fieldName 'status'

$kindVal = $null
if ($kindType) { $kindVal = GetEnumFirstValue -s $schema -enumName $kindType }
if (-not $kindVal) { $kindVal = "OTHER" }

$statusVal = $null
if ($statusType) { $statusVal = GetEnumFirstValue -s $schema -enumName $statusType }
if (-not $statusVal) { $statusVal = "OPEN" }

Write-Host ("[DIAG] Model: " + $modelName)
Write-Host ("[DIAG] kindType=" + $kindType + " defaultKind=" + $kindVal)
Write-Host ("[DIAG] statusType=" + $statusType + " defaultStatus=" + $statusVal)

$target = Join-Path $Root "src/app/api/dev/seed-eco/route.ts"
EnsureDir (Split-Path -Parent $target)
BackupFile $Root $target $backupDir

# TS lines as single-quoted PS strings (no \" no PS)
$lines = @(
"import { NextResponse } from 'next/server';",
"import { prisma } from '@/lib/prisma';",
"",
"export const runtime = 'nodejs';",
"export const dynamic = 'force-dynamic';",
"",
"type TI = { cid: number; name: string; type: string; notnull: number; dflt_value: any; pk: number };",
"",
"const DEFAULT_KIND: string = '" + $kindVal + "';",
"const DEFAULT_STATUS: string = '" + $statusVal + "';",
"",
"function clamp(n: number, a: number, b: number) { return Math.max(a, Math.min(b, n)); }",
"function qInt(url: URL, key: string, defVal: number, minV: number, maxV: number) {",
"  const v = url.searchParams.get(key);",
"  if (!v) return defVal;",
"  const n = Number.parseInt(v, 10);",
"  if (!Number.isFinite(n)) return defVal;",
"  return clamp(n, minV, maxV);",
"}",
"",
"function mkId(prefix: string) {",
"  const r = Math.random().toString(36).slice(2, 8);",
"  const t = Date.now().toString(36).slice(-6);",
"  return prefix + '-' + t + '-' + r;",
"}",
"",
"function pickModel(pc: any, preferred: string, candidates: string[]) {",
"  const all = [preferred, ...candidates];",
"  for (const k of all) {",
"    const m = pc?.[k];",
"    if (m && typeof m.create === 'function') return { key: k, model: m };",
"  }",
"  for (const k of Object.keys(pc || {})) {",
"    const m = pc?.[k];",
"    if (m && typeof m.create === 'function') return { key: k, model: m };",
"  }",
"  return null;",
"}",
"",
"async function qRaw<T = any>(sql: string): Promise<T[]> {",
"  try {",
"    const rows = await (prisma as any).$queryRawUnsafe<T[]>(sql);",
"    return Array.isArray(rows) ? rows : [];",
"  } catch {",
"    return [];",
"  }",
"}",
"",
"async function listTables(): Promise<string[]> {",
"  const rows = await qRaw<any>(\"SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name\");",
"  return rows.map((r: any) => String(r?.name || '')).filter(Boolean);",
"}",
"",
"async function tableInfo(table: string): Promise<TI[]> {",
"  const q = 'PRAGMA table_info(\"' + table + '\")';",
"  const rows = await qRaw<any>(q);",
"  return rows as TI[];",
"}",
"",
"async function resolveTableForKey(key: string): Promise<{ table: string; cols: TI[] }> {",
"  let cols = await tableInfo(key);",
"  if (cols.length) return { table: key, cols };",
"  const tables = await listTables();",
"  const low = key.toLowerCase();",
"  const hit = tables.find(t => t.toLowerCase() === low) || tables.find(t => t.toLowerCase().includes(low));",
"  if (hit) {",
"    cols = await tableInfo(hit);",
"    if (cols.length) return { table: hit, cols };",
"  }",
"  return { table: key, cols: [] };",
"}",
"",
"function hasCol(cols: TI[], name: string) { return cols.some(c => c.name === name); }",
"function pickFk(cols: TI[]) {",
"  if (hasCol(cols, 'pointId')) return 'pointId';",
"  if (hasCol(cols, 'criticalPointId')) return 'criticalPointId';",
"  if (hasCol(cols, 'ecoCriticalPointId')) return 'ecoCriticalPointId';",
"  return 'pointId';",
"}",
"",
"function fallbackByType(t: string, i: number) {",
"  const up = (t || '').toUpperCase();",
"  if (up.includes('INT')) return i + 1;",
"  if (up.includes('REAL') || up.includes('FLOA') || up.includes('DOUB')) return 0.1 + i * 0.01;",
"  if (up.includes('BOOL')) return false;",
"  if (up.includes('DATE') || up.includes('TIME')) return new Date();",
"  return 'seed';",
"}",
"",
"function makeData(cols: TI[] | null, base: any, i: number) {",
"  const out: any = {};",
"  if (!cols || cols.length === 0) {",
"    for (const k of Object.keys(base || {})) out[k] = base[k];",
"    if (out.kind === undefined) out.kind = DEFAULT_KIND;",
"    if (out.status === undefined) out.status = DEFAULT_STATUS;",
"    return out;",
"  }",
"  const names = new Set(cols.map(c => c.name));",
"  for (const k of Object.keys(base || {})) {",
"    if (names.has(k)) out[k] = base[k];",
"  }",
"  for (const c of cols) {",
"    const need = c.notnull === 1 && (c.dflt_value === null || c.dflt_value === undefined);",
"    if (!need) continue;",
"    if (out[c.name] !== undefined) continue;",
"    if (c.name === 'kind') { out[c.name] = DEFAULT_KIND; continue; }",
"    if (c.name === 'status') { out[c.name] = DEFAULT_STATUS; continue; }",
"    if (c.name === 'lat') { out[c.name] = -22.52; continue; }",
"    if (c.name === 'lng') { out[c.name] = -44.10; continue; }",
"    if (c.name === 'createdAt' || c.name === 'updatedAt') { out[c.name] = new Date(); continue; }",
"    if (c.name === 'title' || c.name === 'name') { out[c.name] = 'Ponto critico (seed) #' + (i + 1); continue; }",
"    if (c.name === 'description' || c.name === 'text' || c.name === 'body') { out[c.name] = 'Gerado pelo seed de dev.'; continue; }",
"    if (c.name === 'bairro' || c.name === 'neighborhood') { out[c.name] = 'Centro'; continue; }",
"    out[c.name] = fallbackByType(c.type, i);",
"  }",
"  return out;",
"}",
"",
"export async function GET(req: Request) {",
"  const url = new URL(req.url);",
"  const n = qInt(url, 'n', 3, 1, 40);",
"  const wantConfirm = qInt(url, 'confirm', 0, 0, 1) === 1;",
"  const wantSupport = qInt(url, 'support', 0, 0, 1) === 1;",
"  const wantReplicar = qInt(url, 'replicar', 0, 0, 1) === 1;",
"",
"  const pc: any = prisma as any;",
"  const pointPick = pickModel(pc, 'ecoCriticalPoint', ['criticalPoint', 'ecoPoint', 'point']);",
"  const confirmPick = pickModel(pc, 'ecoCriticalPointConfirm', ['ecoPointConfirm', 'pointConfirm', 'criticalPointConfirm']);",
"  const supportPick = pickModel(pc, 'ecoPointSupport', ['pointSupport']);",
"  const replicarPick = pickModel(pc, 'ecoPointReplicate', ['ecoPointReplicar', 'pointReplicate', 'pointReplicar']);",
"",
"  if (!pointPick) {",
"    return NextResponse.json({ ok: false, error: 'point_model_not_found', keys: Object.keys(pc || {}) }, { status: 500 });",
"  }",
"",
"  try {",
"    const pointTI = await resolveTableForKey(pointPick.key);",
"    const confirmTI = confirmPick ? await resolveTableForKey(confirmPick.key) : { table: '', cols: [] as TI[] };",
"    const supportTI = supportPick ? await resolveTableForKey(supportPick.key) : { table: '', cols: [] as TI[] };",
"    const replicarTI = replicarPick ? await resolveTableForKey(replicarPick.key) : { table: '', cols: [] as TI[] };",
"",
"    let createdPoints = 0;",
"    let createdConfirm = 0;",
"    let createdSupport = 0;",
"    let createdReplicar = 0;",
"    const ids: string[] = [];",
"",
"    const baseLat = -22.5200;",
"    const baseLng = -44.1040;",
"",
"    for (let i = 0; i < n; i++) {",
"      const pid = mkId('p');",
"      const now = new Date();",
"      const basePoint: any = {",
"        id: pid,",
"        createdAt: now,",
"        updatedAt: now,",
"        lat: baseLat + i * 0.001,",
"        lng: baseLng + i * 0.001,",
"        status: DEFAULT_STATUS,",
"        kind: DEFAULT_KIND,",
"        title: 'Ponto critico (seed) #' + (i + 1),",
"        description: 'Gerado pelo seed de dev.',",
"        neighborhood: 'Centro',",
"        bairro: 'Centro',",
"      };",
"",
"      const pointData = makeData(pointTI.cols, basePoint, i);",
"      const p = await pointPick.model.create({ data: pointData });",
"      const realId = String((p as any)?.id || pid);",
"      ids.push(realId);",
"      createdPoints++;",
"",
"      if (wantConfirm && confirmPick) {",
"        const fk = pickFk(confirmTI.cols);",
"        const baseC: any = { id: mkId('c'), createdAt: now, updatedAt: now };",
"        baseC[fk] = realId;",
"        const cData = makeData(confirmTI.cols, baseC, i);",
"        await confirmPick.model.create({ data: cData });",
"        createdConfirm++;",
"      }",
"",
"      if (wantSupport && supportPick) {",
"        const fk = pickFk(supportTI.cols);",
"        const baseS: any = { id: mkId('s'), createdAt: now, updatedAt: now };",
"        baseS[fk] = realId;",
"        const sData = makeData(supportTI.cols, baseS, i);",
"        await supportPick.model.create({ data: sData });",
"        createdSupport++;",
"      }",
"",
"      if (wantReplicar && replicarPick) {",
"        const fk = pickFk(replicarTI.cols);",
"        const baseR: any = { id: mkId('r'), createdAt: now, updatedAt: now };",
"        baseR[fk] = realId;",
"        const rData = makeData(replicarTI.cols, baseR, i);",
"        await replicarPick.model.create({ data: rData });",
"        createdReplicar++;",
"      }",
"    }",
"",
"    return NextResponse.json({",
"      ok: true,",
"      error: null,",
"      created: { points: createdPoints, confirm: createdConfirm, support: createdSupport, replicar: createdReplicar },",
"      models: { pointModel: pointPick.key, confirmModel: confirmPick?.key || null, supportModel: supportPick?.key || null, replicarModel: replicarPick?.key || null },",
"      defaults: { kind: DEFAULT_KIND, status: DEFAULT_STATUS },",
"      sampleIds: ids.slice(0, 5),",
"    });",
"  } catch (e: any) {",
"    return NextResponse.json({ ok: false, error: 'seed_failed', message: String(e?.message || e) }, { status: 500 });",
"  }",
"}"
) -join "`n"

WriteUtf8NoBom $target $lines
Write-Host ("[PATCH] rewrote " + $target)

$repPath = Join-Path $reportDir ("eco-step-106d-rewrite-seed-eco-kind-required-v0_2-" + $ts + ".md")
$rep = @(
"# eco-step-106d-rewrite-seed-eco-kind-required-v0_2",
"",
"- Time: " + $ts,
"- Backup: " + $backupDir,
"- Patched: src/app/api/dev/seed-eco/route.ts",
"- Model in schema: " + $modelName,
"- Default kind: " + $kindVal,
"- Default status: " + $statusVal,
"",
"## Verify",
"1) Ctrl+C -> npm run dev",
"2) irm 'http://localhost:3000/api/dev/seed-eco?n=3&confirm=1&support=1' | ConvertTo-Json -Depth 60",
"3) irm 'http://localhost:3000/api/eco/points?limit=5' | ConvertTo-Json -Depth 80",
"4) Abra /eco/mural e /eco/mural/confirmados"
) -join "`n"
WriteUtf8NoBom $repPath $rep
Write-Host ("[REPORT] " + $repPath)

Write-Host ""
Write-Host "[VERIFY] rode:"
Write-Host "  irm 'http://localhost:3000/api/dev/seed-eco?n=3&confirm=1&support=1' | ConvertTo-Json -Depth 60"
Write-Host "  irm 'http://localhost:3000/api/eco/points?limit=5' | ConvertTo-Json -Depth 80"