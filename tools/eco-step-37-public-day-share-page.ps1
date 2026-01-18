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

$rep = NewReport "eco-step-37-public-day-share-page"
$log = @()
$log += "# ECO — STEP 37 — Página pública /s/dia/[day] (OG + download/share)"
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

$log += "## DIAG"
$log += ("Client: {0}" -f $clientPath)
$log += ("Page  : {0}" -f $pagePath)
$log += ("Backup client: {0}" -f ($bk1 ? $bk1 : "(novo)"))
$log += ("Backup page  : {0}" -f ($bk2 ? $bk2 : "(novo)"))
$log += ""

$log += "## PATCH"

$client = @'
"use client";

type ShareNav = Navigator & { share?: (data: ShareData) => Promise<void>; canShare?: (data: ShareData) => boolean };

export default function DayShareClient(props: { day: string }) {
  const day = props.day;

  const url3x4 = `/api/share/route-day-card?day=${encodeURIComponent(day)}&format=3x4`;
  const url1x1 = `/api/share/route-day-card?day=${encodeURIComponent(day)}&format=1x1`;

  const onCopyLink = async () => {
    const link = window.location.href;
    try {
      await navigator.clipboard.writeText(link);
      alert("Link copiado!");
    } catch {
      prompt("Copie o link:", link);
    }
  };

  const onWhatsApp = () => {
    const link = window.location.href;
    const text = `ECO — Fechamento do dia ${day}\n${link}`;
    const wa = `https://wa.me/?text=${encodeURIComponent(text)}`;
    window.open(wa, "_blank", "noopener,noreferrer");
  };

  const onShareLink = async () => {
    const link = window.location.href;
    const nav = navigator as ShareNav;
    const data: ShareData = {
      title: `ECO — Fechamento do dia ${day}`,
      text: `ECO — Fechamento do dia ${day}`,
      url: link,
    };
    if (nav.share && (!nav.canShare || nav.canShare(data))) {
      await nav.share(data);
      return;
    }
    await onCopyLink();
  };

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 10, marginTop: 14 }}>
      <div style={{ display: "flex", flexWrap: "wrap", gap: 10 }}>
        <a href={url3x4} target="_blank" rel="noreferrer" style={{ padding: "8px 10px", border: "1px solid #333", borderRadius: 10 }}>
          Baixar card 3:4
        </a>
        <a href={url1x1} target="_blank" rel="noreferrer" style={{ padding: "8px 10px", border: "1px solid #333", borderRadius: 10 }}>
          Baixar card 1:1
        </a>
      </div>

      <div style={{ display: "flex", flexWrap: "wrap", gap: 10 }}>
        <button type="button" onClick={onCopyLink} style={{ padding: "8px 10px", border: "1px solid #333", borderRadius: 10 }}>
          Copiar link
        </button>
        <button type="button" onClick={onWhatsApp} style={{ padding: "8px 10px", border: "1px solid #333", borderRadius: 10 }}>
          WhatsApp
        </button>
        <button type="button" onClick={onShareLink} style={{ padding: "8px 10px", border: "1px solid #333", borderRadius: 10 }}>
          Compartilhar (Share Sheet)
        </button>
      </div>
    </div>
  );
}