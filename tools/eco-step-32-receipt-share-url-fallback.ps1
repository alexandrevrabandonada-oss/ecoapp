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
function InsertAfterMarker([string]$txt, [string]$marker, [string]$insert){
  $idx = $txt.IndexOf($marker)
  if($idx -lt 0){ return @{ ok=$false; txt=$txt } }
  $idxNL = $txt.IndexOf("`n", $idx)
  if($idxNL -lt 0){ return @{ ok=$false; txt=$txt } }
  $out = $txt.Insert($idxNL + 1, $insert)
  return @{ ok=$true; txt=$out }
}

$rep = NewReport "eco-step-32-receipt-share-url-fallback"
$log = @()
$log += "# ECO — STEP 32 — ReceiptShareBar: WebShare com URL fallback + botões link"
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

# 1) limpar blocos STEP32 antigos (idempotente)
$before = $txt
$txt = RemoveBlockByMarkers $txt "// ECO_STEP32_LINK_HELPERS_START" "// ECO_STEP32_LINK_HELPERS_END"
if($txt -ne $before){ $log += "- OK: removi bloco antigo STEP32 (link helpers), se existia." }

$before2 = $txt
$txt = RemoveBlockByMarkers $txt "// ECO_STEP32_SHARECARD_REPLACE_START" "// ECO_STEP32_SHARECARD_REPLACE_END"
if($txt -ne $before2){ $log += "- OK: removi bloco antigo STEP32 (sharecard replace), se existia." }

# 2) inserir helpers de link (precisa do ecoToast do STEP31; se não existir, ainda compila sem toast? aqui assume STEP31 já existe)
$linkHelpers = @"
// ECO_STEP32_LINK_HELPERS_START
  const ecoReceiptUrl = () => {
    const c = encodeURIComponent(String($codeVar));
    return window.location.origin + "/r/" + c;
  };

  const eco32_copyLink = async () => {
    const u = ecoReceiptUrl();
    try {
      await navigator.clipboard.writeText(u);
      if (typeof ecoToast === "function") ecoToast("Link copiado!");
    } catch {
      // fallback bem simples
      window.prompt("Copie o link do recibo:", u);
      if (typeof ecoToast === "function") ecoToast("Link pronto!");
    }
  };

  const eco32_shareLink = async () => {
    const u = ecoReceiptUrl();
    const nav: any = navigator as any;
    const data: ShareData = { title: "Recibo ECO", text: "Recibo ECO: " + String($codeVar), url: u };
    if (nav.share && (!nav.canShare || nav.canShare(data))) {
      await nav.share(data);
      if (typeof ecoToast === "function") ecoToast("Compartilhado!");
      return;
    }
    await eco32_copyLink();
  };
// ECO_STEP32_LINK_HELPERS_END
"@

# ancora: logo após ECO_STEP31_TOAST_STATE_END (melhor ponto)
$ins1 = InsertAfterMarker $txt "// ECO_STEP31_TOAST_STATE_END" ("`n" + $linkHelpers + "`n")
if($ins1.ok){
  $txt = $ins1.txt
  $log += "- OK: inseri helpers de link após STEP31_TOAST_STATE_END."
} else {
  $log += "- WARN: não achei âncora STEP31_TOAST_STATE_END; não inseri helpers de link."
}

# 3) substituir ecoShareCard para incluir URL fallback (apenas se ecoShareCard existir)
$reShare = [regex]::new("const\s+ecoShareCard\s*=\s*async\s*\(\s*fmt\s*:\s*EcoCardFormat\s*\)\s*=>\s*\{[\s\S]*?\};", "Multiline")
$ms = $reShare.Match($txt)

if($ms.Success){
  $replacement = @"
// ECO_STEP32_SHARECARD_REPLACE_START
  const ecoShareCard = async (fmt: EcoCardFormat) => {
    const card = ecoCardUrl(fmt);
    const shareUrl = (typeof ecoReceiptUrl === "function") ? ecoReceiptUrl() : "";

    // tenta pegar como blob pra Web Share / download com nome
    let res: Response | null = null;
    try {
      res = await fetch(card, { cache: "no-store" });
    } catch {
      res = null;
    }

    if(!res || !res.ok){
      // se não deu pra baixar o PNG, ao menos compartilha o link do recibo
      const nav: any = navigator as any;
      const dataUrl: ShareData = { title: "Recibo ECO", text: "Recibo ECO: " + String($codeVar), url: shareUrl };
      if(nav.share && shareUrl && (!nav.canShare || nav.canShare(dataUrl))){
        await nav.share(dataUrl);
        if (typeof ecoToast === "function") ecoToast("Compartilhado!");
        return;
      }
      window.open(card, "_blank", "noopener,noreferrer");
      return;
    }

    const blob = await res.blob();
    const fileName = "recibo-eco-" + String($codeVar) + "-" + fmt + ".png";
    const file = new File([blob], fileName, { type: "image/png" });

    const nav: any = navigator as any;

    const dataFiles: ShareData = {
      title: "Recibo ECO",
      text: "Recibo ECO: " + String($codeVar),
      url: shareUrl || undefined,
      files: [file],
    };

    const dataUrl: ShareData = {
      title: "Recibo ECO",
      text: "Recibo ECO: " + String($codeVar),
      url: shareUrl,
    };

    // 1) tenta share com arquivo
    if(nav.share){
      if(!nav.canShare || nav.canShare(dataFiles)){
        try {
          await nav.share(dataFiles);
          if (typeof ecoToast === "function") ecoToast("Compartilhado!");
          return;
        } catch {
          # noop -> tenta share só com url
        }
      }
      // 2) fallback: share só com URL
      if(shareUrl && (!nav.canShare || nav.canShare(dataUrl))){
        await nav.share(dataUrl);
        if (typeof ecoToast === "function") ecoToast("Compartilhado!");
        return;
      }
    }

    // 3) fallback final: download do PNG
    const a = document.createElement("a");
    const obj = URL.createObjectURL(blob);
    a.href = obj;
    a.download = fileName;
    document.body.appendChild(a);
    a.click();
    a.remove();
    setTimeout(() => URL.revokeObjectURL(obj), 1200);
  };
// ECO_STEP32_SHARECARD_REPLACE_END
"@
  $txt = $reShare.Replace($txt, $replacement, 1)
  $log += "- OK: ecoShareCard atualizado (file share -> url share -> download)."
} else {
  $log += "- WARN: não achei ecoShareCard(fmt) para atualizar (skip)."
}

# 4) inserir botões de link (idempotente)
if($txt -match "Copiar link"){
  $log += "- INFO: botões de link já existem (skip)."
} else {
  # ancorar após "Baixar card 1:1" se existir; senão após "Baixar card 3:4"
  $needle1 = "Baixar card 1:1</button>"
  $needle2 = "Baixar card 3:4</button>"
  $idx = $txt.IndexOf($needle1)
  if($idx -lt 0){ $idx = $txt.IndexOf($needle2) }
  if($idx -ge 0){
    $pos = $idx + (($idx -eq $txt.IndexOf($needle1)) ? $needle1.Length : $needle2.Length)
    $btns = @"
      <button type="button" onClick={eco32_copyLink} className="underline">Copiar link</button>
      <button type="button" onClick={eco32_shareLink} className="underline">Compartilhar link</button>
"@
    $txt = $txt.Insert($pos, "`n" + $btns)
    $log += "- OK: inseri botões Copiar link + Compartilhar link."
  } else {
    $log += "- WARN: não achei botão Baixar card para ancorar (skip botões link)."
  }
}

WriteUtf8NoBom $shareComp $txt

$log += ""
$log += "## VERIFY"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1"
$log += "3) Abra /r/[code] e teste:"
$log += "   - Copiar link (toast) + colar em outro lugar"
$log += "   - Compartilhar link (abre share sheet quando suportado)"
$log += "   - Compartilhar 3:4/1:1: se não suportar files, deve compartilhar URL do recibo"
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")
Write-Host ("✅ STEP 32 aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) Teste /r/[code] (link + share fallback)" -ForegroundColor Yellow