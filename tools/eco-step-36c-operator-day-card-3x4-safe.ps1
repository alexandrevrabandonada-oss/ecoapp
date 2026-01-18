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
function LowerCamel([string]$s){
  if(!$s){ return $s }
  if($s.Length -eq 1){ return $s.ToLower() }
  return $s.Substring(0,1).ToLower() + $s.Substring(1)
}
function DetectPickupModelAndFields([string[]]$lines){
  $models = @()
  for($i=0; $i -lt $lines.Count; $i++){
    if($lines[$i] -match "^\s*model\s+([A-Za-z_][A-Za-z0-9_]*)\s*\{"){
      $name = $Matches[1]
      if($name -match "Pickup"){ $models += $name }
    }
  }
  $model = $null
  foreach($m in $models){ if($m -match "Request"){ $model = $m; break } }
  if(!$model -and $models.Count -gt 0){ $model = $models[0] }
  if(!$model){ $model = "PickupRequest" }

  $start = -1; $end = -1
  for($i=0; $i -lt $lines.Count; $i++){
    if($lines[$i] -match "^\s*model\s+$model\s*\{"){ $start = $i; break }
  }
  if($start -ge 0){
    for($j=$start+1; $j -lt $lines.Count; $j++){
      if($lines[$j] -match "^\s*\}\s*$"){ $end = $j; break }
    }
  }

  $routeField = "routeDay"
  $statusField = "status"
  if($start -ge 0 -and $end -gt $start){
    $found = @{}
    for($k=$start; $k -le $end; $k++){
      $t = $lines[$k].Trim()
      if($t -match "^([A-Za-z_][A-Za-z0-9_]*)\b"){ $found[$Matches[1]] = $true }
    }
    foreach($c in @("routeDay","routeDate","day","rotaDia","date")){
      if($found.ContainsKey($c)){ $routeField = $c; break }
    }
    foreach($c in @("status","state","pickupStatus")){
      if($found.ContainsKey($c)){ $statusField = $c; break }
    }
  }

  return @{
    Model = $model
    Delegate = (LowerCamel $model)
    RouteField = $routeField
    StatusField = $statusField
  }
}

$rep = NewReport "eco-step-36c-operator-day-card-3x4-safe"
$log = @()
$log += "# ECO — STEP 36c — Card do dia (PNG 3:4) + Baixar/Compartilhar no /operador/triagem (SAFE)"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

# defaults
$pickupDelegate = "pickupRequest"
$routeField = "routeDay"
$statusField = "status"

$schema = "prisma/schema.prisma"
if(!(Test-Path -LiteralPath $schema)){ $schema = FindFirst "." "\\prisma\\schema\.prisma$" }
if($schema -and (Test-Path -LiteralPath $schema)){
  $det = DetectPickupModelAndFields (Get-Content -LiteralPath $schema)
  $pickupDelegate = $det.Delegate
  $routeField = $det.RouteField
  $statusField = $det.StatusField
}

$log += "## DIAG"
$log += ("schema: {0}" -f ($schema ? $schema : "(não achei)"))
$log += ("pickup delegate: {0}" -f $pickupDelegate)
$log += ("route field   : {0}" -f $routeField)
$log += ("status field  : {0}" -f $statusField)
$log += ""

$log += "## PATCH"

# 1) API /api/share/route-day-card
$routeDir = "src/app/api/share/route-day-card"
$routeFile = Join-Path $routeDir "route.ts"
EnsureDir $routeDir
$bkR = BackupFile $routeFile

$ts = @"
import { NextRequest } from "next/server";
import { ImageResponse } from "next/og";
import { PrismaClient } from "@prisma/client";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };
const prisma = globalForPrisma.prisma ?? new PrismaClient();
if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = prisma;

function pickSize(fmt: string | null) {
  if (fmt === "1x1") return { width: 1080, height: 1080 };
  return { width: 1080, height: 1350 }; // 3:4
}

function safeStr(v: any) {
  return (v ?? "").toString();
}

export async function GET(req: NextRequest) {
  const u = new URL(req.url);
  const day = (u.searchParams.get("day") || "").trim();
  const format = (u.searchParams.get("format") || "3x4").trim();

  if (!day) return new Response("missing day", { status: 400 });

  const MODEL = "__PICKUP_DELEGATE__";
  const ROUTE_FIELD = "__ROUTE_FIELD__";
  const STATUS_FIELD = "__STATUS_FIELD__";

  const where: any = {};
  where[ROUTE_FIELD] = day;

  const select: any = {};
  select[STATUS_FIELD] = true;

  const items: any[] = await (prisma as any)[MODEL].findMany({ where, select });

  const stats: any = { total: items.length, NEW: 0, IN_ROUTE: 0, DONE: 0, CANCELED: 0, OTHER: 0 };
  for (const it of items) {
    const st = safeStr(it?.[STATUS_FIELD]) || "NEW";
    if (st === "NEW" || st === "IN_ROUTE" || st === "DONE" || st === "CANCELED") stats[st] = (stats[st] || 0) + 1;
    else stats.OTHER = (stats.OTHER || 0) + 1;
  }

  const { width, height } = pickSize(format);

  return new ImageResponse(
    (
      <div style={{
        width:"100%", height:"100%", display:"flex", flexDirection:"column",
        background:"#0b0b0b", color:"#fff", padding:56,
        fontFamily:"system-ui, -apple-system, Segoe UI, Roboto, Arial",
        justifyContent:"space-between"
      }}>
        <div style={{ display:"flex", flexDirection:"column", gap:12 }}>
          <div style={{ display:"flex", alignItems:"center", gap:14 }}>
            <div style={{ width:56, height:56, borderRadius:999, border:"6px solid #22c55e", boxSizing:"border-box" }} />
            <div style={{ display:"flex", flexDirection:"column" }}>
              <div style={{ fontSize:42, fontWeight:900, letterSpacing:1 }}>ECO</div>
              <div style={{ fontSize:20, opacity:0.85 }}>Recibo e lei • Cuidado e coletivo</div>
            </div>
          </div>
          <div style={{ marginTop:20, fontSize:34, fontWeight:900 }}>Fechamento do dia</div>
          <div style={{ fontSize:26, opacity:0.9 }}>{day}</div>
        </div>

        <div style={{
          display:"flex", flexDirection:"column", gap:16,
          background:"rgba(255,255,255,0.06)",
          border:"1px solid rgba(255,255,255,0.12)",
          borderRadius:18, padding:26
        }}>
          <div style={{ fontSize:30, fontWeight:900 }}>Resumo</div>
          <div style={{ display:"flex", flexWrap:"wrap", gap:14, fontSize:24 }}>
            <div style={{ padding:"10px 14px", background:"rgba(34,197,94,0.15)", borderRadius:14 }}>
              Total: <b>{stats.total}</b>
            </div>
            <div style={{ padding:"10px 14px", background:"rgba(255,255,255,0.08)", borderRadius:14 }}>
              NEW: <b>{stats.NEW}</b>
            </div>
            <div style={{ padding:"10px 14px", background:"rgba(255,255,255,0.08)", borderRadius:14 }}>
              IN_ROUTE: <b>{stats.IN_ROUTE}</b>
            </div>
            <div style={{ padding:"10px 14px", background:"rgba(34,197,94,0.22)", borderRadius:14 }}>
              DONE: <b>{stats.DONE}</b>
            </div>
            <div style={{ padding:"10px 14px", background:"rgba(239,68,68,0.22)", borderRadius:14 }}>
              CANCELED: <b>{stats.CANCELED}</b>
            </div>
            {stats.OTHER ? (
              <div style={{ padding:"10px 14px", background:"rgba(255,255,255,0.08)", borderRadius:14 }}>
                OUTROS: <b>{stats.OTHER}</b>
              </div>
            ) : null}
          </div>
        </div>

        <div style={{ fontSize:18, opacity:0.8 }}>
          #ECO — Escutar • Cuidar • Organizar
        </div>
      </div>
    ),
    { width, height }
  );
}
"@

$ts = $ts.Replace("__PICKUP_DELEGATE__", $pickupDelegate)
$ts = $ts.Replace("__ROUTE_FIELD__", $routeField)
$ts = $ts.Replace("__STATUS_FIELD__", $statusField)

WriteUtf8NoBom $routeFile $ts
$log += ("- OK: API /api/share/route-day-card criada. Backup: {0}" -f ($bkR ? $bkR : "(nenhum)"))

# 2) Patch UI /operador/triagem (tenta OperatorTriageV2, senão qualquer tsx da pasta)
$tri = "src/app/operador/triagem/OperatorTriageV2.tsx"
if(!(Test-Path -LiteralPath $tri)){
  $tri = FindFirst "." "\\src\\app\\operador\\triagem\\OperatorTriageV2\.tsx$"
}
if(!(Test-Path -LiteralPath $tri)){
  $tri = FindFirst "." "\\src\\app\\operador\\triagem\\.*\.tsx$"
}
if(!(Test-Path -LiteralPath $tri)){
  $log += "- WARN: não achei TSX em src/app/operador/triagem para inserir botões (API ficou pronta)."
  WriteUtf8NoBom $rep ($log -join "`n")
  Write-Host ("✅ STEP 36c aplicado (somente API). Report -> {0}" -f $rep) -ForegroundColor Green
  exit 0
}

$bkT = BackupFile $tri
$txtT = Get-Content -LiteralPath $tri -Raw
$log += ("- UI alvo: {0}" -f $tri)
$log += ("- Backup UI: {0}" -f ($bkT ? $bkT : "(nenhum)"))

# escolher variável do dia (evita assumir errado)
$dayVar = "routeDay"
if($txtT -notmatch "\brouteDay\b"){
  if($txtT -match "\brouteDate\b"){ $dayVar = "routeDate" }
  elseif($txtT -match "\brotaDia\b"){ $dayVar = "rotaDia" }
  elseif($txtT -match "\bday\b"){ $dayVar = "day" }
}

if($txtT -notmatch "ECO_STEP36C_DAY_CARD_HELPERS_START"){
  $helper = @"
  /* ECO_STEP36C_DAY_CARD_HELPERS_START */
  type ShareNav = Navigator & { share?: (data: ShareData) => Promise<void>; canShare?: (data: ShareData) => boolean };

  const __ecoDayStr = () => String($dayVar ?? "").trim();

  const ecoDayCardUrl = (fmt: "3x4" | "1x1" = "3x4") => {
    const d = encodeURIComponent(__ecoDayStr());
    return "/api/share/route-day-card?day=" + d + "&format=" + fmt;
  };

  const onDayCard3x4 = () => {
    const d = __ecoDayStr();
    if(!d) return;
    window.open(ecoDayCardUrl("3x4"), "_blank", "noopener,noreferrer");
  };

  const onShareDayCard3x4 = async () => {
    const d = __ecoDayStr();
    if(!d) return;

    const card = ecoDayCardUrl("3x4");
    let res: Response | null = null;
    try { res = await fetch(card, { cache: "no-store" }); } catch { res = null; }

    if(!res || !res.ok){
      window.open(card, "_blank", "noopener,noreferrer");
      return;
    }

    const blob = await res.blob();
    const fileName = "eco-fechamento-" + d + "-3x4.png";
    const file = new File([blob], fileName, { type: "image/png" });

    const nav = navigator as ShareNav;
    const data: ShareData = { title: "ECO — Fechamento do dia", text: "ECO — Fechamento do dia " + d, files: [file] };

    if(nav.share && (!nav.canShare || nav.canShare(data))){
      await nav.share(data);
      return;
    }

    const a = document.createElement("a");
    const obj = URL.createObjectURL(blob);
    a.href = obj;
    a.download = fileName;
    document.body.appendChild(a);
    a.click();
    a.remove();
    setTimeout(() => URL.revokeObjectURL(obj), 1200);
  };
  /* ECO_STEP36C_DAY_CARD_HELPERS_END */
"@

  $pos = $txtT.IndexOf("ECO_STEP35_DAY_CLOSE_END")
  if($pos -ge 0){
    $nl = $txtT.IndexOf("`n", $pos)
    if($nl -gt 0){ $txtT = $txtT.Insert($nl+1, "`n" + $helper + "`n") }
    else { $txtT = $helper + "`n" + $txtT }
    $log += "- OK: helpers inseridos após STEP35."
  } else {
    # depois de 'use client' se existir
    $uc = $txtT.IndexOf("'use client'")
    if($uc -ge 0){
      $nl2 = $txtT.IndexOf("`n", $uc)
      if($nl2 -gt 0){ $txtT = $txtT.Insert($nl2+1, "`n" + $helper + "`n") }
      else { $txtT = $helper + "`n" + $txtT }
      $log += "- OK: helpers inseridos após 'use client'."
    } else {
      $txtT = $helper + "`n" + $txtT
      $log += "- OK: helpers inseridos no topo (fallback)."
    }
  }
} else {
  $log += "- INFO: helpers já existem (skip)."
}

if($txtT -notmatch "ECO_STEP36C_DAY_CARD_UI_START"){
  $needle = "onClick={onWaDailyBulletin}"
  $idx = $txtT.IndexOf($needle)
  if($idx -ge 0){
    $btnEnd = $txtT.IndexOf("</button>", $idx)
    if($btnEnd -gt 0){
      $insertPos = $btnEnd + 9
      $ui = @"
          {/* ECO_STEP36C_DAY_CARD_UI_START */}
          <button type="button" onClick={onDayCard3x4} style={{ padding: '6px 10px' }}>Baixar card do dia (3:4)</button>
          <button type="button" onClick={onShareDayCard3x4} style={{ padding: '6px 10px' }}>Compartilhar card (3:4)</button>
          {/* ECO_STEP36C_DAY_CARD_UI_END */}
"@
      $txtT = $txtT.Insert($insertPos, "`n" + $ui)
      $log += "- OK: botões inseridos ao lado do WhatsApp do boletim."
    } else {
      $log += "- WARN: âncora achada, mas não achei </button> (skip UI)."
    }
  } else {
    $log += "- WARN: não achei onWaDailyBulletin na UI (skip botões)."
  }
} else {
  $log += "- INFO: botões já existem (skip)."
}

WriteUtf8NoBom $tri $txtT
$log += "- OK: UI escrita."

$log += ""
$log += "## VERIFY"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1"
$log += "3) Teste manual:"
$log += "   - /api/share/route-day-card?day=YYYY-MM-DD&format=3x4 (abre PNG)"
$log += "   - /operador/triagem -> Fechamento do dia -> Baixar/Compartilhar card (3:4)"

WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 36c aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) Teste /operador/triagem (Baixar/Compartilhar card do dia)" -ForegroundColor Yellow