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

$rep = NewReport "eco-step-36f-day-card-1x1-buttons-and-webshare"
$log = @()
$log += "# ECO — STEP 36f — Card do dia: botões 1:1 + Web Share (fallback download)"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

$tri = "src/app/operador/triagem/OperatorTriageV2.tsx"
if(!(Test-Path -LiteralPath $tri)){
  $tri = FindFirst "." "\\src\\app\\operador\\triagem\\OperatorTriageV2\.tsx$"
}
if(!(Test-Path -LiteralPath $tri)){
  $log += "## ERRO"
  $log += "Não achei OperatorTriageV2.tsx"
  WriteUtf8NoBom $rep ($log -join "`n")
  throw "Não achei OperatorTriageV2.tsx"
}

$bk = BackupFile $tri
$txt = Get-Content -LiteralPath $tri -Raw

$log += "## DIAG"
$log += ("Arquivo: {0}" -f $tri)
$log += ("Backup : {0}" -f ($bk ? $bk : "(nenhum)"))
$log += ""

$log += "## PATCH"

# 1) Helpers: inserir onDayCard1x1 / onShareDayCard1x1 dentro do bloco STEP36 (se existir)
$start = $txt.IndexOf("ECO_STEP36_DAY_CARD_HELPERS_START")
$end   = $txt.IndexOf("ECO_STEP36_DAY_CARD_HELPERS_END")

if($start -ge 0 -and $end -ge 0 -and $end -gt $start){
  $blockLen = ($end - $start)
  $block = $txt.Substring($start, $blockLen)

  $need1 = ($block -notmatch "onDayCard1x1")
  $need2 = ($block -notmatch "onShareDayCard1x1")

  if(-not $need1 -and -not $need2){
    $log += "- INFO: helpers 1:1 já existem (skip)."
  } else {
    $insPos = $end
    $add = @"
  // ECO_STEP36F_DAY_CARD_1X1_START
  const onDayCard1x1 = () => {
    window.open(ecoDayCardUrl("1x1"), "_blank", "noopener,noreferrer");
  };

  const onShareDayCard1x1 = async () => {
    const card = ecoDayCardUrl("1x1");
    let res: Response | null = null;
    try { res = await fetch(card, { cache: "no-store" }); } catch { res = null; }
    if(!res || !res.ok){
      window.open(card, "_blank", "noopener,noreferrer");
      return;
    }
    const blob = await res.blob();
    const fileName = "eco-fechamento-" + String(routeDay) + "-1x1.png";
    const file = new File([blob], fileName, { type: "image/png" });

    const nav = navigator as ShareNav;
    const data: ShareData = { title: "ECO — Fechamento do dia", text: "ECO — Fechamento do dia " + String(routeDay), files: [file] };

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
  // ECO_STEP36F_DAY_CARD_1X1_END
"@

    # insere antes do END marker (mantém o bloco existente)
    $txt = $txt.Insert($insPos, "`n" + $add + "`n")
    $log += "- OK: helpers 1:1 inseridos no bloco STEP36."
  }
} else {
  $log += "- WARN: não achei bloco ECO_STEP36_DAY_CARD_HELPERS_* (skip helpers)."
}

# 2) UI: inserir botões 1:1 dentro do bloco UI STEP36 (se existir)
$uiStart = $txt.IndexOf("ECO_STEP36_DAY_CARD_UI_START")
$uiEnd   = $txt.IndexOf("ECO_STEP36_DAY_CARD_UI_END")

if($uiStart -ge 0 -and $uiEnd -ge 0 -and $uiEnd -gt $uiStart){
  $uiBlockLen = ($uiEnd - $uiStart)
  $uiBlock = $txt.Substring($uiStart, $uiBlockLen)

  if($uiBlock -match "1:1"){
    $log += "- INFO: botões 1:1 já existem (skip UI)."
  } else {
    $insPos = $uiEnd
    $uiAdd = @"
           <button type="button" onClick={onDayCard1x1} style={{ padding: '6px 10px' }}>Baixar card do dia (1:1)</button>
           <button type="button" onClick={onShareDayCard1x1} style={{ padding: '6px 10px' }}>Compartilhar card (1:1)</button>
"@
    $txt = $txt.Insert($insPos, "`n" + $uiAdd)
    $log += "- OK: botões 1:1 inseridos no painel do fechamento."
  }
} else {
  $log += "- WARN: não achei bloco ECO_STEP36_DAY_CARD_UI_* (skip UI)."
}

WriteUtf8NoBom $tri $txt
$log += "- OK: arquivo atualizado."

$log += ""
$log += "## VERIFY"
$log += "1) Teste API:"
$log += "   - /api/share/route-day-card?day=2025-12-26&format=3x4"
$log += "   - /api/share/route-day-card?day=2025-12-26&format=1x1"
$log += "2) Teste UI:"
$log += "   - /operador/triagem -> Fechamento do dia -> botões 3:4 e 1:1 (download/share)"
$log += "3) Rode o smoke (se você tiver ele estável): pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1"
WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 36f aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Teste /api/share/route-day-card?day=2025-12-26&format=1x1" -ForegroundColor Yellow
Write-Host "2) Teste /operador/triagem (Fechamento do dia: botões 1:1)" -ForegroundColor Yellow