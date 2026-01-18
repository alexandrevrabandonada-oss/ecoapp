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

function FindModelBlocks([string]$txt){
  # retorna objetos { name, start, end, blockText }
  $lines = $txt -split "`n", -1
  $blocks = @()
  for($i=0; $i -lt $lines.Count; $i++){
    if($lines[$i] -match '^\s*model\s+([A-Za-z0-9_]+)\s*\{\s*$'){
      $name = $Matches[1]
      $start = $i
      $depth = 0
      for($j=$i; $j -lt $lines.Count; $j++){
        if($lines[$j] -match '\{'){ $depth++ }
        if($lines[$j] -match '\}'){ $depth-- }
        if($depth -eq 0){
          $end = $j
          $blockText = ($lines[$start..$end] -join "`n")
          $blocks += [pscustomobject]@{ name=$name; start=$start; end=$end; block=$blockText }
          $i = $end
          break
        }
      }
    }
  }
  return $blocks
}

$rep = NewReport "eco-step-10b-prisma-add-receipt-public"
$log = @()
$log += "# ECO — STEP 10b — Prisma: adicionar public Boolean @default(false) no Receipt"
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
$blocks = FindModelBlocks $txt

# modelos “Receipt/Recibo”
$receiptBlocks = $blocks | Where-Object { $_.name -match '(?i)(receipt|recibo)' }
if(-not $receiptBlocks -or $receiptBlocks.Count -eq 0){
  $names = ($blocks | Select-Object -ExpandProperty name) -join ", "
  throw "Não encontrei model Receipt/Recibo no schema. Models vistos: $names"
}

$log += ("Models alvo: " + (($receiptBlocks | Select-Object -ExpandProperty name) -join ", "))

$lines = $txt -split "`n", -1
$changed = 0
$patchedNames = @()

foreach($b in $receiptBlocks){
  # checa se já tem public Boolean
  $hasPublic = $false
  for($k=$b.start; $k -le $b.end; $k++){
    if($lines[$k] -match '^\s*public\s+Boolean\b'){ $hasPublic = $true; break }
  }
  if($hasPublic){
    $log += ("- SKIP {0}: já tem field public" -f $b.name)
    continue
  }

  # inserir antes de @@index/@@unique/@@map ou antes do "}"
  $insertAt = $b.end
  for($k=$b.start; $k -le $b.end; $k++){
    if($lines[$k] -match '^\s*@@'){ $insertAt = $k; break }
  }

  $indent = "  "
  $newLine = ($indent + "public Boolean @default(false)")
  $pre = @()
  $pre += $lines[0..($insertAt-1)]
  $pre += $newLine
  $post = @()
  $post += $lines[$insertAt..($lines.Count-1)]
  $lines = @($pre + $post)

  # como mexemos nas linhas, precisamos recomputar blocos pra próximos (mais simples: marcar e seguir)
  $changed++
  $patchedNames += $b.name

  # reparse pra atualizar offsets
  $txt2 = ($lines -join "`n")
  $blocks = FindModelBlocks $txt2
  $receiptBlocks = $blocks | Where-Object { $_.name -match '(?i)(receipt|recibo)' }
}

if($changed -gt 0){
  $txtOut = ($lines -join "`n")
  WriteUtf8NoBom $schema $txtOut
}

$log += ""
$log += "## PATCH"
$log += ("Alterações aplicadas: {0}" -f $changed)
if($patchedNames.Count){ $log += ("Models alterados: " + ($patchedNames -join ", ")) }
$log += ""

$log += "## VERIFY"
$verifyTxt = Get-Content -LiteralPath $schema -Raw
$log += ("Contains 'public Boolean'? " + ($verifyTxt -match '^\s*public\s+Boolean\b'))
$log += ""

# Rodar migrate/generate só se mudou algo
if($changed -gt 0){
  $log += "## MIGRATE/GENERATE"
  $log += "- Rodando: npx prisma migrate dev --name eco_receipt_public"
  $log += "- Rodando: npx prisma generate"
  $log += ""

  & npx prisma migrate dev --name eco_receipt_public | ForEach-Object { $log += $_ }
  & npx prisma generate | ForEach-Object { $log += $_ }
} else {
  $log += "## MIGRATE/GENERATE"
  $log += "- Nada a migrar (campo já existia)."
}

$log += ""
$log += "## Próximos passos"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1"
$log += "3) Abra um recibo: /recibo/[code] e teste o toggle Público/Privado (STEP 10)"
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 10b aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) Abra /recibo/[code] e teste Tornar público/privado + QR" -ForegroundColor Yellow