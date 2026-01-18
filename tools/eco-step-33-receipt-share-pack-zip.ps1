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

$rep = NewReport "eco-step-33-receipt-share-pack-zip"
$log = @()
$log += "# ECO — STEP 33 — Share Pack (ZIP) do Recibo (3x4 + 1x1 + textos)"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

# --- DIAG: localizar componente ---
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

# --- DIAG: package.json ---
$pkg = "package.json"
if(!(Test-Path -LiteralPath $pkg)){
  $pkg = FindFirst "." "\\package\.json$"
}

$log += "## DIAG"
$log += ("ReceiptShareBar: {0}" -f $shareComp)
$log += ("package.json   : {0}" -f ($pkg ? $pkg : "(não achei)"))
$log += ""

$log += "## PATCH"

# 1) garantir dependência jszip
$installed = $false
if($pkg -and (Test-Path -LiteralPath $pkg)){
  $pkgTxt = Get-Content -LiteralPath $pkg -Raw
  if($pkgTxt -match '"jszip"\s*:'){ $installed = $true }
}
if(!$installed){
  $log += "- INFO: jszip não encontrado no package.json -> npm i jszip"
  npm i jszip | Out-Null
  $log += "- OK: npm i jszip"
} else {
  $log += "- OK: jszip já estava instalado."
}

# 2) criar/atualizar API route /api/share/receipt-pack
$routeDir = "src/app/api/share/receipt-pack"
$routeFile = Join-Path $routeDir "route.ts"
EnsureDir $routeDir
if(Test-Path -LiteralPath $routeFile){ $log += ("- Backup route: {0}" -f (BackupFile $routeFile)) }

$routeTs = @"
import JSZip from "jszip";
import { NextResponse } from "next/server";

export const runtime = "nodejs";

export async function GET(req: Request) {
  const url = new URL(req.url);
  const code = (url.searchParams.get("code") ?? "").trim();

  if (!code) {
    return NextResponse.json({ error: "missing code" }, { status: 400 });
  }

  const origin = url.origin;
  const enc = encodeURIComponent(code);

  const card3 = origin + "/api/share/receipt-card?code=" + enc + "&format=3x4";
  const card1 = origin + "/api/share/receipt-card?code=" + enc + "&format=1x1";
  const publicUrl = origin + "/r/" + enc;

  const [r3, r1] = await Promise.all([
    fetch(card3, { cache: "no-store" }),
    fetch(card1, { cache: "no-store" }),
  ]);

  if (!r3.ok || !r1.ok) {
    return NextResponse.json(
      { error: "failed to render cards", ok3: r3.ok, ok1: r1.ok },
      { status: 500 }
    );
  }

  const b3 = await r3.arrayBuffer();
  const b1 = await r1.arrayBuffer();

  const captionShort =
    "Recibo ECO #" + code + "\n" +
    "Escutar • Cuidar • Organizar\n" +
    "Acesse e compartilhe: " + publicUrl;

  const captionLong =
    "Recibo ECO #" + code + "\n\n" +
    "Isso aqui é prova de cuidado, não é 'like'.\n" +
    "Recibo é transparência: mostra a ação, ajuda a organizar o bairro e fortalece a cooperativa.\n\n" +
    "Link público do recibo:\n" + publicUrl + "\n\n" +
    "#ECO #ReciboECO #EscutarCuidarOrganizar";

  const zap =
    "Bora de recibo? ♻️\n" +
    "Aqui tá o meu Recibo ECO #" + code + ":\n" +
    publicUrl;

  const meta = {
    code,
    publicUrl,
    generatedAt: new Date().toISOString(),
    files: [
      "recibo-eco-" + code + "-3x4.png",
      "recibo-eco-" + code + "-1x1.png",
      "caption.txt",
      "caption-long.txt",
      "zap.txt",
      "meta.json",
    ],
  };

  const zip = new JSZip();
  zip.file("recibo-eco-" + code + "-3x4.png", b3);
  zip.file("recibo-eco-" + code + "-1x1.png", b1);
  zip.file("caption.txt", captionShort);
  zip.file("caption-long.txt", captionLong);
  zip.file("zap.txt", zap);
  zip.file("meta.json", JSON.stringify(meta, null, 2));

  const out = await zip.generateAsync({ type: "nodebuffer", compression: "DEFLATE" });

  return new NextResponse(out, {
    headers: {
      "Content-Type": "application/zip",
      "Content-Disposition": 'attachment; filename="eco-share-pack-' + code + '.zip"',
      "Cache-Control": "no-store",
    },
  });
}
"@

WriteUtf8NoBom $routeFile $routeTs
$log += ("- OK: criado/atualizado {0}" -f $routeFile)

# 3) patch ReceiptShareBar: helper + botão "Baixar pack (ZIP)"
$bkComp = BackupFile $shareComp
$txt = Get-Content -LiteralPath $shareComp -Raw

$log += ("- Backup ReceiptShareBar: {0}" -f $bkComp)

# descobrir variável do code no componente (default: code)
$codeVar = "code"
$m = [regex]::Match($txt, "ReceiptShareBar\s*\(\s*\{\s*([A-Za-z_][A-Za-z0-9_]*)", "IgnoreCase")
if($m.Success){ $codeVar = $m.Groups[1].Value }

# limpar bloco STEP33 antigo (idempotente)
$txt2 = RemoveBlockByMarkers $txt "// ECO_STEP33_PACK_HELPERS_START" "// ECO_STEP33_PACK_HELPERS_END"
if($txt2 -ne $txt){
  $txt = $txt2
  $log += "- OK: removi bloco antigo STEP33 (se existia)."
}

$helpers = @"
// ECO_STEP33_PACK_HELPERS_START
  const eco33_packUrl = () => {
    const c = encodeURIComponent(String($codeVar));
    return "/api/share/receipt-pack?code=" + c;
  };

  const eco33_downloadPack = async () => {
    const u = eco33_packUrl();
    let res: Response | null = null;
    try {
      res = await fetch(u, { cache: "no-store" });
    } catch {
      res = null;
    }

    if (!res || !res.ok) {
      // fallback: abre em nova aba
      window.open(u, "_blank", "noopener,noreferrer");
      return;
    }

    const blob = await res.blob();
    const fileName = "eco-share-pack-" + String($codeVar) + ".zip";

    const a = document.createElement("a");
    const obj = URL.createObjectURL(blob);
    a.href = obj;
    a.download = fileName;
    document.body.appendChild(a);
    a.click();
    a.remove();
    setTimeout(() => URL.revokeObjectURL(obj), 1200);

    if (typeof ecoToast === "function") ecoToast("Pack baixado!");
  };
// ECO_STEP33_PACK_HELPERS_END
"@

# inserir helpers após STEP32_LINK_HELPERS_END (melhor), senão após STEP31_TOAST_STATE_END, senão após 'use client'
$inserted = $false
$ins = InsertAfterMarker $txt "// ECO_STEP32_LINK_HELPERS_END" ("`n" + $helpers + "`n")
if($ins.ok){
  $txt = $ins.txt
  $inserted = $true
  $log += "- OK: helpers STEP33 inseridos após STEP32_LINK_HELPERS_END."
}
if(!$inserted){
  $ins = InsertAfterMarker $txt "// ECO_STEP31_TOAST_STATE_END" ("`n" + $helpers + "`n")
  if($ins.ok){
    $txt = $ins.txt
    $inserted = $true
    $log += "- OK: helpers STEP33 inseridos após STEP31_TOAST_STATE_END."
  }
}
if(!$inserted){
  $idx = $txt.IndexOf("'use client'")
  if($idx -ge 0){
    $idxNL = $txt.IndexOf("`n", $idx)
    if($idxNL -gt 0){
      $txt = $txt.Insert($idxNL+1, "`n" + $helpers + "`n")
      $inserted = $true
      $log += "- OK: helpers STEP33 inseridos após 'use client' (fallback)."
    }
  }
}
if(!$inserted){
  $txt = $helpers + "`n" + $txt
  $log += "- OK: helpers STEP33 inseridos no topo (fallback)."
}

# inserir botão (idempotente)
if($txt -match "Baixar pack"){
  $log += "- INFO: botão 'Baixar pack' já existe (skip)."
} else {
  $needle = "Compartilhar link</button>"
  $idxB = $txt.IndexOf($needle)
  if($idxB -lt 0){
    $needle = "Baixar card 1:1</button>"
    $idxB = $txt.IndexOf($needle)
  }
  if($idxB -lt 0){
    $needle = "Baixar card 3:4</button>"
    $idxB = $txt.IndexOf($needle)
  }

  if($idxB -ge 0){
    $pos = $idxB + $needle.Length
    $btn = @"
      <button type="button" onClick={eco33_downloadPack} className="underline">Baixar pack (ZIP)</button>
"@
    $txt = $txt.Insert($pos, "`n" + $btn)
    $log += "- OK: inseri botão 'Baixar pack (ZIP)'."
  } else {
    $log += "- WARN: não achei âncora de botões para inserir 'Baixar pack (ZIP)'."
  }
}

WriteUtf8NoBom $shareComp $txt

$log += ""
$log += "## VERIFY"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1"
$log += "3) Teste manual:"
$log += "   - Abra /r/[code]"
$log += "   - Clique 'Baixar pack (ZIP)' e confira o zip (2 PNG + textos)"
$log += "   - (Opcional) abra /api/share/receipt-pack?code=[code] direto e veja se baixa"
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 33 aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) Teste /r/[code] -> Baixar pack (ZIP)" -ForegroundColor Yellow