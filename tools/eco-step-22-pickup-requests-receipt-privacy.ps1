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

function DetectFieldInModel([string[]]$lines, [string]$modelName, [string[]]$candidates){
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

function RemoveMarkedBlock([string]$txt, [string]$startMark, [string]$endMark){
  $pat = '(?s)^\s*' + [regex]::Escape($startMark) + '.*?' + [regex]::Escape($endMark) + '\s*`r?`n?'
  return [regex]::Replace($txt, $pat, '', 'Multiline')
}

$rep = NewReport "eco-step-22-pickup-requests-receipt-privacy"
$log = @()
$log += "# ECO — STEP 22 — Privacidade do receipt em /api/pickup-requests"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

# DIAG schema
$schema = "prisma/schema.prisma"
if(!(Test-Path -LiteralPath $schema)){ $schema = FindFirst "." "\\prisma\\schema\.prisma$" }

$receiptField = "receipt"
$receiptPublicField = "public"

if($schema -and (Test-Path -LiteralPath $schema)){
  $lines = Get-Content -LiteralPath $schema
  $receiptField = DetectReceiptRelationFieldInPickup $lines
  $pf = DetectFieldInModel $lines "Receipt" @("public","isPublic")
  if($pf){ $receiptPublicField = $pf }
}

$log += "## DIAG"
$log += ("schema: {0}" -f ($schema ? $schema : "(não achei)"))
$log += ("PickupRequest receipt field: {0}" -f $receiptField)
$log += ("Receipt public field: {0}" -f $receiptPublicField)
$log += ""

# locate route
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

# Detect GET param name (req vs request)
$reqName = "req"
$mGet = [regex]::Match($txt, 'export\s+async\s+function\s+GET\s*\(\s*([A-Za-z_][A-Za-z0-9_]*)', 'Multiline')
if($mGet.Success){ $reqName = $mGet.Groups[1].Value }

# (1) Operator helper (idempotent)
$startOp = "// ECO_HELPER_OPERATOR_START"
$endOp   = "// ECO_HELPER_OPERATOR_END"
$txt = RemoveMarkedBlock $txt $startOp $endOp

$opLines = @(
$startOp,
'function ecoGetToken(req: Request): string | null {',
'  const h = req.headers.get("x-eco-token") ?? req.headers.get("authorization") ?? "";',
'  if (h.startsWith("Bearer ")) return h.slice(7).trim();',
'  if (h && !h.includes(" ")) return h.trim();',
'  try {',
'    const u = new URL(req.url);',
'    const t = u.searchParams.get("token");',
'    if (t) return t.trim();',
'  } catch {}',
'  return null;',
'}',
'function ecoIsOperator(req: Request): boolean {',
'  const t = ecoGetToken(req);',
'  if (!t) return false;',
'  const env = process.env.ECO_OPERATOR_TOKEN;',
'  if (!env) return false;',
'  const allow = env.split(",").map(s => s.trim()).filter(Boolean);',
'  return allow.includes(t);',
'}',
$endOp,
''
)
$opBlock = ($opLines -join "`n")

# insert after last import (and after runtime export if it's right there)
$mImp = [regex]::Matches($txt, '^\s*import\s+.*?;\s*$', 'Multiline')
$insAt = 0
if($mImp.Count -gt 0){
  $last = $mImp[$mImp.Count-1]
  $insAt = $last.Index + $last.Length
}
# if runtime line is immediately after imports, insert after it
if($insAt -lt $txt.Length){
  $sliceLen = [Math]::Min(800, $txt.Length - $insAt)
  $slice = $txt.Substring($insAt, $sliceLen)
  $idxRt = $slice.IndexOf("export const runtime")
  if($idxRt -ge 0){
    $abs = $insAt + $idxRt
    $lnEnd = $txt.IndexOf("`n", $abs)
    if($lnEnd -gt 0){ $insAt = $lnEnd + 1 }
  }
}
$txt = $txt.Insert($insAt, "`n" + $opBlock + "`n")
$log += "- OK: helper ecoIsOperator inserido (idempotente)."

# (2) Privacy block before success return (idempotent)
$startPv = "// ECO_PICKUP_RECEIPT_PRIVACY_START"
$endPv   = "// ECO_PICKUP_RECEIPT_PRIVACY_END"
$txt = RemoveMarkedBlock $txt $startPv $endPv

# find a return that likely returns items
$idx = $txt.IndexOf("NextResponse.json")
if($idx -lt 0){
  WriteUtf8NoBom $rep ($log -join "`n")
  throw "Não achei NextResponse.json no route."
}

# prefer a return that mentions 'items'
$idxItemsReturn = $txt.IndexOf("NextResponse.json({ items")
if($idxItemsReturn -ge 0){ $idx = $idxItemsReturn }

$idxLine = $txt.LastIndexOf("`n", $idx)
if($idxLine -lt 0){ $idxLine = 0 }

$pvLines = @(
$startPv,
("const __eco_isOp = ecoIsOperator({0});" -f $reqName),
'if (!__eco_isOp) {',
("  const __rf = ""{0}"";" -f $receiptField),
("  const __pf = ""{0}"";" -f $receiptPublicField),
'  for (const it of (items as any[])) {',
'    const r = (it as any)?.[__rf];',
'    if (r && !(r as any)?.[__pf]) {',
'      (it as any)[__rf] = null;',
'    }',
'  }',
'}',
$endPv,
''
)
$pvBlock = ($pvLines -join "`n")

$txt = $txt.Insert($idxLine + 1, $pvBlock + "`n")
$log += "- OK: bloco de privacidade inserido antes do return de items."

WriteUtf8NoBom $route $txt

$log += ""
$log += "## VERIFY"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1"
$log += "3) Teste /pedidos: operador vê recibo privado; anônimo só vê recibo public."
$log += ""
WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 22 aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) /pedidos normal vs anônimo: privado some p/ anônimo; public continua." -ForegroundColor Yellow