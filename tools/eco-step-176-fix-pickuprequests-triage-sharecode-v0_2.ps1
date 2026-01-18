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
$targetRel = "src\app\api\pickup-requests\triage\route.ts"
$target    = Join-Path $repoRoot $targetRel
if(!(Test-Path -LiteralPath $target)){ throw ("Nao achei: " + $targetRel) }

$raw = Get-Content -LiteralPath $target -Raw

$beforeDot = ([regex]::Matches($raw, "\.shareCode\b")).Count
$beforeSel = ([regex]::Matches($raw, "\bshareCode\s*:\s*true\b")).Count

# PATCH (neste arquivo apenas):
# 1) select: shareCode: true -> code: true
# 2) acesso: .shareCode -> .code
$raw2 = [regex]::Replace($raw, "\bshareCode\s*:\s*true\b", "code: true")
$raw2 = [regex]::Replace($raw2, "\.shareCode\b", ".code")

$afterDot = ([regex]::Matches($raw2, "\.shareCode\b")).Count
$afterSel = ([regex]::Matches($raw2, "\bshareCode\s*:\s*true\b")).Count

$stamp = NowStamp
$bakDir = Join-Path $repoRoot ("tools\_patch_backup\eco-step-176\" + $stamp)
EnsureDir $bakDir
EnsureDir (Join-Path $repoRoot "reports")

$reportPath = Join-Path $repoRoot ("reports\eco-step-176-fix-pickuprequests-triage-sharecode-" + $stamp + ".md")

$patchLog = ""
if($raw2 -eq $raw){
  $patchLog += "[SKIP] nenhum cambio (talvez ja esteja code).`n"
} else {
  $bak = BackupFile $target $bakDir
  WriteUtf8NoBom $target $raw2
  $patchLog += "[OK]   shareCode: true -> code: true (triage)`n"
  $patchLog += "[OK]   .shareCode -> .code (triage)`n"
  $patchLog += ("       backup: " + $bak + "`n")
}

$r = @()
$r += ("# eco-step-176 — triage shareCode->code — " + $stamp)
$r += ""
$r += "## DIAG"
$r += ("alvo: " + $targetRel)
$r += ("antes: .shareCode = " + $beforeDot + " | shareCode:true = " + $beforeSel)
$r += ""
$r += "## PATCH LOG"
$r += "~~~"
$r += $patchLog.TrimEnd()
$r += "~~~"
$r += ""
$r += "## POS"
$r += ("depois: .shareCode = " + $afterDot + " | shareCode:true = " + $afterSel)
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