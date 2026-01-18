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

$rep = NewReport "eco-step-22b-fix-pickup-requests-privacy-dedupe"
$log = @()
$log += "# ECO — STEP 22b — Dedupe bloco de privacidade do receipt em /api/pickup-requests"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

# schema -> detectar campos (pra não hardcodar)
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

# (A) remover TODOS os blocos marcados (mesmo duplicados)
$opt = [System.Text.RegularExpressions.RegexOptions]::Multiline -bor `
       [System.Text.RegularExpressions.RegexOptions]::Singleline

$patBlock = '^\s*//\s*ECO_PICKUP_RECEIPT_PRIVACY_START.*?^\s*//\s*ECO_PICKUP_RECEIPT_PRIVACY_END\s*`r?`n?'
$beforeLen = $txt.Length
while([System.Text.RegularExpressions.Regex]::IsMatch($txt, $patBlock, $opt)){
  $txt = [System.Text.RegularExpressions.Regex]::Replace($txt, $patBlock, "", $opt)
}
$afterLen = $txt.Length
$log += ("- OK: removi blocos marcados ECO_PICKUP_RECEIPT_PRIVACY (len {0} -> {1})." -f $beforeLen, $afterLen)

# (B) remover linhas órfãs que causam redeclare (caso tenham ficado fora de marcador)
$patOrphan = '^\s*const\s+__eco_isOp\s*=\s*ecoIsOperator\([^\)]*\)\s*;\s*`r?`n'
$txt = [System.Text.RegularExpressions.Regex]::Replace($txt, $patOrphan, "", [System.Text.RegularExpressions.RegexOptions]::Multiline)
$log += "- OK: removi possíveis linhas órfãs 'const __eco_isOp = ecoIsOperator(...)'."

# descobrir nome do param em GET(...)
$reqName = "req"
$mGet = [regex]::Match($txt, 'export\s+async\s+function\s+GET\s*\(\s*([A-Za-z_][A-Za-z0-9_]*)', 'Multiline')
if($mGet.Success){ $reqName = $mGet.Groups[1].Value }

# achar ponto de inserção: antes do return NextResponse.json({ items ... })
$idx = $txt.IndexOf("NextResponse.json({ items")
if($idx -lt 0){ $idx = $txt.IndexOf("NextResponse.json") }
if($idx -lt 0){
  WriteUtf8NoBom $rep ($log -join "`n")
  throw "Não achei NextResponse.json no route."
}
$idxLine = $txt.LastIndexOf("`n", $idx)
if($idxLine -lt 0){ $idxLine = 0 }

# bloco novo (com block-scope pra não quebrar mesmo se duplicar no futuro)
$linesBlock = @(
"// ECO_PICKUP_RECEIPT_PRIVACY_START",
"{",
("  const __eco_isOp = ecoIsOperator({0});" -f $reqName),
"  if (!__eco_isOp) {",
("    const __rf = ""{0}"";" -f $receiptField),
("    const __pf = ""{0}"";" -f $receiptPublicField),
"    for (const it of (items as any[])) {",
"      const r = (it as any)?.[__rf];",
"      if (r && !(r as any)?.[__pf]) {",
"        (it as any)[__rf] = null;",
"      }",
"    }",
"  }",
"}",
"// ECO_PICKUP_RECEIPT_PRIVACY_END",
""
)
$block = ($linesBlock -join "`n")

$txt = $txt.Insert($idxLine + 1, $block + "`n")
$log += "- OK: reinjetei bloco de privacidade (único) antes do return."

WriteUtf8NoBom $route $txt

$log += ""
$log += "## VERIFY"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1"
$log += "3) /api/pickup-requests deve voltar 200"
$log += ""
WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 22b aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) Se passar, teste /pedidos normal vs anônimo" -ForegroundColor Yellow