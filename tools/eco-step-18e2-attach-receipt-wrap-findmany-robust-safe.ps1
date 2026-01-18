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

    # comentários
    if($ch -eq "/" -and $n1 -eq "/"){ $inLC = $true; $i++; continue }
    if($ch -eq "/" -and $n1 -eq "*"){ $inBC = $true; $i++; continue }

    # strings
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

$rep = NewReport "eco-step-18e2-attach-receipt-wrap-findmany-robust-safe"
$log = @()
$log += "# ECO — STEP 18e2 — /api/pickup-requests: anexar receipt (robusto)"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

# localizar rota
$api = "src/app/api/pickup-requests/route.ts"
if(!(Test-Path -LiteralPath $api)){ $api = "app/api/pickup-requests/route.ts" }
if(!(Test-Path -LiteralPath $api)){ $api = FindFirst "src/app" "\\api\\pickup-requests\\route\.ts$" }
if(!(Test-Path -LiteralPath $api)){ $api = FindFirst "app" "\\api\\pickup-requests\\route\.ts$" }
if(-not $api){ throw "Não achei /api/pickup-requests/route.ts" }

$txt = Get-Content -LiteralPath $api -Raw

$log += "## DIAG"
$log += ("API: {0}" -f $api)
$log += ""

if($txt -match "ECO_STEP18E2_ATTACH_RECEIPT"){
  $log += "- INFO: marker já existe (skip)."
  WriteUtf8NoBom $rep ($log -join "`n")
  Write-Host ("✅ STEP 18e2 aplicado (skip). Report -> {0}" -f $rep) -ForegroundColor Green
  exit 0
}

$log += "## PATCH"
$log += ("Backup: {0}" -f (BackupFile $api))
$log += ""

# helper
if($txt -notmatch "function\s+withReceipt\s*\("){
  $helper = @"
`n// ECO_STEP18E2_ATTACH_RECEIPT
function withReceipt(args: any) {
  const a: any = args ?? {};
  if (a?.select?.receipt || a?.include?.receipt) return a;

  if (a.select) return { ...a, select: { ...a.select, receipt: true } };
  return { ...a, include: { ...(a.include ?? {}), receipt: true } };
}
"@
  $mImp = [regex]::Matches($txt, "^\s*import\s+.*?;\s*$", "Multiline")
  if($mImp.Count -gt 0){
    $last = $mImp[$mImp.Count-1]
    $insAt = $last.Index + $last.Length
    $txt = $txt.Insert($insAt, $helper)
    $log += "- OK: helper withReceipt injetado após imports."
  } else {
    $txt = $helper + "`n" + $txt
    $log += "- OK: helper withReceipt injetado no topo."
  }
} else {
  $log += "- INFO: helper withReceipt já existe (skip helper)."
}

# achar findMany preferindo "const items = await ...findMany("
$rx = [regex] "const\s+items\s*=\s*await\s+[\w\.\[\]]+\s*\.findMany\s*\("
$m = $rx.Match($txt)
if($m.Success){
  $idxFind = $m.Index + $m.Value.LastIndexOf(".findMany(")
  $log += "- OK: findMany escolhido via 'const items = await ...'"
} else {
  $idxFind = $txt.IndexOf(".findMany(")
  if($idxFind -lt 0){ throw "Não encontrei '.findMany(' em /api/pickup-requests." }
  $log += "- WARN: findMany escolhido pelo primeiro match."
}

$idxOpen = $txt.IndexOf("(", $idxFind)
if($idxOpen -lt 0){ throw "Achei .findMany mas não achei '('." }

# já embrulhado?
$afterOpen = $txt.Substring($idxOpen+1, [Math]::Min(80, $txt.Length-($idxOpen+1))).TrimStart()
if($afterOpen.StartsWith("withReceipt(")){
  $log += "- INFO: já está com withReceipt (skip wrap)."
} else {
  $idxClose = FindParenClose $txt $idxOpen
  if($idxClose -lt 0){ throw "Não consegui achar o ')' que fecha o findMany(...)." }

  $inside = $txt.Substring($idxOpen+1, $idxClose-($idxOpen+1))
  if($inside.Trim().Length -eq 0){
    # findMany() vazio -> vira findMany(withReceipt({}))
    $txt = $txt.Substring(0, $idxOpen+1) + "withReceipt({})" + $txt.Substring($idxClose)
    $log += "- OK: findMany() vazio -> withReceipt({})."
  } else {
    # inserir withReceipt( ... ) e um ')' antes do fechamento original
    $txt = $txt.Insert($idxOpen+1, "withReceipt(")

    # recalcular close por segurança (texto mudou)
    $idxOpen2 = $txt.IndexOf("(", $idxFind)
    $idxClose2 = FindParenClose $txt $idxOpen2
    if($idxClose2 -lt 0){ throw "Após inserir withReceipt(, não achei fechamento do findMany." }

    $txt = $txt.Insert($idxClose2, ")")
    $log += "- OK: findMany(...) -> findMany(withReceipt(...))."
  }
}

WriteUtf8NoBom $api $txt

$log += ""
$log += "## Próximos passos"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1"
$log += "3) Abra /pedidos: quando houver receipt, deve aparecer 'Ver recibo'."
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 18e2 aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) /pedidos -> deve aparecer 'Ver recibo' quando houver receipt" -ForegroundColor Yellow