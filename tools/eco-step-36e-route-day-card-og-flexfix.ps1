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

$rep = NewReport "eco-step-36e-route-day-card-og-flexfix"
$log = @()
$log += "# ECO — STEP 36e — Fix next/og: div com múltiplos filhos exige display:flex"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

$routeFile = "src/app/api/share/route-day-card/route.ts"
if(!(Test-Path -LiteralPath $routeFile)){
  $log += "## ERRO"
  $log += "Não achei: $routeFile"
  WriteUtf8NoBom $rep ($log -join "`n")
  throw "Não achei route-day-card/route.ts"
}

$bk = BackupFile $routeFile
$txt = Get-Content -LiteralPath $routeFile -Raw

$log += "## DIAG"
$log += ("Arquivo: {0}" -f $routeFile)
$log += ("Backup : {0}" -f ($bk ? $bk : "(nenhum)"))
$log += ""

$log += "## PATCH"
$needleOld = 'style: { padding: "10px 14px", background: bg, borderRadius: 14 }'
$needleNew = 'style: { display: "flex", alignItems: "center", gap: 8, padding: "10px 14px", background: bg, borderRadius: 14 }'

if($txt.Contains($needleNew)){
  $log += "- INFO: pill já tem display:flex (skip)."
} elseif($txt.Contains($needleOld)){
  $txt = $txt.Replace($needleOld, $needleNew)
  $log += "- OK: adicionou display:flex no pill() (evita erro do next/og)."
} else {
  # fallback: troca mais genérica (se o formato mudou)
  $fallbackOld = 'padding: "10px 14px", background: bg, borderRadius: 14'
  if($txt.Contains($fallbackOld) -and $txt.Contains("const pill")){
    $txt = $txt.Replace($fallbackOld, 'display: "flex", alignItems: "center", gap: 8, ' + $fallbackOld)
    $log += "- OK: adicionou display:flex no pill() via fallback."
  } else {
    $log += "- WARN: não achei o trecho do pill() para patch automático. (Abra o arquivo e procure por const pill / padding: '10px 14px')."
  }
}

WriteUtf8NoBom $routeFile $txt

$log += ""
$log += "## VERIFY"
$log += "1) Sem precisar reiniciar: teste novamente:"
$log += "   - /api/share/route-day-card?day=2025-12-26&format=3x4"
$log += "   - /api/share/route-day-card?day=2025-12-26&format=1x1"
$log += "2) Se ainda der 500, me cola o trecho do pill() do route.ts."
WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 36e aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Abra /api/share/route-day-card?day=2025-12-26&format=3x4" -ForegroundColor Yellow
Write-Host "2) Abra /api/share/route-day-card?day=2025-12-26&format=1x1" -ForegroundColor Yellow