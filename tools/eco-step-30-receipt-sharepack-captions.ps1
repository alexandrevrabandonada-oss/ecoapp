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

$rep = NewReport "eco-step-30-receipt-sharepack-captions"
$log = @()
$log += "# ECO — STEP 30 — ReceiptShareBar: share pack (legendas prontas p/ copiar)"
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

# detectar nome do prop/variável do código (default: code)
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

# 1) idempotência
$before = $txt
$txt = RemoveBlockByMarkers $txt "// ECO_STEP30_CAPTIONS_HELPERS_START" "// ECO_STEP30_CAPTIONS_HELPERS_END"
$txt = RemoveBlockByMarkers $txt "{/* ECO_STEP30_CAPTIONS_BUTTONS_START */}" "{/* ECO_STEP30_CAPTIONS_BUTTONS_END */}"
if($txt -ne $before){
  $log += "- OK: removi blocos antigos do STEP 30 (se existiam)."
}

# 2) helpers (top-level)
$helpers = @"
// ECO_STEP30_CAPTIONS_HELPERS_START
type Eco30ShareNav = Navigator & { share?: (data: ShareData) => Promise<void>; canShare?: (data: ShareData) => boolean };

function eco30_publicUrl(code: string) {
  return window.location.origin + "/r/" + encodeURIComponent(String(code));
}

function eco30_captionShort(code: string) {
  return "Bora de recibo? ✅ Recibo ECO confirmado — código: " + String(code);
}

function eco30_captionLong(code: string) {
  return (
    "✅ Recibo ECO confirmado\n" +
    "Código: " + String(code) + "\n" +
    "Isso é cuidado que vira prova: menos discurso, mais recibo.\n" +
    "ECO — Escutar • Cuidar • Organizar"
  );
}

function eco30_captionZap(code: string) {
  const url = eco30_publicUrl(code);
  return eco30_captionShort(code) + "\n" + url;
}

async function eco30_copyText(text: string) {
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

async function eco30_copyCaptionShort(code: string) {
  await eco30_copyText(eco30_captionShort(code));
}
async function eco30_copyCaptionLong(code: string) {
  await eco30_copyText(eco30_captionLong(code));
}
async function eco30_copyZap(code: string) {
  await eco30_copyText(eco30_captionZap(code));
}

async function eco30_shareText(code: string) {
  const url = eco30_publicUrl(code);
  const text = eco30_captionShort(code);
  const nav = navigator as Eco30ShareNav;
  const data: ShareData = { title: "Recibo ECO", text, url };
  if (nav.share && (!nav.canShare || nav.canShare(data))) {
    await nav.share(data);
    return;
  }
  await eco30_copyText(text + "\n" + url);
}
// ECO_STEP30_CAPTIONS_HELPERS_END
"@

$txt = InsertAfterLastImport $txt $helpers
$log += "- OK: injetei helpers do STEP 30 (top-level)."

# 3) botões: inserir após o STEP 29 se existir; senão tenta após STEP 28; senão cola no final do bloco
$buttons = @"
      {/* ECO_STEP30_CAPTIONS_BUTTONS_START */}
      <button type="button" onClick={() => eco30_copyCaptionShort($codeVar)} className="underline">Copiar legenda (curta)</button>
      <button type="button" onClick={() => eco30_copyCaptionLong($codeVar)} className="underline">Copiar legenda (longa)</button>
      <button type="button" onClick={() => eco30_copyZap($codeVar)} className="underline">Copiar (zap pronta)</button>
      <button type="button" onClick={() => eco30_shareText($codeVar)} className="underline">Compartilhar texto</button>
      {/* ECO_STEP30_CAPTIONS_BUTTONS_END */}
"@

$ins = InsertAfterMarker $txt "{/* ECO_STEP29_LINK_BUTTONS_END */}" ("`n" + $buttons)
if($ins.ok){
  $txt = $ins.txt
  $log += "- OK: inseri botões do STEP 30 após ECO_STEP29_LINK_BUTTONS_END."
} else {
  $ins2 = InsertAfterMarker $txt "{/* ECO_STEP28_BUTTONS_END */}" ("`n" + $buttons)
  if($ins2.ok){
    $txt = $ins2.txt
    $log += "- OK: inseri botões do STEP 30 após ECO_STEP28_BUTTONS_END."
  } else {
    # fallback: tenta achar um "Baixar card 3:4" e inserir logo depois do botão
    $needle = "Baixar card 3:4</button>"
    $idx = $txt.IndexOf($needle)
    if($idx -ge 0){
      $pos = $idx + $needle.Length
      $txt = $txt.Insert($pos, "`n" + $buttons)
      $log += "- OK: inseri botões do STEP 30 após 'Baixar card 3:4'."
    } else {
      $log += "- WARN: não achei âncora pra inserir botões do STEP 30. (helpers OK)"
      $log += "  DICA: confira o JSX do ReceiptShareBar e ancore manualmente perto dos botões de share."
    }
  }
}

WriteUtf8NoBom $shareComp $txt

$log += ""
$log += "## VERIFY"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1"
$log += "3) Abra /r/[code] e teste botões:"
$log += "   - Copiar legenda (curta / longa / zap pronta)"
$log += "   - Compartilhar texto (no celular/PWA: share sheet; no desktop: copia tudo)"
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")
Write-Host ("✅ STEP 30 aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) Teste /r/[code] (legendas/share pack)" -ForegroundColor Yellow