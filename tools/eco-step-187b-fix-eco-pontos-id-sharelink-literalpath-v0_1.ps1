param([switch]$OpenReport)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$tools = Join-Path $root "tools"
$reports = Join-Path $root "reports"
$backupRoot = Join-Path $tools "_patch_backup"

function EnsureDir([string]$p){ if(!(Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function WriteUtf8NoBom([string]$p,[string]$s){ [IO.File]::WriteAllText($p,$s,[Text.UTF8Encoding]::new($false)) }
function BackupFile([string]$src,[string]$tag){
  $safe = ($src -replace "[:\\\/]","_")
  $dstDir = Join-Path $backupRoot $tag
  EnsureDir $dstDir
  $dst = Join-Path $dstDir ((Get-Date).ToString("yyyyMMdd-HHmmss") + "-" + $safe)
  Copy-Item -LiteralPath $src -Destination $dst -Force
  return $dst
}

EnsureDir $reports
$stamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
$tag = "eco-step-187b"
$reportPath = Join-Path $reports ("eco-step-187b-fix-eco-pontos-id-sharelink-" + $stamp + ".md")

$target = Join-Path $root "src\app\eco\pontos\[id]\page.tsx"

# fallback search (caso a árvore tenha mudado)
if(!(Test-Path -LiteralPath $target)){
  $candRoot = Join-Path $root "src\app\eco\pontos"
  if(Test-Path -LiteralPath $candRoot){
    $found = Get-ChildItem -Recurse -File -LiteralPath $candRoot -Filter "page.tsx" |
      Where-Object { $_.FullName -match "\\eco\\pontos\\\[id\]\\page\.tsx$" } |
      Select-Object -First 1
    if($found){ $target = $found.FullName }
  }
}

if(!(Test-Path -LiteralPath $target)){
  throw ("Nao achei o arquivo do Next: src/app/eco/pontos/[id]/page.tsx. Caminho tentado: " + $target)
}

$raw = Get-Content -LiteralPath $target -Raw -Encoding UTF8
$bak = BackupFile $target $tag

# patch: remove "|| id" (id nao existe)
$newRaw = $raw.Replace(
  'encodeURIComponent(String(params?.id || id || ""))',
  'encodeURIComponent(String(params?.id || ""))'
)

# fallback regex
if($newRaw -eq $raw){
  $newRaw = [regex]::Replace($raw, 'params\?\.\s*id\s*\|\|\s*id\s*\|\|\s*""', 'params?.id || ""')
}

if($newRaw -eq $raw){
  throw "Nao consegui aplicar patch (padrao nao encontrado). Me cole o trecho do href do share."
}

WriteUtf8NoBom $target $newRaw

$r = @()
$r += "# eco-step-187b — fix id undefined (eco/pontos/[id]) — " + $stamp
$r += ""
$r += "## DIAG"
$r += "- alvo: " + $target
$r += ""
$r += "## PATCH"
$r += "- backup: " + $bak
$r += "- removeu referencia a id inexistente no href do share (usa so params?.id)"
$r += ""
$r += "## VERIFY"
$r += "Rode:"
$r += "- npm run build"

WriteUtf8NoBom $reportPath ($r -join "`n")
Write-Host ("[REPORT] " + $reportPath)
if($OpenReport){ try{ Start-Process $reportPath | Out-Null } catch {} }