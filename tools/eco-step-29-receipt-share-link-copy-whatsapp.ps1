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
  $idxUC = $txt.IndexOf("'use client'")
  if($idxUC -ge 0){
    $idxNL = $txt.IndexOf("`n", $idxUC)
    if($idxNL -ge 0){
      return $txt.Insert($idxNL + 1, "`n" + $insert + "`n")
    }
  }
  return ($insert + "`n" + $txt)
}
function InsertAfterMarker([string]$txt, [string]$marker, [string]$insert){
  $idx = $txt.IndexOf($marker)
  if($idx -lt 0){ return @{ ok=$false; txt=$txt } }
  $idxNL = $txt.IndexOf("`n", $idx)
  if($idxNL -lt 0){ return @{ ok=$false; txt=$txt } }
  $out = $txt.Insert($idxNL + 1, $insert)
  return @{ ok=$true; txt=$out }
}
function InsertButtonsAfterAnchor([string]$txt, [string]$anchorText, [string]$buttonsBlock){
  $idx = $txt.IndexOf($anchorText)
  if($idx -lt 0){ return @{ ok=$false; txt=$txt; why="anchor-not-found" } }
  $idxClose = $txt.IndexOf("</button>", $idx)
  if($idxClose -lt 0){ return @{ ok=$false; txt=$txt; why="button-close-not-found" } }
  $insertPos = $idxClose + "</button>".Length
  $out = $txt.Insert($insertPos, "`n" + $buttonsBlock)
  return @{ ok=$true; txt=$out; why="ok" }
}

$rep = NewReport "eco-step-29-receipt-share-link-copy-whatsapp"
$log = @()
$log += "# ECO — STEP 29 — ReceiptShareBar: copiar link + WhatsApp + Web Share (link)"
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

# detectar nome do prop/variável que carrega o code (default: code)
$codeVar = "code"
$m = [regex]::Match($txt, "ReceiptShareBar\s*\(\s*\{\s*([A-Za-z_][A-Za-z0-9_]*)", "IgnoreCase")
if($m.Success){
  $codeVar = $m.Groups[1].Value
}

$log += "## DIAG"
$log += ("Arquivo: {0}" -f $shareComp)
$log += ("Backup : {0}" -f $bk)
$log += ("codeVar: {0}" -f $codeVar)
$log += ""

$log += "## PATCH"

# 1) remover versões anteriores do step 29 (idempotência)
$before = $txt
$txt = RemoveBlockByMarkers $txt "// ECO_STEP29_LINK_HELPERS_START" "// ECO_STEP29_LINK_HELPERS_END"
$txt = RemoveBlockByMarkers $txt "{/* ECO_STEP29_LINK_BUTTONS_START */}" "{/* ECO_STEP29_LINK_BUTTONS_END */}"
if($txt -ne $before){ $log += "- OK: removi blocos antigos do STEP 29 (se existiam)." }

# 2) inserir helpers (top-level)
$helpers = @"
// ECO_STEP29_LINK_HELPERS_START
type Eco29ShareNav = Navigator & { share?: (data: ShareData) => Promise<void>; canShare?: (data: ShareData) => boolean };

function eco29_publicUrl(code: string) {
  // padrão: página pública do recibo
  return window.location.origin + "/r/" + encodeURIComponent(String(code));
}

function eco29_caption(code: string) {
  // texto curto, pronto pra zap / share
  return "Recibo ECO — bora de recibo? Código: " + String(code);
}

async function eco29_copyText(text: string) {
  try {
    if (navigator.clipboard && navigator.clipboard.writeText) {
      await navigator.clipboard.writeText(text);
      return true;
    }
  } catch {}
  try {
    const ta = document.createElement("textarea");
    ta.value = text;
    ta.style.position = "fixed";
    ta.style.left = "-9999px";
    ta.style.top = "-9999px";
    document.body.appendChild(ta);
    ta.focus();
    ta.select();
    const ok = document.execCommand("copy");
    ta.remove();
    return ok;
  } catch {
    return false;
  }
}

async function eco29_copyLink(code: string) {
  const url = eco29_publicUrl(code);
  await eco29_copyText(url);
}

async function eco29_copyTextAndLink(code: string) {
  const url = eco29_publicUrl(code);
  const text = eco29_caption(code) + "\n" + url;
  await eco29_copyText(text);
}

async function eco29_shareLink(code: string) {
  const url = eco29_publicUrl(code);
  const text = eco29_caption(code);
  const nav = navigator as Eco29ShareNav;

  const data: ShareData = { title: "Recibo ECO", text, url };

  if (nav.share && (!nav.canShare || nav.canShare(data))) {
    await nav.share(data);
    return;
  }

  // fallback: copiar tudo
  await eco29_copyText(text + "\n" + url);
}

function eco29_whatsApp(code: string) {
  const url = eco29_publicUrl(code);
  const text = eco29_caption(code) + "\n" + url;
  const wa = "https://wa.me/?text=" + encodeURIComponent(text);
  window.open(wa, "_blank", "noopener,noreferrer");
}
// ECO_STEP29_LINK_HELPERS_END
"@

if($txt -notmatch "ECO_STEP29_LINK_HELPERS_START"){
  $txt = InsertAfterLastImport $txt $helpers
  $log += "- OK: injetei helpers do STEP 29 (top-level)."
} else {
  $log += "- INFO: helpers do STEP 29 já existem (skip)."
}

# 3) inserir botões (após o bloco do STEP 28 se existir; senão após botão 'Baixar card 3:4')
$buttons = @"
      {/* ECO_STEP29_LINK_BUTTONS_START */}
      <button type="button" onClick={() => eco29_copyLink(__ECO_CODEVAR__)} className="underline">Copiar link</button>
      <button type="button" onClick={() => eco29_copyTextAndLink(__ECO_CODEVAR__)} className="underline">Copiar texto + link</button>
      <button type="button" onClick={() => eco29_whatsApp(__ECO_CODEVAR__)} className="underline">WhatsApp</button>
      <button type="button" onClick={() => eco29_shareLink(__ECO_CODEVAR__)} className="underline">Compartilhar link</button>
      {/* ECO_STEP29_LINK_BUTTONS_END */}
"@
$buttons = $buttons.Replace("__ECO_CODEVAR__", $codeVar)

$ins = InsertAfterMarker $txt "{/* ECO_STEP28_BUTTONS_END */}" ("`n" + $buttons)
if($ins.ok){
  $txt = $ins.txt
  $log += "- OK: inseri botões do STEP 29 após ECO_STEP28_BUTTONS_END."
} else {
  $res = InsertButtonsAfterAnchor $txt "Baixar card 3:4" $buttons
  $txt = $res.txt
  if($res.ok){
    $log += "- OK: inseri botões do STEP 29 após 'Baixar card 3:4'."
  } else {
    $log += ("- WARN: não consegui ancorar botões do STEP 29 ({0})." -f $res.why)
    $log += "  DICA: confira o label do botão 3:4 no ReceiptShareBar."
  }
}

WriteUtf8NoBom $shareComp $txt

$log += ""
$log += "## VERIFY"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1"
$log += "3) Abra /r/[code] e teste:"
$log += "   - Copiar link"
$log += "   - Copiar texto + link"
$log += "   - WhatsApp (abre wa.me com texto)"
$log += "   - Compartilhar link (no celular/PWA: share sheet; no desktop: copia tudo)"
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")
Write-Host ("✅ STEP 29 aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) Teste /r/[code] (copiar/whatsapp/share link)" -ForegroundColor Yellow