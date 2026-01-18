$ErrorActionPreference = "Stop"

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
function FindFirst([string]$root, [string]$pattern){
  if(!(Test-Path -LiteralPath $root)){ return $null }
  $f = Get-ChildItem -Recurse -File -Path $root -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -match $pattern } |
    Select-Object -First 1
  if($f){ return $f.FullName }
  return $null
}

function DetectModelField([string[]]$lines, [string]$modelName, [string[]]$candidates){
  $start = -1
  for($i=0; $i -lt $lines.Count; $i++){
    if($lines[$i] -match "^\s*model\s+$modelName\s*\{"){ $start = $i; break }
  }
  if($start -lt 0){ return $null }
  $end = -1
  for($j=$start+1; $j -lt $lines.Count; $j++){
    if($lines[$j] -match "^\s*\}\s*$"){ $end = $j; break }
  }
  if($end -lt 0){ return $null }

  $found = @{}
  for($k=$start; $k -le $end; $k++){
    $line = $lines[$k].Trim()
    if($line -match "^\s*([A-Za-z_][A-Za-z0-9_]*)\b"){
      $fname = $Matches[1]
      $found[$fname] = $true
    }
  }
  foreach($c in $candidates){
    if($found.ContainsKey($c)){ return $c }
  }
  return $null
}

$rep = NewReport "eco-step-27-receipt-card-share-endpoint-3x4"
$log = @()
$log += "# ECO — STEP 27 — Card PNG do Recibo (3:4) + API pública sanitizada"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

# --- Detect fields in prisma/schema.prisma
$schema = "prisma/schema.prisma"
if(!(Test-Path -LiteralPath $schema)){ $schema = FindFirst "." "\\prisma\\schema\.prisma$" }

$receiptCodeField = "code"
$receiptPublicField = $null
$receiptDateField = $null

if($schema -and (Test-Path -LiteralPath $schema)){
  $lines = Get-Content -LiteralPath $schema
  $receiptCodeField = (DetectModelField $lines "Receipt" @("code","shareCode","publicCode","slug","id"))
  if(!$receiptCodeField){ $receiptCodeField = "id" }

  $receiptPublicField = (DetectModelField $lines "Receipt" @("public","isPublic"))
  $receiptDateField = (DetectModelField $lines "Receipt" @("createdAt","issuedAt","date","updatedAt"))
  if(!$receiptDateField){ $receiptDateField = "createdAt" } # fallback (se não existir, vamos tentar mesmo assim)
}

$log += "## DIAG"
$log += ("schema: {0}" -f ($schema ? $schema : "(não achei)"))
$log += ("Receipt code field  : {0}" -f $receiptCodeField)
$log += ("Receipt public field: {0}" -f ($receiptPublicField ? $receiptPublicField : "(nenhum)"))
$log += ("Receipt date field  : {0}" -f $receiptDateField)
$log += ""

# --- (1) Node route: /api/receipts/public?code=...
$pubRoute = "src/app/api/receipts/public/route.ts"
if(!(Test-Path -LiteralPath (Split-Path -Parent $pubRoute))){
  EnsureDir (Split-Path -Parent $pubRoute)
}
$bkPub = BackupFile $pubRoute

$log += "## PATCH"
$log += ("- Node route: {0}" -f $pubRoute)
$log += ("  Backup: {0}" -f ($bkPub ? $bkPub : "(novo)"))

$ts = New-Object System.Collections.Generic.List[string]
$ts.Add('import { NextResponse } from "next/server";')
$ts.Add('import { PrismaClient } from "@prisma/client";')
$ts.Add('')
$ts.Add('export const runtime = "nodejs";')
$ts.Add('')
$ts.Add('const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };')
$ts.Add('const prisma = globalForPrisma.prisma ?? new PrismaClient();')
$ts.Add('if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = prisma;')
$ts.Add('')
$ts.Add('const CODE_FIELD = "' + $receiptCodeField + '";')

if($receiptPublicField){
  $ts.Add('const PUBLIC_FIELD = "' + $receiptPublicField + '";')
} else {
  $ts.Add('const PUBLIC_FIELD = null as unknown as string;')
}
$ts.Add('const DATE_FIELD = "' + $receiptDateField + '";')
$ts.Add('')
$ts.Add('export async function GET(req: Request) {')
$ts.Add('  try {')
$ts.Add('    const u = new URL(req.url);')
$ts.Add('    const code = (u.searchParams.get("code") ?? "").trim();')
$ts.Add('    if (!code) return NextResponse.json({ ok: false, error: "missing_code" }, { status: 400 });')
$ts.Add('')
$ts.Add('    const where: any = {};')
$ts.Add('    where[CODE_FIELD] = code;')
$ts.Add('    if (PUBLIC_FIELD) where[PUBLIC_FIELD] = true;')
$ts.Add('')
$ts.Add('    const select: any = {};')
$ts.Add('    select[CODE_FIELD] = true;')
$ts.Add('    select[DATE_FIELD] = true;')
$ts.Add('    if (PUBLIC_FIELD) select[PUBLIC_FIELD] = true;')
$ts.Add('')
$ts.Add('    const r: any = await (prisma as any).receipt.findFirst({ where, select });')
$ts.Add('    if (!r) return NextResponse.json({ ok: false, error: "not_found" }, { status: 404 });')
$ts.Add('')
$ts.Add('    // se não existe campo public, este endpoint fica "sempre público".')
$ts.Add('    const isPublic = PUBLIC_FIELD ? Boolean(r[PUBLIC_FIELD]) : true;')
$ts.Add('    if (!isPublic) return NextResponse.json({ ok: false, error: "not_public" }, { status: 404 });')
$ts.Add('')
$ts.Add('    return NextResponse.json({')
$ts.Add('      ok: true,')
$ts.Add('      receipt: {')
$ts.Add('        code: String(r[CODE_FIELD] ?? code),')
$ts.Add('        date: r[DATE_FIELD] ?? null,')
$ts.Add('        public: isPublic,')
$ts.Add('      },')
$ts.Add('    });')
$ts.Add('  } catch (e: any) {')
$ts.Add('    return NextResponse.json({ ok: false, error: "server_error", detail: String(e?.message ?? e) }, { status: 500 });')
$ts.Add('  }')
$ts.Add('}')
$tsText = ($ts.ToArray() -join "`n")

WriteUtf8NoBom $pubRoute $tsText
$log += "  - OK: route escrita."

# --- (2) Edge route: /api/share/receipt-card?code=...&format=3x4|1x1
$cardRoute = "src/app/api/share/receipt-card/route.ts"
if(!(Test-Path -LiteralPath (Split-Path -Parent $cardRoute))){
  EnsureDir (Split-Path -Parent $cardRoute)
}
$bkCard = BackupFile $cardRoute
$log += ""
$log += ("- Edge route: {0}" -f $cardRoute)
$log += ("  Backup: {0}" -f ($bkCard ? $bkCard : "(novo)"))

$ts2 = New-Object System.Collections.Generic.List[string]
$ts2.Add('import { ImageResponse } from "next/og";')
$ts2.Add('')
$ts2.Add('export const runtime = "edge";')
$ts2.Add('')
$ts2.Add('function fmtDatePtBR(input: any): string {')
$ts2.Add('  try {')
$ts2.Add('    if (!input) return "";')
$ts2.Add('    const d = new Date(input);')
$ts2.Add('    if (Number.isNaN(d.getTime())) return "";')
$ts2.Add('    return d.toLocaleDateString("pt-BR");')
$ts2.Add('  } catch {')
$ts2.Add('    return "";')
$ts2.Add('  }')
$ts2.Add('}')
$ts2.Add('')
$ts2.Add('export async function GET(req: Request) {')
$ts2.Add('  const u = new URL(req.url);')
$ts2.Add('  const code = (u.searchParams.get("code") ?? "").trim();')
$ts2.Add('  if (!code) return new Response("missing code", { status: 400 });')
$ts2.Add('  const format = (u.searchParams.get("format") ?? "3x4").toLowerCase();')
$ts2.Add('  const width = 1080;')
$ts2.Add('  const height = format === "1x1" ? 1080 : 1350;')
$ts2.Add('')
$ts2.Add('  const api = new URL("/api/receipts/public", u);')
$ts2.Add('  api.searchParams.set("code", code);')
$ts2.Add('  const r = await fetch(api.toString(), { cache: "no-store" });')
$ts2.Add('  if (!r.ok) return new Response("not found", { status: r.status });')
$ts2.Add('  const j: any = await r.json();')
$ts2.Add('  const c = String(j?.receipt?.code ?? code);')
$ts2.Add('  const d = fmtDatePtBR(j?.receipt?.date);')
$ts2.Add('')
$ts2.Add('  const bg = "#0B0F0E";') # preto esverdeado
$ts2.Add('  const ink = "#F3F4F6";') # off-white
$ts2.Add('  const green = "#22C55E";')
$ts2.Add('  const yellow = "#FACC15";')
$ts2.Add('')
$ts2.Add('  return new ImageResponse((')
$ts2.Add('    <div style={{ width: "100%", height: "100%", background: bg, display: "flex", flexDirection: "column", padding: 72, color: ink, fontFamily: "ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Arial" }}>')
$ts2.Add('      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>')
$ts2.Add('        <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>')
$ts2.Add('          <div style={{ fontSize: 28, letterSpacing: 2, color: green, fontWeight: 700 }}>RECIBO ECO</div>')
$ts2.Add('          <div style={{ fontSize: 64, lineHeight: 1.05, fontWeight: 900 }}>BORA DE RECIBO?</div>')
$ts2.Add('        </div>')
$ts2.Add('        <div style={{ width: 140, height: 140, borderRadius: 999, border: "10px solid " + green, display: "flex", alignItems: "center", justifyContent: "center", boxShadow: "0 0 0 10px rgba(250,204,21,0.25)" }}>')
$ts2.Add('          <div style={{ width: 86, height: 86, borderRadius: 999, border: "8px dashed " + yellow }} />')
$ts2.Add('        </div>')
$ts2.Add('      </div>')
$ts2.Add('')
$ts2.Add('      <div style={{ marginTop: 56, padding: 42, borderRadius: 28, border: "2px solid rgba(34,197,94,0.55)", background: "rgba(255,255,255,0.04)", display: "flex", flexDirection: "column", gap: 14 }}>')
$ts2.Add('        <div style={{ fontSize: 22, letterSpacing: 1.5, opacity: 0.9 }}>CÓDIGO DO RECIBO</div>')
$ts2.Add('        <div style={{ fontSize: 54, fontWeight: 900, letterSpacing: 3 }}>{c}</div>')
$ts2.Add('        {d ? <div style={{ fontSize: 26, opacity: 0.9 }}>Emitido em {d}</div> : null}')
$ts2.Add('      </div>')
$ts2.Add('')
$ts2.Add('      <div style={{ marginTop: "auto", display: "flex", flexDirection: "column", gap: 14 }}>')
$ts2.Add('        <div style={{ height: 2, background: "rgba(243,244,246,0.25)" }} />')
$ts2.Add('        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", fontSize: 22, opacity: 0.95 }}>')
$ts2.Add('          <div style={{ letterSpacing: 1.4 }}>ECO — ESCUTAR • CUIDAR • ORGANIZAR</div>')
$ts2.Add('          <div style={{ color: yellow, fontWeight: 800 }}>#RECIBOÉLEI</div>')
$ts2.Add('        </div>')
$ts2.Add('      </div>')
$ts2.Add('    </div>')
$ts2.Add('  ), { width, height });')
$ts2.Add('}')
$ts2Text = ($ts2.ToArray() -join "`n")

WriteUtf8NoBom $cardRoute $ts2Text
$log += "  - OK: route escrita."

# --- (3) Update ReceiptShareBar: add button "Baixar card 3:4"
$shareComp = "src/components/eco/ReceiptShareBar.tsx"
if(!(Test-Path -LiteralPath $shareComp)){
  $shareComp = FindFirst "." "\\src\\components\\eco\\ReceiptShareBar\.tsx$"
}
if(Test-Path -LiteralPath $shareComp){
  $bkShare = BackupFile $shareComp
  $txt = Get-Content -LiteralPath $shareComp -Raw

  if($txt -match "Baixar card"){
    $log += ""
    $log += ("- INFO: ReceiptShareBar já tem 'Baixar card' (skip). Arquivo: {0}" -f $shareComp)
  } else {
    $log += ""
    $log += ("- Update: {0}" -f $shareComp)
    $log += ("  Backup: {0}" -f $bkShare)

    # inject handler + button (best effort)
    if($txt -notmatch "const onCard"){
      $txt = $txt -replace "(const onWhatsApp = \(\) => \{\s*[\s\S]*?\};\s*)", "`$1`n  const onCard3x4 = () => {`n    if (!url) return;`n    const c = encodeURIComponent(code);`n    const card = '/api/share/receipt-card?code=' + c + '&format=3x4';`n    window.open(card, '_blank', 'noopener,noreferrer');`n  };`n"
    }

    # add button after WhatsApp
    $txt = $txt -replace "(<button type=""button"" onClick=\{onWhatsApp\} className=""underline"">\s*WhatsApp\s*</button>)", "`$1`n      <button type=""button"" onClick={onCard3x4} className=""underline"">Baixar card 3:4</button>"

    WriteUtf8NoBom $shareComp $txt
    $log += "  - OK: botão inserido."
  }
} else {
  $log += ""
  $log += "- WARN: não achei src/components/eco/ReceiptShareBar.tsx (skip update botão)."
}

$log += ""
$log += "## VERIFY"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1"
$log += "3) Pegue um receipt code público e teste:"
$log += "   - GET /api/receipts/public?code=SEU_CODE (200)"
$log += "   - Abrir /api/share/receipt-card?code=SEU_CODE&format=3x4 (gera PNG)"
$log += "   - Em /r/[code], clique 'Baixar card 3:4'"

WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 27 aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) Teste /api/receipts/public?code=... e /api/share/receipt-card?code=...&format=3x4" -ForegroundColor Yellow
Write-Host "4) Teste /r/[code] -> botão 'Baixar card 3:4'" -ForegroundColor Yellow