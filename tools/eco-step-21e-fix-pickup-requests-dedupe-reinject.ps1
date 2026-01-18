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

function DetectReceiptRelationFieldInPickup([string[]]$lines){
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

function DetectModelField([string[]]$lines, [string]$modelName, [string[]]$candidates){
  $start = -1
  for($i=0; $i -lt $lines.Count; $i++){
    if($lines[$i] -match "^\s*model\s+$modelName\s*\{"){ $start = $i; break }
  }
  if($start -lt 0){ return $null }
  $end = -1
  for($j=$start+1; $j -lt $lines.Count; $j++){
    if($lines[$j] -match "^\s*\}\s*$"){ $end = $j; break }
  }
  if($end -lt 0){ return $null }

  $found = @{}
  for($k=$start; $k -le $end; $k++){
    $line = $lines[$k].Trim()
    if($line -match "^\s*([A-Za-z_][A-Za-z0-9_]*)\b"){
      $found[$Matches[1]] = $true
    }
  }
  foreach($c in $candidates){
    if($found.ContainsKey($c)){ return $c }
  }
  return $null
}

function RemoveFunctionBlock([string]$txt, [int]$idx){
  $idxBrace = $txt.IndexOf("{", $idx)
  if($idxBrace -lt 0){ return $txt }

  $depth = 0
  $inS = $false
  $inD = $false
  $inLC = $false
  $inBC = $false
  $endIdx = -1

  for($i=$idxBrace; $i -lt $txt.Length; $i++){
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
      if($depth -eq 0){ $endIdx = $i; break }
    }
  }

  if($endIdx -lt 0){ return $txt }

  $after = $endIdx + 1
  if($after -lt $txt.Length -and $txt[$after] -eq "`r"){ $after++ }
  if($after -lt $txt.Length -and $txt[$after] -eq "`n"){ $after++ }

  return $txt.Remove($idx, $after - $idx)
}

function RemoveAllEcoWithReceipt([string]$txt){
  # remove marker-only lines
  $txt = [regex]::Replace($txt, "^\s*//\s*ECO_STEP.*?`r?`n", "", "Multiline")
  $txt = [regex]::Replace($txt, "^\s*//\s*ECO_HELPER_WITH_RECEIPT_(START|END)\s*`r?`n", "", "Multiline")

  while($true){
    $idx = $txt.IndexOf("function ecoWithReceipt")
    if($idx -lt 0){ break }
    $txt = RemoveFunctionBlock $txt $idx
  }
  return $txt
}

$rep = NewReport "eco-step-21e-fix-pickup-requests-dedupe-reinject"
$log = @()
$log += "# ECO — STEP 21e — Fix /api/pickup-requests (dedupe ecoWithReceipt + reinject limpo)"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

$schema = "prisma/schema.prisma"
if(!(Test-Path -LiteralPath $schema)){ $schema = FindFirst "." "\\prisma\\schema\.prisma$" }

$receiptField = "receipt"
$receiptCodeField = "code"
$receiptPublicField = $null

if($schema -and (Test-Path -LiteralPath $schema)){
  $lines = Get-Content -LiteralPath $schema
  $receiptField = DetectReceiptRelationFieldInPickup $lines
  $receiptCodeField = (DetectModelField $lines "Receipt" @("code","shareCode","publicCode","slug","id"))
  if(!$receiptCodeField){ $receiptCodeField = "id" }
  $receiptPublicField = (DetectModelField $lines "Receipt" @("public","isPublic"))
}

$selectPairs = @()
$selectPairs += ($receiptCodeField + ": true")
if($receiptPublicField){ $selectPairs += ($receiptPublicField + ": true") }
$selectBody = ($selectPairs -join ", ")

$log += "## DIAG"
$log += ("schema: {0}" -f ($schema ? $schema : "(não achei)"))
$log += ("PickupRequest.receipt field: {0}" -f $receiptField)
$log += ("Receipt select: {0}" -f $selectBody)
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

$log += "## PATCH"
$log += ("Arquivo: {0}" -f $route)
$log += ("Backup : {0}" -f (BackupFile $route))

# 1) remove all ecoWithReceipt blocks
$beforeLen = $txt.Length
$txt = RemoveAllEcoWithReceipt $txt
$afterLen = $txt.Length
$log += ("- OK: removi ecoWithReceipt antigos (len {0} -> {1})." -f $beforeLen, $afterLen)

# 2) guard: fix accidental concatenation "...export const runtime"
$txt = ($txt -replace '([A-Za-z0-9_])export\s+const\s+runtime', ('$1' + "`n" + 'export const runtime'))

# 3) inject one clean helper
$helper = @"
// ECO_HELPER_WITH_RECEIPT_START
function ecoWithReceipt(args: any) {
  const a: any = args ?? {};
  const f = "__RECEIPT_FIELD__";
  const receiptPick: any = { select: { __RECEIPT_SELECT__ } };
  if (a?.select?.[f] || a?.include?.[f]) return a;
  if (a.select) return { ...a, select: { ...a.select, [f]: receiptPick } };
  return { ...a, include: { ...(a.include ?? {}), [f]: receiptPick } };
}
// ECO_HELPER_WITH_RECEIPT_END
"@

$helper = $helper.Replace("__RECEIPT_FIELD__", $receiptField)
$helper = $helper.Replace("__RECEIPT_SELECT__", $selectBody)

# insertion point after imports (and after runtime line if it sits right there)
$mImp = [regex]::Matches($txt, '^\s*import\s+.*?;\s*$', 'Multiline')
$insAt = 0
if($mImp.Count -gt 0){
  $last = $mImp[$mImp.Count-1]
  $insAt = $last.Index + $last.Length
}

# if runtime is right after imports, insert after its line
$idxRuntime = $txt.IndexOf("export const runtime", $insAt)
if($idxRuntime -ge 0 -and $idxRuntime -lt ($insAt + 300)){
  $idxLineEnd = $txt.IndexOf("`n", $idxRuntime)
  if($idxLineEnd -gt 0){ $insAt = $idxLineEnd + 1 }
}

$txt = $txt.Insert($insAt, "`n" + $helper + "`n")
$log += "- OK: reinjetei UM helper ecoWithReceipt."

# 4) wrap delegate.findMany
if($txt -match 'delegate\.findMany\(\s*ecoWithReceipt\('){
  $log += "- INFO: delegate.findMany já embrulhado."
} else {
  $before = $txt
  $txt = [regex]::Replace($txt, 'delegate\.findMany\(\s*args\s*\)', 'delegate.findMany(ecoWithReceipt(args))')
  if($txt -ne $before){
    $log += "- OK: delegate.findMany(args) embrulhado."
  } else {
    $before2 = $txt
    $txt = [regex]::Replace($txt, 'delegate\.findMany\(\s*\)', 'delegate.findMany(ecoWithReceipt({}))')
    if($txt -ne $before2){
      $log += "- OK: delegate.findMany() embrulhado."
    } else {
      $log += "- WARN: não achei delegate.findMany(...) para embrulhar (talvez não use 'delegate')."
    }
  }
}

WriteUtf8NoBom $route $txt

$log += ""
$log += "## VERIFY"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1"
$log += "3) /api/pickup-requests deve voltar 200"
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")
Write-Host ("✅ STEP 21e aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) Se smoke OK, teste /pedidos (aba normal vs aba anônima)" -ForegroundColor Yellow