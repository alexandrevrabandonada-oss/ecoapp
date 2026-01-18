$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# --- bootstrap (preferencial) ---
$bootstrap = Join-Path $PSScriptRoot "_bootstrap.ps1"
if(Test-Path -LiteralPath $bootstrap){
  . $bootstrap
} else {
  function EnsureDir([string]$p){
    if($p -and !(Test-Path -LiteralPath $p)){
      New-Item -ItemType Directory -Force -Path $p | Out-Null
    }
  }
  function WriteUtf8NoBom([string]$path, [string]$content){
    $dir = Split-Path -Parent $path
    if($dir){ EnsureDir $dir }
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
  }
  function BackupFile([string]$path){
    if(!(Test-Path -LiteralPath $path)){ return $null }
    EnsureDir "tools/_patch_backup"
    $ts = Get-Date -Format "yyyyMMdd-HHmmss"
    $safe = ($path -replace '[\\/:*?"<>|]', '_')
    $dst = "tools/_patch_backup/$ts-$safe"
    Copy-Item -Force -LiteralPath $path $dst
    return $dst
  }
  function NewReport([string]$name){
    EnsureDir "reports"
    $ts = Get-Date -Format "yyyyMMdd-HHmmss"
    return "reports/$ts-$name.md"
  }
}

function RunCmd([string]$exe, [string[]]$args){
  $lines = & $exe @args 2>&1
  $exit = $LASTEXITCODE
  return [pscustomobject]@{ ExitCode = $exit; Lines = $lines }
}

function FindFirstFile([string[]]$candidates){
  foreach($p in $candidates){
    if(Test-Path -LiteralPath $p){ return $p }
  }
  return $null
}

$rep = NewReport "eco-step-52-day-close-migrate-and-api-upsert"
$log = @()
$log += "# ECO — STEP 52 — Day Close (Prisma + API upsert/compute)"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

try {
  # -------------------------
  # DIAG
  # -------------------------
  $log += "## DIAG"
  $log += ("Node: {0}" -f (node -v))
  $log += ("Npm : {0}" -f (npm -v))
  $log += ""

  if(!(Test-Path -LiteralPath "prisma/schema.prisma")){
    throw "GUARD: não achei prisma/schema.prisma — rode no repo ECO."
  }
  if(!(Test-Path -LiteralPath "src/app")){
    throw "GUARD: não achei src/app — estrutura inesperada."
  }

  $schemaPath = "prisma/schema.prisma"
  $schemaRaw = Get-Content -LiteralPath $schemaPath -Raw

  $hasModel = $schemaRaw -match "(?ms)^\s*model\s+EcoDayClose\s*\{"
  $log += ("Prisma: model EcoDayClose presente? {0}" -f ($(if($hasModel){"SIM"}else{"NÃO"})))
  $log += ""

  # -------------------------
  # PATCH 1) Prisma model EcoDayClose (se faltar)
  # -------------------------
  if(-not $hasModel){
    $bk = BackupFile $schemaPath
    $log += "## PATCH — Prisma schema (EcoDayClose)"
    $log += ("Backup: {0}" -f $bk)

    $append = @(
      "",
      "model EcoDayClose {",
      "  day      String   @id",
      "  summary   Json",
      "  closedAt  DateTime?",
      "  closedBy  String?",
      "  createdAt DateTime @default(now())",
      "  updatedAt DateTime @updatedAt",
      "}",
      ""
    ) -join "`n"

    $schemaRaw2 = $schemaRaw.TrimEnd() + "`n" + $append
    WriteUtf8NoBom $schemaPath $schemaRaw2

    $log += "- OK: adicionei model EcoDayClose no schema."
    $log += ""
  }

  # -------------------------
  # PATCH 2) Prisma format + migrate + generate (sem npx)
  # -------------------------
  $log += "## PATCH — Prisma migrate/generate"
  $prismaCmd = FindFirstFile @(".\node_modules\.bin\prisma.cmd", ".\node_modules\.bin\prisma")
  if(-not $prismaCmd){
    $log += "- Prisma bin não encontrado. Instalando deps..."
    $r1 = RunCmd "npm" @("i","-D","prisma")
    $log += ("npm i -D prisma (exit {0})" -f $r1.ExitCode)
    $r2 = RunCmd "npm" @("i","@prisma/client")
    $log += ("npm i @prisma/client (exit {0})" -f $r2.ExitCode)
    $prismaCmd = FindFirstFile @(".\node_modules\.bin\prisma.cmd", ".\node_modules\.bin\prisma")
    if(-not $prismaCmd){ throw "Não consegui achar prisma.cmd mesmo após instalar." }
  }
  $log += ("Prisma bin: {0}" -f $prismaCmd)

  $fmt = RunCmd $prismaCmd @("format")
  $log += ("prisma format (exit {0})" -f $fmt.ExitCode)

  $mig = RunCmd $prismaCmd @("migrate","dev","--name","eco_day_close")
  $log += ("prisma migrate dev (exit {0})" -f $mig.ExitCode)

  $migTxt = ($mig.Lines -join "`n")
  $needsReset = ($migTxt -match "Drift detected") -or ($migTxt -match "We need to reset")
  if($needsReset){
    $log += ""
    $log += "⚠️ Drift detectado. Fazendo backup de prisma/dev.db e reset (DEV)."
    if(Test-Path -LiteralPath "prisma/dev.db"){
      $bkdb = BackupFile "prisma/dev.db"
      $log += ("Backup dev.db: {0}" -f $bkdb)
    }
    $reset = RunCmd $prismaCmd @("migrate","reset","--force")
    $log += ("prisma migrate reset --force (exit {0})" -f $reset.ExitCode)

    $mig2 = RunCmd $prismaCmd @("migrate","dev","--name","eco_day_close")
    $log += ("prisma migrate dev (2) (exit {0})" -f $mig2.ExitCode)
  }

  $gen = RunCmd $prismaCmd @("generate")
  $log += ("prisma generate (exit {0})" -f $gen.ExitCode)
  $log += ""

  # -------------------------
  # PATCH 3) API /api/eco/day-close (GET compute+cache + POST upsert)
  # -------------------------
  $routePath = "src/app/api/eco/day-close/route.ts"
  EnsureDir (Split-Path -Parent $routePath)

  $bkRoute = BackupFile $routePath
  $log += "## PATCH — API day-close"
  $log += ("Arquivo: {0}" -f $routePath)
  $log += ("Backup : {0}" -f ($(if($bkRoute){$bkRoute}else{"(novo)"})))
  $log += ""

  $routeLines = @(
    'import { NextResponse } from "next/server";',
    'import { prisma } from "@/lib/prisma";',
    '',
    'export const runtime = "nodejs";',
    '',
    'function safeDay(input: string | null): string | null {',
    '  const s = String(input || "").trim();',
    '  if (/^\\d{4}-\\d{2}-\\d{2}$/.test(s)) return s;',
    '  return null;',
    '}',
    '',
    'function asMsg(e: unknown) {',
    '  if (e instanceof Error) return e.message;',
    '  try { return String(e); } catch { return "unknown"; }',
    '}',
    '',
    'function looksLikeMissingTable(msg: string) {',
    '  const m = msg.toLowerCase();',
    '  return m.includes("does not exist") || m.includes("no such table") || m.includes("p2021");',
    '}',
    '',
    'function getDayCloseModel() {',
    '  const pc: any = prisma as any;',
    '  return pc?.ecoDayClose;',
    '}',
    '',
    'function getTriagemModel() {',
    '  const pc: any = prisma as any;',
    '  const candidates = ["ecoTriagem", "triagem", "ecoSorting", "sorting"];',
    '  for (const k of candidates) {',
    '    const m = pc?.[k];',
    '    if (m && typeof m.findMany === "function") return { key: k, model: m as any };',
    '  }',
    '  return null;',
    '}',
    '',
    'function dayRange(day: string) {',
    '  // Brasil -03:00 (sem depender de timezone do server)',
    '  const start = new Date(day + "T00:00:00-03:00");',
    '  const end = new Date(day + "T23:59:59.999-03:00");',
    '  return { start, end };',
    '}',
    '',
    'function bump(obj: any, key: string, inc: number) {',
    '  if (!obj[key]) obj[key] = 0;',
    '  obj[key] += inc;',
    '}',
    '',
    'function normalizeMaterial(s: string) {',
    '  const t = String(s || "").toLowerCase();',
    '  if (t.includes("papel")) return "papel";',
    '  if (t.includes("plasti")) return "plastico";',
    '  if (t.includes("metal")) return "metal";',
    '  if (t.includes("vidro")) return "vidro";',
    '  if (t.includes("org")) return "organico";',
    '  if (t.includes("reje")) return "rejeito";',
    '  return "outros";',
    '}',
    '',
    'async function computeSummary(day: string) {',
    '  const { start, end } = dayRange(day);',
    '  const tri = getTriagemModel();',
    '',
    '  const totals: any = { totalKg: 0, byMaterialKg: {}, count: 0 };',
    '  const meta: any = { computedAt: new Date().toISOString(), source: [] as string[] };',
    '',
    '  if (tri) {',
    '    meta.source.push("triagem:" + tri.key);',
    '    const rows = await tri.model.findMany({',
    '      where: { createdAt: { gte: start, lte: end } },',
    '    });',
    '    totals.count = rows.length;',
    '    for (const r of rows) {',
    '      const kg = Number((r && (r.weightKg ?? r.kg ?? r.weight ?? 0)) || 0) || 0;',
    '      const mat = normalizeMaterial(String((r && (r.material ?? r.kind ?? r.type ?? "")) || ""));',
    '      totals.totalKg += kg;',
    '      bump(totals.byMaterialKg, mat, kg);',
    '    }',
    '  } else {',
    '    meta.source.push("triagem:missing");',
    '  }',
    '',
    '  const summary = {',
    '    day,',
    '    totals,',
    '    meta,',
    '    notes: [],',
    '    version: "v0",',
    '  };',
    '  return summary;',
    '}',
    '',
    'export async function GET(req: Request) {',
    '  const { searchParams } = new URL(req.url);',
    '  const day = safeDay(searchParams.get("day"));',
    '  const fresh = String(searchParams.get("fresh") || "").trim() === "1";',
    '  if (!day) return NextResponse.json({ ok: false, error: "bad_day" }, { status: 400 });',
    '',
    '  const model = getDayCloseModel();',
    '  if (!model?.findUnique) {',
    '    return NextResponse.json({ ok: false, error: "model_not_ready" }, { status: 503 });',
    '  }',
    '',
    '  try {',
    '    if (!fresh) {',
    '      const row = await model.findUnique({ where: { day } });',
    '      if (row) return NextResponse.json({ ok: true, item: row, cached: true });',
    '    }',
    '',
    '    const summary = await computeSummary(day);',
    '    const item = await model.upsert({',
    '      where: { day },',
    '      update: { summary },',
    '      create: { day, summary },',
    '    });',
    '    return NextResponse.json({ ok: true, item, cached: false });',
    '  } catch (e) {',
    '    const msg = asMsg(e);',
    '    if (looksLikeMissingTable(msg)) {',
    '      return NextResponse.json({ ok: false, error: "db_not_ready", detail: msg }, { status: 503 });',
    '    }',
    '    return NextResponse.json({ ok: false, error: "db_error", detail: msg }, { status: 500 });',
    '  }',
    '}',
    '',
    'export async function POST(req: Request) {',
    '  const body = (await req.json().catch(() => null)) as any;',
    '  const day = safeDay(body?.day ?? null);',
    '  if (!day) return NextResponse.json({ ok: false, error: "bad_day" }, { status: 400 });',
    '',
    '  const model = getDayCloseModel();',
    '  if (!model?.upsert) {',
    '    return NextResponse.json({ ok: false, error: "model_not_ready" }, { status: 503 });',
    '  }',
    '',
    '  try {',
    '    const summary = body?.summary ?? (await computeSummary(day));',
    '    const item = await model.upsert({',
    '      where: { day },',
    '      update: { summary },',
    '      create: { day, summary },',
    '    });',
    '    return NextResponse.json({ ok: true, item });',
    '  } catch (e) {',
    '    const msg = asMsg(e);',
    '    if (looksLikeMissingTable(msg)) {',
    '      return NextResponse.json({ ok: false, error: "db_not_ready", detail: msg }, { status: 503 });',
    '    }',
    '    return NextResponse.json({ ok: false, error: "db_error", detail: msg }, { status: 500 });',
    '  }',
    '}'
  )

  WriteUtf8NoBom $routePath ($routeLines -join "`n")

  $log += "- OK: day-close agora faz compute+cache no GET e upsert no POST."
  $log += ""

  # -------------------------
  # REPORT
  # -------------------------
  WriteUtf8NoBom $rep ($log -join "`n")
  Write-Host ("✅ STEP 52 aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
  Write-Host "VERIFY:" -ForegroundColor Yellow
  Write-Host "1) (Se dev rodando) CTRL+C e npm run dev" -ForegroundColor Yellow
  Write-Host "2) GET /api/eco/day-close?day=2025-12-26  (esperado 200, ok:true)" -ForegroundColor Yellow
  Write-Host "3) GET /api/eco/day-close?day=2025-12-26&fresh=1  (recalcula e salva)" -ForegroundColor Yellow
  Write-Host "4) /s/dia/2025-12-26 -> Auto preencher (triagem) deve continuar ok" -ForegroundColor Yellow

} catch {
  try { WriteUtf8NoBom $rep ($log -join "`n") } catch {}
  throw
}