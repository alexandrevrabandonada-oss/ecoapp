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
function FindIndexRegex([string]$text, [string]$pattern, [int]$start){
  $sub = $text.Substring($start)
  $m = [regex]::Match($sub, $pattern)
  if($m.Success){ return $start + $m.Index }
  return -1
}

$rep = NewReport "eco-step-16b-harden-receipts-get-public-only-robust"
$log = @()
$log += "# ECO — STEP 16b — Harden Recibos (GET por code respeita público/privado) — robust"
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
# PATCH: API — injeta guard dentro do GET, no ramo if(code)
# =========
$apiTxt = Get-Content -LiteralPath $apiReceipts -Raw

if($apiTxt -match "ECO_RECEIPTS_PUBLIC_GUARD_V1"){
  $log += "- INFO: API já tem ECO_RECEIPTS_PUBLIC_GUARD_V1 (skip)."
} else {
  $posGet = $apiTxt.IndexOf("export async function GET")
  if($posGet -lt 0){ throw "Não achei 'export async function GET' em /api/receipts." }

  # acha if (code) depois do GET
  $posIfCode = FindIndexRegex $apiTxt 'if\s*\(\s*code\s*\)' $posGet
  if($posIfCode -lt 0){ throw "Não achei 'if (code)' dentro do GET em /api/receipts." }

  # acha if (!receipt) depois do if(code)
  $posIfReceipt = FindIndexRegex $apiTxt 'if\s*\(\s*!receipt\s*\)' $posIfCode
  if($posIfReceipt -lt 0){ throw "Não achei 'if (!receipt)' dentro do ramo if(code) em /api/receipts." }

  # ponto de inserção = após o primeiro ';' depois do if(!receipt)
  $posSemi = $apiTxt.IndexOf(";", $posIfReceipt)
  if($posSemi -lt 0){ throw "Não achei ';' após 'if (!receipt)' para inserir o guard." }
  $insertAt = $posSemi + 1

  $snippet = @"

      // ECO_RECEIPTS_PUBLIC_GUARD_V1
      // Se ECO_OPERATOR_TOKEN estiver setado:
      // - recibo público => retorna normal
      // - recibo privado => só retorna se token bater (header x-eco-token ou query ?token=)
      $isPublic = !!((receipt as any).public ?? (receipt as any).isPublic);
      const required = process.env.ECO_OPERATOR_TOKEN;

      if (!$isPublic && required) {
        const u = new URL(req.url);
        const token =
          req.headers.get("x-eco-token") ||
          u.searchParams.get("token") ||
          u.searchParams.get("operatorToken") ||
          "";

        if (!token || token !== required) {
          // 404 para não revelar existência
          return NextResponse.json({ error: "receipt_not_found", code }, { status: 404 });
        }
      }

"@

  $apiTxt2 = $apiTxt.Insert($insertAt, $snippet)
  WriteUtf8NoBom $apiReceipts $apiTxt2
  $log += "- OK: Guard inserido no GET por code (ECO_OPERATOR_TOKEN opcional, privado não vaza)."
}

# =========
# PATCH: UI — GET manda token via query (sem depender do formato exato do fetch options)
# =========
$cliTxt = Get-Content -LiteralPath $reciboClient -Raw

if($cliTxt -match "ECO_RECEIPTS_GET_SEND_TOKEN_V2"){
  $log += "- INFO: Client já tem ECO_RECEIPTS_GET_SEND_TOKEN_V2 (skip)."
} else {
  # troca apenas o template da URL no fetch do GET
  $before = '/api/receipts?code=${encodeURIComponent(code)}'
  $after  = '/api/receipts?code=${encodeURIComponent(code)}${operatorToken ? "&token=" + encodeURIComponent(operatorToken) : ""}'

  if($cliTxt -notmatch [regex]::Escape($before)){
    $log += "- WARN: Não achei a URL padrão do GET no recibo-client. Não alterei o client."
  } else {
    $cliTxt2 = $cliTxt -replace [regex]::Escape($before), $after
    $cliTxt2 = $cliTxt2 -replace 'useEffect\(\s*\(\)\s*=>\s*\{\s*if\s*\(code\)\s*load\(\)\s*;\s*\}\s*,\s*\[code\]\s*\)\s*;','useEffect(() => { if (code) load(); }, [code]);'

    # marca
    $cliTxt2 = $cliTxt2 + "`n`n// ECO_RECEIPTS_GET_SEND_TOKEN_V2`n"
    WriteUtf8NoBom $reciboClient $cliTxt2
    $log += "- OK: /recibo/[code] GET agora adiciona &token=... quando a chave estiver preenchida."
  }
}

# =========
# REGISTRO
# =========
$log += ""
$log += "## Próximos passos"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1"
$log += "3) Com ECO_OPERATOR_TOKEN no .env: recibo privado deve virar 404 sem token (aba anônima)."
$log += "4) Preencha a chave no /recibo/[code] para conseguir ver/toggle se for operador."
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")
Write-Host ("✅ STEP 16b aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) Teste recibo privado (com ECO_OPERATOR_TOKEN setado) em aba anônima: deve dar 404" -ForegroundColor Yellow