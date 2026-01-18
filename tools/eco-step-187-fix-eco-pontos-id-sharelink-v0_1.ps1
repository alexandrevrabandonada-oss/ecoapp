param([switch]$OpenReport)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$tools = Join-Path $root "tools"
$reports = Join-Path $root "reports"
$backupRoot = Join-Path $tools "_patch_backup"

function EnsureDir($p){ if(!(Test-Path $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function WriteUtf8NoBom($p,$s){ [IO.File]::WriteAllText($p,$s,[Text.UTF8Encoding]::new($false)) }
function BackupFile($src,$tag){
  $safe = ($src -replace "[:\\\/]","_")
  $dstDir = Join-Path $backupRoot $tag
  EnsureDir $dstDir
  $dst = Join-Path $dstDir ((Get-Date).ToString("yyyyMMdd-HHmmss") + "-" + $safe)
  Copy-Item -Force $src $dst
  return $dst
}

EnsureDir $reports
$stamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
$tag = "eco-step-187"
$reportPath = Join-Path $reports ("eco-step-187-fix-eco-pontos-id-sharelink-" + $stamp + ".md")

$target = Join-Path $root "src\app\eco\pontos\[id]\page.tsx"
if(!(Test-Path -LiteralPath $target)){ throw "Nao achei: src\app\eco\pontos\[id]\page.tsx" }

$raw = Get-Content -Raw -Encoding UTF8 $target
$r = @()
$r += "# eco-step-187 — fix id undefined (eco/pontos/[id]) — " + $stamp
$r += ""
$r += "## DIAG"
$r += "- alvo: src/app/eco/pontos/[id]/page.tsx"
$r += "- contem padrao (params?.id || id): " + ([bool]($raw -match "params\?\.\s*id\s*\|\|\s*id"))
$r += ""

$bak = BackupFile $target $tag

# patch 1 (direto)
$newRaw = $raw.Replace(
  'encodeURIComponent(String(params?.id || id || ""))',
  'encodeURIComponent(String(params?.id || ""))'
)

# patch 2 (fallback regex)
if($newRaw -eq $raw){
  $newRaw = [regex]::Replace($raw, 'params\?\.\s*id\s*\|\|\s*id\s*\|\|\s*""', 'params?.id || ""')
}

if($newRaw -eq $raw){ throw "Nao consegui aplicar patch (padrao nao encontrado). Abra src/app/eco/pontos/[id]/page.tsx e me cole o trecho do link do share." }

WriteUtf8NoBom $target $newRaw

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