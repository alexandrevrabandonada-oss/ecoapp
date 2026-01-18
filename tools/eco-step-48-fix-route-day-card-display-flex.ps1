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
  $safe = ($path -replace '[\\/:*?"<>|]','_')
  $dst = "tools/_patch_backup/$ts-$safe"
  Copy-Item -Force -LiteralPath $path $dst
  return $dst
}
function NewReport([string]$name){
  EnsureDir "reports"
  $ts = Get-Date -Format "yyyyMMdd-HHmmss"
  return "reports/$ts-$name.md"
}

$rep = NewReport "eco-step-48-fix-route-day-card-display-flex"
$log = @()
$log += "# ECO — STEP 48 — Fix route-day-card (ImageResponse display:flex)"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

try {
  $route = "src/app/api/share/route-day-card/route.ts"
  if(!(Test-Path -LiteralPath "src/app/api/share/route-day-card")){
    throw "GUARD: nao achei src/app/api/share/route-day-card"
  }
  EnsureDir (Split-Path -Parent $route)
  $bk = BackupFile $route
  $log += "## PATCH — route-day-card"
  $log += ("Arquivo: {0}" -f $route)
  $log += ("Backup : {0}" -f ($(if($bk){$bk}else{"(novo)"})))
  $log += ""

  $tsLines = @()
  $tsLines += 'import React from "react";'
  $tsLines += 'import { ImageResponse } from "next/og";'
  $tsLines += ''
  $tsLines += 'export const runtime = "edge";'
  $tsLines += ''
  $tsLines += 'function safeDay(input: string | null): string {'
  $tsLines += '  const s = String(input || "").trim();'
  $tsLines += '  if (/^\d{4}-\d{2}-\d{2}$/.test(s)) return s;'
  $tsLines += '  const d = new Date();'
  $tsLines += '  const yyyy = d.getUTCFullYear();'
  $tsLines += '  const mm = String(d.getUTCMonth() + 1).padStart(2, "0");'
  $tsLines += '  const dd = String(d.getUTCDate()).padStart(2, "0");'
  $tsLines += '  return `${yyyy}-${mm}-${dd}`;'
  $tsLines += '}'
  $tsLines += ''
  $tsLines += 'function sizeFor(format: string | null) {'
  $tsLines += '  const f = String(format || "").toLowerCase();'
  $tsLines += '  if (f === "1x1") return { w: 1080, h: 1080, label: "1:1" as const };'
  $tsLines += '  return { w: 1080, h: 1350, label: "3:4" as const };'
  $tsLines += '}'
  $tsLines += ''
  $tsLines += 'export async function GET(req: Request) {'
  $tsLines += '  try {'
  $tsLines += '    const { searchParams } = new URL(req.url);'
  $tsLines += '    const day = safeDay(searchParams.get("day"));'
  $tsLines += '    const fmt = sizeFor(searchParams.get("format"));'
  $tsLines += ''
  $tsLines += '    const bg = "#0b0b0b";'
  $tsLines += '    const yellow = "#ffd400";'
  $tsLines += '    const red = "#ff3b30";'
  $tsLines += '    const off = "#f5f5f5";'
  $tsLines += '    const gray = "#bdbdbd";'
  $tsLines += ''
  $tsLines += '    const rootStyle: React.CSSProperties = {'
  $tsLines += '      width: "100%",'
  $tsLines += '      height: "100%",'
  $tsLines += '      display: "flex",'
  $tsLines += '      flexDirection: "column",'
  $tsLines += '      background: bg,'
  $tsLines += '      color: off,'
  $tsLines += '      padding: 64,'
  $tsLines += '      boxSizing: "border-box",'
  $tsLines += '      fontFamily: "system-ui, -apple-system, Segoe UI, Roboto, Ubuntu, Cantarell, Helvetica Neue, Arial",'
  $tsLines += '      border: `10px solid ${yellow}`,'
  $tsLines += '    };'
  $tsLines += ''
  $tsLines += '    const pill = (text: string) =>'
  $tsLines += '      React.createElement("div", {'
  $tsLines += '        style: { display: "flex", padding: "10px 14px", borderRadius: 999, border: `2px solid ${gray}`, fontSize: 20 },'
  $tsLines += '      }, text);'
  $tsLines += ''
  $tsLines += '    const titleLine = React.createElement('
  $tsLines += '      "div",'
  $tsLines += '      { style: { display: "flex", alignItems: "baseline", gap: 10, fontSize: 64, fontWeight: 900, lineHeight: 1.0 } },'
  $tsLines += '      "FECHAMENTO",'
  $tsLines += '      React.createElement("span", { style: { color: yellow } }, " DO DIA")'
  $tsLines += '    );'
  $tsLines += ''
  $tsLines += '    const headerLeft = React.createElement('
  $tsLines += '      "div",'
  $tsLines += '      { style: { display: "flex", flexDirection: "column", gap: 10 } },'
  $tsLines += '      React.createElement("div", { style: { display: "flex", fontSize: 22, letterSpacing: 2, color: gray } }, "#ECO — Escutar • Cuidar • Organizar"),'
  $tsLines += '      titleLine,'
  $tsLines += '      React.createElement("div", { style: { display: "flex", fontSize: 42, fontWeight: 800, color: off } }, day)'
  $tsLines += '    );'
  $tsLines += ''
  $tsLines += '    const headerBadge = React.createElement('
  $tsLines += '      "div",'
  $tsLines += '      { style: { display: "flex", width: 120, height: 120, borderRadius: 999, border: `8px solid ${yellow}`, alignItems: "center", justifyContent: "center", fontSize: 34, fontWeight: 900, color: yellow } },'
  $tsLines += '      fmt.label'
  $tsLines += '    );'
  $tsLines += ''
  $tsLines += '    const header = React.createElement('
  $tsLines += '      "div",'
  $tsLines += '      { style: { display: "flex", justifyContent: "space-between", alignItems: "flex-start" } },'
  $tsLines += '      headerLeft,'
  $tsLines += '      headerBadge'
  $tsLines += '    );'
  $tsLines += ''
  $tsLines += '    const pills = React.createElement('
  $tsLines += '      "div",'
  $tsLines += '      { style: { display: "flex", gap: 14, flexWrap: "wrap" } },'
  $tsLines += '      pill("Recibo é lei"),'
  $tsLines += '      pill("Cuidado é coletivo"),'
  $tsLines += '      pill("Trabalho digno no centro")'
  $tsLines += '    );'
  $tsLines += ''
  $tsLines += '    const footer = React.createElement('
  $tsLines += '      "div",'
  $tsLines += '      { style: { display: "flex", justifyContent: "space-between", alignItems: "flex-end" } },'
  $tsLines += '      React.createElement("div", { style: { display: "flex", fontSize: 22, opacity: 0.9, color: gray } }, `Compartilhe: /s/dia/${day}`),'
  $tsLines += '      React.createElement("div", { style: { display: "flex", fontSize: 18, color: red, opacity: 0.95 } }, "Sem greenwashing • Abandono × Cuidado")'
  $tsLines += '    );'
  $tsLines += ''
  $tsLines += '    const bottom = React.createElement('
  $tsLines += '      "div",'
  $tsLines += '      { style: { display: "flex", flex: 1, flexDirection: "column", justifyContent: "flex-end", gap: 18 } },'
  $tsLines += '      pills,'
  $tsLines += '      footer'
  $tsLines += '    );'
  $tsLines += ''
  $tsLines += '    const tree = React.createElement("div", { style: rootStyle }, header, bottom);'
  $tsLines += ''
  $tsLines += '    return new ImageResponse(tree, {'
  $tsLines += '      width: fmt.w,'
  $tsLines += '      height: fmt.h,'
  $tsLines += '      headers: { "cache-control": "public, max-age=0, s-maxage=3600, stale-while-revalidate=86400" },'
  $tsLines += '    });'
  $tsLines += '  } catch (err: any) {'
  $tsLines += '    return new Response("route-day-card error: " + (err?.message || "unknown"), { status: 500 });'
  $tsLines += '  }'
  $tsLines += '}'

  $routeTxt = $tsLines -join "`n"
  WriteUtf8NoBom $route $routeTxt
  $log += "- OK: route-day-card reescrito com display:flex onde precisa."
  $log += ""

  WriteUtf8NoBom $rep ($log -join "`n")
  Write-Host ("✅ STEP 48 aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
  Write-Host "VERIFY:" -ForegroundColor Yellow
  Write-Host "1) (se dev rodando) CTRL+C e npm run dev" -ForegroundColor Yellow
  Write-Host "2) GET /api/share/route-day-card?day=2025-12-26&format=3x4 (deve 200)" -ForegroundColor Yellow
  Write-Host "3) GET /api/share/route-day-card?day=2025-12-26&format=1x1 (deve 200)" -ForegroundColor Yellow
} catch {
  try { WriteUtf8NoBom $rep ($log -join "`n") } catch {}
  throw
}