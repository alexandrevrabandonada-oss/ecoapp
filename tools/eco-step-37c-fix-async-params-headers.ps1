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

$rep = NewReport "eco-step-37c-fix-async-params-headers"
$log = @()
$log += "# ECO — STEP 37c — Fix Next 16 async params + async headers() em /s/dia/[day]"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

$pagePath = "src/app/s/dia/[day]/page.tsx"
if(!(Test-Path -LiteralPath $pagePath)){
  $log += "## ERRO"
  $log += "Não achei: $pagePath"
  WriteUtf8NoBom $rep ($log -join "`n")
  throw "Não achei page.tsx do /s/dia/[day]"
}

$bk = BackupFile $pagePath
$log += "## DIAG"
$log += ("Arquivo: {0}" -f $pagePath)
$log += ("Backup : {0}" -f $bk)
$log += ""

$log += "## PATCH"

$lines = @(
'import type { Metadata } from "next";',
'import { headers } from "next/headers";',
'import DayShareClient from "./DayShareClient";',
'',
'export const dynamic = "force-dynamic";',
'',
'function safeDay(input: unknown): string {',
'  const s = String(input || "").trim();',
'  if (s.length === 10 && /^[0-9-]+$/.test(s)) return s;',
'  return "2025-01-01";',
'}',
'',
'async function originFromHeaders() {',
'  const h = await headers();',
'  const proto = h.get("x-forwarded-proto") || "http";',
'  const host = h.get("x-forwarded-host") || h.get("host") || "localhost:3000";',
'  return `${proto}://${host}`;',
'}',
'',
'export async function generateMetadata({ params }: { params: Promise<{ day: string }> }): Promise<Metadata> {',
'  const p = await params;',
'  const day = safeDay(p?.day);',
'  const origin = await originFromHeaders();',
'  const og3x4 = `${origin}/api/share/route-day-card?day=${encodeURIComponent(day)}&format=3x4`;',
'',
'  return {',
'    title: `ECO — Fechamento do dia ${day}`,',
'    description: `Fechamento do dia ${day} — ECO (Escutar • Cuidar • Organizar)`,',
'    openGraph: {',
'      title: `ECO — Fechamento do dia ${day}`,',
'      description: `Fechamento do dia ${day} — ECO`,',
'      images: [{ url: og3x4, width: 1080, height: 1350 }],',
'    },',
'    twitter: {',
'      card: "summary_large_image",',
'      title: `ECO — Fechamento do dia ${day}`,',
'      description: `Fechamento do dia ${day} — ECO`,',
'      images: [og3x4],',
'    },',
'  };',
'}',
'',
'export default async function Page({ params }: { params: Promise<{ day: string }> }) {',
'  const p = await params;',
'  const day = safeDay(p?.day);',
'  const img3x4 = `/api/share/route-day-card?day=${encodeURIComponent(day)}&format=3x4`;',
'  const img1x1 = `/api/share/route-day-card?day=${encodeURIComponent(day)}&format=1x1`;',
'',
'  return (',
'    <main style={{ maxWidth: 980, margin: "0 auto", padding: 18 }}>',
'      <h1 style={{ fontSize: 22, fontWeight: 800 }}>ECO — Fechamento do dia</h1>',
'      <p style={{ opacity: 0.85, marginTop: 6 }}>',
'        Dia: <strong>{day}</strong>',
'      </p>',
'',
'      <DayShareClient day={day} />',
'',
'      <div style={{ display: "flex", flexWrap: "wrap", gap: 18, marginTop: 18 }}>',
'        <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>',
'          <div style={{ fontWeight: 700 }}>Preview 3:4</div>',
'          <img src={img3x4} alt={`Card 3:4 — ${day}`} width={360} height={450} style={{ borderRadius: 14, border: "1px solid #222" }} />',
'        </div>',
'',
'        <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>',
'          <div style={{ fontWeight: 700 }}>Preview 1:1</div>',
'          <img src={img1x1} alt={`Card 1:1 — ${day}`} width={360} height={360} style={{ borderRadius: 14, border: "1px solid #222" }} />',
'        </div>',
'      </div>',
'',
'      <p style={{ marginTop: 18, fontSize: 12, opacity: 0.75 }}>',
'        Recibo é lei. Cuidado é coletivo. Trabalho digno é o centro. — #ECO • Escutar • Cuidar • Organizar',
'      </p>',
'    </main>',
'  );',
'}'
)

WriteUtf8NoBom $pagePath ($lines -join "`n")

$log += "- OK: page.tsx reescrito com async params + async headers() (Next 16)."
$log += ""
$log += "## VERIFY"
$log += "1) Reinicie o dev: CTRL+C ; npm run dev"
$log += "2) Abra /s/dia/2025-12-26"
$log += "3) Confirme que previews chamam day=2025-12-26 (não 2025-01-01)"
$log += "4) Cole o link no WhatsApp e veja se puxa OG"
WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 37c aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Abra /s/dia/2025-12-26" -ForegroundColor Yellow
Write-Host "3) Veja se o OG já não dá erro e se a data fica correta" -ForegroundColor Yellow