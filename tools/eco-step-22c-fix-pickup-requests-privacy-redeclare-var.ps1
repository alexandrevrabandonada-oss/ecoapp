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

$rep = NewReport "eco-step-22c-fix-pickup-requests-privacy-redeclare-var"
$log = @()
$log += "# ECO — STEP 22c — Fix rápido: __eco_isOp duplicado (const/let -> var) em /api/pickup-requests"
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

function CountRe([string]$t, [string]$pat){
  return ([regex]::Matches($t, $pat)).Count
}

$cntConst = CountRe $txt "\bconst\s+__eco_isOp\b"
$cntLet   = CountRe $txt "\blet\s+__eco_isOp\b"
$cntVar   = CountRe $txt "\bvar\s+__eco_isOp\b"

$log += "## DIAG"
$log += ("Arquivo: {0}" -f $route)
$log += ("Antes: const={0} | let={1} | var={2}" -f $cntConst, $cntLet, $cntVar)
$log += ""

$log += "## PATCH"
$log += ("Backup: {0}" -f (BackupFile $route))

if(($cntConst + $cntLet) -eq 0){
  $log += "- INFO: não encontrei const/let __eco_isOp (skip)."
} else {
  $before = $txt

  # troca SOMENTE declarações no começo da linha (evita mexer em comentários/strings)
  $txt = [regex]::Replace(
    $txt,
    '(^\s*)(const|let)\s+__eco_isOp\s*=',
    '${1}var __eco_isOp =',
    'Multiline'
  )

  if($txt -ne $before){
    $log += "- OK: converti const/let __eco_isOp -> var __eco_isOp."
  } else {
    $log += "- WARN: padrão não bateu apesar de contagem > 0 (nada alterado)."
  }
}

$cntConst2 = CountRe $txt "\bconst\s+__eco_isOp\b"
$cntLet2   = CountRe $txt "\blet\s+__eco_isOp\b"
$cntVar2   = CountRe $txt "\bvar\s+__eco_isOp\b"

$log += ("Depois: const={0} | let={1} | var={2}" -f $cntConst2, $cntLet2, $cntVar2)
$log += ""

WriteUtf8NoBom $route $txt

$log += "## VERIFY"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1"
$log += "3) /api/pickup-requests deve voltar 200"
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 22c aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) /api/pickup-requests deve voltar 200" -ForegroundColor Yellow