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

# --- small parsers (paren/brace) with string/comment awareness ---
function FindParenClose([string]$txt, [int]$openIdx){
  $depth = 0
  $inS = $false; $inD = $false; $inLC = $false; $inBC = $false
  for($i=$openIdx; $i -lt $txt.Length; $i++){
    $ch = $txt[$i]
    $n1 = if($i+1 -lt $txt.Length){ $txt[$i+1] } else { [char]0 }

    if($inLC){ if($ch -eq "`n"){ $inLC = $false }; continue }
    if($inBC){ if($ch -eq "*" -and $n1 -eq "/"){ $inBC=$false; $i++; }; continue }

    if($inS){
      if($ch -eq "\" -and $n1 -ne [char]0){ $i++; continue }
      if($ch -eq "'"){ $inS = $false }
      continue
    }
    if($inD){
      if($ch -eq "\" -and $n1 -ne [char]0){ $i++; continue }
      if($ch -eq '"'){ $inD = $false }
      continue
    }

    if($ch -eq "/" -and $n1 -eq "/"){ $inLC = $true; $i++; continue }
    if($ch -eq "/" -and $n1 -eq "*"){ $inBC = $true; $i++; continue }

    if($ch -eq "'"){ $inS = $true; continue }
    if($ch -eq '"'){ $inD = $true; continue }

    if($ch -eq "("){ $depth++; continue }
    if($ch -eq ")"){
      $depth--
      if($depth -eq 0){ return $i }
      continue
    }
  }
  return -1
}
function FindBraceClose([string]$txt, [int]$openIdx){
  $depth = 0
  $inS = $false; $inD = $false; $inLC = $false; $inBC = $false
  for($i=$openIdx; $i -lt $txt.Length; $i++){
    $ch = $txt[$i]
    $n1 = if($i+1 -lt $txt.Length){ $txt[$i+1] } else { [char]0 }

    if($inLC){ if($ch -eq "`n"){ $inLC = $false }; continue }
    if($inBC){ if($ch -eq "*" -and $n1 -eq "/"){ $inBC=$false; $i++; }; continue }

    if($inS){
      if($ch -eq "\" -and $n1 -ne [char]0){ $i++; continue }
      if($ch -eq "'"){ $inS = $false }
      continue
    }
    if($inD){
      if($ch -eq "\" -and $n1 -ne [char]0){ $i++; continue }
      if($ch -eq '"'){ $inD = $false }
      continue
    }

    if($ch -eq "/" -and $n1 -eq "/"){ $inLC = $true; $i++; continue }
    if($ch -eq "/" -and $n1 -eq "*"){ $inBC = $true; $i++; continue }

    if($ch -eq "'"){ $inS = $true; continue }
    if($ch -eq '"'){ $inD = $true; continue }

    if($ch -eq "{"){ $depth++; continue }
    if($ch -eq "}"){
      $depth--
      if($depth -eq 0){ return $i }
      continue
    }
  }
  return -1
}

function DetectPickupReceiptField([string]$schemaPath){
  if(!(Test-Path -LiteralPath $schemaPath)){ return "receipt" }
  $lines = Get-Content -LiteralPath $schemaPath
  $start = -1
  for($i=0; $i -lt $lines.Count; $i++){
    if($lines[$i] -match "^\s*model\s+PickupRequest\s*\{"){ $start = $i; break }
  }
  if($start -lt 0){ return "receipt" }
  $end = -1
  for($j=$start+1; $j -lt $lines.Count; $j++){
    if($lines[$j] -match "^\s*\}\s*$"){ $end = $j; break }
  }
  if($end -lt 0){ return "receipt" }

  for($k=$start; $k -le $end; $k++){
    $line = $lines[$k].Trim()
    if($line -match "^\s*([A-Za-z_][A-Za-z0-9_]*)\s+Receipt\??\b"){
      return $Matches[1]
    }
  }
  return "receipt"
}
function DetectReceiptCodeField([string]$schemaPath){
  if(!(Test-Path -LiteralPath $schemaPath)){ return "shareCode" }
  $lines = Get-Content -LiteralPath $schemaPath
  $start = -1
  for($i=0; $i -lt $lines.Count; $i++){
    if($lines[$i] -match "^\s*model\s+Receipt\s*\{"){ $start = $i; break }
  }
  if($start -lt 0){ return "shareCode" }
  $end = -1
  for($j=$start+1; $j -lt $lines.Count; $j++){
    if($lines[$j] -match "^\s*\}\s*$"){ $end = $j; break }
  }
  if($end -lt 0){ return "shareCode" }

  $hasShare = $false
  $hasCode = $false
  for($k=$start; $k -le $end; $k++){
    $t = $lines[$k].Trim()
    if($t -match "^\s*shareCode\b"){ $hasShare = $true }
    if($t -match "^\s*code\b"){ $hasCode = $true }
  }
  if($hasShare){ return "shareCode" }
  if($hasCode){ return "code" }
  return "shareCode"
}
function DetectReceiptPublicField([string]$schemaPath){
  if(!(Test-Path -LiteralPath $schemaPath)){ return "" }
  $lines = Get-Content -LiteralPath $schemaPath
  $start = -1
  for($i=0; $i -lt $lines.Count; $i++){
    if($lines[$i] -match "^\s*model\s+Receipt\s*\{"){ $start = $i; break }
  }
  if($start -lt 0){ return "" }
  $end = -1
  for($j=$start+1; $j -lt $lines.Count; $j++){
    if($lines[$j] -match "^\s*\}\s*$"){ $end = $j; break }
  }
  if($end -lt 0){ return "" }

  $hasPublic = $false
  $hasIsPublic = $false
  for($k=$start; $k -le $end; $k++){
    $t = $lines[$k].Trim()
    if($t -match "^\s*public\b"){ $hasPublic = $true }
    if($t -match "^\s*isPublic\b"){ $hasIsPublic = $true }
  }
  if($hasPublic){ return "public" }
  if($hasIsPublic){ return "isPublic" }
  return ""
}

$rep = NewReport "eco-step-21-pickup-requests-attach-receipt-and-pedidos-token"
$log = @()
$log += "# ECO — STEP 21 — PickupRequests inclui Receipt + /pedidos envia token"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

# --- DIAG: schema + fields ---
$schema = "prisma/schema.prisma"
if(!(Test-Path -LiteralPath $schema)){ $schema = FindFirst "." "\\prisma\\schema\.prisma$" }

$receiptField = DetectPickupReceiptField $schema
$codeField = DetectReceiptCodeField $schema
$publicField = DetectReceiptPublicField $schema

$log += "## DIAG (schema)"
$log += ("schema: {0}" -f ($schema ? $schema : "(não achei)"))
$log += ("PickupRequest.receipt field: {0}" -f $receiptField)
$log += ("Receipt code field: {0}" -f $codeField)
$log += ("Receipt public field: {0}" -f ($publicField ? $publicField : "(nenhum)"))
$log += ""

# --- DIAG: route file ---
$route = "src/app/api/pickup-requests/route.ts"
if(!(Test-Path -LiteralPath $route)){ $route = "app/api/pickup-requests/route.ts" }
if(!(Test-Path -LiteralPath $route)){
  $route = FindFirst "src/app" "\\api\\pickup-requests\\route\.ts$"
}
if(!(Test-Path -LiteralPath $route)){
  $route = FindFirst "app" "\\api\\pickup-requests\\route\.ts$"
}
if(-not $route){ WriteUtf8NoBom $rep ($log -join "`n"); throw "Não achei /api/pickup-requests/route.ts" }

$log += "## DIAG (arquivos)"
$log += ("route: {0}" -f $route)

# --- DIAG: /pedidos file (primeiro que tiver /api/pickup-requests e fetch) ---
$pedidosFile = $null
$roots = @()
if(Test-Path -LiteralPath "src"){ $roots += "src" }
if(Test-Path -LiteralPath "app"){ $roots += "app" }

foreach($r in $roots){
  $files = Get-ChildItem -Recurse -File -Path $r -ErrorAction SilentlyContinue |
    Where-Object { $_.Extension -in @(".ts",".tsx",".js",".jsx") }
  foreach($f in $files){
    if($f.FullName -like "*api\pickup-requests\route.ts"){ continue }
    $t = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction SilentlyContinue
    if(!$t){ continue }
    if($t.Contains("/api/pickup-requests") -and $t.Contains("fetch(") -and $t.Contains("pedidos")){
      $pedidosFile = $f.FullName
      break
    }
  }
  if($pedidosFile){ break }
}
if(-not $pedidosFile){
  foreach($r in $roots){
    $files = Get-ChildItem -Recurse -File -Path $r -ErrorAction SilentlyContinue |
      Where-Object { $_.Extension -in @(".ts",".tsx",".js",".jsx") }
    foreach($f in $files){
      if($f.FullName -like "*api\pickup-requests\route.ts"){ continue }
      $t = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction SilentlyContinue
      if(!$t){ continue }
      if($t.Contains("/api/pickup-requests") -and $t.Contains("fetch(")){
        $pedidosFile = $f.FullName
        break
      }
    }
    if($pedidosFile){ break }
  }
}

$log += ("pedidos fetch file: {0}" -f ($pedidosFile ? $pedidosFile : "(não achei; vou patchar só a API)"))
$log += ""

# ==========================
# PATCH 1) /api/pickup-requests
# ==========================
$log += "## PATCH (api/pickup-requests)"
$log += ("Backup route: {0}" -f (BackupFile $route))

$txt = Get-Content -LiteralPath $route -Raw

# Detect GET param name (default 'req')
$reqName = "req"
$m = [regex]::Match($txt, 'export\s+async\s+function\s+GET\s*\(\s*([A-Za-z_][A-Za-z0-9_]*)')
if($m.Success){ $reqName = $m.Groups[1].Value }

$log += ("GET param: {0}" -f $reqName)

# Inject helper block once
if($txt -notmatch "ECO_STEP21_ATTACH_RECEIPT_BEGIN"){
  $codeLine = ""
  if($codeField){ $codeLine = ", $codeField: true" }
  $pubLine = ""
  if($publicField){ $pubLine = ", $publicField: true" }

  $helper = @"
`n// ECO_STEP21_ATTACH_RECEIPT_BEGIN
const ECO_TOKEN_HEADER = "x-eco-token";

function ecoIsOperator($reqName: Request): boolean {
  const required = process.env.ECO_OPERATOR_TOKEN;
  if (!required) return true; // MVP aberto quando env não existe
  const url = new URL($reqName.url);
  const token = (($reqName.headers.get(ECO_TOKEN_HEADER) || url.searchParams.get("token") || "") as string).trim();
  return !!token && token === required;
}

function ecoWithReceipt(args: any) {
  const a: any = args ?? {};
  const f = "$receiptField";
  const receiptPick = { select: { id: true$codeLine$pubLine } };

  if (a?.select?.[f] || a?.include?.[f]) return a;
  if (a.select) return { ...a, select: { ...a.select, [f]: receiptPick } };
  return { ...a, include: { ...(a.include ?? {}), [f]: receiptPick } };
}

function ecoStripReceiptForAnon(receipt: any, isOp: boolean) {
  if (!receipt) return receipt;
  const isPublic = !!(receipt.public ?? receipt.isPublic);
  if (isOp || isPublic) return receipt;

  const r: any = { ...receipt };
  if ("shareCode" in r) r.shareCode = null;
  if ("code" in r) r.code = null;
  return r;
}
// ECO_STEP21_ATTACH_RECEIPT_END
"@

  # insert after last import, else top
  $mImp = [regex]::Matches($txt, '^\s*import\s+.*?;\s*$', 'Multiline')
  if($mImp.Count -gt 0){
    $last = $mImp[$mImp.Count-1]
    $insAt = $last.Index + $last.Length
    $txt = $txt.Insert($insAt, $helper)
    $log += "- OK: helper injetado após imports."
  } else {
    $txt = $helper + "`n" + $txt
    $log += "- OK: helper injetado no topo."
  }
} else {
  $log += "- INFO: helper já existe (skip)."
}

# Find GET block to patch inside only
$idxGet = $txt.IndexOf("export async function GET")
if($idxGet -lt 0){
  WriteUtf8NoBom $route $txt
  $log += "- WARN: Não achei GET para patch fino. Mantive apenas helper."
} else {
  $idxBrace = $txt.IndexOf("{", $idxGet)
  if($idxBrace -lt 0){
    WriteUtf8NoBom $route $txt
    $log += "- WARN: Não achei '{' do GET. Mantive apenas helper."
  } else {
    $idxBraceClose = FindBraceClose $txt $idxBrace
    if($idxBraceClose -lt 0){
      WriteUtf8NoBom $route $txt
      $log += "- WARN: Não achei '}' de fechamento do GET. Mantive apenas helper."
    } else {

      # Patch first .findMany(...) inside GET: wrap args with ecoWithReceipt(...)
      $idxFM = $txt.IndexOf(".findMany", $idxBrace)
      if($idxFM -ge 0 -and $idxFM -lt $idxBraceClose){
        $idxOpen = $txt.IndexOf("(", $idxFM)
        if($idxOpen -ge 0 -and $idxOpen -lt $idxBraceClose){
          $idxClose = FindParenClose $txt $idxOpen
          if($idxClose -ge 0 -and $idxClose -lt $idxBraceClose){
            $inside = $txt.Substring($idxOpen+1, $idxClose-($idxOpen+1))
            if($inside -match "ecoWithReceipt\s*\("){
              $log += "- INFO: findMany já está embrulhado com ecoWithReceipt (skip)."
            } else {
              $insideTrim = $inside.Trim()
              if($insideTrim.Length -eq 0){
                $newInside = "ecoWithReceipt({}, $reqName)"
              } else {
                $newInside = "ecoWithReceipt(" + $inside + ", " + $reqName + ")"
              }
              $txt = $txt.Substring(0, $idxOpen+1) + $newInside + $txt.Substring($idxClose)
              $log += "- OK: findMany(...) -> findMany(ecoWithReceipt(..., req))."
            }
          } else { $log += "- WARN: Não consegui achar fechamento do findMany(...) no GET." }
        } else { $log += "- WARN: Não consegui achar '(' do findMany no GET." }
      } else {
        $log += "- WARN: Não achei .findMany dentro do GET (não embrulhei)."
      }

      # Patch return NextResponse.json({ items }); inside GET (sanitize receipt)
      $txt2 = $txt.Substring($idxBrace, ($idxBraceClose - $idxBrace + 1))
      $pat = 'return\s+NextResponse\.json\(\s*\{\s*items\s*\}\s*\)\s*;'
      if([regex]::IsMatch($txt2, $pat)){
        $replacement = @"
const __eco_isOp = ecoIsOperator($reqName);
  const __eco_items = (items ?? []).map((it: any) => ({
    ...it,
    ["$receiptField"]: ecoStripReceiptForAnon((it as any)?.["$receiptField"], __eco_isOp),
  }));
  return NextResponse.json({ items: __eco_items });
"@
        $txt2b = [regex]::Replace($txt2, $pat, $replacement, 1)
        $txt = $txt.Substring(0, $idxBrace) + $txt2b + $txt.Substring($idxBraceClose+1)
        $log += "- OK: return items sanitizado (privado sem token => sem shareCode/code)."
      } else {
        $log += "- WARN: Não achei `return NextResponse.json({ items });` no GET (não sanitizei retorno)."
      }
    }
  }
}

WriteUtf8NoBom $route $txt

# ==========================
# PATCH 2) /pedidos fetch envia token (se achou arquivo)
# ==========================
$log += ""
$log += "## PATCH (/pedidos token header)"
if($pedidosFile){
  $log += ("Arquivo: {0}" -f $pedidosFile)
  $log += ("Backup : {0}" -f (BackupFile $pedidosFile))

  $p = Get-Content -LiteralPath $pedidosFile -Raw

  if($p -notmatch "ECO_STEP21_PEDIDOS_TOKEN"){
    $pedHelper = @"
`n// ECO_STEP21_PEDIDOS_TOKEN
const ECO_TOKEN_KEY = "eco_operator_token";
function ecoReadToken() {
  if (typeof window === "undefined") return "";
  try { return localStorage.getItem(ECO_TOKEN_KEY) || ""; } catch { return ""; }
}
function ecoAuthHeaders() {
  const t = (ecoReadToken() || "").trim();
  return t ? { "x-eco-token": t } : {};
}
// ECO_STEP21_PEDIDOS_TOKEN_END
"@
    $mImp2 = [regex]::Matches($p, '^\s*import\s+.*?;\s*$', 'Multiline')
    if($mImp2.Count -gt 0){
      $last2 = $mImp2[$mImp2.Count-1]
      $insAt2 = $last2.Index + $last2.Length
      $p = $p.Insert($insAt2, $pedHelper)
      $log += "- OK: helper ecoAuthHeaders injetado após imports."
    } else {
      $p = $pedHelper + "`n" + $p
      $log += "- OK: helper ecoAuthHeaders injetado no topo."
    }
  } else {
    $log += "- INFO: helper ECO_STEP21_PEDIDOS_TOKEN já existe (skip)."
  }

  # Patch first fetch to /api/pickup-requests to include headers (if not already)
  $needle1 = 'fetch("/api/pickup-requests"'
  $needle2 = "fetch('/api/pickup-requests'"
  $idx = $p.IndexOf($needle1)
  if($idx -lt 0){ $idx = $p.IndexOf($needle2) }

  if($idx -ge 0){
    # find parens of fetch(...)
    $idxFetch = $p.LastIndexOf("fetch", $idx)
    $idxOpen = $p.IndexOf("(", $idxFetch)
    if($idxOpen -ge 0){
      $idxClose = FindParenClose $p $idxOpen
      if($idxClose -ge 0){
        $inside = $p.Substring($idxOpen+1, $idxClose-($idxOpen+1))
        if($inside -match "headers\s*:"){
          $log += "- INFO: fetch já tem headers (skip)."
        } else {
          # If there is a comma, try to inject into options object
          $comma = $inside.IndexOf(",")
          if($comma -ge 0){
            $afterComma = $inside.Substring($comma+1)
            $brace = $afterComma.IndexOf("{")
            if($brace -ge 0){
              $absBrace = ($idxOpen+1) + ($comma+1) + $brace
              $p = $p.Substring(0, $absBrace+1) + "`n    headers: ecoAuthHeaders()," + $p.Substring($absBrace+1)
              $log += "- OK: headers: ecoAuthHeaders() inserido no objeto de options do fetch."
            } else {
              # fallback: replace "fetch(url, something)" -> add wrapper (last resort)
              $p = $p.Substring(0, $idxClose) + ", { headers: ecoAuthHeaders() }" + $p.Substring($idxClose)
              $log += "- WARN: não achei '{' de options; adicionei segundo arg { headers } no final (fallback)."
            }
          } else {
            # no second arg: add one
            $p = $p.Substring(0, $idxClose) + ", { headers: ecoAuthHeaders() }" + $p.Substring($idxClose)
            $log += "- OK: fetch(url) -> fetch(url, { headers: ecoAuthHeaders() })."
          }
        }
      } else {
        $log += "- WARN: Não consegui achar ')' do fetch(/api/pickup-requests)."
      }
    } else {
      $log += "- WARN: Não consegui achar '(' do fetch."
    }
  } else {
    $log += "- WARN: Não achei fetch('/api/pickup-requests') nesse arquivo."
  }

  WriteUtf8NoBom $pedidosFile $p
} else {
  $log += "- INFO: Não achei arquivo /pedidos com fetch; patch aplicado só na API."
}

$log += ""
$log += "## Próximos passos"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1"
$log += "3) Em /pedidos: operador (com eco_operator_token no localStorage) deve ver 'Ver recibo' inclusive privado."
$log += "4) Em aba anônima (sem token): recibo privado não deve vazar shareCode/code no payload do /api/pickup-requests."
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 21 aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) Teste /pedidos (com token) e aba anônima (sem token)" -ForegroundColor Yellow