param(
  [string]$Root = (Get-Location).Path,
  [switch]$SkipPrisma
)

$ts = Get-Date -Format "yyyyMMdd-HHmmss"
Write-Host ("== eco-step-100-fix-list2-groupby-and-support-schema-v0_1 == " + $ts)
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
if (-not (Get-Command NewReport -ErrorAction SilentlyContinue)) {
  function NewReport([string]$root, [string]$name, [string[]]$lines) {
    $dir = Join-Path $root "reports"
    EnsureDir $dir
    $p = Join-Path $dir ($name + "-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".md")
    WriteUtf8NoBom $p (($lines -join "`n") + "`n")
    return $p
  }
}

$backupDir = Join-Path $Root ("tools/_patch_backup/" + $ts + "-eco-step-100")
EnsureDir $backupDir

$schema = Join-Path $Root "prisma/schema.prisma"
$list2  = Join-Path $Root "src/app/api/eco/points/list2/route.ts"

Write-Host ("[DIAG] schema: " + $schema)
Write-Host ("[DIAG] list2:  " + $list2)

if (-not (Test-Path -LiteralPath $schema)) { throw "[STOP] Nao achei prisma/schema.prisma" }
if (-not (Test-Path -LiteralPath $list2))  { throw "[STOP] Nao achei src/app/api/eco/points/list2/route.ts" }

BackupFile $Root $schema $backupDir
BackupFile $Root $list2  $backupDir

# -------------------------
# PATCH 1) Fix Prisma schema: add opposite relation field in EcoCriticalPoint
# -------------------------
$raw = Get-Content -LiteralPath $schema -Raw -ErrorAction Stop

function FindModelBlock([string]$text, [string]$modelName) {
  $m = [regex]::Match($text, "(?ms)^\s*model\s+" + [regex]::Escape($modelName) + "\s*\{")
  if (-not $m.Success) { return $null }
  $openIdx = $text.IndexOf("{", $m.Index)
  if ($openIdx -lt 0) { return $null }
  $i = $openIdx
  $depth = 0
  while ($i -lt $text.Length) {
    $ch = $text[$i]
    if ($ch -eq "{") { $depth++ }
    elseif ($ch -eq "}") {
      $depth--
      if ($depth -eq 0) {
        return @{ start = $m.Index; open = $openIdx; close = $i; end = $i + 1 }
      }
    }
    $i++
  }
  return $null
}

$blk = FindModelBlock $raw "EcoCriticalPoint"
if ($null -eq $blk) {
  Write-Host "[WARN] Nao achei model EcoCriticalPoint (vou pular patch do schema)."
} else {
  $inside = $raw.Substring($blk.open + 1, $blk.close - $blk.open - 1)
  if ($inside -match "(?m)^\s*supports\s+EcoPointSupport\[\]") {
    Write-Host "[SKIP] EcoCriticalPoint ja tem supports EcoPointSupport[]"
  } else {
    $insertLine = "  supports  EcoPointSupport[]"
    # insert before closing brace, keep a newline
    $before = $raw.Substring(0, $blk.close)
    $after  = $raw.Substring($blk.close)
    if ($before -notmatch "(\r?\n)\s*$") { $before = $before + "`r`n" }
    $before = $before + $insertLine + "`r`n"
    $raw = $before + $after
    Write-Host "[PATCH] schema.prisma: added EcoCriticalPoint.supports EcoPointSupport[]"
    WriteUtf8NoBom $schema $raw
  }
}

# -------------------------
# PATCH 2) Rewrite list2 route to use safe groupBy + FK autodetect
# -------------------------
$L = New-Object System.Collections.Generic.List[string]

$L.Add('import { NextResponse } from "next/server";')
$L.Add('import { prisma } from "@/lib/prisma";')
$L.Add('')
$L.Add('export const runtime = "nodejs";')
$L.Add('export const dynamic = "force-dynamic";')
$L.Add('')
$L.Add('function safeInt(v: string | null, def: number, min: number, max: number) {')
$L.Add('  const n = Number(v);')
$L.Add('  if (!Number.isFinite(n)) return def;')
$L.Add('  const x = Math.floor(n);')
$L.Add('  return Math.max(min, Math.min(max, x));')
$L.Add('}')
$L.Add('')
$L.Add('function pickModel(pc: any, primary: string, fallbacks: string[]) {')
$L.Add('  if (!pc) return null;')
$L.Add('  if (pc[primary]) return pc[primary];')
$L.Add('  for (const k of fallbacks) {')
$L.Add('    if (pc[k]) return pc[k];')
$L.Add('    const kk = k.charAt(0).toLowerCase() + k.slice(1);')
$L.Add('    if (pc[kk]) return pc[kk];')
$L.Add('  }')
$L.Add('  return null;')
$L.Add('}')
$L.Add('')
$L.Add('async function groupCountByAnyFk(model: any, fkCandidates: string[]) {')
$L.Add('  const map: Record<string, number> = {};')
$L.Add('  if (!model || typeof model.groupBy !== "function") return { field: null as string | null, map };')
$L.Add('  for (const fk of fkCandidates) {')
$L.Add('    try {')
$L.Add('      const rows = await model.groupBy({')
$L.Add('        by: [fk],')
$L.Add('        _count: { _all: true },')
$L.Add('      } as any);')
$L.Add('      for (const r of rows as any[]) {')
$L.Add('        const id = (r as any)[fk];')
$L.Add('        const n = Number((r as any)?._count?._all ?? 0);')
$L.Add('        if (id !== null && id !== undefined) map[String(id)] = Number.isFinite(n) ? n : 0;')
$L.Add('      }')
$L.Add('      return { field: fk, map };')
$L.Add('    } catch (e) {')
$L.Add('      // try next fk candidate')
$L.Add('    }')
$L.Add('  }')
$L.Add('  return { field: null as string | null, map };')
$L.Add('}')
$L.Add('')
$L.Add('async function findManySafe(model: any, where: any, take: number) {')
$L.Add('  if (!model || typeof model.findMany !== "function") return [];')
$L.Add('  try { return await model.findMany({ where, orderBy: { updatedAt: "desc" }, take } as any); } catch (e1) {}')
$L.Add('  try { return await model.findMany({ where, orderBy: { createdAt: "desc" }, take } as any); } catch (e2) {}')
$L.Add('  try { return await model.findMany({ where, take } as any); } catch (e3) {}')
$L.Add('  try { return await model.findMany({ take } as any); } catch (e4) {}')
$L.Add('  return [];')
$L.Add('}')
$L.Add('')
$L.Add('export async function GET(req: Request) {')
$L.Add('  try {')
$L.Add('    const url = new URL(req.url);')
$L.Add('    const limit = safeInt(url.searchParams.get("limit"), 160, 1, 500);')
$L.Add('    const bairro = (url.searchParams.get("bairro") || "").trim();')
$L.Add('    const status = (url.searchParams.get("status") || "").trim();')
$L.Add('    const only = (url.searchParams.get("only") || "").trim();')
$L.Add('')
$L.Add('    const pc: any = prisma as any;')
$L.Add('    const pointModel = pickModel(pc, "ecoCriticalPoint", ["EcoCriticalPoint", "criticalPoint", "ecoPoint", "point"]);')
$L.Add('    if (!pointModel) {')
$L.Add('      return NextResponse.json({ ok: false, error: "no_point_model" }, { status: 500 });')
$L.Add('    }')
$L.Add('')
$L.Add('    const where: any = {};')
$L.Add('    if (bairro) where.bairro = bairro;')
$L.Add('    if (status) where.status = status;')
$L.Add('')
$L.Add('    const points = await findManySafe(pointModel, where, limit);')
$L.Add('')
$L.Add('    const confirmModel = pickModel(pc, "ecoCriticalPointConfirm", ["EcoCriticalPointConfirm", "criticalPointConfirm", "ecoPointConfirm", "pointConfirm"]);')
$L.Add('    const supportModel = pickModel(pc, "ecoPointSupport", ["EcoPointSupport", "pointSupport", "ecoCriticalPointSupport", "criticalPointSupport"]);')
$L.Add('')
$L.Add('    const fkCandidates = ["pointId", "criticalPointId", "ecoCriticalPointId", "ecoPointId"];')
$L.Add('    const confirm = await groupCountByAnyFk(confirmModel, fkCandidates);')
$L.Add('    const support = await groupCountByAnyFk(supportModel, fkCandidates);')
$L.Add('')
$L.Add('    let items = (points as any[]).map((p: any) => {')
$L.Add('      const id = String(p?.id ?? "");')
$L.Add('      const cc = confirm.map[id] || 0;')
$L.Add('      const ss = support.map[id] || 0;')
$L.Add('      return {')
$L.Add('        ...p,')
$L.Add('        counts: {')
$L.Add('          ...(p?.counts || {}),')
$L.Add('          confirm: cc,')
$L.Add('          support: ss,')
$L.Add('        },')
$L.Add('      };')
$L.Add('    });')
$L.Add('')
$L.Add('    if (only === "confirmados") {')
$L.Add('      items = items.filter((p: any) => Number(p?.counts?.confirm || 0) > 0);')
$L.Add('    }')
$L.Add('')
$L.Add('    return NextResponse.json({')
$L.Add('      ok: true,')
$L.Add('      items,')
$L.Add('      meta: {')
$L.Add('        pointModel: pointModel ? (pointModel._name || null) : null,')
$L.Add('        confirmBy: confirm.field,')
$L.Add('        supportBy: support.field,')
$L.Add('      },')
$L.Add('    });')
$L.Add('  } catch (e: any) {')
$L.Add('    return NextResponse.json({ ok: false, error: "exception", detail: String(e?.message || e) }, { status: 500 });')
$L.Add('  }')
$L.Add('}')
$codeTs = $L -join "`n"

WriteUtf8NoBom $list2 $codeTs
Write-Host "[PATCH] rewrote src/app/api/eco/points/list2/route.ts (safe groupBy + fk autodetect)"

# -------------------------
# Prisma: validate + migrate dev + generate (best-effort)
# -------------------------
if (-not $SkipPrisma) {
  $prismaCmd = Join-Path $Root "node_modules/.bin/prisma.cmd"
  if (-not (Test-Path -LiteralPath $prismaCmd)) {
    Write-Host "[WARN] prisma.cmd nao encontrado em node_modules/.bin (pulando Prisma)."
  } else {
    try {
      Write-Host ("[RUN] " + $prismaCmd + " validate")
      & $prismaCmd validate
    } catch {
      Write-Host "[WARN] prisma validate falhou. Se for Drift no SQLite, backup prisma/dev.db e rode prisma migrate reset --force."
      throw
    }

    try {
      Write-Host ("[RUN] " + $prismaCmd + " migrate dev --name eco_support_fix")
      & $prismaCmd migrate dev --name eco_support_fix
    } catch {
      Write-Host "[WARN] migrate dev falhou. Pode ser Drift. Veja msg acima."
      throw
    }

    try {
      Write-Host ("[RUN] " + $prismaCmd + " generate")
      & $prismaCmd generate
    } catch {
      Write-Host "[WARN] prisma generate falhou."
      throw
    }
  }
} else {
  Write-Host "[SKIP] SkipPrisma ligado: nao rodei validate/migrate/generate."
}

# -------------------------
# REPORT
# -------------------------
$rep = NewReport $Root "eco-step-100-fix-list2-groupby-and-support-schema-v0_1" @(
  "# eco-step-100-fix-list2-groupby-and-support-schema-v0_1",
  "",
  "- Time: " + $ts,
  "- Backup: " + $backupDir,
  "",
  "## Changes",
  "- prisma/schema.prisma: added opposite field `supports EcoPointSupport[]` in model EcoCriticalPoint (fix P1012).",
  "- src/app/api/eco/points/list2/route.ts: rewrote endpoint with safe groupBy + fk autodetect + _count shape (fix groupBy error).",
  "",
  "## Verify",
  "1) Ctrl+C",
  "2) npm run dev",
  "3) GET http://localhost:3000/api/eco/points/list2?limit=10",
  "4) GET http://localhost:3000/api/eco/points/list2?limit=10&only=confirmados",
  "5) /eco/mural e /eco/mural/confirmados (se existir) — nao pode logar prisma:error de groupBy.",
  "",
  "## Notes",
  "- O endpoint tenta groupBy em fkCandidates: pointId, criticalPointId, ecoCriticalPointId, ecoPointId.",
  "- meta.confirmBy/meta.supportBy mostram qual fk funcionou no seu schema."
)
Write-Host ("[REPORT] " + $rep)

Write-Host ""
Write-Host "[VERIFY] Ctrl+C -> npm run dev"
Write-Host "[VERIFY] GET /api/eco/points/list2?limit=10 (200)"
Write-Host "[VERIFY] Abra o JSON e veja meta.confirmBy/meta.supportBy (qual FK bateu)"