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
$tag = "eco-step-185"
$reportPath = Join-Path $reports ("eco-step-185-fix-muralacoesclient-num-" + $stamp + ".md")

$target = Join-Path $root "src\app\eco\mural-acoes\MuralAcoesClient.tsx"
if(!(Test-Path -LiteralPath $target)){ throw "Nao achei: src\app\eco\mural-acoes\MuralAcoesClient.tsx" }

$raw = Get-Content -Raw -Encoding UTF8 $target
$r = @()
$r += "# eco-step-185 — fix num() missing (MuralAcoesClient) — " + $stamp
$r += ""
$r += "## DIAG"
$r += "- alvo: src\app\eco\mural-acoes\MuralAcoesClient.tsx"
$r += "- tem score(): " + ([bool]($raw -match "function\s+score\s*\("))
$r += "- ja tem num(): " + ([bool]($raw -match "function\s+num\s*\(" -or $raw -match "const\s+num\s*="))

if($raw -match "function\s+num\s*\(" -or $raw -match "const\s+num\s*="){
  $r += "## PATCH"
  $r += "- SKIP: num() ja existe no arquivo."
  $r += ""
  $r += "## VERIFY"
  $r += "- npm run build"
  WriteUtf8NoBom $reportPath ($r -join "`n")
  Write-Host ("[REPORT] " + $reportPath)
  if($OpenReport){ Start-Process $reportPath | Out-Null }
  exit 0
}

$bak = BackupFile $target $tag
$ls = $raw -split "`n"
$out = @()
$inserted = $false
foreach($line in $ls){
  if(-not $inserted -and $line -match "^\s*function\s+score\s*\("){
    $indent = ""
    if($line -match "^(\s*)"){ $indent = $Matches[1] }
    $out += ($indent + "function num(v: any): number {")
    $out += ($indent + "  const n = Number(v);")
    $out += ($indent + "  return Number.isFinite(n) ? n : 0;")
    $out += ($indent + "}")
    $out += ""
    $inserted = $true
  }
  $out += $line
}
if(-not $inserted){ throw "Nao achei linha de `function score(` para inserir num() antes." }

$newRaw = ($out -join "`n")
WriteUtf8NoBom $target $newRaw

$r += "## PATCH"
$r += "- backup: " + $bak
$r += "- inseriu helper `num()` antes de `score()`"
$r += ""
$r += "## VERIFY"
$r += "Rode:"
$r += "- npm run build"

WriteUtf8NoBom $reportPath ($r -join "`n")
Write-Host ("[REPORT] " + $reportPath)
if($OpenReport){ Start-Process $reportPath | Out-Null }