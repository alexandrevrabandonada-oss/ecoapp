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

function FindBestFindManyIndex([string]$txt){
  $matches = [regex]::Matches($txt, "\.findMany\s*\(")
  if($matches.Count -eq 0){ return -1 }

  $bestIdx = -1
  $bestScore = -999

  foreach($m in $matches){
    $i = $m.Index
    $start = [Math]::Max(0, $i - 180)
    $ctx = $txt.Substring($start, [Math]::Min(260, $txt.Length - $start))

    $score = 0
    if($ctx -match "const\s+items\s*="){ $score += 50 }
    if($ctx -match "\bitems\b"){ $score += 10 }
    if($ctx -match "pickup" -or $ctx -match "Pickup"){ $score += 10 }
    if($ctx -match "request" -or $ctx -match "Request"){ $score += 5 }

    if($score -gt $bestScore){
      $bestScore = $score
      $bestIdx = $i
    }
  }
  return $bestIdx
}

function FindMatchingParenClose([string]$txt, [int]$openIdx){
  $depth = 0
  $inS = $false
  $inD = $false
  $inT = $false
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
    if($inT){
      if($ch -eq "\" -and $n1 -ne [char]0){ $i++; continue }
      if($ch -eq "`"){ $inT = $false }
      continue
    }

    # comentários
    if($ch -eq "/" -and $n1 -eq "/"){ $inLC = $true; $i++; continue }
    if($ch -eq "/" -and $n1 -eq "*"){ $inBC = $true; $i++; continue }

    # strings
    if($ch -eq "'"){ $inS = $true; continue }
    if($ch -eq '"'){ $inD = $true; continue }
    if($ch -eq "`"){ $inT = $true; continue }

    if($ch -eq "("){
      $depth++
      continue
    }
    if($ch -eq ")"){
      $depth--
      if($depth -eq 0){
        return $i
      }
      continue
    }
  }
  return -1
}

$rep = NewReport "eco-step-18e-attach-receipt-wrap-findmany-robust"
$log = @()
$log += "# ECO — STEP 18e — /api/pickup-requests: anexar receipt via wrap findMany()"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

# =========
# DIAG: localizar rota
# =========
$api = "src/app/api/pickup-requests/route.ts"
if(!(Test-Path -LiteralPath $api)){ $api = "app/api/pickup-requests/route.ts" }
if(!(Test-Path -LiteralPath $api)){ $api = FindFirst "src/app" "\\api\\pickup-requests\\route\.ts$" }
if(!(Test-Path -LiteralPath $api)){ $api = FindFirst "app" "\\api\\pickup-requests\\route\.ts$" }
if(-not $api){ throw "Não achei /api/pickup-requests/route.ts" }

$log += "## DIAG"
$log += ("API: {0}" -f $api)
$log += ""

$txt = Get-Content -LiteralPath $api -Raw

if($txt -match "ECO_STEP18E_ATTACH_RECEIPT"){
  $log += "- INFO: marker já existe (skip)."
  WriteUtf8NoBom $rep ($log -join "`n")
  Write-Host ("✅ STEP 18e aplicado (skip). Report -> {0}" -f $rep) -ForegroundColor Green
  exit 0
}

$idxFind = FindBestFindManyIndex $txt
if($idxFind -lt 0){
  throw "Não encontrei nenhuma ocorrência de '.findMany(' em /api/pickup-requests."
}

# achar o '(' do findMany
$idxOpen = $txt.IndexOf("(", $idxFind)
if($idxOpen -lt 0){ throw "Achei .findMany mas não achei '(' logo após." }

# achar fechamento do parêntese do findMany
$idxClose = FindMatchingParenClose $txt $idxOpen
if($idxClose -lt 0){ throw "Não consegui achar o ')' de fechamento do findMany (parser simples falhou)." }

$log += ("- findMany() escolhido em index {0}" -f $idxFind)

# =========
# PATCH
# =========
$log += ""
$log += "## PATCH"
$log += ("Backup: {0}" -f (BackupFile $api))
$log += ""

# 1) injetar helper (perto do topo) — depois de imports, ou no começo do arquivo
$helper = @"
`n// ECO_STEP18E_ATTACH_RECEIPT
function withReceipt(args: any) {
  const a: any = args ?? {};
  // se já tem select/include de receipt, mantém
  if (a?.select?.receipt || a?.include?.receipt) return a;

  if (a.select) {
    return { ...a, select: { ...a.select, receipt: true } };
  }
  return { ...a, include: { ...(a.include ?? {}), receipt: true } };
}
"@

if($txt -match "function\s+withReceipt\("){
  $log += "- INFO: helper withReceipt já existe (skip helper)."
} else {
  # tenta inserir após último import
  $mImp = [regex]::Matches($txt, "^\s*import\s+.*?;\s*$", "Multiline")
  if($mImp.Count -gt 0){
    $last = $mImp[$mImp.Count-1]
    $insAt = $last.Index + $last.Length
    $txt = $txt.Insert($insAt, $helper)
    $log += "- OK: helper withReceipt injetado após imports."
  } else {
    $txt = $helper + "`n" + $txt
    $log += "- OK: helper withReceipt injetado no topo (sem imports detectados)."
  }
}

# 2) embrulhar findMany( X ) -> findMany(withReceipt( X ))
#    trocar apenas a ocorrência escolhida
$before = $txt.Substring(0, $idxOpen+1) # inclui '('
$after = $txt.Substring($idxOpen+1)

# evitar duplicar se já estiver com withReceipt(
if($after.TrimStart().StartsWith("withReceipt(")){
  $log += "- INFO: findMany já está embrulhado com withReceipt (skip wrap)."
} else {
  $txt = $before + "withReceipt(" + $after

  # como adicionamos 1 '(' extra, precisamos inserir 1 ')' antes do ')' original
  # recalcular close (porque o texto mudou)
  $idxOpen2 = $txt.IndexOf("(", $idxFind) # open do findMany (o mesmo)
  $idxClose2 = FindMatchingParenClose $txt $idxOpen2
  if($idxClose2 -lt 0){ throw "Após wrap, não consegui recalcular fechamento do findMany." }

  # inserir ')' antes do ')' final
  $txt = $txt.Insert($idxClose2, ")")
  $log += "- OK: findMany(...) agora chama findMany(withReceipt(...))."
}

WriteUtf8NoBom $api $txt

$log += ""
$log += "## Próximos passos"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1"
$log += "3) Abra /pedidos: quando houver receipt, deve aparecer 'Ver recibo'."
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 18e aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) /pedidos -> deve aparecer 'Ver recibo' quando houver receipt" -ForegroundColor Yellow