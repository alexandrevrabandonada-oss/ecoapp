param([string]$Root = (Get-Location).Path)

$ts = Get-Date -Format "yyyyMMdd-HHmmss"
Write-Host ("== eco-step-92c-mural-confirmado-badge-counts-v0_2 == " + $ts)
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
if (-not (Get-Command WriteAllLinesUtf8NoBom -ErrorAction SilentlyContinue)) {
  function WriteAllLinesUtf8NoBom([string]$p, [string[]]$lines) {
    EnsureDir (Split-Path -Parent $p)
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllLines($p, $lines, $enc)
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

function FindFirstFile([string]$root, [string]$filter, [string]$contains) {
  $hits = Get-ChildItem -LiteralPath (Join-Path $root "src") -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $filter }
  foreach ($h in $hits) {
    try {
      $raw = Get-Content -LiteralPath $h.FullName -Raw -ErrorAction Stop
      if (-not $contains -or $raw -match $contains) { return $h.FullName }
    } catch {}
  }
  return $null
}

$backupDir = Join-Path $Root ("tools/_patch_backup/" + $ts + "-eco-step-92c-mural-confirmado-badge-counts-v0_2")
$reportDir = Join-Path $Root "reports"
EnsureDir $backupDir
EnsureDir $reportDir

# --- locate files (robust) ---
$muralClient = Join-Path $Root "src/app/eco/mural/MuralClient.tsx"
if (-not (Test-Path -LiteralPath $muralClient)) {
  $muralClient = FindFirstFile $Root "MuralClient.tsx" "export default|function|const"
}
$actionsInline = Join-Path $Root "src/app/eco/_components/PointActionsInline.tsx"
if (-not (Test-Path -LiteralPath $actionsInline)) {
  $actionsInline = FindFirstFile $Root "PointActionsInline.tsx" "PointActionsInline"
}
$badgeFile = Join-Path $Root "src/app/eco/_components/ConfirmadoBadge.tsx"

if (-not $muralClient) { throw "[STOP] Nao achei MuralClient.tsx" }
if (-not $actionsInline) { throw "[STOP] Nao achei PointActionsInline.tsx" }

Write-Host ("[DIAG] MuralClient: " + $muralClient)
Write-Host ("[DIAG] PointActionsInline: " + $actionsInline)
Write-Host ("[DIAG] Will write: " + $badgeFile)

BackupFile $Root $muralClient $backupDir
BackupFile $Root $actionsInline $backupDir
BackupFile $Root $badgeFile $backupDir

# --- 1) write ConfirmadoBadge.tsx ---
$badgeLines = @(
'"use client";',
'',
'type AnyObj = any;',
'',
'function num(v: any): number {',
'  const n = Number(v);',
'  return Number.isFinite(n) ? n : 0;',
'}',
'',
'function readCount(data: AnyObj): number {',
'  if (!data) return 0;',
'  // direct keys',
'  const keys = ["confirm","confirmar","confirmed","confirmations","confirmCount","confirmarCount"];',
'  for (const k of keys) {',
'    const n = num((data as any)[k]);',
'    if (n > 0) return n;',
'  }',
'  // nested holders',
'  const holders = [',
'    (data as any).counts,',
'    (data as any).stats,',
'    (data as any).actions,',
'    (data as any).meta?.counts,',
'    (data as any).meta?.stats,',
'  ].filter(Boolean);',
'  for (const h of holders) {',
'    for (const k of keys) {',
'      const n = num((h as any)[k]);',
'      if (n > 0) return n;',
'    }',
'  }',
'  // arrays fallback',
'  const arrs = [',
'    (data as any).confirmations,',
'    (data as any).confirms,',
'    (data as any).confirmedBy,',
'    (data as any).confirmBy,',
'  ].filter(Boolean);',
'  for (const a of arrs) {',
'    if (Array.isArray(a) && a.length > 0) return a.length;',
'  }',
'  return 0;',
'}',
'',
'export default function ConfirmadoBadge({ data }: { data: AnyObj }) {',
'  const n = readCount(data);',
'  if (!n || n <= 0) return null;',
'  return (',
'    <span',
'      title={"Confirmado por " + n}',
'      style={{',
'        display: "inline-flex",',
'        alignItems: "center",',
'        gap: 8,',
'        padding: "5px 10px",',
'        borderRadius: 999,',
'        border: "1px solid #111",',
'        background: "#fff",',
'        fontWeight: 900,',
'        fontSize: 12,',
'        lineHeight: "12px",',
'        whiteSpace: "nowrap",',
'      }}',
'    >',
'      ✅ CONFIRMADO',
'      <span',
'        style={{',
'          display: "inline-flex",',
'          alignItems: "center",',
'          justifyContent: "center",',
'          minWidth: 20,',
'          padding: "2px 8px",',
'          borderRadius: 999,',
'          background: "#111",',
'          color: "#fff",',
'          fontWeight: 900,',
'          fontSize: 12,',
'          lineHeight: "12px",',
'        }}',
'      >',
'        {n}',
'      </span>',
'    </span>',
'  );',
'}'
)
WriteAllLinesUtf8NoBom $badgeFile $badgeLines
Write-Host "[PATCH] wrote ConfirmadoBadge.tsx"

# --- 2) ensure PointActionsInline has default export (avoid invalid element type) ---
$rawA = Get-Content -LiteralPath $actionsInline -Raw -ErrorAction Stop
$changedA = $false

if ($rawA -notmatch 'export\s+default') {
  if ($rawA -match 'export\s+function\s+PointActionsInline') {
    $rawA = $rawA.TrimEnd() + "`n`nexport default PointActionsInline;`n"
    $changedA = $true
  } elseif ($rawA -match 'export\s+const\s+PointActionsInline') {
    $rawA = $rawA -replace 'export\s+const\s+PointActionsInline', 'const PointActionsInline'
    if ($rawA -notmatch 'export\s+\{\s*PointActionsInline\s*\}') {
      $rawA = $rawA.TrimEnd() + "`n`nexport { PointActionsInline };`n"
    }
    $rawA = $rawA.TrimEnd() + "`nexport default PointActionsInline;`n"
    $changedA = $true
  } elseif ($rawA -match 'function\s+PointActionsInline') {
    $rawA = $rawA.TrimEnd() + "`n`nexport default PointActionsInline;`n"
    $changedA = $true
  }
}
if ($changedA) {
  WriteUtf8NoBom $actionsInline $rawA
  Write-Host "[PATCH] PointActionsInline: ensured export default"
} else {
  Write-Host "[SKIP] PointActionsInline: export default already OK (or pattern not detected)"
}

# --- 3) create API /api/eco/points/list2 with counts.confirm (detect prisma model keys from existing routes) ---
$apiPointsDir = Join-Path $Root "src/app/api/eco/points"
$pointKey = $null
$confirmKey = $null

if (Test-Path -LiteralPath $apiPointsDir) {
  $routes = Get-ChildItem -LiteralPath $apiPointsDir -Recurse -File -Filter "route.ts" -ErrorAction SilentlyContinue

  # confirm route usually in .../confirm/route.ts
  $confirmRoute = $routes | Where-Object { $_.FullName -match '[\\/]confirm[\\/]route\.ts$' } | Select-Object -First 1
  if ($confirmRoute) {
    $cr = Get-Content -LiteralPath $confirmRoute.FullName -Raw -ErrorAction SilentlyContinue
    $m1 = [regex]::Match($cr, 'prisma\.([A-Za-z0-9_]+)\.(create|upsert|update|findFirst|findMany)')
    if ($m1.Success) { $confirmKey = $m1.Groups[1].Value }
  }

  # pick any route with prisma.X.findMany that is not confirm
  foreach ($r in $routes) {
    if ($r.FullName -match '[\\/]confirm[\\/]route\.ts$') { continue }
    $rr = Get-Content -LiteralPath $r.FullName -Raw -ErrorAction SilentlyContinue
    $m2 = [regex]::Match($rr, 'prisma\.([A-Za-z0-9_]+)\.findMany')
    if ($m2.Success) { $pointKey = $m2.Groups[1].Value; break }
  }
}

if (-not $pointKey) { $pointKey = "ecoPoint" }
if (-not $confirmKey) { $confirmKey = "ecoPointConfirm" }

Write-Host ("[DIAG] Prisma keys inferred: pointKey=" + $pointKey + " confirmKey=" + $confirmKey)

$apiList2 = Join-Path $Root "src/app/api/eco/points/list2/route.ts"
BackupFile $Root $apiList2 $backupDir

$apiLines = @(
'// ECO — points list v2 (adds counts.confirm) — auto-generated',
'',
'import { NextResponse } from "next/server";',
'import { prisma } from "@/lib/prisma";',
'',
'export const runtime = "nodejs";',
'export const dynamic = "force-dynamic";',
'',
'function safeInt(v: string | null, d: number) {',
'  const n = Number(v);',
'  return Number.isFinite(n) && n > 0 ? Math.floor(n) : d;',
'}',
'',
'function pickModel(pc: any, key: string, fallbacks: string[]) {',
'  const m = pc?.[key];',
'  if (m && typeof m.findMany === "function") return m;',
'  for (const k of fallbacks) {',
'    const mm = pc?.[k];',
'    if (mm && typeof mm.findMany === "function") return mm;',
'  }',
'  return null;',
'}',
'',
'export async function GET(req: Request) {',
'  const url = new URL(req.url);',
'  const status = String(url.searchParams.get("status") || "").trim();',
'  const limit = safeInt(url.searchParams.get("limit"), 60);',
'',
'  const pc: any = prisma as any;',
'  const point = pickModel(pc, "' + $pointKey + '", ["ecoCriticalPoint","criticalPoint","ecoPoint","point"]);',
'  if (!point) {',
'    return NextResponse.json({ ok: false, error: "model_not_ready", hint: "point model missing" }, { status: 503 });',
'  }',
'',
'  let items: any[] = [];',
'  try {',
'    const where: any = {};',
'    if (status) where.status = status;',
'    items = await point.findMany({ where, take: limit, orderBy: { createdAt: "desc" } });',
'  } catch {',
'    try {',
'      const where: any = {};',
'      if (status) where.status = status;',
'      items = await point.findMany({ where, take: limit });',
'    } catch (e: any) {',
'      return NextResponse.json({ ok: false, error: "db_error", detail: String(e?.message || e) }, { status: 500 });',
'    }',
'  }',
'',
'  // counts.confirm via groupBy(pointId)',
'  const confirm = pc?.["' + $confirmKey + '"];',
'  const map: Record<string, number> = {};',
'  if (confirm && typeof confirm.groupBy === "function") {',
'    try {',
'      const ids = items.map((p) => p?.id).filter(Boolean);',
'      if (ids.length) {',
'        const rows = await confirm.groupBy({',
'          by: ["pointId"],',
'          where: { pointId: { in: ids } },',
'          _count: { _all: true },',
'        });',
'        for (const r of rows || []) {',
'          map[String((r as any).pointId)] = Number((r as any)._count?._all || 0) || 0;',
'        }',
'      }',
'    } catch {',
'      // ignore; keep map empty',
'    }',
'  }',
'',
'  const out = items.map((p) => ({',
'    ...p,',
'    counts: {',
'      ...(p?.counts || {}),',
'      confirm: map[String(p?.id)] || 0,',
'    },',
'  }));',
'',
'  return NextResponse.json({ ok: true, items: out });',
'}'
)

WriteAllLinesUtf8NoBom $apiList2 $apiLines
Write-Host "[PATCH] wrote /api/eco/points/list2"

# --- 4) patch MuralClient to use list2 + render ConfirmadoBadge near actions ---
$raw = Get-Content -LiteralPath $muralClient -Raw -ErrorAction Stop
$changed = $false

# fix import style for PointActionsInline (default import)
$raw2 = $raw.Replace('import { PointActionsInline } from "../_components/PointActionsInline";', 'import PointActionsInline from "../_components/PointActionsInline";')
$raw2 = $raw2.Replace("import { PointActionsInline } from '../_components/PointActionsInline';", "import PointActionsInline from '../_components/PointActionsInline';")
if ($raw2 -ne $raw) { $raw = $raw2; $changed = $true; Write-Host "[PATCH] MuralClient: normalized PointActionsInline import" }

# ensure ConfirmadoBadge import
if ($raw -notmatch 'ConfirmadoBadge') {
  $lines = $raw -split "`n"
  $lastImport = -1
  for ($i=0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match '^\s*import\s+') { $lastImport = $i } }
  $ins = 'import ConfirmadoBadge from "../_components/ConfirmadoBadge";'
  $new = New-Object System.Collections.Generic.List[string]
  for ($i=0; $i -lt $lines.Count; $i++) {
    $new.Add($lines[$i])
    if ($i -eq $lastImport) { $new.Add($ins) }
  }
  $raw = ($new -join "`n")
  $changed = $true
  Write-Host "[PATCH] MuralClient: added ConfirmadoBadge import"
}

# switch endpoint list -> list2
$raw3 = $raw.Replace("/api/eco/points/list", "/api/eco/points/list2")
$raw3 = $raw3.Replace("'/api/eco/points/list'", "'/api/eco/points/list2'")
$raw3 = $raw3.Replace('"/api/eco/points/list"', '"/api/eco/points/list2"')
if ($raw3 -ne $raw) { $raw = $raw3; $changed = $true; Write-Host "[PATCH] MuralClient: switched to /api/eco/points/list2" }

# inject <ConfirmadoBadge data={var} /> above PointActionsInline/Bar if possible
if ($raw -notmatch '<ConfirmadoBadge\b') {
  $var = "p"
  $mm = [regex]::Match($raw, '\.map\(\s*\(\s*([A-Za-z_][A-Za-z0-9_]*)')
  if ($mm.Success) { $var = $mm.Groups[1].Value }

  $lines2 = $raw -split "`n"
  $idx = -1
  for ($i=0; $i -lt $lines2.Count; $i++) {
    if ($lines2[$i] -match '<PointActionsInline\b' -or $lines2[$i] -match '<PointActionBar\b') { $idx = $i; break }
  }
  if ($idx -ge 0) {
    $indent = ([regex]::Match($lines2[$idx], '^\s*')).Value
    $insLine = $indent + '<ConfirmadoBadge data={' + $var + '} />'
    $new2 = New-Object System.Collections.Generic.List[string]
    for ($i=0; $i -lt $lines2.Count; $i++) {
      if ($i -eq $idx) { $new2.Add($insLine) }
      $new2.Add($lines2[$i])
    }
    $raw = ($new2 -join "`n")
    $changed = $true
    Write-Host ("[PATCH] MuralClient: injected ConfirmadoBadge using var {" + $var + "}")
  } else {
    Write-Host "[SKIP] MuralClient: nao achei PointActionsInline/Bar para injetar badge (ok; badge pode ser adicionado depois)"
  }
}

if ($changed) {
  WriteUtf8NoBom $muralClient $raw
  Write-Host "[PATCH] wrote MuralClient.tsx"
} else {
  Write-Host "[SKIP] MuralClient: no changes"
}

# --- report ---
$rep = Join-Path $reportDir ("eco-step-92c-mural-confirmado-badge-counts-v0_2-" + $ts + ".md")
$repText = @(
"# eco-step-92c-mural-confirmado-badge-counts-v0_2",
"",
"- Time: " + $ts,
"- Backup: " + $backupDir,
"",
"## Changes",
"- Added: src/app/eco/_components/ConfirmadoBadge.tsx",
"- Ensured default export: PointActionsInline",
"- Added: /api/eco/points/list2 (returns items with counts.confirm)",
"- Patched: MuralClient to use list2 and (if detected) render ConfirmadoBadge near actions",
"",
"## Verify",
"1) Ctrl+C -> npm run dev",
"2) Abra /eco/mural (sem 500).",
"3) Em pontos com confirmações, badge ✅ CONFIRMADO + numero aparece (se houver confirmacoes na base).",
"4) /eco/mural/chamados idem.",
"",
"## Notes",
"- list2 tenta inferir pointKey/confirmKey lendo seus route.ts existentes; se falhar, usa fallbacks.",
"- Se badge nao aparecer, pode ser que ainda nao existam confirmacoes registradas para os pontos testados."
) -join "`n"
WriteUtf8NoBom $rep $repText
Write-Host ("[REPORT] " + $rep)

Write-Host ""
Write-Host "[VERIFY] Ctrl+C -> npm run dev"
Write-Host "[VERIFY] /eco/mural e /eco/mural/chamados"
Write-Host "[VERIFY] se tiver confirmacoes, deve aparecer ✅ CONFIRMADO + contador"