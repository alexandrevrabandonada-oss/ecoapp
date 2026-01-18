param([string]$Root = (Get-Location).Path)

$ts = Get-Date -Format "yyyyMMdd-HHmmss"
Write-Host ("== eco-step-94-mural-api-confirm-counts-v0_1 == " + $ts)
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

function FindFirstFile([string]$root, [string]$name, [string]$contains) {
  $hits = Get-ChildItem -LiteralPath (Join-Path $root "src") -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $name }
  foreach ($h in $hits) {
    try {
      $raw = Get-Content -LiteralPath $h.FullName -Raw -ErrorAction Stop
      if ([string]::IsNullOrWhiteSpace($contains) -or $raw.Contains($contains)) { return $h.FullName }
    } catch {}
  }
  return $null
}

$backupDir = Join-Path $Root ("tools/_patch_backup/" + $ts + "-eco-step-94-mural-api-confirm-counts-v0_1")
$reportDir = Join-Path $Root "reports"
EnsureDir $backupDir
EnsureDir $reportDir

$muralClient = Join-Path $Root "src/app/eco/mural/MuralClient.tsx"
if (-not (Test-Path -LiteralPath $muralClient)) { $muralClient = FindFirstFile $Root "MuralClient.tsx" "" }
if (-not $muralClient) { throw "[STOP] Nao achei MuralClient.tsx" }

$apiFile = Join-Path $Root "src/app/api/eco/mural/list/route.ts"

Write-Host ("[DIAG] MuralClient: " + $muralClient)
Write-Host ("[DIAG] Will write: " + $apiFile)

BackupFile $Root $muralClient $backupDir
BackupFile $Root $apiFile $backupDir

# 1) Write API /api/eco/mural/list
$A = @(
'import { NextResponse } from "next/server";',
'import { prisma } from "@/lib/prisma";',
'',
'export const runtime = "nodejs";',
'export const dynamic = "force-dynamic";',
'',
'function asMsg(e: unknown) {',
'  if (e instanceof Error) return e.message;',
'  try { return String(e); } catch { return "unknown"; }',
'}',
'',
'function getPointModel() {',
'  const pc: any = prisma as any;',
'  const candidates = [',
'    "ecoPoint", "point", "ecoCriticalPoint", "criticalPoint", "ecoPonto", "ponto",',
'    "ecoPointCritical", "ecoPontoCritico", "ecoPointCritico",',
'  ];',
'  for (const k of candidates) {',
'    const m = pc?.[k];',
'    if (m && typeof m.findMany === "function") return { key: k, model: m as any };',
'  }',
'  return null;',
'}',
'',
'function getConfirmModel() {',
'  const pc: any = prisma as any;',
'  const candidates = [',
'    "ecoPointConfirm", "pointConfirm", "ecoPointConfirmation", "pointConfirmation",',
'    "ecoConfirm", "confirm", "ecoConfirmation", "confirmation",',
'  ];',
'  for (const k of candidates) {',
'    const m = pc?.[k];',
'    if (m && (typeof m.groupBy === "function" || typeof m.findMany === "function")) return { key: k, model: m as any };',
'  }',
'  return null;',
'}',
'',
'function pickId(p: any): string {',
'  return String(p?.id || p?.pointId || "");',
'}',
'',
'function mergeCounts(p: any, confirmCount: number) {',
'  const prev = (p as any)?.counts && typeof (p as any).counts === "object" ? (p as any).counts : {};',
'  return { ...p, counts: { ...prev, confirm: confirmCount } };',
'}',
'',
'async function tryFindManyPoint(model: any, where: any, orderBy: any) {',
'  // tenta com where+orderBy e cai pra versoes mais simples se o schema nao aceitar',
'  try { return await model.findMany({ where, orderBy }); } catch {}',
'  try { return await model.findMany({ where }); } catch {}',
'  try { return await model.findMany({ orderBy }); } catch {}',
'  return await model.findMany({});',
'}',
'',
'async function buildConfirmMap(confirmModel: any) {',
'  const map: Record<string, number> = {};',
'  if (!confirmModel) return map;',
'',
'  // 1) tenta groupBy(pointId)',
'  if (typeof confirmModel.groupBy === "function") {',
'    try {',
'      const rows = await confirmModel.groupBy({ by: ["pointId"], _count: { _all: true } });',
'      for (const r of rows || []) {',
'        const pid = String((r as any)?.pointId || "");',
'        const n = Number((r as any)?._count?._all || 0) || 0;',
'        if (pid) map[pid] = n;',
'      }',
'      return map;',
'    } catch {}',
'  }',
'',
'  // 2) fallback: findMany + conta em JS (pode ser mais pesado, mas é MVP)',
'  if (typeof confirmModel.findMany === "function") {',
'    try {',
'      const rows = await confirmModel.findMany({});',
'      for (const r of rows || []) {',
'        const pid = String((r as any)?.pointId || (r as any)?.pontoId || "");',
'        if (!pid) continue;',
'        map[pid] = (map[pid] || 0) + 1;',
'      }',
'    } catch {}',
'  }',
'',
'  return map;',
'}',
'',
'export async function GET(req: Request) {',
'  const { searchParams } = new URL(req.url);',
'  const base = String(searchParams.get("base") || "pontos");',
'',
'  const point = getPointModel();',
'  if (!point?.model) {',
'    return NextResponse.json({ ok: false, error: "point_model_not_ready" }, { status: 503 });',
'  }',
'',
'  const confirm = getConfirmModel();',
'  const confirmMap = await buildConfirmMap(confirm?.model);',
'',
'  // filtro best-effort: chamados/confirmados costumam ser OPEN',
'  const where: any = {};',
'  if (base === "chamados" || base === "confirmados") {',
'    where.status = "OPEN";',
'  }',
'',
'  let items: any[] = [];',
'  try {',
'    // order best-effort',
'    items = await tryFindManyPoint(point.model, where, { createdAt: "desc" });',
'  } catch (e) {',
'    const msg = asMsg(e);',
'    return NextResponse.json({ ok: false, error: "db_error", detail: msg, model: point.key }, { status: 500 });',
'  }',
'',
'  // anexa counts.confirm',
'  const out = (items || []).map((p: any) => {',
'    const id = pickId(p);',
'    const n = id ? (confirmMap[id] || 0) : 0;',
'    return mergeCounts(p, n);',
'  });',
'',
'  return NextResponse.json({',
'    ok: true,',
'    items: out,',
'    meta: {',
'      base,',
'      pointModel: point.key,',
'      confirmModel: confirm ? confirm.key : null,',
'      withCounts: true,',
'    },',
'  });',
'}'
)
WriteAllLinesUtf8NoBom $apiFile $A
Write-Host "[PATCH] wrote /api/eco/mural/list"

# 2) Patch MuralClient fetch to use /api/eco/mural/list?base=...
$raw = Get-Content -LiteralPath $muralClient -Raw -ErrorAction Stop
if ($raw -notmatch '/api/eco/mural/list') {
  $lines = $raw -split "`n"
  $changed = $false

  for ($i=0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    if ($line -match 'fetch\s*\(' -and $line -match '/api/eco/' -and $line -match '["' + "'" + ']') {
      $indent = ([regex]::Match($line, '^\s*')).Value

      # inject apiUrl line once (just before first matching fetch)
      $apiLine = $indent + 'const apiUrl = "/api/eco/mural/list?base=" + encodeURIComponent(String(base || "pontos"));'
      $alreadyApiLine = $false
      for ($k = [Math]::Max(0, $i-8); $k -le $i; $k++) {
        if ($lines[$k] -match 'const\s+apiUrl\s*=\s*"/api/eco/mural/list\?base="') { $alreadyApiLine = $true; break }
      }

      $new = New-Object System.Collections.Generic.List[string]
      for ($j=0; $j -lt $lines.Count; $j++) {
        if ($j -eq $i) {
          if (-not $alreadyApiLine) { $new.Add($apiLine) }
          $patchedLine = [regex]::Replace($lines[$j], 'fetch\s*\(\s*["' + "'" + '][^"' + "'" + ']+["' + "'" + ']', 'fetch(apiUrl')
          $new.Add($patchedLine)
          $changed = $true
        } else {
          $new.Add($lines[$j])
        }
      }

      $raw2 = ($new -join "`n")
      WriteUtf8NoBom $muralClient $raw2
      Write-Host "[PATCH] MuralClient: fetch now uses /api/eco/mural/list?base=..."
      break
    }
  }

  if (-not $changed) {
    Write-Host "[SKIP] Nao consegui achar um fetch(/api/eco/...) em MuralClient para trocar. (Se acontecer, voce cola o arquivo aqui.)"
  }
} else {
  Write-Host "[SKIP] MuralClient ja usa /api/eco/mural/list"
}

# report
$rep = Join-Path $reportDir ("eco-step-94-mural-api-confirm-counts-v0_1-" + $ts + ".md")
$repText = @(
"# eco-step-94-mural-api-confirm-counts-v0_1",
"",
"- Time: " + $ts,
"- Backup: " + $backupDir,
"",
"## Changes",
"- Added API: src/app/api/eco/mural/list/route.ts (items + counts.confirm best-effort via Prisma dynamic models)",
"- Patched: src/app/eco/mural/MuralClient.tsx (fetch from /api/eco/mural/list?base=...)",
"",
"## Verify",
"1) Ctrl+C -> npm run dev",
"2) /eco/mural (carrega sem 500)",
"3) /eco/mural/confirmados (filtra por counts.confirm > 0)",
"4) Se tiver ponto confirmado, deve aparecer badge/contagem com consistencia.",
"",
"## Notes",
"- A API tenta detectar automaticamente os models do Prisma (pontos + confirmacoes).",
"- Se meta.confirmModel vier null, seu schema ainda nao tem o model de confirmacao ou o nome e diferente (a gente ajusta candidatos)."
) -join "`n"
WriteUtf8NoBom $rep $repText
Write-Host ("[REPORT] " + $rep)

Write-Host ""
Write-Host "[VERIFY] Ctrl+C -> npm run dev"
Write-Host "[VERIFY] /eco/mural"
Write-Host "[VERIFY] /eco/mural/confirmados"
Write-Host "[VERIFY] (abra o DevTools -> Network -> /api/eco/mural/list e veja meta.confirmModel)"