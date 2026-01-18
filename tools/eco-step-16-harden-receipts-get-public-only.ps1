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
  $f = Get-ChildItem -Recurse -File -Path $root -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -match $pattern } |
    Select-Object -First 1
  if($f){ return $f.FullName }
  return $null
}

$rep = NewReport "eco-step-16-harden-receipts-get-public-only"
$log = @()
$log += "# ECO — STEP 16 — Harden Recibos (GET por code respeita público/privado)"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

# =========
# DIAG
# =========
$apiReceipts = "src/app/api/receipts/route.ts"
if(!(Test-Path -LiteralPath $apiReceipts)){
  $apiReceipts = FindFirst "src/app" "\\api\\receipts\\route\.ts$"
}
if(-not $apiReceipts){ throw "Não achei /api/receipts/route.ts" }

$reciboClient = "src/app/recibo/[code]/recibo-client.tsx"
if(!(Test-Path -LiteralPath $reciboClient)){
  $reciboClient = FindFirst "src/app" "\\recibo\\\[code\]\\recibo-client\.tsx$"
}
if(-not $reciboClient){ throw "Não achei recibo-client.tsx em /recibo/[code]" }

$log += "## DIAG"
$log += ("API receipts : {0}" -f $apiReceipts)
$log += ("Recibo client: {0}" -f $reciboClient)
$log += ""

# =========
# PATCH (backup)
# =========
$log += "## PATCH"
$log += ("Backup API    : {0}" -f (BackupFile $apiReceipts))
$log += ("Backup Client : {0}" -f (BackupFile $reciboClient))
$log += ""

# =========
# PATCH: API — GET ?code= só retorna recibo se for público,
# ou se tiver ECO_OPERATOR_TOKEN e token válido no header/query
# =========
$apiTxt = Get-Content -LiteralPath $apiReceipts -Raw

if($apiTxt -match "ECO_RECEIPTS_PUBLIC_GUARD_V1"){
  $log += "- INFO: API já tem ECO_RECEIPTS_PUBLIC_GUARD_V1 (skip)."
} else {
  $needleReturn = 'return NextResponse.json({ ok: true, delegate: found.key, model: found.modelName, receipt });'
  if($apiTxt -notmatch [regex]::Escape($needleReturn)){
    throw "Não achei o return esperado no GET (por code) em /api/receipts para aplicar o guard."
  }

  $replacement = @"
      // ECO_RECEIPTS_PUBLIC_GUARD_V1
      const pubField = getPublicField(found);
      const isPublic = pubField ? !!(receipt as any)[pubField] : true;

      const required = process.env.ECO_OPERATOR_TOKEN;
      if (!isPublic && required) {
        const token =
          req.headers.get("x-eco-token") ||
          url.searchParams.get("token") ||
          url.searchParams.get("operatorToken") ||
          "";
        if (!token || token !== required) {
          // 404 para não revelar existência de recibo privado
          return NextResponse.json({ error: "receipt_not_found", code }, { status: 404 });
        }
      }

      return NextResponse.json({ ok: true, delegate: found.key, model: found.modelName, receipt, isPublic });
"@

  $apiTxt2 = $apiTxt -replace [regex]::Escape($needleReturn), $replacement
  WriteUtf8NoBom $apiReceipts $apiTxt2
  $log += "- OK: /api/receipts GET (?code=) agora respeita público/privado (com token opcional)."
}

# =========
# PATCH: UI — no /recibo/[code], GET envia x-eco-token (se preenchido)
# =========
$cliTxt = Get-Content -LiteralPath $reciboClient -Raw

if($cliTxt -match "ECO_RECEIPTS_GET_SEND_TOKEN_V1"){
  $log += "- INFO: Client já tem ECO_RECEIPTS_GET_SEND_TOKEN_V1 (skip)."
} else {
  # 1) fetch com headers
  $needleFetch = 'const res = await fetch(`/api/receipts?code=${encodeURIComponent(code)}`, { cache: "no-store" });'
  if($cliTxt -notmatch [regex]::Escape($needleFetch)){
    throw "Não achei o fetch esperado no recibo-client.tsx para aplicar headers."
  }

  $fetchReplacement = @"
      // ECO_RECEIPTS_GET_SEND_TOKEN_V1
      const res = await fetch(`/api/receipts?code=${encodeURIComponent(code)}`, {
        cache: "no-store",
        headers: operatorToken ? { "x-eco-token": operatorToken } : undefined,
      });
"@

  $cliTxt2 = $cliTxt -replace [regex]::Escape($needleFetch), $fetchReplacement

  # 2) mensagem melhor para 404/401 no load()
  $needleErr = 'if (!res.ok) throw new Error(json?.error ?? `GET /api/receipts?code falhou (${res.status})`);'
  if($cliTxt2 -match [regex]::Escape($needleErr)){
    $errReplacement = @"
      if (res.status === 401) throw new Error("unauthorized (preencha a chave de operador)");
      if (res.status === 404) throw new Error("Recibo privado (ou inexistente). Se você é operador, preencha a chave e recarregue.");
      if (!res.ok) throw new Error(json?.error ?? `GET /api/receipts?code falhou (${res.status})`);
"@
    $cliTxt2 = $cliTxt2 -replace [regex]::Escape($needleErr), $errReplacement
  } else {
    $log += "- WARN: Não achei o if(!res.ok) exato para melhorar mensagem (skip parcial)."
  }

  WriteUtf8NoBom $reciboClient $cliTxt2
  $log += "- OK: /recibo/[code] agora manda token no GET e mostra mensagem decente em 404/401."
}

# =========
# REGISTRO
# =========
$log += ""
$log += "## Próximos passos"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1"
$log += "3) Crie um recibo PRIVADO e tente abrir /recibo/[code] em aba anônima (deve dar 404/privado)."
$log += "4) Se você usar ECO_OPERATOR_TOKEN no .env, preencha a chave na tela pra ver/toggle."
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")
Write-Host ("✅ STEP 16 aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) Teste /recibo/[code] (privado não vaza sem token quando ECO_OPERATOR_TOKEN existir)" -ForegroundColor Yellow