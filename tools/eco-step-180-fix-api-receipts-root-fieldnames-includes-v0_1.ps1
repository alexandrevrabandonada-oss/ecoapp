param([switch]$OpenReport)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function NowStamp(){ (Get-Date).ToString("yyyyMMdd-HHmmss") }
function EnsureDir([string]$p){ if(!(Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function WriteUtf8NoBom([string]$path, [string]$text){ [IO.File]::WriteAllText($path, $text, [Text.UTF8Encoding]::new($false)) }
function BackupFile([string]$file, [string]$bakDir){
  EnsureDir $bakDir
  $safe = ($file -replace "[:\\\/\[\]\s]", "_")
  $dst = Join-Path $bakDir ((NowStamp) + "-" + $safe)
  Copy-Item -LiteralPath $file -Destination $dst -Force
  return $dst
}

if(!(Test-Path -LiteralPath "package.json")){ throw "Rode na raiz do repo (onde tem package.json)." }

$repoRoot  = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
$targetRel = "src\app\api\receipts\route.ts"
$target    = Join-Path $repoRoot $targetRel
if(!(Test-Path -LiteralPath $target)){ throw ("Nao achei: " + $targetRel) }

$raw = Get-Content -LiteralPath $target -Raw

# PATCH: found.fieldNames.includes("X") -> (found.fieldNames as any).includes("X")
$rx  = 'found\.fieldNames\.includes\("([^"]+)"\)'
$rep = '(found.fieldNames as any).includes("$1")'

$before = ([regex]::Matches($raw, $rx)).Count
$raw2   = [regex]::Replace($raw, $rx, $rep)
$after  = ([regex]::Matches($raw2, $rx)).Count

$stamp = NowStamp
EnsureDir (Join-Path $repoRoot "reports")
$bakDir = Join-Path $repoRoot ("tools\_patch_backup\eco-step-180\" + $stamp)
EnsureDir $bakDir

$reportPath = Join-Path $repoRoot ("reports\eco-step-180-fix-api-receipts-root-fieldnames-includes-" + $stamp + ".md")

$patchLog = ""
if($raw2 -eq $raw){
  $patchLog = "[SKIP] nenhum found.fieldNames.includes(...) encontrado (talvez ja esteja ok)."
} else {
  $bak = BackupFile $target $bakDir
  WriteUtf8NoBom $target $raw2
  $patchLog = "[OK]  cast global: found.fieldNames.includes -> (found.fieldNames as any).includes; backup: " + $bak
}

$r = @()
$r += ("# eco-step-180 — fix api/receipts fieldNames.includes — " + $stamp)
$r += ""
$r += "## DIAG"
$r += ("alvo: " + $targetRel)
$r += ("ocorrencias antes: " + $before)
$r += ""
$r += "## PATCH"
$r += $patchLog
$r += ""
$r += "## POS"
$r += ("ocorrencias depois: " + $after)
$r += ""
$r += "## VERIFY"
$r += "- npm run build"
$r += ""

WriteUtf8NoBom $reportPath ($r -join "`n")
Write-Host ("[REPORT] " + $reportPath)
if($OpenReport){ try{ Start-Process $reportPath | Out-Null } catch {} }

Write-Host ""
Write-Host "[NEXT] rode:"
Write-Host "  npm run build"