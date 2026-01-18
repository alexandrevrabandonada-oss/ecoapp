param([switch]$OpenReport)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function NowStamp(){ (Get-Date).ToString("yyyyMMdd-HHmmss") }
function EnsureDir([string]$p){ if(!(Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function WriteUtf8NoBom([string]$path,[string]$text){ [IO.File]::WriteAllText($path,$text,[Text.UTF8Encoding]::new($false)) }
function BackupFile([string]$file,[string]$bakDir){
  EnsureDir $bakDir
  $safe = ($file -replace "[:\\\/\[\]\s]", "_")
  $dst = Join-Path $bakDir ((NowStamp) + "-" + $safe)
  Copy-Item -LiteralPath $file -Destination $dst -Force
  return $dst
}

if(!(Test-Path -LiteralPath "package.json")){ throw "Rode na raiz do repo (onde tem package.json)." }

$root = (Resolve-Path ".").Path
$targetRel = "src\components\eco\OperatorTriageBoard.tsx"
$target = Join-Path $root $targetRel

if(!(Test-Path -LiteralPath $target)){
  throw ("Nao achei o arquivo alvo: " + $targetRel)
}

$raw = Get-Content -LiteralPath $target -Raw -Encoding UTF8
$lines = $raw -split "\r?\n"

$removed = 0
$newLines = New-Object System.Collections.Generic.List[string]
foreach($l in $lines){
  if($l -match '^\s*\(\);\s*$'){
    $removed++
    continue
  }
  $newLines.Add($l) | Out-Null
}

$stamp = NowStamp
EnsureDir (Join-Path $root "reports")
$backupDir = Join-Path $root ("tools\_patch_backup\eco-step-189\" + $stamp)
EnsureDir $backupDir

$reportPath = Join-Path $root ("reports\eco-step-189-fix-operatortriageboard-stray-call-" + $stamp + ".md")

if($removed -eq 0){
  $r = @()
  $r += ("# eco-step-189 — remove stray (); — " + $stamp)
  $r += ""
  $r += "## DIAG"
  $r += ("alvo: " + $targetRel)
  $r += "nao encontrei linha exatamente '();' (nada a fazer)"
  $r += ""
  $r += "## VERIFY"
  $r += "- npm run build"
  WriteUtf8NoBom $reportPath ($r -join "`n")
  Write-Host ("[REPORT] " + $reportPath)
  if($OpenReport){ try{ Start-Process $reportPath | Out-Null } catch {} }
  exit 0
}

$bak = BackupFile $target $backupDir
WriteUtf8NoBom $target ($newLines -join "`n")

$r = @()
$r += ("# eco-step-189 — remove stray (); — " + $stamp)
$r += ""
$r += "## DIAG"
$r += ("alvo: " + $targetRel)
$r += ("linhas removidas: " + $removed)
$r += ""
$r += "## PATCH"
$r += ("removeu linhas com apenas '();' (erro de parsing)")
$r += ("backup: " + $bak)
$r += ""
$r += "## VERIFY"
$r += "- npm run build"
WriteUtf8NoBom $reportPath ($r -join "`n")

Write-Host ("[OK] patched: " + $target)
Write-Host ("[REPORT] " + $reportPath)
if($OpenReport){ try{ Start-Process $reportPath | Out-Null } catch {} }

Write-Host ""
Write-Host "[NEXT] rode:"
Write-Host "  npm run build"