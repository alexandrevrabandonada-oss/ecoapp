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

$rep = NewReport "eco-step-18h2-fix-findmany-type-and-wrap-runtime"
$log = @()
$log += "# ECO — STEP 18h2 — Fix: findMany type quebrado + wrap no runtime"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

$route = "src/app/api/pickup-requests/route.ts"
if(!(Test-Path -LiteralPath $route)){ $route = "app/api/pickup-requests/route.ts" }
if(!(Test-Path -LiteralPath $route)){
  $route = FindFirst "." "\\api\\pickup-requests\\route\.(ts|js)$"
}
if(-not $route){
  WriteUtf8NoBom $rep ($log -join "`n")
  throw "Não achei /api/pickup-requests/route.(ts|js). Veja: $rep"
}

$log += "## DIAG"
$log += ("route: {0}" -f $route)
$log += ""

$txt = Get-Content -LiteralPath $route -Raw

$log += "## PATCH"
$log += ("Backup: {0}" -f (BackupFile $route))

# 1) Corrigir tipagem quebrada: qualquer linha findMany?: ... com ecoWithReceipt vira assinatura normal
$lines = $txt -split "`n"
$fixedType = $false
for($i=0; $i -lt $lines.Count; $i++){
  if($lines[$i] -match "findMany\?\s*:" -and $lines[$i].Contains("ecoWithReceipt")){
    $indent = ($lines[$i] -replace '^(\s*).*$', '$1')
    $lines[$i] = ($indent + "findMany?: (args?: any) => Promise<any>;")
    $fixedType = $true
  }
}
if($fixedType){
  $txt = ($lines -join "`n")
  $log += "- OK: tipagem findMany (AnyDelegate) corrigida (remove ecoWithReceipt da assinatura)."
} else {
  $log += "- INFO: não achei tipagem findMany quebrada (ou já corrigida)."
}

# 2) Wrap no runtime: procurar delegate.findMany(
$idx = $txt.IndexOf("delegate.findMany")
if($idx -lt 0){
  WriteUtf8NoBom $rep ($log -join "`n")
  throw "Não encontrei 'delegate.findMany' no arquivo. Eu não vou embrulhar findMany genérico de novo (evita quebrar type). Veja: $rep"
}

$idxOpen = $txt.IndexOf("(", $idx)
if($idxOpen -lt 0){
  WriteUtf8NoBom $rep ($log -join "`n")
  throw "Não achei '(' após delegate.findMany. Veja: $rep"
}

$idxClose = FindParenClose $txt $idxOpen
if($idxClose -lt 0){
  WriteUtf8NoBom $rep ($log -join "`n")
  throw "Não achei fechamento ')' da chamada delegate.findMany(...). Veja: $rep"
}

$inside = $txt.Substring($idxOpen+1, $idxClose-($idxOpen+1))
$insideTrim = $inside.Trim()

if($insideTrim.StartsWith("ecoWithReceipt(")){
  $log += "- INFO: runtime já está embrulhado com ecoWithReceipt (skip)."
} else {
  if($insideTrim.Length -eq 0){
    $txt = $txt.Substring(0, $idxOpen+1) + "ecoWithReceipt({})" + $txt.Substring($idxClose)
    $log += "- OK: delegate.findMany() -> delegate.findMany(ecoWithReceipt({}))."
  } else {
    $txt = $txt.Substring(0, $idxOpen+1) + "ecoWithReceipt(" + $inside + ")" + $txt.Substring($idxClose)
    $log += "- OK: delegate.findMany(ARG) -> delegate.findMany(ecoWithReceipt(ARG))."
  }
}

WriteUtf8NoBom $route $txt

$log += ""
$log += "## Próximos passos"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1"
$log += "3) /api/pickup-requests deve voltar 200"
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 18h2 aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) /api/pickup-requests -> 200" -ForegroundColor Yellow