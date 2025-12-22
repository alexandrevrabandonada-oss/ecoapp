$ErrorActionPreference = "Stop"

function Ensure-Dir([string]$p){ if(!(Test-Path $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function WriteUtf8NoBom([string]$path, [string]$content){
  $dir = Split-Path $path -Parent
  if($dir){ Ensure-Dir $dir }
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
}
function Backup-File([string]$path){
  if(!(Test-Path $path)){ return $null }
  Ensure-Dir "tools/_patch_backup"
  $ts = Get-Date -Format "yyyyMMdd-HHmmss"
  $safe = ($path -replace '[\\/:*?"<>|]', '_')
  $dst = "tools/_patch_backup/$ts-$safe"
  Copy-Item -Force $path $dst
  return $dst
}
function New-Report([string]$name){
  Ensure-Dir "reports"
  $ts = Get-Date -Format "yyyyMMdd-HHmmss"
  return "reports/$ts-$name.md"
}
function ToLowerCamel([string]$s){
  if([string]::IsNullOrWhiteSpace($s)){ return $s }
  if($s.Length -eq 1){ return $s.ToLower() }
  return $s.Substring(0,1).ToLower() + $s.Substring(1)
}
function Run([string]$cmd){
  Write-Host ">> $cmd" -ForegroundColor DarkGray
  & cmd.exe /d /s /c $cmd
  if($LASTEXITCODE -ne 0){ throw "Falhou: $cmd (exit=$LASTEXITCODE)" }
}

Ensure-Dir "tools"
Ensure-Dir "tools/_patch_backup"
Ensure-Dir "reports"

$rep = New-Report "eco-prisma-pickuprequest-fix"
$log = @()
$log += "# ECO — Prisma Fix (PickupRequest)"
$log += ""
$log += "- Data: " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
$log += "- PWD : " + (Get-Location).Path
$log += "- Node: " + (node -v 2>$null)
$log += "- npm : " + (npm -v 2>$null)
$log += ""

$schemaPath = "prisma/schema.prisma"
if(!(Test-Path $schemaPath)){
  $log += "❌ Não achei $schemaPath"
  WriteUtf8NoBom $rep ($log -join "`n")
  throw "Não achei prisma/schema.prisma"
}

$bak = Backup-File $schemaPath
if($bak){ $log += "- Backup schema: $bak" }

$txt = Get-Content $schemaPath -Raw

# --- DIAG: achar models que referenciam PickupRequest ---
$refs = @()
$matches = [regex]::Matches($txt, '(?ms)^\s*model\s+([A-Za-z_]\w*)\s*\{.*?^\s*\}\s*$')
foreach($m in $matches){
  $modelName = $m.Groups[1].Value
  $block = $m.Value
  if($modelName -ne "PickupRequest" -and ($block -match '(?m)^\s*\w+\s+PickupRequest\b')){
    $hasUnique = $false
    if($block -match '(?m)^\s*requestId\s+String\b.*@unique'){ $hasUnique = $true }
    $refs += [pscustomobject]@{ ModelName = $modelName; Unique = $hasUnique }
  }
}
$log += "## DIAG"
$log += "- Refs -> PickupRequest: " + ($refs.Count)
if($refs.Count -gt 0){
  $log += '```'
  foreach($r in $refs){
    $log += ("- " + $r.ModelName + " (requestId unique: " + $r.Unique + ")")
  }
  $log += '```'
}
$log += ""

# --- PATCH: criar ou completar model PickupRequest ---
$hasPickupRequest = ($txt -match '(?m)^\s*model\s+PickupRequest\s*\{')
if(-not $hasPickupRequest){
  $log += "## PATCH"
  $log += "- model PickupRequest não existia -> vou criar"

  $lines = @()
  $lines += "model PickupRequest {"
  $lines += "  id        String   @id @default(cuid())"
  $lines += "  createdAt DateTime @default(now())"
  $lines += "  updatedAt DateTime @updatedAt"

  foreach($r in $refs){
    $field = ToLowerCamel $r.ModelName
    if($r.Unique){
      $lines += ("  " + $field + " " + $r.ModelName + "?")
    } else {
      # plural simples: adiciona 's'
      $lines += ("  " + $field + "s " + $r.ModelName + "[]")
    }
  }

  $lines += "}"
  $lines += ""

  $modelText = ($lines -join "`n")

  $firstModel = [regex]::Match($txt, '(?m)^\s*model\s+')
  if(-not $firstModel.Success){
    throw "Não consegui achar ponto de inserção de models no schema."
  }

  $txt = $txt.Substring(0, $firstModel.Index) + $modelText + $txt.Substring($firstModel.Index)
  $log += "- Inserido PickupRequest antes do primeiro model: OK"
} else {
  $log += "## PATCH"
  $log += "- model PickupRequest existe -> vou garantir back-relations"

  $prMatch = [regex]::Match($txt, '(?ms)^\s*model\s+PickupRequest\s*\{.*?^\s*\}\s*$')
  if(-not $prMatch.Success){
    throw "Achei 'model PickupRequest' mas não consegui capturar o bloco."
  }

  $prBlock = $prMatch.Value
  $prLines = $prBlock -split "(`r`n|`n|`r)"
  $closeIdx = -1
  for($i=$prLines.Length-1; $i -ge 0; $i--){
    if($prLines[$i].Trim() -eq "}"){ $closeIdx = $i; break }
  }
  if($closeIdx -lt 0){ throw "Não achei '}' final do model PickupRequest." }

  $added = 0
  foreach($r in $refs){
    $field = ToLowerCamel $r.ModelName
    $needLine = ""
    if($r.Unique){
      $needLine = ("  " + $field + " " + $r.ModelName + "?")
    } else {
      $needLine = ("  " + $field + "s " + $r.ModelName + "[]")
    }

    $typePattern = "(?m)^\s*" + [regex]::Escape($field) + "s?\s+" + [regex]::Escape($r.ModelName) + "\b"
    if(-not ([regex]::IsMatch($prBlock, $typePattern))){
      $prLines = @($prLines[0..($closeIdx-1)] + $needLine + $prLines[$closeIdx..($prLines.Length-1)])
      $closeIdx += 1
      $added += 1
    }
  }

  $newPrBlock = ($prLines -join "`n")
  $txt = $txt.Substring(0, $prMatch.Index) + $newPrBlock + $txt.Substring($prMatch.Index + $prMatch.Length)
  $log += "- Back-relations adicionadas: $added"
}

WriteUtf8NoBom $schemaPath $txt
$log += "- Schema salvo: OK"
$log += ""

# --- VERIFY ---
$log += "## VERIFY"
try {
  Run "npx prisma format --schema=prisma/schema.prisma"
  $log += "- prisma format: OK"
} catch {
  $log += "- prisma format: FAIL"
  throw
}

try {
  Run "npx prisma generate --schema=prisma/schema.prisma"
  $log += "- prisma generate: OK"
} catch {
  $log += "- prisma generate: FAIL"
  throw
}

# db push é opcional mas ajuda a evitar 'table does not exist' depois
try {
  Run "npx prisma db push --schema=prisma/schema.prisma"
  $log += "- prisma db push: OK"
} catch {
  $log += "- prisma db push: FAIL (sem aplicar). Pode ser alerta de data loss; a gente revisa depois."
}

WriteUtf8NoBom $rep ($log -join "`n")
Write-Host "✅ Fix aplicado. Report -> $rep" -ForegroundColor Green