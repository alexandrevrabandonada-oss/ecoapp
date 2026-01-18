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

function FindParenClose([string]$txt, [int]$openIdx){
  $depth = 0
  $inS = $false
  $inD = $false
  $inLC = $false
  $inBC = $false

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

function FindOpenParenAfter([string]$txt, [int]$idx){
  for($i = $idx; $i -lt $txt.Length; $i++){
    $ch = $txt[$i]
    if($ch -eq "("){ return $i }
    if($ch -eq " " -or $ch -eq "`t" -or $ch -eq "`r" -or $ch -eq "`n"){ continue }
    # se encontrar algo não-whitespace antes do '(', aborta (não é call)
    if($ch -ne "("){ return -1 }
  }
  return -1
}

function DetectReceiptField([string]$schemaPath){
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

$rep = NewReport "eco-step-18f-attach-receipt-findmany-anywhere-safe"
$log = @()
$log += "# ECO — STEP 18f — Anexar receipt no list de pickup-requests (onde estiver)"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

# ===== DIAG schema =====
$schema = "prisma/schema.prisma"
if(!(Test-Path -LiteralPath $schema)){ $schema = FindFirst "." "\\prisma\\schema\.prisma$" }
$receiptField = DetectReceiptField $schema
$log += "## DIAG"
$log += ("schema.prisma: {0}" -f ($schema ? $schema : "(não achei)"))
$log += ("receipt field: {0}" -f $receiptField)
$log += ""

# ===== localizar rota (só para log) =====
$route = "src/app/api/pickup-requests/route.ts"
if(!(Test-Path -LiteralPath $route)){ $route = "app/api/pickup-requests/route.ts" }
if(!(Test-Path -LiteralPath $route)){ $route = FindFirst "src/app" "\\api\\pickup-requests\\route\.ts$" }
if(!(Test-Path -LiteralPath $route)){ $route = FindFirst "app" "\\api\\pickup-requests\\route\.ts$" }
$log += ("route (ref): {0}" -f ($route ? $route : "(não achei)"))
$log += ""

# ===== encontrar o arquivo REAL com findMany do pickupRequest =====
$roots = @()
if(Test-Path -LiteralPath "src"){ $roots += "src" }
if(Test-Path -LiteralPath "app"){ $roots += "app" }
if($roots.Count -eq 0){ throw "Não achei pasta src/ nem app/. Repo está diferente?" }

$candidates = @()

foreach($r in $roots){
  $files = Get-ChildItem -Recurse -File -Path $r -ErrorAction SilentlyContinue |
    Where-Object { $_.Extension -in @(".ts",".tsx",".js",".jsx") }
  foreach($f in $files){
    $t = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction SilentlyContinue
    if(!$t){ continue }

    # precisa ter pickupRequest e findMany em algum lugar do arquivo
    if($t.Contains("pickupRequest") -and $t.Contains("findMany")){
      $candidates += $f.FullName
    }
  }
}

$candidates = $candidates | Select-Object -Unique

$log += "## Arquivos candidatos"
if($candidates.Count -eq 0){
  $log += "- (nenhum) — não achei arquivo com 'pickupRequest' + 'findMany'"
  WriteUtf8NoBom $rep ($log -join "`n")
  throw "Não achei onde é feito o list do pickupRequest. Veja o report: $rep"
} else {
  foreach($c in $candidates){ $log += ("- " + $c) }
}
$log += ""

# ===== PATCH: aplicar no primeiro arquivo que contiver call findMany de pickupRequest =====
$patchedAny = $false

foreach($file in $candidates){
  $txt = Get-Content -LiteralPath $file -Raw
  if($txt -match "ECO_STEP18F_ATTACH_RECEIPT"){ continue }

  # achar a ocorrência de 'findMany' mais próxima de 'pickupRequest'
  $idx = $txt.IndexOf("findMany")
  if($idx -lt 0){ continue }

  # procurar ".findMany" também (mas sem exigir '(')
  $idxDot = $txt.IndexOf(".findMany")
  if($idxDot -lt 0){ $idxDot = $idx }

  # achar '(' depois de findMany (pode ter espaço/linha)
  $idxOpen = FindOpenParenAfter $txt ($idxDot + 8)
  if($idxOpen -lt 0){ continue }

  # limitar: somente se houver "pickupRequest" nos 200 chars antes
  $from = [Math]::Max(0, $idxDot - 200)
  $before = $txt.Substring($from, $idxDot - $from)
  if(-not $before.Contains("pickupRequest")){ continue }

  $idxClose = FindParenClose $txt $idxOpen
  if($idxClose -lt 0){ continue }

  $inside = $txt.Substring($idxOpen+1, $idxClose-($idxOpen+1))

  # helper
  $helper = @"
`n// ECO_STEP18F_ATTACH_RECEIPT
function withReceipt(args: any) {
  const a: any = args ?? {};
  if (a?.select?.$receiptField || a?.include?.$receiptField) return a;
  if (a.select) return { ...a, select: { ...a.select, $receiptField: true } };
  return { ...a, include: { ...(a.include ?? {}), $receiptField: true } };
}
"@

  $log += "## PATCH"
  $log += ("Arquivo: {0}" -f $file)
  $log += ("Backup : {0}" -f (BackupFile $file))

  # injeta helper após imports (ou topo)
  if(-not $txt.Contains("function withReceipt(args")){
    $mImp = [regex]::Matches($txt, "^\s*import\s+.*?;\s*$", "Multiline")
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
    $log += "- INFO: helper já existe."
  }

  # recalcular índices no texto já modificado
  $idxDot2 = $txt.IndexOf(".findMany", $from)
  if($idxDot2 -lt 0){ $idxDot2 = $txt.IndexOf("findMany", $from) }
  if($idxDot2 -lt 0){ throw "Perdi o findMany após inserir helper, arquivo: $file" }

  $idxOpen2 = FindOpenParenAfter $txt ($idxDot2 + 8)
  if($idxOpen2 -lt 0){ throw "Não achei '(' após findMany (mesmo após helper), arquivo: $file" }

  $idxClose2 = FindParenClose $txt $idxOpen2
  if($idxClose2 -lt 0){ throw "Não achei ')' do findMany, arquivo: $file" }

  $inside2 = $txt.Substring($idxOpen2+1, $idxClose2-($idxOpen2+1)).TrimStart()

  if($inside2.StartsWith("withReceipt(")){
    $log += "- INFO: findMany já está embrulhado (skip wrap)."
  } else {
    if($inside2.Trim().Length -eq 0){
      $txt = $txt.Substring(0, $idxOpen2+1) + "withReceipt({})" + $txt.Substring($idxClose2)
      $log += "- OK: findMany() -> withReceipt({})."
    } else {
      $txt = $txt.Insert($idxOpen2+1, "withReceipt(")
      $idxClose3 = FindParenClose $txt $idxOpen2
      if($idxClose3 -lt 0){ throw "Após inserir withReceipt(, não achei fechamento do findMany, arquivo: $file" }
      $txt = $txt.Insert($idxClose3, ")")
      $log += "- OK: findMany(ARG) -> findMany(withReceipt(ARG))."
    }
  }

  WriteUtf8NoBom $file $txt
  $patchedAny = $true
  $log += ""
  $log += "- DONE: patch aplicado neste arquivo."
  $log += ""
  break
}

if(-not $patchedAny){
  WriteUtf8NoBom $rep ($log -join "`n")
  throw "Achei candidatos, mas não encontrei um call findMany aplicável (pickupRequest perto). Veja o report: $rep"
}

$log += "## Próximos passos"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1"
$log += "3) Abra /pedidos: quando vier receipt, deve aparecer 'Ver recibo'."
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 18f aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) /pedidos -> deve aparecer 'Ver recibo' quando houver receipt" -ForegroundColor Yellow