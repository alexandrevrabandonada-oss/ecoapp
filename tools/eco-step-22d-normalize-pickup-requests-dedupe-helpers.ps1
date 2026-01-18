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

function FindMatchingBrace([string]$txt, [int]$openIdx){
  if($openIdx -lt 0 -or $openIdx -ge $txt.Length){ return -1 }

  $depth = 0
  $inS = $false
  $inD = $false
  $inLC = $false
  $inBC = $false

  for($i=$openIdx; $i -lt $txt.Length; $i++){
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

function RemoveDuplicateNamedFunction([string]$txt, [string]$name, [ref]$removedCount){
  $removedCount.Value = 0
  if([string]::IsNullOrWhiteSpace($txt)){ return $txt }

  $rx = New-Object System.Text.RegularExpressions.Regex("(?m)\bfunction\s+$name\s*\(", "Compiled")
  $matches = $rx.Matches($txt)
  if($matches.Count -le 1){ return $txt }

  # remove from end to start, skipping the first occurrence (keep earliest)
  for($m = $matches.Count - 1; $m -ge 1; $m--){
    $startIdx = $matches[$m].Index
    $idxBrace = $txt.IndexOf("{", $startIdx)
    if($idxBrace -lt 0){ continue }

    $endBrace = FindMatchingBrace $txt $idxBrace
    if($endBrace -lt 0){ continue }

    $after = $endBrace + 1
    if($after -lt $txt.Length -and $txt[$after] -eq "`r"){ $after++ }
    if($after -lt $txt.Length -and $txt[$after] -eq "`n"){ $after++ }

    $txt = $txt.Remove($startIdx, $after - $startIdx)
    $removedCount.Value++
  }

  return $txt
}

function RemoveDuplicateMarkerBlocks([string]$txt, [string]$startToken, [string]$endToken, [ref]$removedCount){
  $removedCount.Value = 0
  if([string]::IsNullOrWhiteSpace($txt)){ return $txt }

  $startRx = New-Object System.Text.RegularExpressions.Regex("(?m)^\s*//\s*$startToken\s*$")
  $endRx   = New-Object System.Text.RegularExpressions.Regex("(?m)^\s*//\s*$endToken\s*$")

  $starts = $startRx.Matches($txt)
  if($starts.Count -le 1){ return $txt }

  # remove blocks from end to start, skipping first start marker
  for($i = $starts.Count - 1; $i -ge 1; $i--){
    $sIdx = $starts[$i].Index
    $sub = $txt.Substring($sIdx)
    $endM = $endRx.Match($sub)
    if(!$endM.Success){ continue }

    $endAbs = $sIdx + $endM.Index + $endM.Length
    # remove trailing newline
    if($endAbs -lt $txt.Length -and $txt[$endAbs] -eq "`r"){ $endAbs++ }
    if($endAbs -lt $txt.Length -and $txt[$endAbs] -eq "`n"){ $endAbs++ }

    $txt = $txt.Remove($sIdx, $endAbs - $sIdx)
    $removedCount.Value++
  }

  return $txt
}

function CountRegex([string]$txt, [string]$pattern){
  if([string]::IsNullOrWhiteSpace($txt)){ return 0 }
  return ([regex]::Matches($txt, $pattern)).Count
}

$rep = NewReport "eco-step-22d-normalize-pickup-requests-dedupe-helpers"
$log = @()
$log += "# ECO — STEP 22d — Normalizar /api/pickup-requests (dedupe helpers/blocks repetidos)"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

$route = "src/app/api/pickup-requests/route.ts"
if(!(Test-Path -LiteralPath $route)){
  $route = FindFirst "." "\\src\\app\\api\\pickup-requests\\route\.ts$"
}
if(!(Test-Path -LiteralPath $route)){
  WriteUtf8NoBom $rep ($log -join "`n")
  throw "Não achei src/app/api/pickup-requests/route.ts"
}

$txt = Get-Content -LiteralPath $route -Raw

$log += "## DIAG (antes)"
$log += ("Arquivo: {0}" -f $route)
$log += ("Backup : {0}" -f (BackupFile $route))

$log += ("- count function ecoGetToken : {0}" -f (CountRegex $txt "\bfunction\s+ecoGetToken\s*\("))
$log += ("- count function ecoIsOperator: {0}" -f (CountRegex $txt "\bfunction\s+ecoIsOperator\s*\("))
$log += ("- count function ecoWithReceipt: {0}" -f (CountRegex $txt "\bfunction\s+ecoWithReceipt\s*\("))
$log += ("- count marker OP start      : {0}" -f (CountRegex $txt "(?m)^\s*//\s*ECO_HELPER_OPERATOR_START\s*$"))
$log += ("- count marker RECEIPT start : {0}" -f (CountRegex $txt "(?m)^\s*//\s*ECO_HELPER_WITH_RECEIPT_START\s*$"))
$log += ("- count marker PRIVACY start : {0}" -f (CountRegex $txt "(?m)^\s*//\s*ECO_PICKUP_RECEIPT_PRIVACY_START\s*$"))
$log += ""

$log += "## PATCH"

# 1) Se tiver blocos com markers repetidos, remove duplicatas (mantém o primeiro)
$rc = 0
$txt = RemoveDuplicateMarkerBlocks $txt "ECO_HELPER_OPERATOR_START" "ECO_HELPER_OPERATOR_END" ([ref]$rc)
$log += ("- dedupe block ECO_HELPER_OPERATOR_* removidos: {0}" -f $rc)

$rc = 0
$txt = RemoveDuplicateMarkerBlocks $txt "ECO_HELPER_WITH_RECEIPT_START" "ECO_HELPER_WITH_RECEIPT_END" ([ref]$rc)
$log += ("- dedupe block ECO_HELPER_WITH_RECEIPT_* removidos: {0}" -f $rc)

$rc = 0
$txt = RemoveDuplicateMarkerBlocks $txt "ECO_PICKUP_RECEIPT_PRIVACY_START" "ECO_PICKUP_RECEIPT_PRIVACY_END" ([ref]$rc)
$log += ("- dedupe block ECO_PICKUP_RECEIPT_PRIVACY_* removidos: {0}" -f $rc)

# 2) Deduplicar por nome de função (robusto mesmo se marker falhou)
$rm = 0
$txt = RemoveDuplicateNamedFunction $txt "ecoGetToken" ([ref]$rm)
$log += ("- dedupe function ecoGetToken removidos: {0}" -f $rm)

$rm = 0
$txt = RemoveDuplicateNamedFunction $txt "ecoIsOperator" ([ref]$rm)
$log += ("- dedupe function ecoIsOperator removidos: {0}" -f $rm)

$rm = 0
$txt = RemoveDuplicateNamedFunction $txt "ecoWithReceipt" ([ref]$rm)
$log += ("- dedupe function ecoWithReceipt removidos: {0}" -f $rm)

# 3) Se ainda tiver blocos repetidos e consts '__eco_*' colidindo, troca para 'var' (evita redeclare)
$beforeVar = $txt
$txt = ($txt -replace '\bconst\s+(__eco_[A-Za-z0-9_]+)\s*=', 'var $1 =')
if($txt -ne $beforeVar){
  $log += "- normalize: const __eco_* -> var __eco_* (anti-redeclare)"
}

WriteUtf8NoBom $route $txt

$log += ""
$log += "## DIAG (depois)"
$log += ("- count function ecoGetToken : {0}" -f (CountRegex $txt "\bfunction\s+ecoGetToken\s*\("))
$log += ("- count function ecoIsOperator: {0}" -f (CountRegex $txt "\bfunction\s+ecoIsOperator\s*\("))
$log += ("- count function ecoWithReceipt: {0}" -f (CountRegex $txt "\bfunction\s+ecoWithReceipt\s*\("))
$log += ("- count marker OP start      : {0}" -f (CountRegex $txt "(?m)^\s*//\s*ECO_HELPER_OPERATOR_START\s*$"))
$log += ("- count marker RECEIPT start : {0}" -f (CountRegex $txt "(?m)^\s*//\s*ECO_HELPER_WITH_RECEIPT_START\s*$"))
$log += ("- count marker PRIVACY start : {0}" -f (CountRegex $txt "(?m)^\s*//\s*ECO_PICKUP_RECEIPT_PRIVACY_START\s*$"))

$log += ""
$log += "## VERIFY"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1"
$log += "3) /api/pickup-requests deve voltar 200"
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")
Write-Host ("✅ STEP 22d aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) Se passar, teste /pedidos normal vs anônimo" -ForegroundColor Yellow