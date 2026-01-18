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

$rep = NewReport "eco-step-29-receipt-sharepack-text-and-preview"
$log = @()
$log += "# ECO — STEP 29 — Share Pack v0 (texto pronto + preview 1:1) no ReceiptShareBar"
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

# 1) remover helper block antigo do STEP 29 (idempotente)
$hs = "// ECO_STEP29_SHAREPACK_HELPERS_START"
$he = "// ECO_STEP29_SHAREPACK_HELPERS_END"
$len0 = $txt.Length
$txt = RemoveBlockByMarkers $txt $hs $he
$len1 = $txt.Length
if($len1 -ne $len0){ $log += ("- OK: removi helpers STEP29 antigos (len {0}->{1})." -f $len0, $len1) } else { $log += "- INFO: helpers STEP29 não existiam." }

# 2) reinjetar helpers STEP29 depois do bloco STEP28 (ou após 'use client')
$helpers = @"
$hs
const ecoReceiptShareText = () => {
  const code = (typeof window !== "undefined") ? (window.location.pathname.split("/").filter(Boolean).pop() ?? "") : "";
  const link = (typeof window !== "undefined") ? window.location.href : "";
  const c = decodeURIComponent(String(code || "").trim());
  const l = String(link || "").trim();

  // texto curtinho e militante/convocatório, sem exagero
  const line1 = "Bora de recibo? 🌱♻️";
  const line2 = c ? ("Meu Recibo ECO: " + c) : "Meu Recibo ECO";
  const line3 = l ? ("Veja aqui: " + l) : "";
  const line4 = "#ECO #ReciboECO";

  return [line1, line2, line3, line4].filter(Boolean).join("\n");
};

const ecoReceiptCopyText = async () => {
  const t = ecoReceiptShareText();
  if (!t) return;
  try {
    await navigator.clipboard.writeText(t);
    return;
  } catch {
    try {
      const ta = document.createElement("textarea");
      ta.value = t;
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

const ecoReceiptOpenWhatsApp = () => {
  const t = ecoReceiptShareText();
  const url = "https://wa.me/?text=" + encodeURIComponent(t);
  window.open(url, "_blank", "noopener,noreferrer");
};
$he
"@

$insertAt = -1
$idx28end = $txt.IndexOf("// ECO_STEP28_SHARE_HELPERS_END")
if($idx28end -ge 0){
  $idxNL = $txt.IndexOf("`n", $idx28end)
  if($idxNL -gt 0){ $insertAt = $idxNL + 1 }
}
if($insertAt -lt 0){
  $idxUse = $txt.IndexOf("'use client'")
  if($idxUse -lt 0){ $idxUse = $txt.IndexOf('"use client"') }
  if($idxUse -ge 0){
    $idxNL2 = $txt.IndexOf("`n", $idxUse)
    if($idxNL2 -gt 0){ $insertAt = $idxNL2 + 1 }
  }
}
if($insertAt -lt 0){ $insertAt = 0 }

$txt = $txt.Insert($insertAt, "`n" + $helpers + "`n")
$log += "- OK: helpers STEP29 inseridos."

# 3) remover UI antiga do STEP 29 (idempotente)
$us = "{/* ECO_STEP29_SHAREPACK_UI_START */}"
$ue = "{/* ECO_STEP29_SHAREPACK_UI_END */}"
$len2 = $txt.Length
$txt = RemoveBlockByMarkers $txt $us $ue
$len3 = $txt.Length
if($len3 -ne $len2){ $log += ("- OK: removi UI STEP29 antiga (len {0}->{1})." -f $len2, $len3) } else { $log += "- INFO: UI STEP29 não existia." }

# 4) inserir UI após o bloco de botões (ancora no "Compartilhar link</button>" do STEP 28c)
$anchor = "Compartilhar link</button>"
$idxA = $txt.IndexOf($anchor)
if($idxA -ge 0){
  $pos = $idxA + $anchor.Length
  $ui = @"
`n      $us
      <div className="mt-3 flex flex-col gap-2">
        <div className="text-xs opacity-80">Preview 1:1</div>
        <a href={ecoReceiptCardUrl("1x1")} target="_blank" rel="noreferrer noopener" className="inline-block">
          <img
            src={ecoReceiptCardUrl("1x1")}
            alt="Card 1:1 do recibo"
            className="w-40 max-w-full rounded border"
          />
        </a>

        <div className="text-xs opacity-80">Mensagem pronta</div>
        <textarea
          readOnly
          value={ecoReceiptShareText()}
          className="w-full rounded border p-2 text-xs bg-transparent"
          rows={4}
        />

        <div className="flex flex-wrap gap-2">
          <button type="button" onClick={ecoReceiptCopyText} className="underline">Copiar texto</button>
          <button type="button" onClick={ecoReceiptOpenWhatsApp} className="underline">WhatsApp</button>
        </div>
      </div>
      $ue
"@
  $txt = $txt.Insert($pos, $ui)
  $log += "- OK: UI STEP29 inserida após 'Compartilhar link'."
} else {
  $log += "- WARN: não achei âncora 'Compartilhar link</button>' para inserir UI. (Se os botões do STEP 28c não existem, rode o 28c antes.)"
}

WriteUtf8NoBom $shareComp $txt

$log += ""
$log += "## VERIFY"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1"
$log += "3) Abra /r/[code] e teste:"
$log += "   - Preview 1:1 aparece"
$log += "   - Copiar texto"
$log += "   - WhatsApp abre com texto preenchido"
$log += "   - Compartilhar 3:4/1:1 continua funcionando"

WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 29 aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) Teste /r/[code] (preview + texto + WhatsApp)" -ForegroundColor Yellow