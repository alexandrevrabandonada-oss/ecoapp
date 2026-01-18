param([switch]$OpenReport)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function EnsureDir([string]$p){
  if(!(Test-Path -LiteralPath $p)){
    New-Item -ItemType Directory -Force -Path $p | Out-Null
  }
}
function WriteUtf8NoBom([string]$path, [string]$text){
  [IO.File]::WriteAllText($path, $text, [Text.UTF8Encoding]::new($false))
}
function BackupFile([string]$fileFull, [string]$backupDir, [string]$stamp){
  EnsureDir $backupDir
  $safe = ($fileFull -replace "[:\\\/\[\]\s]", "_")
  $dst = Join-Path $backupDir ($stamp + "-" + $safe)
  Copy-Item -LiteralPath $fileFull -Destination $dst -Force
  return $dst
}
function ReplaceRegex([string]$repoRoot,[string]$fileRel,[string]$pattern,[string]$replacement,[ref]$log,[string]$label,[string]$backupDir,[string]$stamp){
  $full = Join-Path $repoRoot $fileRel
  if(!(Test-Path -LiteralPath $full)){
    $log.Value += ("[MISS] " + $fileRel + " (" + $label + ": file not found)`n")
    return $false
  }
  $raw = Get-Content -LiteralPath $full -Raw
  if($null -eq $raw){
    $log.Value += ("[ERR]  " + $fileRel + " (" + $label + ": read null)`n")
    return $false
  }
  $new = [regex]::Replace($raw, $pattern, $replacement)
  if($new -eq $raw){
    $log.Value += ("[SKIP] " + $fileRel + " (" + $label + ": no change)`n")
    return $false
  }
  $bk = BackupFile $full $backupDir $stamp
  WriteUtf8NoBom $full $new
  $log.Value += ("[OK]   " + $fileRel + " (" + $label + ")`n")
  $log.Value += ("       backup: " + $bk + "`n")
  return $true
}

function RunCmd([string]$label,[scriptblock]$sb,[ref]$out){
  $out.Value += ("### " + $label + "`n~~~`n")
  try {
    $o = (& $sb 2>&1 | Out-String).TrimEnd()
    if($o){ $out.Value += ($o + "`n") }
  } catch {
    $out.Value += ("[ERR] " + $_.Exception.Message + "`n")
  }
  $out.Value += "~~~`n`n"
}

if(!(Test-Path -LiteralPath "package.json")){ throw "Rode na raiz do repo (onde tem package.json)." }

$repoRoot  = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
$stamp     = Get-Date -Format "yyyyMMdd-HHmmss"
$backupDir = Join-Path $repoRoot ("tools\_patch_backup\eco-step-168\" + $stamp)
$reportDir = Join-Path $repoRoot "reports"
EnsureDir $reportDir
EnsureDir $backupDir

$reportPath = Join-Path $reportDir ("eco-step-168-fix-pickuprequests-route-reqname-" + $stamp + ".md")

$targetRel = "src\app\api\pickup-requests\route.ts"
$targetFull = Join-Path $repoRoot $targetRel

$diag = @()
$diag += ("# eco-step-168 — fix pickup-requests route req/request — " + $stamp)
$diag += ""
$diag += "## DIAG"
if(Test-Path -LiteralPath $targetFull){
  $diag += ("alvo: " + $targetRel)
  $m = Select-String -LiteralPath $targetFull -Pattern "ecoIsOperator\s*\(\s*req\s*\)" -AllMatches
  $count = 0
  if($m){ $count = @($m).Count }
  $diag += ("matches ecoIsOperator(req): " + $count)
} else {
  $diag += ("alvo: " + $targetRel + " (NAO ENCONTRADO)")
}
$diag += ""

$patchLog = ""
ReplaceRegex $repoRoot $targetRel 'ecoIsOperator\(\s*req\s*\)' 'ecoIsOperator(request)' ([ref]$patchLog) "req->request in ecoIsOperator()" $backupDir $stamp | Out-Null

$diag += "## PATCH LOG"
$diag += "~~~"
$diag += $patchLog.TrimEnd()
$diag += "~~~"
$diag += ""

$verify = ""
RunCmd "npm run build" { npm run build } ([ref]$verify)

$diag += "## VERIFY"
$diag += $verify

WriteUtf8NoBom $reportPath ($diag -join "`n")
Write-Host ("[REPORT] " + $reportPath)
if($OpenReport){ try { Start-Process $reportPath | Out-Null } catch {} }

Write-Host ""
Write-Host "[NEXT] Se o build passar, rode o smoke:"
Write-Host "  pwsh -NoProfile -ExecutionPolicy Bypass -File tools\eco-step-148b-verify-smoke-autodev-v0_1.ps1 -OpenReport"