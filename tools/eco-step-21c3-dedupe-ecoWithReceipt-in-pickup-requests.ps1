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

function FindBraceClose([string]$txt, [int]$openIdx){
  $depth = 0
  $inS = $false; $inD = $false; $inLC = $false; $inBC = $false

  for($i=$openIdx; $i -lt $txt.Length; $i++){
    $ch = $txt[$i]
    $n1 = if($i+1 -lt $txt.Length){ $txt[$i+1] } else { [char]0 }

    if($inLC){ if($ch -eq "`n"){ $inLC = $false }; continue }
    if($inBC){ if($ch -eq "*" -and $n1 -eq "/"){ $inBC=$false; $i++; }; continue }

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

    if($ch -eq "{"){ $depth++; continue }
    if($ch -eq "}"){
      $depth--
      if($depth -eq 0){ return $i }
      continue
    }
  }
  return -1
}

function LineStart([string]$txt, [int]$idx){
  if($idx -le 0){ return 0 }
  $p = $txt.LastIndexOf("`n", [Math]::Max(0, $idx-1))
  if($p -lt 0){ return 0 }
  return $p + 1
}

$rep = NewReport "eco-step-21c3-dedupe-ecoWithReceipt-in-pickup-requests"
$log = @()
$log += "# ECO — STEP 21c3 — Dedupe ecoWithReceipt no /api/pickup-requests"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

$route = "src/app/api/pickup-requests/route.ts"
if(!(Test-Path -LiteralPath $route)){
  $route = FindFirst "." "\\api\\pickup-requests\\route\.ts$"
}
$log += ("route: {0}" -f ($route ? $route : "(não achei)"))
if(-not $route){
  WriteUtf8NoBom $rep ($log -join "`n")
  throw "Não achei /api/pickup-requests/route.ts. Veja: $rep"
}

$txt = Get-Content -LiteralPath $route -Raw
$backup = BackupFile $route
$log += ("backup: {0}" -f $backup)
$log += ""

# localizar ocorrências
$needle = "function ecoWithReceipt("
$idxs = New-Object System.Collections.Generic.List[int]
$pos = 0
while($true){
  $i = $txt.IndexOf($needle, $pos)
  if($i -lt 0){ break }
  $idxs.Add($i) | Out-Null
  $pos = $i + $needle.Length
}

$log += "## DIAG"
$log += ("ocorrências de ecoWithReceipt: {0}" -f $idxs.Count)
$log += ""

if($idxs.Count -le 1){
  $log += "- OK: não há duplicata. Nada a fazer."
  WriteUtf8NoBom $rep ($log -join "`n")
  Write-Host ("✅ STEP 21c3: nada a alterar (já estava ok). Report -> {0}" -f $rep) -ForegroundColor Green
  exit 0
}

# vamos remover TODAS exceto a primeira (mantém a mais antiga/primeira definida no arquivo)
$removed = 0
for($k = $idxs.Count-1; $k -ge 1; $k--){
  $startFun = $idxs[$k]

  # tenta recuar até um marcador ECO_STEP na linha anterior (se tiver)
  $windowStart = [Math]::Max(0, $startFun - 400)
  $window = $txt.Substring($windowStart, $startFun - $windowStart)
  $m = [regex]::Match($window, "(?ms)(^.*?//\s*ECO_STEP[^\r\n]*\r?\n)\s*$")
  if($m.Success){
    $startFun = $windowStart + $m.Groups[1].Index
  } else {
    $startFun = LineStart $txt $startFun
  }

  # achar { do function
  $braceOpen = $txt.IndexOf("{", $idxs[$k])
  if($braceOpen -lt 0){ continue }
  $braceClose = FindBraceClose $txt $braceOpen
  if($braceClose -lt 0){ continue }

  # incluir newline depois do }
  $end = $braceClose + 1
  if($end -lt $txt.Length -and $txt[$end] -eq "`r"){ $end++ }
  if($end -lt $txt.Length -and $txt[$end] -eq "`n"){ $end++ }

  $txt = $txt.Remove($startFun, $end - $startFun)
  $removed++
}

$log += "## PATCH"
$log += ("- removidas duplicatas: {0}" -f $removed)
$log += "- mantida apenas 1 definição de ecoWithReceipt()"
$log += ""

WriteUtf8NoBom $route $txt

$log += "## VERIFY"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1"
$log += "3) /api/pickup-requests deve voltar 200 (sem erro de 'defined multiple times')"
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 21c3 aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) /api/pickup-requests deve voltar 200" -ForegroundColor Yellow