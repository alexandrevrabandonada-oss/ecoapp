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
  $pat = "(?s)\r?\n?\s*" + [regex]::Escape($startMarker) + ".*?" + [regex]::Escape($endMarker) + "\s*\r?\n?"
  return [regex]::Replace($txt, $pat, "")
}
function InsertAfterLastImport([string]$txt, [string]$insert){
  $m = [regex]::Matches($txt, '^\s*import\s+.*?;\s*$', 'Multiline')
  if($m.Count -gt 0){
    $last = $m[$m.Count-1]
    $at = $last.Index + $last.Length
    return $txt.Insert($at, "`n`n" + $insert + "`n")
  }

  # fallback: depois do 'use client'
  $idxUC = $txt.IndexOf("'use client'")
  if($idxUC -ge 0){
    $idxNL = $txt.IndexOf("`n", $idxUC)
    if($idxNL -ge 0){
      return $txt.Insert($idxNL + 1, "`n" + $insert + "`n")
    }
  }

  return ($insert + "`n" + $txt)
}
function InsertButtonsAfterAnchor([string]$txt, [string]$anchorText, [string]$buttonsBlock){
  $idx = $txt.IndexOf($anchorText)
  if($idx -lt 0){ return @{ ok=$false; txt=$txt; why="anchor-not-found" } }

  # procura fechamento do botão depois do texto âncora
  $idxClose = $txt.IndexOf("</button>", $idx)
  if($idxClose -lt 0){ return @{ ok=$false; txt=$txt; why="button-close-not-found" } }

  $insertPos = $idxClose + "</button>".Length
  $out = $txt.Insert($insertPos, "`n" + $buttonsBlock)
  return @{ ok=$true; txt=$out; why="ok" }
}

$rep = NewReport "eco-step-28c-receipt-sharebar-webshare-1x1-hardening"
$log = @()
$log += "# ECO — STEP 28c — ReceiptShareBar: Web Share (PNG) + botão 1:1 (hardening/idempotente)"
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

$log += "## DIAG"
$log += ("Arquivo: {0}" -f $shareComp)
$log += ""

$bk = BackupFile $shareComp
$txt = Get-Content -LiteralPath $shareComp -Raw

$log += "## PATCH"
$log += ("Backup: {0}" -f $bk)

# 1) limpar blocos antigos (helpers + botões) se existirem
$txt2 = RemoveBlockByMarkers $txt "// ECO_STEP28_SHARE_HELPERS_START" "// ECO_STEP28_SHARE_HELPERS_END"
if($txt2 -ne $txt){ $log += "- OK: removi bloco antigo ECO_STEP28_SHARE_HELPERS." }
$txt = $txt2

$txt2 = RemoveBlockByMarkers $txt "{/* ECO_STEP28_BUTTONS_START */}" "{/* ECO_STEP28_BUTTONS_END */}"
if($txt2 -ne $txt){ $log += "- OK: removi bloco antigo ECO_STEP28_BUTTONS." }
$txt = $txt2

# 2) inserir helper limpo UMA vez (top-level) — não depende do corpo do componente
$helpers = @"
// ECO_STEP28_SHARE_HELPERS_START
type Eco28CardFormat = "3x4" | "1x1";
type Eco28ShareNav = Navigator & { share?: (data: ShareData) => Promise<void>; canShare?: (data: ShareData) => boolean };

function eco28_cardUrl(code: string, fmt: Eco28CardFormat) {
  const c = encodeURIComponent(String(code));
  return "/api/share/receipt-card?code=" + c + "&format=" + fmt;
}

async function eco28_fetchBlob(url: string): Promise<Blob | null> {
  try {
    const res = await fetch(url, { cache: "no-store" });
    if (!res.ok) return null;
    return await res.blob();
  } catch {
    return null;
  }
}

function eco28_downloadBlob(blob: Blob, fileName: string) {
  const a = document.createElement("a");
  const obj = URL.createObjectURL(blob);
  a.href = obj;
  a.download = fileName;
  document.body.appendChild(a);
  a.click();
  a.remove();
  setTimeout(() => URL.revokeObjectURL(obj), 1200);
}

async function eco28_downloadCard(code: string, fmt: Eco28CardFormat) {
  const url = eco28_cardUrl(code, fmt);
  const blob = await eco28_fetchBlob(url);
  if (!blob) {
    window.open(url, "_blank", "noopener,noreferrer");
    return;
  }
  const fileName = "recibo-eco-" + String(code) + "-" + fmt + ".png";
  eco28_downloadBlob(blob, fileName);
}

async function eco28_shareCard(code: string, fmt: Eco28CardFormat) {
  const url = eco28_cardUrl(code, fmt);
  const blob = await eco28_fetchBlob(url);
  if (!blob) {
    window.open(url, "_blank", "noopener,noreferrer");
    return;
  }

  const fileName = "recibo-eco-" + String(code) + "-" + fmt + ".png";
  const file = new File([blob], fileName, { type: "image/png" });

  const nav = navigator as Eco28ShareNav;
  const data: ShareData = {
    title: "Recibo ECO",
    text: "Recibo ECO: " + String(code),
    files: [file],
  };

  // Web Share quando disponível; fallback: download
  if (nav.share && (!nav.canShare || nav.canShare(data))) {
    await nav.share(data);
    return;
  }

  eco28_downloadBlob(blob, fileName);
}
// ECO_STEP28_SHARE_HELPERS_END
"@

if($txt -notmatch "ECO_STEP28_SHARE_HELPERS_START"){
  $txt = InsertAfterLastImport $txt $helpers
  $log += "- OK: injetei helpers ECO_STEP28_SHARE_HELPERS (top-level)."
} else {
  $log += "- INFO: helpers já existiam (skip)."
}

# 3) inserir botões logo após o botão "Baixar card 3:4"
$buttons = @"
      {/* ECO_STEP28_BUTTONS_START */}
      <button type="button" onClick={() => eco28_downloadCard(code, "1x1")} className="underline">Baixar card 1:1</button>
      <button type="button" onClick={() => eco28_shareCard(code, "3x4")} className="underline">Compartilhar 3:4</button>
      <button type="button" onClick={() => eco28_shareCard(code, "1x1")} className="underline">Compartilhar 1:1</button>
      {/* ECO_STEP28_BUTTONS_END */}
"@

$res = InsertButtonsAfterAnchor $txt "Baixar card 3:4" $buttons
$txt = $res.txt
if($res.ok){
  $log += "- OK: inseri botões (1:1 + compartilhar 3:4/1:1) após 'Baixar card 3:4'."
} else {
  $log += ("- WARN: não consegui ancorar botões após 'Baixar card 3:4' ({0})." -f $res.why)
  $log += "  DICA: confirme se o texto do botão existe no ReceiptShareBar (pode ter outro label)."
}

WriteUtf8NoBom $shareComp $txt

$log += ""
$log += "## VERIFY"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1"
$log += "3) Abra um recibo /r/[code] e teste:"
$log += "   - Baixar card 3:4"
$log += "   - Baixar card 1:1"
$log += "   - Compartilhar 3:4 / 1:1 (no celular/PWA deve abrir share sheet; senão baixa)"
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")
Write-Host ("✅ STEP 28c aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) Teste /r/[code] (download 1:1 e share 3:4/1:1)" -ForegroundColor Yellow