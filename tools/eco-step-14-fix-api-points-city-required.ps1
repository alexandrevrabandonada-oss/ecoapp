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
  $f = Get-ChildItem -Recurse -File -Path $root -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -match $pattern } |
    Select-Object -First 1
  if($f){ return $f.FullName }
  return $null
}

$rep = NewReport "eco-step-14-fix-api-points-city-required"
$log = @()
$log += "# ECO — STEP 14 — Fix /api/points (city required) + default ECO_DEFAULT_CITY"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

# =========
# DIAG
# =========
$apiPoints = "src/app/api/points/route.ts"
if(!(Test-Path -LiteralPath $apiPoints)){
  $apiPoints = FindFirst "src/app" "\\api\\points\\route\.ts$"
}
if(-not $apiPoints){ throw "Não achei /api/points/route.ts" }

$txt = Get-Content -LiteralPath $apiPoints -Raw

$log += "## DIAG"
$log += ("API points: {0}" -f $apiPoints)
$log += ("Já tem city no create? {0}" -f ([bool]([regex]::IsMatch($txt, '(?s)prisma\.point\.create\(\{.*?data:\s*\{.*?\bcity\s*:'))))
$log += ""

# =========
# PATCH (backup)
# =========
$log += "## PATCH"
$log += ("Backup API: {0}" -f (BackupFile $apiPoints))
$log += ""

# =========
# PATCH: injeta city default no prisma.point.create({ data: { ... } })
# =========
$hasCity = [regex]::IsMatch($txt, '(?s)prisma\.point\.create\(\{.*?data:\s*\{.*?\bcity\s*:')

if($hasCity){
  $log += "- INFO: /api/points já inclui city no create (skip)."
} else {
  $pattern = '(?s)(prisma\.point\.create\(\{.*?data:\s*\{\s*)'
  $cityLine = 'city: (typeof body?.city === "string" && body.city.trim() ? body.city.trim() : (process.env.ECO_DEFAULT_CITY || "Volta Redonda")),'
  $replacement = '$1' + $cityLine + "`n"

  $re = New-Object System.Text.RegularExpressions.Regex($pattern)
  $txt2 = $re.Replace($txt, $replacement, 1)

  if($txt2 -eq $txt){
    throw "Não consegui aplicar patch automaticamente (não achei o bloco prisma.point.create({ data: { ... } })."
  }

  WriteUtf8NoBom $apiPoints $txt2
  $log += "- OK: /api/points POST agora garante city (body.city || ECO_DEFAULT_CITY || 'Volta Redonda')."
}

# =========
# REGISTRO
# =========
$log += ""
$log += "## Como usar"
$log += "- (Opcional) No .env: ECO_DEFAULT_CITY=Volta Redonda"
$log += "- Se não setar, default = 'Volta Redonda' (MVP)."
$log += ""
$log += "## Próximos passos"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1"
$log += "3) Abra /coleta/novo e crie um ponto (POST /api/points não pode mais reclamar de city)"
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 14 aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) /coleta/novo -> criar ponto (POST /api/points sem erro city)" -ForegroundColor Yellow
Write-Host "4) (opcional) .env: ECO_DEFAULT_CITY=Volta Redonda" -ForegroundColor Yellow