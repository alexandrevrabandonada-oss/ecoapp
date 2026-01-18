$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

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

$rep = NewReport "eco-step-48-hotfix-safe-day-card-and-day-close-guard"
$log = @()
$log += "# ECO — STEP 48 — Hotfix SAFE (route-day-card sem JSX + guard day-close + painel tolerante)"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

try {
  # -------------------------
  # GUARDS
  # -------------------------
  if(!(Test-Path -LiteralPath "package.json") -or !(Test-Path -LiteralPath "src/app")){
    throw "GUARD: rode no repo ECO (tem que existir package.json e src/app)."
  }

  # -------------------------
  # PATCH 1) route-day-card sem JSX (React.createElement) + remover route.tsx se existir
  # -------------------------
  $dir = "src/app/api/share/route-day-card"
  EnsureDir $dir

  $routeTs  = Join-Path $dir "route.ts"
  $routeTsx = Join-Path $dir "route.tsx"

  $log += "## PATCH — /api/share/route-day-card"
  if(Test-Path -LiteralPath $routeTsx){
    $bk = BackupFile $routeTsx
    Remove-Item -Force -LiteralPath $routeTsx
    $log += ("- removi route.tsx (Backup: {0})" -f $bk)
  } else {
    $log += "- route.tsx não existe (ok)"
  }

  $bk2 = BackupFile $routeTs
  $log += ("- route.ts backup: {0}" -f ($(if($bk2){$bk2}else{"(novo)"})))

  $routeLines = @(
    'import React from "react";',
    'import { ImageResponse } from "next/og";',
    '',
    'export const runtime = "edge";',
    '',
    'function safeDay(input: string | null): string {',
    '  const s = String(input || "").trim();',
    '  if (/^\d{4}-\d{2}-\d{2}$/.test(s)) return s;',
    '  const d = new Date();',
    '  const yyyy = d.getUTCFullYear();',
    '  const mm = String(d.getUTCMonth() + 1).padStart(2, "0");',
    '  const dd = String(d.getUTCDate()).padStart(2, "0");',
    '  return `${yyyy}-${mm}-${dd}`;',
    '}',
    '',
    'function sizeFor(format: string | null) {',
    '  const f = String(format || "").toLowerCase();',
    '  if (f === "1x1") return { w: 1080, h: 1080, label: "1:1" as const };',
    '  return { w: 1080, h: 1350, label: "3:4" as const };',
    '}',
    '',
    'export async function GET(req: Request) {',
    '  try {',
    '    const { searchParams } = new URL(req.url);',
    '    const day = safeDay(searchParams.get("day"));',
    '    const fmt = sizeFor(searchParams.get("format"));',
    '',
    '    const bg = "#0b0b0b";',
    '    const yellow = "#ffd400";',
    '    const red = "#ff3b30";',
    '    const off = "#f5f5f5";',
    '    const gray = "#bdbdbd";',
    '',
    '    const rootStyle: React.CSSProperties = {',
    '      width: "100%",',
    '      height: "100%",',
    '      display: "flex",',
    '      flexDirection: "column",',
    '      background: bg,',
    '      color: off,',
    '      padding: 64,',
    '      boxSizing: "border-box",',
    '      fontFamily: "system-ui, -apple-system, Segoe UI, Roboto, Ubuntu, Cantarell, Helvetica Neue, Arial",',
    '      border: `10px solid ${yellow}`,',
    '    };',
    '',
    '    const pill = (text: string) =>',
    '      React.createElement(',
    '        "div",',
    '        {',
    '          style: {',
    '            padding: "10px 14px",',
    '            borderRadius: 999,',
    '            border: `2px solid ${gray}`,',
    '            fontSize: 20,',
    '          },',
    '        },',
    '        text',
    '      );',
    '',
    '    const headerLeft = React.createElement(',
    '      "div",',
    '      { style: { display: "flex", flexDirection: "column", gap: 10 } },',
    '      React.createElement("div", { style: { fontSize: 22, letterSpacing: 2, color: gray } }, "#ECO — Escutar • Cuidar • Organizar"),',
    '      React.createElement(',
    '        "div",',
    '        { style: { fontSize: 64, fontWeight: 900, lineHeight: 1.0 } },',
    '        "FECHAMENTO",',
    '        React.createElement("span", { style: { color: yellow } }, " DO DIA")',
    '      ),',
    '      React.createElement("div", { style: { fontSize: 42, fontWeight: 800, color: off } }, day)',
    '    );',
    '',
    '    const headerBadge = React.createElement(',
    '      "div",',
    '      {',
    '        style: {',
    '          width: 120,',
    '          height: 120,',
    '          borderRadius: 999,',
    '          border: `8px solid ${yellow}`,',
    '          display: "flex",',
    '          alignItems: "center",',
    '          justifyContent: "center",',
    '          fontSize: 34,',
    '          fontWeight: 900,',
    '          color: yellow,',
    '        },',
    '      },',
    '      fmt.label',
    '    );',
    '',
    '    const header = React.createElement(',
    '      "div",',
    '      { style: { display: "flex", justifyContent: "space-between", alignItems: "flex-start" } },',
    '      headerLeft,',
    '      headerBadge',
    '    );',
    '',
    '    const pills = React.createElement(',
    '      "div",',
    '      { style: { display: "flex", gap: 14, flexWrap: "wrap" } },',
    '      pill("Recibo é lei"),',
    '      pill("Cuidado é coletivo"),',
    '      pill("Trabalho digno no centro")',
    '    );',
    '',
    '    const footer = React.createElement(',
    '      "div",',
    '      { style: { display: "flex", justifyContent: "space-between", alignItems: "flex-end" } },',
    '      React.createElement("div", { style: { fontSize: 22, opacity: 0.9, color: gray } }, `Compartilhe: /s/dia/${day}`),',
    '      React.createElement("div", { style: { fontSize: 18, color: red, opacity: 0.95 } }, "Sem greenwashing • Abandono × Cuidado")',
    '    );',
    '',
    '    const bottom = React.createElement(',
    '      "div",',
    '      { style: { flex: 1, display: "flex", flexDirection: "column", justifyContent: "flex-end", gap: 18 } },',
    '      pills,',
    '      footer',
    '    );',
    '',
    '    const tree = React.createElement("div", { style: rootStyle }, header, bottom);',
    '',
    '    return new ImageResponse(tree, {',
    '      width: fmt.w,',
    '      height: fmt.h,',
    '      headers: {',
    '        "cache-control": "public, max-age=0, s-maxage=3600, stale-while-revalidate=86400",',
    '      },',
    '    });',
    '  } catch (err: any) {',
    '    return new Response("route-day-card error: " + (err?.message || "unknown"), { status: 500 });',
    '  }',
    '}'
  )

  WriteUtf8NoBom $routeTs ($routeLines -join "`n")
  $log += "- OK: route-day-card reescrito (SEM JSX)."
  $log += ""

  # -------------------------
  # PATCH 2) day-close guard (404/503 em vez de 500)
  # -------------------------
  $dayClose = "src/app/api/eco/day-close/route.ts"
  EnsureDir (Split-Path -Parent $dayClose)
  $bkDc = BackupFile $dayClose

  $log += "## PATCH — /api/eco/day-close guard"
  $log += ("- arquivo: {0}" -f $dayClose)
  $log += ("- backup : {0}" -f ($(if($bkDc){$bkDc}else{"(novo)"})))

  $dcLines = @(
    'import { NextResponse } from "next/server";',
    'import { prisma } from "@/lib/prisma";',
    '',
    'export const runtime = "nodejs";',
    '',
    'function safeDay(input: string | null): string | null {',
    '  const s = String(input || "").trim();',
    '  if (/^\d{4}-\d{2}-\d{2}$/.test(s)) return s;',
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
    'function getModel() {',
    '  const pc: any = prisma as any;',
    '  return pc?.ecoDayClose;',
    '}',
    '',
    'export async function GET(req: Request) {',
    '  const { searchParams } = new URL(req.url);',
    '  const day = safeDay(searchParams.get("day"));',
    '  if (!day) return NextResponse.json({ ok: false, error: "bad_day" }, { status: 400 });',
    '',
    '  const model = getModel();',
    '  if (!model?.findUnique) {',
    '    return NextResponse.json({ ok: false, error: "model_not_ready", hint: "rode migrate + prisma generate (se aplicável)" }, { status: 503 });',
    '  }',
    '',
    '  try {',
    '    const row = await model.findUnique({ where: { day } });',
    '    if (!row) return NextResponse.json({ ok: false, error: "not_found" }, { status: 404 });',
    '    return NextResponse.json({ ok: true, item: row });',
    '  } catch (e) {',
    '    const msg = asMsg(e);',
    '    if (looksLikeMissingTable(msg)) {',
    '      return NextResponse.json({ ok: false, error: "db_not_ready", hint: "npx prisma migrate dev --name eco_day_close", detail: msg }, { status: 503 });',
    '    }',
    '    return NextResponse.json({ ok: false, error: "db_error", detail: msg }, { status: 500 });',
    '  }',
    '}',
    '',
    'export async function POST(req: Request) {',
    '  const body = (await req.json().catch(() => null)) as { day?: string; summary?: unknown } | null;',
    '  const day = safeDay(body?.day ?? null);',
    '  if (!day) return NextResponse.json({ ok: false, error: "bad_day" }, { status: 400 });',
    '',
    '  const model = getModel();',
    '  if (!model?.upsert) {',
    '    return NextResponse.json({ ok: false, error: "model_not_ready", hint: "rode migrate + prisma generate (se aplicável)" }, { status: 503 });',
    '  }',
    '',
    '  try {',
    '    const summary = body?.summary ?? {};',
    '    const item = await model.upsert({ where: { day }, update: { summary }, create: { day, summary } });',
    '    return NextResponse.json({ ok: true, item });',
    '  } catch (e) {',
    '    const msg = asMsg(e);',
    '    if (looksLikeMissingTable(msg)) {',
    '      return NextResponse.json({ ok: false, error: "db_not_ready", hint: "npx prisma migrate dev --name eco_day_close", detail: msg }, { status: 503 });',
    '    }',
    '    return NextResponse.json({ ok: false, error: "db_error", detail: msg }, { status: 500 });',
    '  }',
    '}'
  )

  WriteUtf8NoBom $dayClose ($dcLines -join "`n")
  $log += "- OK: day-close endurecido."
  $log += ""

  # -------------------------
  # PATCH 3) DayClosePanel tolerante (db_not_ready/model_not_ready)
  # -------------------------
  $panel = "src/app/s/dia/[day]/DayClosePanel.tsx"
  if(Test-Path -LiteralPath $panel){
    $bkP = BackupFile $panel
    $raw = Get-Content -LiteralPath $panel -Raw
    if(-not $raw){ throw "DayClosePanel.tsx está vazio (raw null)." }

    $old = 'if (j.error !== "not_found") throw new Error(j.error);'
    if($raw.Contains($old)){
      $new = 'if (j.error === "not_found") return;' + "`n" +
             '          if (j.error === "db_not_ready" || j.error === "model_not_ready") { setErr("Banco ainda não pronto (rode migrate/prisma)."); return; }' + "`n" +
             '          throw new Error(j.error);'
      $raw2 = $raw.Replace($old, $new)
      WriteUtf8NoBom $panel $raw2
      $log += "## PATCH — DayClosePanel"
      $log += ("- backup: {0}" -f $bkP)
      $log += "- OK: trata db_not_ready/model_not_ready sem quebrar."
      $log += ""
    } else {
      $log += "## PATCH — DayClosePanel"
      $log += ("- backup: {0}" -f $bkP)
      $log += "- INFO: padrão não encontrado (provável já ajustado)."
      $log += ""
    }
  } else {
    $log += "## WARN"
    $log += "Não achei DayClosePanel.tsx — pulei patch do painel."
    $log += ""
  }

  WriteUtf8NoBom $rep ($log -join "`n")
  Write-Host ("✅ STEP 48 aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
  Write-Host "VERIFY:" -ForegroundColor Yellow
  Write-Host "1) CTRL+C (se dev rodando) e: npm run dev" -ForegroundColor Yellow
  Write-Host "2) GET /api/share/route-day-card?day=2025-12-26&format=3x4 (esperado 200)" -ForegroundColor Yellow
  Write-Host "3) GET /api/eco/day-close?day=2025-12-26 (esperado 404 ou 503, NÃO 500)" -ForegroundColor Yellow
  Write-Host "4) /s/dia/2025-12-26 -> Auto preencher (triagem) -> Salvar fechamento" -ForegroundColor Yellow

} catch {
  try { WriteUtf8NoBom $rep ($log -join "`n") } catch {}
  throw
}