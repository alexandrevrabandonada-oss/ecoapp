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

$rep = NewReport "eco-step-08b-fix-api-requests-alias-to-pickup"
$log = @()
$log += "# ECO — STEP 08b — Fix /api/requests (alias para /api/pickup-requests)"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

$requestsRoute = "src/app/api/requests/route.ts"
$pickupRoute   = "src/app/api/pickup-requests/route.ts"

$log += "## DIAG (antes)"
$log += ("Exists " + $requestsRoute + "? " + (Test-Path -LiteralPath $requestsRoute))
$log += ("Exists " + $pickupRoute   + "? " + (Test-Path -LiteralPath $pickupRoute))
$log += ""

if(!(Test-Path -LiteralPath $pickupRoute)){
  throw "Não achei $pickupRoute. (Mas o smoke diz que existe). Confere se o path é src/app/api/pickup-requests/route.ts."
}

EnsureDir "src/app/api/requests"
$bak = $null
if(Test-Path -LiteralPath $requestsRoute){ $bak = BackupFile $requestsRoute }

$log += "## PATCH"
$log += ("Backup: " + ($bak ?? "n/a"))
$log += "- Reescrevendo /api/requests para reexportar GET/POST do /api/pickup-requests"
$log += ""

$content = @(
  'export const runtime = "nodejs";',
  '',
  '// Alias: mantém compatibilidade com telas/links antigos (/api/requests),',
  '// mas usa a lógica oficial do endpoint novo (/api/pickup-requests).',
  'export { GET, POST } from "../pickup-requests/route";',
  ''
) -join "`n"

WriteUtf8NoBom $requestsRoute $content

$log += "## VERIFY"
$log += ("Now exists " + $requestsRoute + "? " + (Test-Path -LiteralPath $requestsRoute))
$log += ""

$log += "## Próximos passos"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1"
$log += "3) Abra /chamar e envie um pedido (POST /api/requests não pode mais reclamar de address)."
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 08b aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) Abra /chamar e envie um pedido (POST /api/requests agora usa /api/pickup-requests)" -ForegroundColor Yellow