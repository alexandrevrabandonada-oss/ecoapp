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
  $i = $txt.IndexOf($startMarker)
  if($i -lt 0){ return $txt }
  $j = $txt.IndexOf($endMarker, $i)
  if($j -lt 0){ return $txt }
  $j2 = $j + $endMarker.Length
  if($j2 -lt $txt.Length -and $txt[$j2] -eq "`r"){ $j2++ }
  if($j2 -lt $txt.Length -and $txt[$j2] -eq "`n"){ $j2++ }
  return $txt.Remove($i, $j2 - $i)
}

$rep = NewReport "eco-step-28c-receipt-sharebar-webshare-safe"
$log = @()
$log += "# ECO — STEP 28c — ReceiptShareBar: Baixar 1:1 + Web Share (imagem) + Copiar/Compartilhar link (SAFE)"
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
if($null -eq $txt){ $txt = "" }

$log += "## PATCH"
$log += ("Backup: {0}" -f $bk)

# 1) limpar quaisquer blocos antigos (idempotente)
$start = "// ECO_STEP28_SHARE_HELPERS_START"
$end   = "// ECO_STEP28_SHARE_HELPERS_END"
$beforeLen = $txt.Length
$txt = RemoveBlockByMarkers $txt $start $end
$afterLen = $txt.Length
if($afterLen -ne $beforeLen){
  $log += ("- OK: removi bloco antigo de helpers (len {0} -> {1})." -f $beforeLen, $afterLen)
} else {
  $log += "- INFO: nenhum bloco antigo de helpers encontrado."
}

# 2) inserir helpers limpos (após 'use client' se existir, senão após imports)
$helpers = @"
$start
type EcoCardFormat = "3x4" | "1x1";
type ShareNav = Navigator & { share?: (data: ShareData) => Promise<void>; canShare?: (data: ShareData) => boolean };

const ecoReceiptCodeFromPath = () => {
  if (typeof window === "undefined") return "";
  const parts = window.location.pathname.split("/").filter(Boolean);
  return decodeURIComponent(parts[parts.length - 1] ?? "");
};

const ecoReceiptCardUrl = (fmt: EcoCardFormat) => {
  const c = encodeURIComponent(ecoReceiptCodeFromPath());
  return "/api/share/receipt-card?code=" + c + "&format=" + fmt;
};

const ecoReceiptDownloadCard = (fmt: EcoCardFormat) => {
  const url = ecoReceiptCardUrl(fmt);
  window.open(url, "_blank", "noopener,noreferrer");
};

const ecoReceiptCopyLink = async () => {
  const link = (typeof window !== "undefined") ? window.location.href : "";
  if (!link) return;
  try {
    await navigator.clipboard.writeText(link);
    return;
  } catch {
    // fallback textarea
    try {
      const ta = document.createElement("textarea");
      ta.value = link;
      ta.setAttribute("readonly", "true");
      ta.style.position = "absolute";
      ta.style.left = "-9999px";
      document.body.appendChild(ta);
      ta.select();
      document.execCommand("copy");
      ta.remove();
    } catch { }
  }
};

const ecoReceiptShareLink = async () => {
  const link = (typeof window !== "undefined") ? window.location.href : "";
  const nav = navigator as ShareNav;
  if (nav.share) {
    try {
      await nav.share({ title: "Recibo ECO", text: "Recibo ECO", url: link });
      return;
    } catch { }
  }
  await ecoReceiptCopyLink();
};

const ecoReceiptShareCard = async (fmt: EcoCardFormat) => {
  const card = ecoReceiptCardUrl(fmt);

  let res: Response | null = null;
  try {
    res = await fetch(card, { cache: "no-store" });
  } catch {
    res = null;
  }

  if (!res || !res.ok) {
    window.open(card, "_blank", "noopener,noreferrer");
    return;
  }

  const blob = await res.blob();
  const code = ecoReceiptCodeFromPath() || "sem-codigo";
  const fileName = "recibo-eco-" + String(code) + "-" + fmt + ".png";
  const file = new File([blob], fileName, { type: "image/png" });

  const nav = navigator as ShareNav;
  const data: ShareData = { title: "Recibo ECO", text: "Recibo ECO: " + String(code), files: [file] };

  if (nav.share && (!nav.canShare || nav.canShare(data))) {
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
$end
"@

$inserted = $false

$idxUseClient = $txt.IndexOf("'use client'")
if($idxUseClient -lt 0){ $idxUseClient = $txt.IndexOf('"use client"') }

if($idxUseClient -ge 0){
  $idxNL = $txt.IndexOf("`n", $idxUseClient)
  if($idxNL -gt 0){
    $txt = $txt.Insert($idxNL + 1, "`n" + $helpers + "`n")
    $inserted = $true
    $log += "- OK: helpers inseridos após 'use client'."
  }
}

if(-not $inserted){
  $mImp = [regex]::Matches($txt, '^\s*import\s+.*?;\s*$', 'Multiline')
  $insAt = 0
  if($mImp.Count -gt 0){
    $last = $mImp[$mImp.Count-1]
    $insAt = $last.Index + $last.Length
  }
  $txt = $txt.Insert($insAt, "`n`n" + $helpers + "`n")
  $log += "- OK: helpers inseridos após imports (fallback)."
}

# 3) inserir botões (idempotente)
if($txt -match "Baixar card 1:1"){
  $log += "- INFO: botão 'Baixar card 1:1' já existe (skip)."
} else {
  $needle = "Baixar card 3:4"
  $idx = $txt.IndexOf($needle)
  if($idx -ge 0){
    $idxClose = $txt.IndexOf("</button>", $idx)
    if($idxClose -ge 0){
      $pos = $idxClose + "</button>".Length
      $buttons = @"
`n      <button type="button" onClick={() => ecoReceiptDownloadCard("1x1")} className="underline">Baixar card 1:1</button>
      <button type="button" onClick={() => ecoReceiptShareCard("3x4")} className="underline">Compartilhar 3:4</button>
      <button type="button" onClick={() => ecoReceiptShareCard("1x1")} className="underline">Compartilhar 1:1</button>
      <button type="button" onClick={ecoReceiptCopyLink} className="underline">Copiar link</button>
      <button type="button" onClick={ecoReceiptShareLink} className="underline">Compartilhar link</button>
"@
      $txt = $txt.Insert($pos, $buttons)
      $log += "- OK: botões (1:1/share/link) inseridos após 'Baixar card 3:4'."
    } else {
      $log += "- WARN: achei o texto 'Baixar card 3:4', mas não encontrei </button> para ancorar."
    }
  } else {
    $log += "- WARN: não achei 'Baixar card 3:4' no JSX; não injetei botões."
  }
}

WriteUtf8NoBom $shareComp $txt

$log += ""
$log += "## VERIFY"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1"
$log += "3) Abra a página do recibo (/r/[code]) e teste:"
$log += "   - Baixar card 3:4 e 1:1"
$log += "   - Compartilhar 3:4 e 1:1 (no celular/PWA abre share sheet; senão faz download)"
$log += "   - Copiar link / Compartilhar link"

WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 28c aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) Teste /r/[code] (download/share/link)" -ForegroundColor Yellow