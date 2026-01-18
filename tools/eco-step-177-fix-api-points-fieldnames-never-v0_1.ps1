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
$targetRel = "src\app\api\points\route.ts"
$target    = Join-Path $repoRoot $targetRel
if(!(Test-Path -LiteralPath $target)){ throw ("Nao achei: " + $targetRel) }

$raw = Get-Content -LiteralPath $target -Raw

$pat = 'found\.fieldNames\.includes\("createdAt"\)'
$rep = '(found.fieldNames as any).includes("createdAt")'

$before = ([regex]::Matches($raw, $pat)).Count
$raw2 = [regex]::Replace($raw, $pat, $rep)
$after  = ([regex]::Matches($raw2, $pat)).Count

$stamp = NowStamp
EnsureDir (Join-Path $repoRoot "reports")
EnsureDir (Join-Path $repoRoot ("tools\_patch_backup\eco-step-177\" + $stamp))

$reportPath = Join-Path $repoRoot ("reports\eco-step-177-fix-api-points-fieldnames-never-" + $stamp + ".md")

$patchLog = ""
if($raw2 -eq $raw){
  $patchLog = "[SKIP] padrao nao encontrado (talvez ja esteja corrigido)."
} else {
  $bak = BackupFile $target (Join-Path $repoRoot ("tools\_patch_backup\eco-step-177\" + $stamp))
  WriteUtf8NoBom $target $raw2
  $patchLog = "[OK]  trocou found.fieldNames.includes(""createdAt"") por cast (any) para evitar never[]; backup: " + $bak
}

$r = @()
$r += ("# eco-step-177 — fix api/points fieldNames never[] — " + $stamp)
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