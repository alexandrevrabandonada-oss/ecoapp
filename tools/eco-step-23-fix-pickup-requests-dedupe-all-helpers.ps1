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
      $fname = $Matches[1]
      $found[$fname] = $true
    }
  }
  foreach($c in $candidates){
    if($found.ContainsKey($c)){ return $c }
  }
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

function RemoveMarkedBlock([string]$txt, [string]$startTag, [string]$endTag){
  $pat = "(?s)^\s*//\s*$startTag.*?^\s*//\s*$endTag\s*`r?`n?"
  return [regex]::Replace($txt, $pat, "", "Multiline")
}

function RemoveAllFunctionDefs([string]$txt, [string]$funcName){
  # remove: (export)? (async)? function FUNC(...) { ... }
  while($true){
    $m = [regex]::Match($txt, "^\s*(export\s+)?(async\s+)?function\s+$funcName\s*\(", "Multiline")
    if(!$m.Success){ break }
    $idx = $m.Index
    $idxBrace = $txt.IndexOf("{", $idx)
    if($idxBrace -lt 0){ break }

    $depth = 0
    $inS = $false; $inD = $false; $inLC = $false; $inBC = $false
    $endIdx = -1

    for($i=$idxBrace; $i -lt $txt.Length; $i++){
      $ch = $txt[$i]
      $n1 = if($i+1 -lt $txt.Length){ $txt[$i+1] } else { [char]0 }

      if($inLC){ if($ch -eq "`n"){ $inLC = $false }; continue }
      if($inBC){ if($ch -eq "*" -and $n1 -eq "/"){ $inBC = $false; $i++; continue }; continue }
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
        continue
      }
    }

    if($endIdx -lt 0){ break }

    $after = $endIdx + 1
    if($after -lt $txt.Length -and $txt[$after] -eq "`r"){ $after++ }
    if($after -lt $txt.Length -and $txt[$after] -eq "`n"){ $after++ }

    $txt = $txt.Remove($idx, $after - $idx)
  }
  return $txt
}

function InsertAfterRuntimeOrImports([string]$txt, [string]$insert){
  $insAt = 0

  $mImp = [regex]::Matches($txt, "^\s*import\s+.*?;\s*$", "Multiline")
  if($mImp.Count -gt 0){
    $last = $mImp[$mImp.Count-1]
    $insAt = $last.Index + $last.Length
  }

  $idxRt = $txt.IndexOf("export const runtime")
  if($idxRt -ge 0){
    $idxLineEnd = $txt.IndexOf("`n", $idxRt)
    if($idxLineEnd -gt 0){
      $insAt = $idxLineEnd + 1
    }
  }

  return $txt.Insert($insAt, "`n" + $insert + "`n")
}

$rep = NewReport "eco-step-23-fix-pickup-requests-dedupe-all-helpers"
$log = @()
$log += "# ECO — STEP 23 — Dedupe TOTAL helpers em /api/pickup-requests (ecoWithReceipt + operador + privacy)"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

# Detect schema + fields
$schema = "prisma/schema.prisma"
if(!(Test-Path -LiteralPath $schema)){ $schema = FindFirst "." "\\prisma\\schema\.prisma$" }

$receiptField = "receipt"
$receiptCodeField = "code"
$receiptPublicField = "public"

if($schema -and (Test-Path -LiteralPath $schema)){
  $lines = Get-Content -LiteralPath $schema
  $receiptField = DetectReceiptRelationFieldInPickup $lines
  $rc = DetectModelField $lines "Receipt" @("code","shareCode","publicCode","slug","id")
  if($rc){ $receiptCodeField = $rc }
  $rp = DetectModelField $lines "Receipt" @("public","isPublic")
  if($rp){ $receiptPublicField = $rp } else { $receiptPublicField = "" }
}

$selectPairs = @()
$selectPairs += ($receiptCodeField + ": true")
if($receiptPublicField){ $selectPairs += ($receiptPublicField + ": true") }
$selectBody = ($selectPairs -join ", ")

$log += "## DIAG"
$log += ("schema: {0}" -f ($schema ? $schema : "(não achei)"))
$log += ("PickupRequest.receipt relation field: {0}" -f $receiptField)
$log += ("Receipt code field: {0}" -f $receiptCodeField)
$log += ("Receipt public flag field: {0}" -f ($receiptPublicField ? $receiptPublicField : "(nenhum)"))
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

# counts before
$cntWithReceiptFn = ([regex]::Matches($txt, "function\s+ecoWithReceipt\s*\(", "IgnoreCase")).Count
$cntGetTokenFn   = ([regex]::Matches($txt, "function\s+ecoGetToken\s*\(", "IgnoreCase")).Count
$cntIsOpFn       = ([regex]::Matches($txt, "function\s+ecoIsOperator\s*\(", "IgnoreCase")).Count
$cntPrivacyStart = ([regex]::Matches($txt, "ECO_PICKUP_RECEIPT_PRIVACY_START")).Count

$log += "### Antes (contagens)"
$log += ("- ecoWithReceipt(): {0}" -f $cntWithReceiptFn)
$log += ("- ecoGetToken(): {0}" -f $cntGetTokenFn)
$log += ("- ecoIsOperator(): {0}" -f $cntIsOpFn)
$log += ("- bloco privacy: {0}" -f $cntPrivacyStart)
$log += ""

$log += "## PATCH"
$log += ("Arquivo: {0}" -f $route)
$log += ("Backup : {0}" -f (BackupFile $route))

# 1) remove marked blocks (if any)
$txt = RemoveMarkedBlock $txt "ECO_HELPER_WITH_RECEIPT_START" "ECO_HELPER_WITH_RECEIPT_END"
$txt = RemoveMarkedBlock $txt "ECO_HELPER_OPERATOR_START" "ECO_HELPER_OPERATOR_END"
$txt = RemoveMarkedBlock $txt "ECO_PICKUP_RECEIPT_PRIVACY_START" "ECO_PICKUP_RECEIPT_PRIVACY_END"

# 2) remove stray step markers lines (safe)
$txt = [regex]::Replace($txt, "^\s*//\s*ECO_STEP[0-9A-Za-z_]+\s*.*?`r?`n", "", "Multiline")

# 3) remove ALL old function defs (unmarked) to avoid duplicates
$txt = RemoveAllFunctionDefs $txt "ecoWithReceipt"
$txt = RemoveAllFunctionDefs $txt "ecoGetToken"
$txt = RemoveAllFunctionDefs $txt "ecoIsOperator"

# 4) fix any accidental concatenation "...export const runtime"
$txt = ($txt -replace "([A-Za-z0-9_])export\s+const\s+runtime", ('$1' + "`n" + "export const runtime"))

# 5) re-inject CLEAN helpers ONCE
$helpers = @"
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

 // ECO_HELPER_OPERATOR_START
 function ecoGetToken(req: Request): string | null {
   const h = req.headers.get("x-eco-token") ?? req.headers.get("authorization") ?? "";
   if (h.startsWith("Bearer ")) return h.slice(7).trim();
   if (h && !h.includes(" ")) return h.trim();
   return null;
 }
 function ecoIsOperator(req: Request): boolean {
   const expected = (process.env.ECO_OPERATOR_TOKEN ?? "").trim();
   if (!expected) return false;
   const got = ecoGetToken(req);
   if (!got) return false;
   return got === expected;
 }
 // ECO_HELPER_OPERATOR_END
"@

$helpers = $helpers.Replace("__RECEIPT_FIELD__", $receiptField)
$helpers = $helpers.Replace("__RECEIPT_SELECT__", $selectBody)

$txt = InsertAfterRuntimeOrImports $txt $helpers
$log += "- OK: reinjetei helpers limpos (ecoWithReceipt + operador) uma única vez."

# 6) ensure findMany wraps args-variable (best effort)
$before = $txt
$txt = [regex]::Replace(
  $txt,
  "prisma\.pickupRequest\.findMany\(\s*(?!ecoWithReceipt\()([A-Za-z_][A-Za-z0-9_]*)\s*\)",
  "prisma.pickupRequest.findMany(ecoWithReceipt(`$1))"
)
if($txt -ne $before){
  $log += "- OK: embrulhei prisma.pickupRequest.findMany(VAR) -> ecoWithReceipt(VAR)."
} else {
  $log += "- INFO: não achei findMany(VAR) simples para embrulhar (talvez já use objeto literal)."
}

# 7) re-inject ONE privacy block before returning items (best effort)
$privacy = @"
 // ECO_PICKUP_RECEIPT_PRIVACY_START
 const __eco_isOp = ecoIsOperator(req);
 if (!__eco_isOp) {
   const __rf = "__RECEIPT_FIELD__";
   const __pf = "__RECEIPT_PUBLIC_FIELD__";
   for (const it of (items as any[])) {
     const r = (it as any)?.[__rf];
     if (r && __pf && (r as any)?.[__pf] !== true) {
       (it as any)[__rf] = null;
     }
     if (r && !__pf) {
       (it as any)[__rf] = null;
     }
   }
 }
 // ECO_PICKUP_RECEIPT_PRIVACY_END
"@
$privacy = $privacy.Replace("__RECEIPT_FIELD__", $receiptField)
$privacy = $privacy.Replace("__RECEIPT_PUBLIC_FIELD__", $receiptPublicField)

# insert only if items return exists
$idxReturn = $txt.IndexOf("return NextResponse.json")
if($idxReturn -gt 0 -and $txt -notmatch "ECO_PICKUP_RECEIPT_PRIVACY_START"){
  $txt = $txt.Insert($idxReturn, "`n" + $privacy + "`n")
  $log += "- OK: reinjetei bloco privacy (1x) antes do return NextResponse.json."
} else {
  if($txt -match "ECO_PICKUP_RECEIPT_PRIVACY_START"){
    $log += "- INFO: bloco privacy já presente (não reinjetei)."
  } else {
    $log += "- WARN: não achei 'return NextResponse.json' para injetar privacy; mantive só os helpers."
  }
}

# counts after
$cntWithReceiptFn2 = ([regex]::Matches($txt, "function\s+ecoWithReceipt\s*\(", "IgnoreCase")).Count
$cntGetTokenFn2   = ([regex]::Matches($txt, "function\s+ecoGetToken\s*\(", "IgnoreCase")).Count
$cntIsOpFn2       = ([regex]::Matches($txt, "function\s+ecoIsOperator\s*\(", "IgnoreCase")).Count
$cntPrivacyStart2 = ([regex]::Matches($txt, "ECO_PICKUP_RECEIPT_PRIVACY_START")).Count

$log += ""
$log += "### Depois (contagens)"
$log += ("- ecoWithReceipt(): {0}" -f $cntWithReceiptFn2)
$log += ("- ecoGetToken(): {0}" -f $cntGetTokenFn2)
$log += ("- ecoIsOperator(): {0}" -f $cntIsOpFn2)
$log += ("- bloco privacy: {0}" -f $cntPrivacyStart2)
$log += ""

WriteUtf8NoBom $route $txt

$log += "## VERIFY"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1"
$log += "3) /api/pickup-requests deve voltar 200"
$log += "4) (Opcional) setar token do operador no .env: ECO_OPERATOR_TOKEN=... (e reiniciar dev)"
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 23 aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) /api/pickup-requests deve voltar 200" -ForegroundColor Yellow
Write-Host "4) (Opcional) .env: ECO_OPERATOR_TOKEN=SEU_TOKEN (reinicie o dev)" -ForegroundColor Yellow