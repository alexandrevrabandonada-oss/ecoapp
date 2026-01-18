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

$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
$targetRel = "src\components\eco\ReceiptPublishButton.tsx"
$target = Join-Path $repoRoot $targetRel
if(!(Test-Path -LiteralPath $target)){ throw ("Nao achei: " + $targetRel) }

$raw = Get-Content -LiteralPath $target -Raw

# troca: 'x-eco-token': token,  -> ...(token ? { "x-eco-token": token } : {}),
$rx = "(['""]x-eco-token['""]\s*:\s*token\s*,)"
$rep = '...(token ? { "x-eco-token": token } : {}),'

$before = ([regex]::Matches($raw, $rx)).Count
$raw2 = [regex]::Replace($raw, $rx, $rep)
$after = ([regex]::Matches($raw2, $rx)).Count

$stamp = NowStamp
$reportsDir = Join-Path $repoRoot "reports"
EnsureDir $reportsDir
$bakDir = Join-Path $repoRoot ("tools\_patch_backup\eco-step-191\" + $stamp)
EnsureDir $bakDir

$reportPath = Join-Path $repoRoot ("reports\eco-step-191-fix-receiptpublishbutton-token-header-" + $stamp + ".md")

$patchLog = ""
if($raw2 -eq $raw){
  $patchLog = "[SKIP] Nao encontrei `'x-eco-token': token,` (talvez ja corrigido)."
} else {
  $bak = BackupFile $target $bakDir
  WriteUtf8NoBom $target $raw2
  $patchLog = "[OK]  trocou header x-eco-token para spread condicional (token ? ... : {}); backup: " + $bak
}

$r = @()
$r += ("# eco-step-191 — fix ReceiptPublishButton token header — " + $stamp)
$r += ""
$r += "## DIAG"
$r += ("alvo: " + $targetRel)
$r += ("matches antes: " + $before)
$r += ""
$r += "## PATCH"
$r += $patchLog
$r += ""
$r += "## POS"
$r += ("matches depois: " + $after)
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