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

$rep = NewReport "eco-step-32c-fix-eco-smoke-triagem"
$log = @()
$log += "# ECO — STEP 32c — Fix eco-smoke (/operador/triagem) sem vírgula"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

$smoke = "tools/eco-smoke.ps1"
if(!(Test-Path -LiteralPath $smoke)){
  $smoke = FindFirst "." "\\tools\\eco-smoke\.ps1$"
}
if(!(Test-Path -LiteralPath $smoke)){
  $log += "## ERRO"
  $log += "Não achei tools/eco-smoke.ps1"
  WriteUtf8NoBom $rep ($log -join "`n")
  throw "Não achei eco-smoke.ps1"
}

$bk = BackupFile $smoke
$lines = Get-Content -LiteralPath $smoke

$log += "## DIAG"
$log += ("Arquivo: {0}" -f $smoke)
$log += ("Backup : {0}" -f $bk)
$log += ""

# 1) se já existe com vírgula, remove a vírgula
$changed = $false
for($i=0; $i -lt $lines.Count; $i++){
  if($lines[$i] -match "(/operador/triagem)'\s*,\s*$"){
    $lines[$i] = ($lines[$i] -replace ",\s*$", "")
    $changed = $true
  }
  if($lines[$i] -match '(/operador/triagem)"\s*,\s*$'){
    $lines[$i] = ($lines[$i] -replace ",\s*$", "")
    $changed = $true
  }
}

# 2) se não existe, insere após /recibos (sem vírgula)
$hasTri = ($lines | Where-Object { $_ -match "/operador/triagem" } | Select-Object -First 1)
if(-not $hasTri){
  $idx = -1
  for($i=0; $i -lt $lines.Count; $i++){
    if($lines[$i] -match "/recibos"){ $idx = $i; break }
  }

  $newLine = "  '/operador/triagem'"
  if($idx -ge 0){
    $lines = @($lines[0..$idx] + $newLine + $lines[($idx+1)..($lines.Count-1)])
    $changed = $true
    $log += "- OK: inseri /operador/triagem após /recibos (sem vírgula)."
  } else {
    # fallback: coloca perto do topo
    $lines = @($newLine) + $lines
    $changed = $true
    $log += "- OK: inseri /operador/triagem no topo (fallback)."
  }
} else {
  $log += "- INFO: /operador/triagem já existia (só normalizei vírgula se tinha)."
}

if($changed){
  WriteUtf8NoBom $smoke ($lines -join "`n")
  $log += "- OK: eco-smoke.ps1 atualizado."
} else {
  $log += "- INFO: nada mudou."
}

$log += ""
$log += "## VERIFY"
$log += "Rode: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1"
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 32c aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow