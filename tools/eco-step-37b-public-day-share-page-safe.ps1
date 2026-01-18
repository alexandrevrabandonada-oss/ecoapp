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

$rep = NewReport "eco-step-37b-public-day-share-page-safe"
$log = @()
$log += "# ECO — STEP 37b — Página pública /s/dia/[day] (OG + download/share) — SAFE"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

$clientPath = "src/app/s/dia/[day]/DayShareClient.tsx"
$pagePath   = "src/app/s/dia/[day]/page.tsx"

EnsureDir (Split-Path -Parent $clientPath)
EnsureDir (Split-Path -Parent $pagePath)

$bk1 = BackupFile $clientPath
$bk2 = BackupFile $pagePath
$bk1s = if($bk1){ $bk1 } else { "(novo)" }
$bk2s = if($bk2){ $bk2 } else { "(novo)" }

$log += "## DIAG"
$log += ("Client: {0}" -f $clientPath)
$log += ("Page  : {0}" -f $pagePath)
$log += ("Backup client: {0}" -f $bk1s)
$log += ("Backup page  : {0}" -f $bk2s)
$log += ""

$log += "## PATCH"

$clientLines = @(
'"use client";',
'',
'type ShareNav = Navigator & { share?: (data: ShareData) => Promise<void>; canShare?: (data: ShareData) => boolean };',
'',
'export default function DayShareClient(props: { day: string }) {',
'  const day = props.day;',
'',
'  const url3x4 = `/api/share/route-day-card?day=${encodeURIComponent(day)}&format=3x4`;',
'  const url1x1 = `/api/share/route-day-card?day=${encodeURIComponent(day)}&format=1x1`;',
'',
'  const onCopyLink = async () => {',
'    const link = window.location.href;',
'    try {',
'      await navigator.clipboard.writeText(link);',
'      alert("Link copiado!");',
'    } catch {',
'      prompt("Copie o link:", link);',
'    }',
'  };',
'',
'  const onWhatsApp = () => {',
'    const link = window.location.href;',
'    const text = `ECO — Fechamento do dia ${day}\n${link}`;',
'    const wa = `https://wa.me/?text=${encodeURIComponent(text)}`;',
'    window.open(wa, "_blank", "noopener,noreferrer");',
'  };',
'',
'  const onShareLink = async () => {',
'    const link = window.location.href;',
'    const nav = navigator as ShareNav;',
'    const data: ShareData = {',
'      title: `ECO — Fechamento do dia ${day}`,',
'      text: `ECO — Fechamento do dia ${day}`,',
'      url: link,',
'    };',
'    if (nav.share && (!nav.canShare || nav.canShare(data))) {',
'      await nav.share(data);',
'      return;',
'    }',
'    await onCopyLink();',
'  };',
'',
'  return (',
'    <div style={{ display: "flex", flexDirection: "column", gap: 10, marginTop: 14 }}>',
'      <div style={{ display: "flex", flexWrap: "wrap", gap: 10 }}>',
'        <a href={url3x4} target="_blank" rel="noreferrer" style={{ padding: "8px 10px", border: "1px solid #333", borderRadius: 10 }}>',
'          Baixar card 3:4',
'        </a>',
'        <a href={url1x1} target="_blank" rel="noreferrer" style={{ padding: "8px 10px", border: "1px solid #333", borderRadius: 10 }}>',
'          Baixar card 1:1',
'        </a>',
'      </div>',
'',
'      <div style={{ display: "flex", flexWrap: "wrap", gap: 10 }}>',
'        <button type="button" onClick={onCopyLink} style={{ padding: "8px 10px", border: "1px solid #333", borderRadius: 10 }}>',
'          Copiar link',
'        </button>',
'        <button type="button" onClick={onWhatsApp} style={{ padding: "8px 10px", border: "1px solid #333", borderRadius: 10 }}>',
'          WhatsApp',
'        </button>',
'        <button type="button" onClick={onShareLink} style={{ padding: "8px 10px", border: "1px solid #333", borderRadius: 10 }}>',
'          Compartilhar (Share Sheet)',
'        </button>',
'      </div>',
'    </div>',
'  );',
'}'
)
$client = ($clientLines -join "`n")

$pageLines = @(
'import type { Metadata } from "next";',
'import { headers } from "next/headers";',
'import DayShareClient from "./DayShareClient";',
'',
'function safeDay(input: string): string {',
'  const s = String(input || "").trim();',
'  if (s.length === 10 && /^[0-9-]+$/.test(s)) return s;',
'  return "2025-01-01";',
'}',
'',
'function originFromHeaders() {',
'  const h = headers();',
'  const proto = h.get("x-forwarded-proto") || "http";',
'  const host = h.get("x-forwarded-host") || h.get("host") || "localhost:3000";',
'  return `${proto}://${host}`;',
'}',
'',
'export async function generateMetadata({ params }: { params: { day: string } }): Promise<Metadata> {',
'  const day = safeDay(params.day);',
'  const origin = originFromHeaders();',
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
'export default function Page({ params }: { params: { day: string } }) {',
'  const day = safeDay(params.day);',
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
$page = ($pageLines -join "`n")

WriteUtf8NoBom $clientPath $client
WriteUtf8NoBom $pagePath $page

$log += "- OK: arquivos criados/atualizados:"
$log += "  - src/app/s/dia/[day]/page.tsx"
$log += "  - src/app/s/dia/[day]/DayShareClient.tsx"
$log += ""
$log += "## VERIFY"
$log += "1) Abra: /s/dia/2025-12-26"
$log += "2) Teste botões: baixar 3:4/1:1 + copiar link + WhatsApp + share sheet"
$log += "3) (Opcional) Colar link no WhatsApp para ver OG"

WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 37b aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Abra /s/dia/2025-12-26" -ForegroundColor Yellow
Write-Host "2) Teste download + share" -ForegroundColor Yellow