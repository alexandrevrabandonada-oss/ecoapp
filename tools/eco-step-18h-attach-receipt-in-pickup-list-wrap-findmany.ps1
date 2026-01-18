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

function DetectReceiptField([string]$schemaPath){
  if(!(Test-Path -LiteralPath $schemaPath)){ return "receipt" }
  $lines = Get-Content -LiteralPath $schemaPath
  $start = -1
  for($i=0; $i -lt $lines.Count; $i++){
    if($lines[$i] -match '^\s*model\s+PickupRequest\s*\{'){ $start = $i; break }
  }
  if($start -lt 0){ return "receipt" }

  $end = -1
  for($j=$start+1; $j -lt $lines.Count; $j++){
    if($lines[$j] -match '^\s*\}\s*$'){ $end = $j; break }
  }
  if($end -lt 0){ return "receipt" }

  for($k=$start; $k -le $end; $k++){
    $line = $lines[$k].Trim()
    if($line -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s+Receipt\??\b'){
      return $Matches[1]
    }
  }
  return "receipt"
}

function FindOpenParenAfter([string]$txt, [int]$idx){
  for($i = $idx; $i -lt $txt.Length; $i++){
    $ch = $txt[$i]
    if($ch -eq "("){ return $i }
    if($ch -eq " " -or $ch -eq "`t" -or $ch -eq "`r" -or $ch -eq "`n"){ continue }
  }
  return -1
}

function FindParenClose([string]$txt, [int]$openIdx){
  $depth = 0
  $inS = $false
  $inD = $false
  $inT = $false
  $inLC = $false
  $inBC = $false
  $bt = [char]96

  for($i = $openIdx; $i -lt $txt.Length; $i++){
    $ch = $txt[$i]
    $n1 = if($i+1 -lt $txt.Length){ $txt[$i+1] } else { [char]0 }

    if($inLC){
      if($ch -eq "`n"){ $inLC = $false }
      continue
    }
    if($inBC){
      if($ch -eq "*" -and $n1 -eq "/"){ $inBC = $false; $i++; continue }
      continue
    }

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
    if($inT){
      if($ch -eq "\" -and $n1 -ne [char]0){ $i++; continue }
      if($ch -eq $bt){ $inT = $false }
      continue
    }

    if($ch -eq "/" -and $n1 -eq "/"){ $inLC = $true; $i++; continue }
    if($ch -eq "/" -and $n1 -eq "*"){ $inBC = $true; $i++; continue }

    if($ch -eq "'"){ $inS = $true; continue }
    if($ch -eq '"'){ $inD = $true; continue }
    if($ch -eq $bt){ $inT = $true; continue }

    if($ch -eq "("){ $depth++; continue }
    if($ch -eq ")"){
      $depth--
      if($depth -eq 0){ return $i }
      continue
    }
  }
  return -1
}

$rep = NewReport "eco-step-18h-attach-receipt-in-pickup-list-wrap-findmany"
$log = @()
$log += "# ECO — STEP 18h — Anexar receipt no list de pickup-requests (wrap findMany)"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

# ===== DIAG: schema + campo Receipt em PickupRequest
$schema = "prisma/schema.prisma"
if(!(Test-Path -LiteralPath $schema)){ $schema = FindFirst "." "\\prisma\\schema\.prisma$" }
$receiptField = DetectReceiptField $schema

$log += "## DIAG"
$log += ("schema: {0}" -f ($schema ? $schema : "(não achei)"))
$log += ("receiptField (PickupRequest -> Receipt?): {0}" -f $receiptField)
$log += ""

# ===== localizar route.ts de /api/pickup-requests
$route = "src/app/api/pickup-requests/route.ts"
if(!(Test-Path -LiteralPath $route)){ $route = "app/api/pickup-requests/route.ts" }
if(!(Test-Path -LiteralPath $route)){
  $route = FindFirst "." "\\api\\pickup-requests\\route\.(ts|js)$"
}
if(-not $route){
  WriteUtf8NoBom $rep ($log -join "`n")
  throw "Não achei /api/pickup-requests/route.(ts|js). Veja o report: $rep"
}

$log += ("route: {0}" -f $route)
$log += ""

$txt0 = Get-Content -LiteralPath $route -Raw
if($txt0 -match "ECO_STEP18H_ATTACH_RECEIPT"){
  $log += "INFO: já existe marker ECO_STEP18H_ATTACH_RECEIPT (skip helper)."
}

# ===== helper TS (sem $var:, sem regex doida)
$helper = @"
`n// ECO_STEP18H_ATTACH_RECEIPT
function ecoWithReceipt(args: any) {
  const a: any = args ?? {};
  const FIELD = "__RECEIPT_FIELD__";
  if ((a as any)?.include?.[FIELD] || (a as any)?.select?.[FIELD]) return a;
  if (a.select) return { ...a, select: { ...a.select, [FIELD]: true } };
  return { ...a, include: { ...(a.include ?? {}), [FIELD]: true } };
}
"@
$helper = $helper.Replace("__RECEIPT_FIELD__", $receiptField)

# ===== injetar helper após imports (ou topo)
$txt = $txt0
if($txt -notmatch "ECO_STEP18H_ATTACH_RECEIPT"){
  $m = [regex]::Matches($txt, '^\s*import\s+.*?;\s*$', 'Multiline')
  if($m.Count -gt 0){
    $last = $m[$m.Count-1]
    $insAt = $last.Index + $last.Length
    $txt = $txt.Insert($insAt, $helper)
    $log += "OK: helper inserido após imports."
  } else {
    $txt = $helper + "`n" + $txt
    $log += "OK: helper inserido no topo."
  }
} else {
  $log += "INFO: helper já estava presente."
}

# ===== achar findMany e embrulhar argumento com ecoWithReceipt(...)
# estratégia: pegar o primeiro "findMany" do arquivo e wrapar a chamada
$idxFind = $txt.IndexOf("findMany")
if($idxFind -lt 0){
  WriteUtf8NoBom $rep ($log -join "`n")
  throw "Não encontrei 'findMany' no arquivo. Veja o report: $rep"
}

# achar '(' depois de findMany
$idxOpen = FindOpenParenAfter $txt ($idxFind + 7)
if($idxOpen -lt 0){
  WriteUtf8NoBom $rep ($log -join "`n")
  throw "Não encontrei '(' após findMany. Veja o report: $rep"
}
$idxClose = FindParenClose $txt $idxOpen
if($idxClose -lt 0){
  WriteUtf8NoBom $rep ($log -join "`n")
  throw "Não encontrei fechamento ')' da chamada findMany. Veja o report: $rep"
}

$inside = $txt.Substring($idxOpen+1, $idxClose-($idxOpen+1))
$insideTrim = $inside.Trim()

$log += ""
$log += "## PATCH"
$log += ("Backup: {0}" -f (BackupFile $route))

# se já está embrulhado, não mexe
if($insideTrim.StartsWith("ecoWithReceipt(")){
  $log += "INFO: findMany já está embrulhado com ecoWithReceipt (skip)."
} else {
  if($insideTrim.Length -eq 0){
    # findMany() -> findMany(ecoWithReceipt({}))
    $txt = $txt.Substring(0, $idxOpen+1) + "ecoWithReceipt({})" + $txt.Substring($idxClose)
    $log += "OK: findMany() -> findMany(ecoWithReceipt({}))"
  } else {
    # findMany(ARG) -> findMany(ecoWithReceipt(ARG))
    $txt = $txt.Substring(0, $idxOpen+1) + "ecoWithReceipt(" + $inside + ")" + $txt.Substring($idxClose)
    $log += "OK: findMany(ARG) -> findMany(ecoWithReceipt(ARG))"
  }
}

WriteUtf8NoBom $route $txt

$log += ""
$log += "## Resultado esperado"
$log += ("- /api/pickup-requests deve incluir `{0}` em cada item (via include/select)." -f $receiptField)
$log += "- /pedidos deve conseguir mostrar 'Ver recibo' quando existir."
$log += ""
$log += "## Próximos passos"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1"
$log += "3) Abra /pedidos e verifique se aparece 'Ver recibo' quando houver recibo."
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")
Write-Host ("✅ STEP 18h aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) /pedidos -> 'Ver recibo' quando houver" -ForegroundColor Yellow