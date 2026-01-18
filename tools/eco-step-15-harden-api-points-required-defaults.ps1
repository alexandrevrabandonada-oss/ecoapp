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

$rep = NewReport "eco-step-15-harden-api-points-required-defaults"
$log = @()
$log += "# ECO — STEP 15 — Harden /api/points (defaults + validação de required)"
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
if(-not $apiPoints){ throw "Não achei src/app/api/points/route.ts" }

$txt = Get-Content -LiteralPath $apiPoints -Raw

$hasSentinel = ($txt -match "ECO_POINT_DEFAULTS_BEGIN")
$hasCleanup  = ($txt -match "Object\.keys\(\s*data\s*\)\.forEach")
$hasCreate   = ($txt -match "prisma\.point\.create\(")

$log += "## DIAG"
$log += ("API points: {0}" -f $apiPoints)
$log += ("Sentinel já existe? {0}" -f $hasSentinel)
$log += ("Tem Object.keys(data).forEach? {0}" -f $hasCleanup)
$log += ("Tem prisma.point.create(? {0}" -f $hasCreate)
$log += ""

if(-not $hasCreate){ throw "Não achei prisma.point.create( no arquivo. Não vou chutar patch." }

# =========
# PATCH (backup)
# =========
$log += "## PATCH"
$log += ("Backup API: {0}" -f (BackupFile $apiPoints))
$log += ""

# =========
# PATCH: garantir Prisma import
# =========
if(($txt -match 'from\s+["'']@prisma/client["''];') -and ($txt -notmatch 'Prisma\s*[,}]')){
  $txt2 = [regex]::Replace(
    $txt,
    'import\s*\{\s*PrismaClient\s*\}\s*from\s*["'']@prisma/client["''];',
    'import { PrismaClient, Prisma } from "@prisma/client";'
  )
  if($txt2 -ne $txt){
    $txt = $txt2
    $log += "- OK: import PrismaClient -> PrismaClient, Prisma"
  } else {
    $log += "- INFO: não consegui substituir import PrismaClient automaticamente (talvez já esteja diferente)."
  }
} elseif($txt -match 'from\s+["'']@prisma/client["''];') {
  $log += "- INFO: Prisma já está importado (ou import não é o padrão)."
} else {
  $log += "- INFO: não encontrei import @prisma/client (estranho, mas sigo)."
}

# =========
# PATCH: injetar defaults/required check (apenas 1x)
# =========
if($txt -notmatch "ECO_POINT_DEFAULTS_BEGIN"){
  $inject = @"
  // ECO_POINT_DEFAULTS_BEGIN
  // Defaults seguros: só aplica se o campo existir no model Point (via Prisma.dmmf).
  const pointModel = Prisma.dmmf.datamodel.models.find((m) => m.name === "Point");
  const pointFieldNames = new Set((pointModel?.fields ?? []).map((f: any) => f.name));

  const defaults = {
    city: process.env.ECO_DEFAULT_CITY || "Volta Redonda",
    uf: process.env.ECO_DEFAULT_UF || "RJ",
    state: process.env.ECO_DEFAULT_STATE || "RJ",
    country: process.env.ECO_DEFAULT_COUNTRY || "Brasil",
  };

  function setIfMissing(field: string, value: string) {
    if (!pointFieldNames.has(field)) return;
    const cur = (data as any)[field];
    if (cur === undefined || cur === null || cur === "") (data as any)[field] = value;
  }

  setIfMissing("city", defaults.city);
  setIfMissing("uf", defaults.uf);
  setIfMissing("state", defaults.state);
  setIfMissing("country", defaults.country);

  // Validação: campos escalares obrigatórios sem default
  const requiredScalars = (pointModel?.fields ?? []).filter((f: any) => {
    if (!f?.isRequired) return false;
    if (f?.kind !== "scalar") return false;
    if (f?.hasDefaultValue) return false;
    const skip = ["id", "createdAt", "updatedAt"];
    return !skip.includes(f.name);
  });

  const missing = requiredScalars
    .map((f: any) => f.name)
    .filter((name: string) => {
      const v = (data as any)[name];
      return v === undefined || v === null || v === "";
    });

  if (missing.length) {
    return NextResponse.json({ error: "missing_required_fields", missing }, { status: 400 });
  }
  // ECO_POINT_DEFAULTS_END
"@

  $inserted = $false

  if($txt -match "Object\.keys\(\s*data\s*\)\.forEach"){
    $m = [regex]::Match($txt, "\r?\n\s*Object\.keys\(\s*data\s*\)\.forEach")
    if($m.Success){
      $idx = $m.Index
      $txt = $txt.Substring(0, $idx) + "`n" + $inject + "`n" + $txt.Substring($idx)
      $inserted = $true
    }
  }

  if(-not $inserted){
    $m2 = [regex]::Match($txt, "\r?\n\s*const\s+point\s*=\s*await\s+prisma\.point\.create\(")
    if($m2.Success){
      $idx2 = $m2.Index
      $txt = $txt.Substring(0, $idx2) + "`n" + $inject + "`n" + $txt.Substring($idx2)
      $inserted = $true
    }
  }

  if(-not $inserted){
    throw "Não consegui achar um ponto seguro pra injetar (cleanup/create)."
  }

  $log += "- OK: injetei defaults/required-check (city/uf/state/country condicionais via Prisma.dmmf)."
} else {
  $log += "- INFO: sentinel já existe, não injetei de novo."
}

WriteUtf8NoBom $apiPoints $txt

# =========
# VERIFY (rápido)
# =========
$txtAfter = Get-Content -LiteralPath $apiPoints -Raw
$ok1 = ($txtAfter -match "ECO_POINT_DEFAULTS_BEGIN")
$ok2 = ($txtAfter -match "Prisma\.dmmf")
$log += ""
$log += "## VERIFY"
$log += ("Sentinel presente? {0}" -f $ok1)
$log += ("Usa Prisma.dmmf?  {0}" -f $ok2)
$log += ""

$log += "## Como usar"
$log += "- (Opcional) .env:"
$log += "  - ECO_DEFAULT_CITY=Volta Redonda"
$log += "  - ECO_DEFAULT_UF=RJ"
$log += "  - ECO_DEFAULT_STATE=RJ"
$log += "  - ECO_DEFAULT_COUNTRY=Brasil"
$log += "- Se não setar: defaults acima (MVP)."
$log += ""

$log += "## Próximos passos"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1"
$log += "3) Abra /coleta/novo e crie um ponto (não pode mais quebrar em city)."
$log += "4) Se der 400 missing_required_fields, a API agora te diz exatamente quais campos faltam."
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 15 aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) Teste /coleta/novo (criar ponto) — agora com defaults/validação robusta" -ForegroundColor Yellow