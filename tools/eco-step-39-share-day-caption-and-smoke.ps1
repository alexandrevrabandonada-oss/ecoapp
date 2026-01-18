$ErrorActionPreference = 'Stop'

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
  EnsureDir 'tools/_patch_backup'
  $ts = Get-Date -Format 'yyyyMMdd-HHmmss'
  $safe = ($path -replace '[\\/:*?"<>|]','_')
  $dst = 'tools/_patch_backup/' + $ts + '-' + $safe
  Copy-Item -Force -LiteralPath $path $dst
  return $dst
}
function NewReport([string]$name){
  EnsureDir 'reports'
  $ts = Get-Date -Format 'yyyyMMdd-HHmmss'
  return 'reports/' + $ts + '-' + $name + '.md'
}
function FindFirst([string]$root, [string]$pattern){
  if(!(Test-Path -LiteralPath $root)){ return $null }
  $f = Get-ChildItem -Recurse -File -Path $root -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -match $pattern } |
    Select-Object -First 1
  if($f){ return $f.FullName }
  return $null
}

$rep = NewReport 'eco-step-39-share-day-caption-and-smoke'
$log = @()
$log += '# ECO — STEP 39 — Share do Dia v1 (legenda pronta + smoke dedicado)'
$log += ''
$log += ('Data: {0}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
$log += ('PWD : {0}' -f (Get-Location).Path)
$log += ''

# -------------------------
# DIAG
# -------------------------
$clientPath = 'src/app/s/dia/[day]/DayShareClient.tsx'
if(!(Test-Path -LiteralPath $clientPath)){ $clientPath = FindFirst '.' '\\src\\app\\s\\dia\\\[day\]\\DayShareClient\.tsx$' }
$smokePath = 'tools/eco-smoke-share-day.ps1'

$log += '## DIAG'
$log += ('Client: {0}' -f ($clientPath ? $clientPath : '(não encontrado)'))
$log += ('Smoke : {0}' -f $smokePath)
$log += ''

if(!(Test-Path -LiteralPath $clientPath)){
  $log += '## ERRO'
  $log += 'Não achei DayShareClient.tsx em src/app/s/dia/[day]/'
  WriteUtf8NoBom $rep ($log -join "`n")
  throw 'Não achei DayShareClient.tsx'
}

# -------------------------
# PATCH 1 — DayShareClient: adicionar legenda/copy (reescreve arquivo) 
# -------------------------
$bkC = BackupFile $clientPath
$log += '## PATCH — DayShareClient.tsx'
$log += ('Arquivo: {0}' -f $clientPath)
$log += ('Backup : {0}' -f $bkC)
$log += ''

$clientTxt = @'
"use client";

type ShareNav = Navigator & { share?: (data: ShareData) => Promise<void>; canShare?: (data: ShareData) => boolean };

function buildCaption(day: string) {
  // Instagram: 5 hashtags (pack ECO)
  return [
    `ECO — Fechamento do dia ${day}`,
    `Recibo é lei. Cuidado é coletivo. Trabalho digno é o centro.`,
    ``,
    `#ECO #ReciboECO #Reciclagem #VoltaRedonda #EconomiaSolidaria`,
  ].join("\\n");
}

export default function DayShareClient(props: { day: string }) {
  const day = props.day;

  const url3x4 = `/api/share/route-day-card?day=${encodeURIComponent(day)}&format=3x4`;
  const url1x1 = `/api/share/route-day-card?day=${encodeURIComponent(day)}&format=1x1`;
  const caption = buildCaption(day);

  const onCopyText = async (text: string, okMsg: string) => {
    try {
      await navigator.clipboard.writeText(text);
      alert(okMsg);
    } catch {
      prompt("Copie:", text);
    }
  };

  const onCopyLink = async () => {
    const link = window.location.href;
    await onCopyText(link, "Link copiado!");
  };

  const onCopyCaption = async () => {
    await onCopyText(caption, "Legenda copiada!");
  };

  const onWhatsApp = () => {
    const link = window.location.href;
    const text = `ECO — Fechamento do dia ${day}\\n${link}`;
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
    <div style={{ display: "flex", flexDirection: "column", gap: 12, marginTop: 14 }}>
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
        <button type="button" onClick={onCopyCaption} style={{ padding: "8px 10px", border: "1px solid #333", borderRadius: 10 }}>
          Copiar legenda (Instagram)
        </button>
        <button type="button" onClick={onWhatsApp} style={{ padding: "8px 10px", border: "1px solid #333", borderRadius: 10 }}>
          WhatsApp
        </button>
        <button type="button" onClick={onShareLink} style={{ padding: "8px 10px", border: "1px solid #333", borderRadius: 10 }}>
          Compartilhar (Share Sheet)
        </button>
      </div>

      <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
        <div style={{ fontWeight: 700, opacity: 0.9 }}>Legenda pronta</div>
        <textarea
          value={caption}
          readOnly
          rows={5}
          style={{ width: "100%", maxWidth: 680, padding: 10, borderRadius: 10, border: "1px solid #333" }}
        />
      </div>
    </div>
  );
}
'@

WriteUtf8NoBom $clientPath $clientTxt
$log += '- OK: DayShareClient.tsx atualizado (legenda + copiar).'
$log += ''

# -------------------------
# PATCH 2 — Smoke dedicado (não mexe no eco-smoke existente)
# -------------------------
$bkS = $null
if(Test-Path -LiteralPath $smokePath){ $bkS = BackupFile $smokePath }
$log += '## PATCH — tools/eco-smoke-share-day.ps1'
$log += ('Arquivo: {0}' -f $smokePath)
$log += ('Backup : {0}' -f ($bkS ? $bkS : '(novo)'))
$log += ''

$smokeTxt = @'
$ErrorActionPreference = "Stop"

$BaseUrl = $args[0]
if([string]::IsNullOrWhiteSpace($BaseUrl)){ $BaseUrl = "http://localhost:3000" }

$today = (Get-Date -Format "yyyy-MM-dd")

function Hit([string]$path){
  $url = $BaseUrl.TrimEnd("/") + $path
  try {
    $r = Invoke-WebRequest -Uri $url -Method GET -TimeoutSec 30 -UseBasicParsing
    $ct = ""
    try { $ct = $r.Headers["Content-Type"] } catch { $ct = "" }
    Write-Host ("OK  {0}  {1}  {2}" -f $r.StatusCode, $path, $ct) -ForegroundColor Green
    return $true
  } catch {
    Write-Host ("FAIL {0}  {1}" -f $path, $_.Exception.Message) -ForegroundColor Red
    return $false
  }
}

Write-Host "== ECO SMOKE SHARE DAY ==" -ForegroundColor Cyan
Write-Host ("BaseUrl: {0}" -f $BaseUrl) -ForegroundColor Cyan
Write-Host ("Today  : {0}" -f $today) -ForegroundColor Cyan

$ok = $true
$ok = (Hit "/s/dia/$today") -and $ok
$ok = (Hit "/api/share/route-day-card?day=$today&format=3x4") -and $ok
$ok = (Hit "/api/share/route-day-card?day=$today&format=1x1") -and $ok
$ok = (Hit "/operador/triagem") -and $ok

if(-not $ok){
  throw "Smoke share-day falhou. Veja os FAIL acima."
}

Write-Host "✅ SMOKE SHARE DAY OK" -ForegroundColor Green
'@

WriteUtf8NoBom $smokePath $smokeTxt
$log += '- OK: eco-smoke-share-day.ps1 criado/atualizado.'
$log += ''

# -------------------------
# REGISTRO + VERIFY
# -------------------------
$log += '## VERIFY'
$log += '1) Reinicie o dev (CTRL+C): npm run dev'
$log += '2) Abra: /s/dia/2025-12-26 e teste: copiar legenda + baixar 3:4/1:1'
$log += '3) Rode: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke-share-day.ps1'
$log += ''

WriteUtf8NoBom $rep ($log -join "`n")
Write-Host ("✅ STEP 39 aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) CTRL+C ; npm run dev" -ForegroundColor Yellow
Write-Host "2) Teste /s/dia/2025-12-26 (legenda + downloads)" -ForegroundColor Yellow
Write-Host "3) Rode smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke-share-day.ps1" -ForegroundColor Yellow