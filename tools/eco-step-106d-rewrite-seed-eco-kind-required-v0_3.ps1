param([string]$Root = (Get-Location).Path)

$ts = Get-Date -Format "yyyyMMdd-HHmmss"
Write-Host ("== eco-step-106d-rewrite-seed-eco-kind-required-v0_3 == " + $ts)
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

$backupDir = Join-Path $Root ("tools/_patch_backup/" + $ts + "-eco-step-106d-v0_3")
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

# inject values safely
$SQ = [char]39
$K = $kindVal
$S = $statusVal

# IMPORTANT: use PS single-quoted strings; when TS needs a single-quote, write it as '' in PS.
$lines = @()
$lines += 'import { NextResponse } from ''next/server'';'
$lines += 'import { prisma } from ''@/lib/prisma'';'
$lines += ''
$lines += 'export const runtime = ''nodejs'';'
$lines += 'export const dynamic = ''force-dynamic'';'
$lines += ''
$lines += 'type TI = { cid: number; name: string; type: string; notnull: number; dflt_value: any; pk: number };'
$lines += ''
$lines += ('const DEFAULT_KIND: string = ' + $SQ + $K + $SQ + ';')
$lines += ('const DEFAULT_STATUS: string = ' + $SQ + $S + $SQ + ';')
$lines += ''
$lines += 'function clamp(n: number, a: number, b: number) { return Math.max(a, Math.min(b, n)); }'
$lines += 'function qInt(url: URL, key: string, defVal: number, minV: number, maxV: number) {'
$lines += '  const v = url.searchParams.get(key);'
$lines += '  if (!v) return defVal;'
$lines += '  const n = Number.parseInt(v, 10);'
$lines += '  if (!Number.isFinite(n)) return defVal;'
$lines += '  return clamp(n, minV, maxV);'
$lines += '}'
$lines += ''
$lines += 'function mkId(prefix: string) {'
$lines += '  const r = Math.random().toString(36).slice(2, 8);'
$lines += '  const t = Date.now().toString(36).slice(-6);'
$lines += '  return prefix + ''-'' + t + ''-'' + r;'
$lines += '}'
$lines += ''
$lines += 'function pickModel(pc: any, preferred: string, candidates: string[]) {'
$lines += '  const all = [preferred, ...candidates];'
$lines += '  for (const k of all) {'
$lines += '    const m = pc?.[k];'
$lines += '    if (m && typeof m.create === ''function'') return { key: k, model: m };'
$lines += '  }'
$lines += '  for (const k of Object.keys(pc || {})) {'
$lines += '    const m = pc?.[k];'
$lines += '    if (m && typeof m.create === ''function'') return { key: k, model: m };'
$lines += '  }'
$lines += '  return null;'
$lines += '}'
$lines += ''
$lines += 'async function qRaw<T = any>(sql: string): Promise<T[]> {'
$lines += '  try {'
$lines += '    const rows = await (prisma as any).$queryRawUnsafe<T[]>(sql);'
$lines += '    return Array.isArray(rows) ? rows : [];'
$lines += '  } catch {'
$lines += '    return [];'
$lines += '  }'
$lines += '}'
$lines += ''
$lines += 'async function listTables(): Promise<string[]> {'
$lines += '  const rows = await qRaw<any>("SELECT name FROM sqlite_master WHERE type = ''table'' ORDER BY name");'
$lines += '  return rows.map((r: any) => String(r?.name || '''')).filter(Boolean);'
$lines += '}'
$lines += ''
$lines += 'async function tableInfo(table: string): Promise<TI[]> {'
$lines += '  const q = ''PRAGMA table_info("'' + table + ''")'';'
$lines += '  const rows = await qRaw<any>(q);'
$lines += '  return rows as TI[];'
$lines += '}'
$lines += ''
$lines += 'async function resolveTableForKey(key: string): Promise<{ table: string; cols: TI[] }> {'
$lines += '  let cols = await tableInfo(key);'
$lines += '  if (cols.length) return { table: key, cols };'
$lines += '  const tables = await listTables();'
$lines += '  const low = key.toLowerCase();'
$lines += '  const hit = tables.find(t => t.toLowerCase() === low) || tables.find(t => t.toLowerCase().includes(low));'
$lines += '  if (hit) {'
$lines += '    cols = await tableInfo(hit);'
$lines += '    if (cols.length) return { table: hit, cols };'
$lines += '  }'
$lines += '  return { table: key, cols: [] };'
$lines += '}'
$lines += ''
$lines += 'function hasCol(cols: TI[], name: string) { return cols.some(c => c.name === name); }'
$lines += 'function pickFk(cols: TI[]) {'
$lines += '  if (hasCol(cols, ''pointId'')) return ''pointId'';'
$lines += '  if (hasCol(cols, ''criticalPointId'')) return ''criticalPointId'';'
$lines += '  if (hasCol(cols, ''ecoCriticalPointId'')) return ''ecoCriticalPointId'';'
$lines += '  return ''pointId'';'
$lines += '}'
$lines += ''
$lines += 'function fallbackByType(t: string, i: number) {'
$lines += '  const up = (t || '''').toUpperCase();'
$lines += '  if (up.includes(''INT'')) return i + 1;'
$lines += '  if (up.includes(''REAL'') || up.includes(''FLOA'') || up.includes(''DOUB'')) return 0.1 + i * 0.01;'
$lines += '  if (up.includes(''BOOL'')) return false;'
$lines += '  if (up.includes(''DATE'') || up.includes(''TIME'')) return new Date();'
$lines += '  return ''seed'';'
$lines += '}'
$lines += ''
$lines += 'function makeData(cols: TI[] | null, base: any, i: number) {'
$lines += '  const out: any = {};'
$lines += '  if (!cols || cols.length === 0) {'
$lines += '    // minimal safe set (avoid unknown fields)'
$lines += '    if (base.id !== undefined) out.id = base.id;'
$lines += '    if (base.createdAt !== undefined) out.createdAt = base.createdAt;'
$lines += '    if (base.updatedAt !== undefined) out.updatedAt = base.updatedAt;'
$lines += '    if (base.lat !== undefined) out.lat = base.lat;'
$lines += '    if (base.lng !== undefined) out.lng = base.lng;'
$lines += '    out.status = (base.status !== undefined ? base.status : DEFAULT_STATUS);'
$lines += '    out.kind = (base.kind !== undefined ? base.kind : DEFAULT_KIND);'
$lines += '    return out;'
$lines += '  }'
$lines += '  const names = new Set(cols.map(c => c.name));'
$lines += '  for (const k of Object.keys(base || {})) {'
$lines += '    if (names.has(k)) out[k] = base[k];'
$lines += '  }'
$lines += '  // hard guarantee'
$lines += '  if (names.has(''kind'') && out.kind === undefined) out.kind = DEFAULT_KIND;'
$lines += '  if (names.has(''status'') && out.status === undefined) out.status = DEFAULT_STATUS;'
$lines += '  for (const c of cols) {'
$lines += '    const need = c.notnull === 1 && (c.dflt_value === null || c.dflt_value === undefined);'
$lines += '    if (!need) continue;'
$lines += '    if (out[c.name] !== undefined) continue;'
$lines += '    if (c.name === ''kind'') { out[c.name] = DEFAULT_KIND; continue; }'
$lines += '    if (c.name === ''status'') { out[c.name] = DEFAULT_STATUS; continue; }'
$lines += '    if (c.name === ''lat'') { out[c.name] = -22.52; continue; }'
$lines += '    if (c.name === ''lng'') { out[c.name] = -44.10; continue; }'
$lines += '    if (c.name === ''createdAt'' || c.name === ''updatedAt'') { out[c.name] = new Date(); continue; }'
$lines += '    if (c.name === ''title'' || c.name === ''name'') { out[c.name] = ''Ponto critico (seed) #'' + (i + 1); continue; }'
$lines += '    if (c.name === ''description'' || c.name === ''text'' || c.name === ''body'') { out[c.name] = ''Gerado pelo seed de dev.''; continue; }'
$lines += '    if (c.name === ''bairro'' || c.name === ''neighborhood'') { out[c.name] = ''Centro''; continue; }'
$lines += '    out[c.name] = fallbackByType(c.type, i);'
$lines += '  }'
$lines += '  return out;'
$lines += '}'
$lines += ''
$lines += 'export async function GET(req: Request) {'
$lines += '  const url = new URL(req.url);'
$lines += '  const n = qInt(url, ''n'', 3, 1, 40);'
$lines += '  const wantConfirm = qInt(url, ''confirm'', 0, 0, 1) === 1;'
$lines += '  const wantSupport = qInt(url, ''support'', 0, 0, 1) === 1;'
$lines += '  const wantReplicar = qInt(url, ''replicar'', 0, 0, 1) === 1;'
$lines += ''
$lines += '  const pc: any = prisma as any;'
$lines += '  const pointPick = pickModel(pc, ''ecoCriticalPoint'', [''criticalPoint'', ''ecoPoint'', ''point'']);'
$lines += '  const confirmPick = pickModel(pc, ''ecoCriticalPointConfirm'', [''ecoPointConfirm'', ''pointConfirm'', ''criticalPointConfirm'']);'
$lines += '  const supportPick = pickModel(pc, ''ecoPointSupport'', [''pointSupport'']);'
$lines += '  const replicarPick = pickModel(pc, ''ecoPointReplicate'', [''ecoPointReplicar'', ''pointReplicate'', ''pointReplicar'']);'
$lines += ''
$lines += '  if (!pointPick) {'
$lines += '    return NextResponse.json({ ok: false, error: ''point_model_not_found'', keys: Object.keys(pc || {}) }, { status: 500 });'
$lines += '  }'
$lines += ''
$lines += '  try {'
$lines += '    const pointTI = await resolveTableForKey(pointPick.key);'
$lines += '    const confirmTI = confirmPick ? await resolveTableForKey(confirmPick.key) : { table: '''', cols: [] as TI[] };'
$lines += '    const supportTI = supportPick ? await resolveTableForKey(supportPick.key) : { table: '''', cols: [] as TI[] };'
$lines += '    const replicarTI = replicarPick ? await resolveTableForKey(replicarPick.key) : { table: '''', cols: [] as TI[] };'
$lines += ''
$lines += '    let createdPoints = 0;'
$lines += '    let createdConfirm = 0;'
$lines += '    let createdSupport = 0;'
$lines += '    let createdReplicar = 0;'
$lines += '    const ids: string[] = [];'
$lines += ''
$lines += '    const baseLat = -22.5200;'
$lines += '    const baseLng = -44.1040;'
$lines += ''
$lines += '    for (let i = 0; i < n; i++) {'
$lines += '      const pid = mkId(''p'');'
$lines += '      const now = new Date();'
$lines += '      const basePoint: any = {'
$lines += '        id: pid,'
$lines += '        createdAt: now,'
$lines += '        updatedAt: now,'
$lines += '        lat: baseLat + i * 0.001,'
$lines += '        lng: baseLng + i * 0.001,'
$lines += '        status: DEFAULT_STATUS,'
$lines += '        kind: DEFAULT_KIND,'
$lines += '        title: ''Ponto critico (seed) #'' + (i + 1),'
$lines += '        description: ''Gerado pelo seed de dev.'','
$lines += '        neighborhood: ''Centro'','
$lines += '        bairro: ''Centro'','
$lines += '      };'
$lines += ''
$lines += '      const pointData = makeData(pointTI.cols, basePoint, i);'
$lines += '      const p = await pointPick.model.create({ data: pointData });'
$lines += '      const realId = String((p as any)?.id || pid);'
$lines += '      ids.push(realId);'
$lines += '      createdPoints++;'
$lines += ''
$lines += '      if (wantConfirm && confirmPick) {'
$lines += '        const fk = pickFk(confirmTI.cols);'
$lines += '        const baseC: any = { id: mkId(''c''), createdAt: now, updatedAt: now };'
$lines += '        baseC[fk] = realId;'
$lines += '        const cData = makeData(confirmTI.cols, baseC, i);'
$lines += '        await confirmPick.model.create({ data: cData });'
$lines += '        createdConfirm++;'
$lines += '      }'
$lines += ''
$lines += '      if (wantSupport && supportPick) {'
$lines += '        const fk = pickFk(supportTI.cols);'
$lines += '        const baseS: any = { id: mkId(''s''), createdAt: now, updatedAt: now };'
$lines += '        baseS[fk] = realId;'
$lines += '        const sData = makeData(supportTI.cols, baseS, i);'
$lines += '        await supportPick.model.create({ data: sData });'
$lines += '        createdSupport++;'
$lines += '      }'
$lines += ''
$lines += '      if (wantReplicar && replicarPick) {'
$lines += '        const fk = pickFk(replicarTI.cols);'
$lines += '        const baseR: any = { id: mkId(''r''), createdAt: now, updatedAt: now };'
$lines += '        baseR[fk] = realId;'
$lines += '        const rData = makeData(replicarTI.cols, baseR, i);'
$lines += '        await replicarPick.model.create({ data: rData });'
$lines += '        createdReplicar++;'
$lines += '      }'
$lines += '    }'
$lines += ''
$lines += '    return NextResponse.json({'
$lines += '      ok: true,'
$lines += '      error: null,'
$lines += '      created: { points: createdPoints, confirm: createdConfirm, support: createdSupport, replicar: createdReplicar },'
$lines += '      models: { pointModel: pointPick.key, confirmModel: confirmPick?.key || null, supportModel: supportPick?.key || null, replicarModel: replicarPick?.key || null },'
$lines += '      defaults: { kind: DEFAULT_KIND, status: DEFAULT_STATUS },'
$lines += '      sampleIds: ids.slice(0, 5),'
$lines += '    });'
$lines += '  } catch (e: any) {'
$lines += '    return NextResponse.json({ ok: false, error: ''seed_failed'', message: String(e?.message || e) }, { status: 500 });'
$lines += '  }'
$lines += '}'

WriteUtf8NoBom $target ($lines -join "`n")
Write-Host ("[PATCH] rewrote " + $target)

$repPath = Join-Path $reportDir ("eco-step-106d-rewrite-seed-eco-kind-required-v0_3-" + $ts + ".md")
$rep = @(
"# eco-step-106d-rewrite-seed-eco-kind-required-v0_3",
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
"2) irm 'http://localhost:3000/api/dev/seed-eco?n=3&confirm=1&support=1' | ConvertTo-Json -Depth 80",
"3) irm 'http://localhost:3000/api/eco/points?limit=5' | ConvertTo-Json -Depth 120",
"4) Abra /eco/mural e /eco/mural/confirmados"
) -join "`n"
WriteUtf8NoBom $repPath $rep
Write-Host ("[REPORT] " + $repPath)

Write-Host ""
Write-Host "[VERIFY] rode:"
Write-Host "  irm 'http://localhost:3000/api/dev/seed-eco?n=3&confirm=1&support=1' | ConvertTo-Json -Depth 80"
Write-Host "  irm 'http://localhost:3000/api/eco/points?limit=5' | ConvertTo-Json -Depth 120"