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

$rep = NewReport "eco-step-14b-fix-api-points-city-required-robust"
$log = @()
$log += "# ECO — STEP 14b — Fix /api/points (city required) via data.city antes do cleanup"
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
$log += ("Tem city em algum lugar? {0}" -f ([bool]([regex]::IsMatch($txt, '\bcity\b'))))
$log += ("Tem data.city? {0}" -f ([bool]([regex]::IsMatch($txt, 'data\.\s*city'))))
$log += ""

# =========
# PATCH (backup)
# =========
$log += "## PATCH"
$log += ("Backup API: {0}" -f (BackupFile $apiPoints))
$log += ""

# se já existe data.city, não mexe
if([regex]::IsMatch($txt, 'data\.\s*city')){
  $log += "- INFO: Já existe data.city no /api/points (skip)."
  WriteUtf8NoBom $rep ($log -join "`n")
  Write-Host ("✅ STEP 14b (skip) — já havia city. Report -> {0}" -f $rep) -ForegroundColor Green
  exit 0
}

# =========
# PATCH: injeta antes do Object.keys(data).forEach(...)
# =========
$patternForeach = '(?m)^\s*Object\.keys\(data\)\.forEach'
$re = New-Object System.Text.RegularExpressions.Regex($patternForeach)

$inject = @"
  // ✅ required field (db): city
  // body.city > ECO_DEFAULT_CITY > 'Volta Redonda'
  if (!(("city" in data) -and data.city) -and ((data.city -ne "") -or ($null -eq data.city))) {
    const c =
      (typeof body?.city === "string" && body.city.trim())
        ? body.city.trim()
        : (process.env.ECO_DEFAULT_CITY || "Volta Redonda");
    (data as any).city = c;
  }

"@

# tenta aplicar 1x
$txt2 = $re.Replace($txt, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) return $inject + $m.Value }, 1, 0)

if($txt2 -eq $txt){
  # fallback: tentar injetar antes do prisma.point.create
  $patternCreate = '(?m)^\s*const\s+point\s*=\s*await\s+prisma\.point\.create'
  $re2 = New-Object System.Text.RegularExpressions.Regex($patternCreate)
  $txt3 = $re2.Replace($txt, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) return $inject + $m.Value }, 1, 0)

  if($txt3 -eq $txt){
    throw "Não consegui aplicar patch automaticamente. Não achei 'Object.keys(data).forEach' nem 'const point = await prisma.point.create'."
  } else {
    $txt2 = $txt3
    $log += "- OK: injetei city antes do prisma.point.create (fallback)."
  }
} else {
  $log += "- OK: injetei city antes do Object.keys(data).forEach (ponto certo)."
}

WriteUtf8NoBom $apiPoints $txt2

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
$log += "3) Abra /coleta/novo e crie um ponto (POST /api/points sem erro city)"
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 14b aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) /coleta/novo -> criar ponto (POST /api/points sem erro city)" -ForegroundColor Yellow
Write-Host "4) (opcional) .env: ECO_DEFAULT_CITY=Volta Redonda" -ForegroundColor Yellow