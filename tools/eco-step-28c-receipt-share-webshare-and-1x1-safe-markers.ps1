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

function RemoveBlockByMarkers([string]$txt, [string]$startMarker, [string]$endMarker){
  if([string]::IsNullOrEmpty($txt)){ return $txt }
  while($true){
    $s = $txt.IndexOf($startMarker)
    if($s -lt 0){ break }
    $e = $txt.IndexOf($endMarker, $s + $startMarker.Length)
    if($e -lt 0){ break }
    $e2 = $e + $endMarker.Length

    # remove one trailing newline if exists
    if($e2 -lt $txt.Length -and $txt[$e2] -eq "`r"){ $e2++ }
    if($e2 -lt $txt.Length -and $txt[$e2] -eq "`n"){ $e2++ }

    $txt = $txt.Remove($s, $e2 - $s)
  }
  return $txt
}

$rep = NewReport "eco-step-28c-receipt-share-webshare-and-1x1-safe-markers"
$log = @()
$log += "# ECO — STEP 28c — ReceiptShareBar: 1:1 + Web Share PNG (safe markers)"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

$shareComp = "src/components/eco/ReceiptShareBar.tsx"
if(!(Test-Path -LiteralPath $shareComp)){
  $shareComp = FindFirst "." "\\src\\components\\eco\\ReceiptShareBar\.tsx$"
}
if(!(Test-Path -LiteralPath $shareComp)){
  $log += "## ERRO"
  $log += "Não achei src/components/eco/ReceiptShareBar.tsx"
  WriteUtf8NoBom $rep ($log -join "`n")
  throw "Não achei ReceiptShareBar.tsx"
}

$bk = BackupFile $shareComp
$txt = Get-Content -LiteralPath $shareComp -Raw

$log += "## DIAG"
$log += ("Arquivo: {0}" -f $shareComp)
$log += ("Backup: {0}" -f $bk)
$log += ""

$log += "## PATCH"

# 0) limpeza idempotente (helpers + buttons antigos)
$txt0 = $txt
$txt = RemoveBlockByMarkers $txt "// ECO_STEP28_SHARE_HELPERS_START" "// ECO_STEP28_SHARE_HELPERS_END"
$txt = RemoveBlockByMarkers $txt "{/* ECO_STEP28_SHARE_BUTTONS_START */}" "{/* ECO_STEP28_SHARE_BUTTONS_END */}"
if($txt -ne $txt0){ $log += "- OK: removi blocos antigos do STEP 28 (markers)." }
else { $log += "- INFO: nenhum bloco antigo do STEP 28 encontrado." }

# 1) injetar helpers (sempre uma vez)
$helpers = @"
// ECO_STEP28_SHARE_HELPERS_START
type EcoCardFormat = "3x4" | "1x1";
type ShareNav = Navigator & { share?: (data: ShareData) => Promise<void>; canShare?: (data: ShareData) => boolean };

const ecoCardUrl = (fmt: EcoCardFormat) => {
  const c = encodeURIComponent(String(code));
  return "/api/share/receipt-card?code=" + c + "&format=" + fmt;
};

const onCard1x1 = () => {
  const card = ecoCardUrl("1x1");
  window.open(card, "_blank", "noopener,noreferrer");
};

const ecoShareCard = async (fmt: EcoCardFormat) => {
  const card = ecoCardUrl(fmt);

  let res: Response | null = null;
  try { res = await fetch(card, { cache: "no-store" }); } catch { res = null; }

  if(!res || !res.ok){
    window.open(card, "_blank", "noopener,noreferrer");
    return;
  }

  const blob = await res.blob();
  const fileName = "recibo-eco-" + String(code) + "-" + fmt + ".png";
  const file = new File([blob], fileName, { type: "image/png" });

  const nav = navigator as ShareNav;
  const data: ShareData = {
    title: "Recibo ECO",
    text: "Recibo ECO: " + String(code),
    files: [file],
  };

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

const onShare3x4 = () => ecoShareCard("3x4");
const onShare1x1 = () => ecoShareCard("1x1");
// ECO_STEP28_SHARE_HELPERS_END
"@

# inserir após onCard3x4, senão após onWhatsApp, senão após 'use client', senão topo
$insertedHelpers = $false
$reOnCard3 = [regex]::new("const\s+onCard3x4\s*=\s*\(\)\s*=>\s*\{[\s\S]*?\n\s*\};", "Singleline")
$m3 = $reOnCard3.Match($txt)
if($m3.Success){
  $insAt = $m3.Index + $m3.Length
  $txt = $txt.Insert($insAt, "`n`n" + $helpers + "`n")
  $insertedHelpers = $true
  $log += "- OK: helpers inseridos após onCard3x4."
} else {
  $reOnWa = [regex]::new("const\s+onWhatsApp\s*=\s*\(\)\s*=>\s*\{[\s\S]*?\n\s*\};", "Singleline")
  $mwa = $reOnWa.Match($txt)
  if($mwa.Success){
    $insAt = $mwa.Index + $mwa.Length
    $txt = $txt.Insert($insAt, "`n`n" + $helpers + "`n")
    $insertedHelpers = $true
    $log += "- OK: helpers inseridos após onWhatsApp."
  }
}

if(-not $insertedHelpers){
  $idxUC = $txt.IndexOf("'use client'")
  if($idxUC -ge 0){
    $idxNL = $txt.IndexOf("`n", $idxUC)
    if($idxNL -ge 0){
      $txt = $txt.Insert($idxNL + 1, "`n" + $helpers + "`n")
      $log += "- OK: helpers inseridos após 'use client'."
    } else {
      $txt = $helpers + "`n" + $txt
      $log += "- OK: helpers inseridos no topo (fallback)."
    }
  } else {
    $txt = $helpers + "`n" + $txt
    $log += "- OK: helpers inseridos no topo (fallback)."
  }
}

# 2) inserir botões após o botão "Baixar card 3:4"
$reBtn34 = [regex]::new("(<button[^>]*>)(\s*)Baixar\s+card\s+3:4(\s*)(</button>)", "IgnoreCase")
$mb = $reBtn34.Match($txt)
if($mb.Success){
  $after = $mb.Index + $mb.Length
  $buttons = @"
{/* ECO_STEP28_SHARE_BUTTONS_START */}
<button type="button" onClick={onCard1x1} className="underline">Baixar card 1:1</button>
<button type="button" onClick={onShare3x4} className="underline">Compartilhar 3:4</button>
<button type="button" onClick={onShare1x1} className="underline">Compartilhar 1:1</button>
{/* ECO_STEP28_SHARE_BUTTONS_END */}
"@
  $txt = $txt.Insert($after, "`n" + $buttons)
  $log += "- OK: botões 1:1 + compartilhar inseridos após 'Baixar card 3:4'."
} else {
  $log += "- WARN: não achei o botão 'Baixar card 3:4' para ancorar; não injetei botões."
}

WriteUtf8NoBom $shareComp $txt
$log += ""
$log += "## VERIFY"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1"
$log += "3) Abra /r/[code] e teste:"
$log += "   - Baixar card 3:4 / 1:1"
$log += "   - Compartilhar 3:4 / 1:1 (no celular/PWA deve abrir share sheet; no desktop cai em download)"
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")
Write-Host ("✅ STEP 28c aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) Teste /r/[code] (download 3:4 e 1:1 + share PNG)" -ForegroundColor Yellow