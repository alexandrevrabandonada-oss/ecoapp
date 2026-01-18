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

function GetSchemaPath(){
  $cands = @("prisma/schema.prisma","src/prisma/schema.prisma","schema.prisma")
  foreach($c in $cands){
    if(Test-Path -LiteralPath $c){ return $c }
  }
  return $null
}

$rep = NewReport "eco-step-10c-prisma-add-receipt-public-robust"
$log = @()
$log += "# ECO — STEP 10c — Prisma: adicionar public Boolean @default(false) no Receipt (parser robusto)"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

$schema = GetSchemaPath
if(-not $schema){ throw "Não achei schema.prisma (procurei em prisma/schema.prisma e src/prisma/schema.prisma)." }

$log += "## DIAG (antes)"
$log += ("Schema: {0}" -f $schema)
$log += ("Backup: {0}" -f (BackupFile $schema))
$log += ""

$txt = Get-Content -LiteralPath $schema -Raw

# Regex robusto: pega blocos model ... { ... }
$re = [regex]::new('(?ms)^\s*model\s+([A-Za-z0-9_]+)\s*\{.*?^\s*\}', `
  [System.Text.RegularExpressions.RegexOptions]::Multiline)

$ms = $re.Matches($txt)
if($ms.Count -eq 0){
  $head = ($txt -split "`n", -1 | Select-Object -First 60) -join "`n"
  $log += "ERRO: não consegui detectar nenhum model via regex."
  $log += ""
  $log += "Head do schema (primeiras 60 linhas):"
  $log += $head
  WriteUtf8NoBom $rep ($log -join "`n")
  throw "Não consegui detectar models no schema (parser robusto falhou). Veja o report: $rep"
}

$modelNames = @()
foreach($m in $ms){ $modelNames += $m.Groups[1].Value }
$log += ("Models detectados: {0}" -f ($modelNames -join ", "))
$log += ""

$receiptMatches = @()
foreach($m in $ms){
  $name = $m.Groups[1].Value
  if($name -match '(?i)(receipt|recibo)'){ $receiptMatches += $m }
}

if($receiptMatches.Count -eq 0){
  $log += "ERRO: Nenhum model com nome Receipt/Recibo encontrado."
  $log += "Dica: o endpoint /api/receipts está funcionando, então o nome do model deve conter receipt/recibo no Prisma."
  WriteUtf8NoBom $rep ($log -join "`n")
  throw "Não encontrei model Receipt/Recibo no schema (mesmo com parser robusto). Report: $rep"
}

$log += ("Models alvo: {0}" -f (($receiptMatches | ForEach-Object { $_.Groups[1].Value }) -join ", "))
$log += ""

$changed = 0
foreach($m in $receiptMatches){
  $name = $m.Groups[1].Value
  $block = $m.Value

  if($block -match '(?m)^\s*public\s+Boolean\b'){
    $log += ("- SKIP {0}: já tem field public" -f $name)
    continue
  }

  $insertLine = "  public Boolean @default(false)"

  $idxAttr = [regex]::Match($block, '(?m)^\s*@@').Index
  if($idxAttr -gt 0){
    $newBlock = $block.Insert($idxAttr, $insertLine + "`n")
  } else {
    $idxClose = $block.LastIndexOf("}")
    if($idxClose -lt 0){ throw "Bloco do model $name sem '}' ?" }
    $newBlock = $block.Insert($idxClose, $insertLine + "`n")
  }

  # substitui apenas esse match (posição exata)
  $txt = $txt.Remove($m.Index, $m.Length).Insert($m.Index, $newBlock)
  $changed++
  $log += ("- OK {0}: field public inserido" -f $name)

  # Depois de alterar o texto, precisamos recomputar matches para manter índices corretos:
  $ms = $re.Matches($txt)
  $receiptMatches = @()
  foreach($mm in $ms){
    $n2 = $mm.Groups[1].Value
    if($n2 -match '(?i)(receipt|recibo)'){ $receiptMatches += $mm }
  }
}

WriteUtf8NoBom $schema $txt

$log += ""
$log += "## PATCH"
$log += ("Alterações aplicadas: {0}" -f $changed)
$log += ""

$log += "## FORMAT"
try {
  & npx prisma format | ForEach-Object { $log += $_ }
} catch {
  $log += "WARN: prisma format falhou (seguindo mesmo assim)."
  $log += ($_.Exception.Message)
}

if($changed -gt 0){
  $log += ""
  $log += "## MIGRATE/GENERATE"
  $log += "- npx prisma migrate dev --name eco_receipt_public"
  $log += "- npx prisma generate"
  try {
    & npx prisma migrate dev --name eco_receipt_public | ForEach-Object { $log += $_ }
  } catch {
    $log += "ERRO: migrate dev falhou."
    $log += ($_.Exception.Message)
    throw
  }
  & npx prisma generate | ForEach-Object { $log += $_ }
} else {
  $log += ""
  $log += "## MIGRATE/GENERATE"
  $log += "- Nada a migrar (campo já existia)."
}

$log += ""
$log += "## Próximos passos"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1"
$log += "3) Abra /recibo/[code] e teste o toggle Público/Privado (STEP 10)"
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 10c aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) Abra /recibo/[code] e teste Tornar público/privado" -ForegroundColor Yellow