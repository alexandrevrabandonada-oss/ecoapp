$ErrorActionPreference = "Stop"

function EnsureDir([string]$p){
  if($p -and !(Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null }
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
function FindFirst([string]$root, [string]$pattern){
  if(!(Test-Path -LiteralPath $root)){ return $null }
  $f = Get-ChildItem -Recurse -File -Path $root -ErrorAction SilentlyContinue | Where-Object { $_.FullName -match $pattern } | Select-Object -First 1
  if($f){ return $f.FullName }
  return $null
}

# 1) FIX /s/dia/[day]/page.tsx (Next 16: params/headers async)
$page = "src/app/s/dia/[day]/page.tsx"
if(!(Test-Path -LiteralPath $page)){ $page = FindFirst "." "\\src\\app\\s\\dia\\\[day\]\\page\.tsx$" }
if(!(Test-Path -LiteralPath $page)){ throw "Não achei src/app/s/dia/[day]/page.tsx" }
$null = BackupFile $page

$pageTxt = @(
  'import type { Metadata } from "next";'
  'import { headers } from "next/headers";'
  'import DayShareClient from "./DayShareClient";'
  ''
  'function safeDay(input: string): string {'
  '  const s = String(input || "").trim();'
  '  if (s.length === 10 && /^[0-9-]+$/.test(s)) return s;'
  '  return "2025-01-01";'
  '}'
  ''
  'async function originFromHeaders() {'
  '  const h = await headers();'
  '  const proto = h.get("x-forwarded-proto") || "http";'
  '  const host = h.get("x-forwarded-host") || h.get("host") || "localhost:3000";'
  '  return `${proto}://${host}`;'
  '}'
  ''
  'export async function generateMetadata('
  '  { params }: { params: Promise<{ day: string }> }'
  '): Promise<Metadata> {'
  '  const p = await params;'
  '  const day = safeDay(p.day);'
  ''
  '  const origin = await originFromHeaders();'
  '  const og3x4 = `${origin}/api/share/route-day-card?day=${encodeURIComponent(day)}&format=3x4`;'
  ''
  '  return {'
  '    title: `ECO — Fechamento do dia ${day}`,'
  '    description: `Fechamento do dia ${day} — ECO (Escutar • Cuidar • Organizar)`,'
  '    openGraph: {'
  '      title: `ECO — Fechamento do dia ${day}`,'
  '      description: `Fechamento do dia ${day} — ECO`,'
  '      images: [{ url: og3x4, width: 1080, height: 1350 }],'
  '    },'
  '    twitter: {'
  '      card: "summary_large_image",'
  '      title: `ECO — Fechamento do dia ${day}`,'
  '      description: `Fechamento do dia ${day} — ECO`,'
  '      images: [og3x4],'
  '    },'
  '  };'
  '}'
  ''
  'export default async function Page('
  '  { params }: { params: Promise<{ day: string }> }'
  ') {'
  '  const p = await params;'
  '  const day = safeDay(p.day);'
  ''
  '  const img3x4 = `/api/share/route-day-card?day=${encodeURIComponent(day)}&format=3x4`;'
  '  const img1x1 = `/api/share/route-day-card?day=${encodeURIComponent(day)}&format=1x1`;'
  ''
  '  return ('
  '    <main style={{ maxWidth: 980, margin: "0 auto", padding: 18 }}>'
  '      <h1 style={{ fontSize: 22, fontWeight: 800 }}>ECO — Fechamento do dia</h1>'
  '      <p style={{ opacity: 0.85, marginTop: 6 }}>'
  '        Dia: <strong>{day}</strong>'
  '      </p>'
  ''
  '      <DayShareClient day={day} />'
  ''
  '      <div style={{ display: "flex", flexWrap: "wrap", gap: 18, marginTop: 18 }}>'
  '        <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>'
  '          <div style={{ fontWeight: 700 }}>Preview 3:4</div>'
  '          <img src={img3x4} alt={`Card 3:4 — ${day}`} width={360} height={450} style={{ borderRadius: 14, border: "1px solid #222" }} />'
  '        </div>'
  ''
  '        <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>'
  '          <div style={{ fontWeight: 700 }}>Preview 1:1</div>'
  '          <img src={img1x1} alt={`Card 1:1 — ${day}`} width={360} height={360} style={{ borderRadius: 14, border: "1px solid #222" }} />'
  '        </div>'
  '      </div>'
  ''
  '      <p style={{ marginTop: 18, fontSize: 12, opacity: 0.75 }}>'
  '        Recibo é lei. Cuidado é coletivo. Trabalho digno é o centro. — #ECO • Escutar • Cuidar • Organizar'
  '      </p>'
  '    </main>'
  '  );'
  '}'
) -join "`n"

WriteUtf8NoBom $page $pageTxt
Write-Host "OK: /s/dia/[day]/page.tsx corrigido" -ForegroundColor Green

# 2) FIX triagem: linha /s/dia/ virou regex
$tri = "src/app/operador/triagem/OperatorTriageV2.tsx"
if(!(Test-Path -LiteralPath $tri)){ $tri = FindFirst "." "\\src\\app\\operador\\triagem\\OperatorTriageV2\.tsx$" }
if(Test-Path -LiteralPath $tri){
  $null = BackupFile $tri
  $txtT = Get-Content -LiteralPath $tri -Raw
  $broken = "const ecoDayPublicSharePath = () => /s/dia/;"
  if($txtT.Contains($broken)){
    $txtT = $txtT.Replace($broken, "const ecoDayPublicSharePath = () => `/s/dia/${encodeURIComponent(routeDay)}`;")
    WriteUtf8NoBom $tri $txtT
    Write-Host "OK: triagem corrigida (/s/dia/ deixou de ser regex)" -ForegroundColor Green
  } else {
    Write-Host "INFO: não achei a linha exata quebrada na triagem (nada a fazer)" -ForegroundColor Yellow
  }
} else {
  Write-Host "WARN: OperatorTriageV2.tsx não encontrado (skip triagem)" -ForegroundColor Yellow
}

Write-Host "✅ HOTFIX 38f finalizado" -ForegroundColor Green