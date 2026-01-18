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

function RemoveMarkedBlock([string]$txt, [string]$start, [string]$end){
  if([string]::IsNullOrEmpty($txt)){ return $txt }
  $ps = [regex]::Escape($start)
  $pe = [regex]::Escape($end)
  $pat = "(?s)$ps.*?$pe\s*"
  return [regex]::Replace($txt, $pat, "")
}

$rep = NewReport "eco-step-28c-receipt-share-webshare-and-1x1-safe2"
$log = @()
$log += "# ECO — STEP 28c — Web Share (PNG) + Baixar 1:1 (ReceiptShareBar) — SAFE v2"
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
if($null -eq $txt){ $txt = "" }

$log += "## DIAG"
$log += ("Arquivo: {0}" -f $shareComp)
$log += ("Backup : {0}" -f $bk)
$log += ""

# endpoint default (não vou assumir outro sem ver)
$endpoint = "/api/share/receipt-card"
$log += ("Endpoint card: {0}" -f $endpoint)
$log += ""

$log += "## PATCH"

# 0) cleanup blocos antigos (idempotente)
$beforeLen = $txt.Length
$txt2 = $txt
$txt2 = RemoveMarkedBlock $txt2 "// ECO_STEP28_SHARE_HELPERS_START" "// ECO_STEP28_SHARE_HELPERS_END"
$txt2 = RemoveMarkedBlock $txt2 "{/* ECO_STEP28_SHARE_BUTTONS_START */}" "{/* ECO_STEP28_SHARE_BUTTONS_END */}"

if($txt2 -ne $txt){
  $log += "- OK: removi blocos STEP28 antigos (se existiam)."
  $txt = $txt2
} else {
  $log += "- INFO: nenhum bloco STEP28 antigo encontrado."
}
$log += ("- len: {0} -> {1}" -f $beforeLen, $txt.Length)

# 1) inserir helpers
if($txt -notmatch "ECO_STEP28_SHARE_HELPERS_START"){
  $helpers = @"
  // ECO_STEP28_SHARE_HELPERS_START
  type __EcoCardFormat28 = "3x4" | "1x1";
  type __EcoShareNav28 = Navigator & { share?: (data: any) => Promise<void>; canShare?: (data: any) => boolean };

  const __ecoCardUrl28 = (fmt: __EcoCardFormat28) => {
    const c = encodeURIComponent(String(code));
    return "$endpoint?code=" + c + "&format=" + fmt;
  };

  const __ecoDownloadCard28 = (fmt: __EcoCardFormat28) => {
    const u = __ecoCardUrl28(fmt);
    window.open(u, "_blank", "noopener,noreferrer");
  };

  const __ecoShareCard28 = async (fmt: __EcoCardFormat28) => {
    const u = __ecoCardUrl28(fmt);

    let res: Response | null = null;
    try { res = await fetch(u, { cache: "no-store" }); } catch { res = null; }

    if(!res || !res.ok){
      window.open(u, "_blank", "noopener,noreferrer");
      return;
    }

    const blob = await res.blob();
    const fileName = "recibo-eco-" + String(code) + "-" + fmt + ".png";
    const file = new File([blob], fileName, { type: "image/png" });

    const nav = navigator as __EcoShareNav28;
    const data: any = { title: "Recibo ECO", text: "Recibo ECO: " + String(code), files: [file] };

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
  // ECO_STEP28_SHARE_HELPERS_END
"@

  $insAt = -1

  $reOnCard3 = [regex]::new("const\s+onCard3x4\s*=\s*\(\)\s*=>\s*\{[\s\S]*?\};", [System.Text.RegularExpressions.RegexOptions]::Multiline)
  $m3 = $reOnCard3.Match($txt)
  if($m3.Success){ $insAt = $m3.Index + $m3.Length }

  if($insAt -lt 0){
    $reOnWa = [regex]::new("const\s+onWhatsApp\s*=\s*\(\)\s*=>\s*\{[\s\S]*?\};", [System.Text.RegularExpressions.RegexOptions]::Multiline)
    $mwa = $reOnWa.Match($txt)
    if($mwa.Success){ $insAt = $mwa.Index + $mwa.Length }
  }

  if($insAt -lt 0){
    $idx = $txt.IndexOf("'use client'")
    if($idx -ge 0){
      $idxNL = $txt.IndexOf("`n", $idx)
      if($idxNL -gt 0){ $insAt = $idxNL + 1 }
    }
  }

  if($insAt -lt 0){ $insAt = 0 }

  $txt = $txt.Insert($insAt, "`n`n" + $helpers + "`n")
  $log += "- OK: helpers WebShare/1:1 inseridos."
} else {
  $log += "- INFO: helpers STEP28 já existem (skip)."
}

# 2) inserir botões logo após o botão 3:4 (procura 'Baixar card 3:4' e fecha </button>)
if($txt -notmatch "ECO_STEP28_SHARE_BUTTONS_START"){
  $idxLabel = $txt.IndexOf("Baixar card 3:4")
  if($idxLabel -ge 0){
    $idxClose = $txt.IndexOf("</button>", $idxLabel)
    if($idxClose -ge 0){
      $insertPos = $idxClose + "</button>".Length
      $buttons = @"
      {/* ECO_STEP28_SHARE_BUTTONS_START */}
      <button type="button" onClick={() => __ecoDownloadCard28("1x1")} className="underline">Baixar card 1:1</button>
      <button type="button" onClick={() => __ecoShareCard28("3x4")} className="underline">Compartilhar 3:4</button>
      <button type="button" onClick={() => __ecoShareCard28("1x1")} className="underline">Compartilhar 1:1</button>
      {/* ECO_STEP28_SHARE_BUTTONS_END */}
"@
      $txt = $txt.Insert($insertPos, "`n" + $buttons)
      $log += "- OK: botões 1:1 + compartilhar inseridos."
    } else {
      $log += "- WARN: achei 'Baixar card 3:4' mas não achei o </button> depois. Não inseri botões."
    }
  } else {
    $log += "- WARN: não achei o texto 'Baixar card 3:4' no componente. Não inseri botões."
  }
} else {
  $log += "- INFO: botões STEP28 já existem (skip)."
}

WriteUtf8NoBom $shareComp $txt

$log += ""
$log += "## VERIFY"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1"
$log += "3) Abra /r/[code] e teste:"
$log += "   - Baixar card 3:4 / 1:1"
$log += "   - Compartilhar 3:4 / 1:1 (celular/PWA abre share sheet; desktop baixa)"

WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 28c aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) Teste /r/[code] (Baixar 1:1 + Compartilhar)" -ForegroundColor Yellow