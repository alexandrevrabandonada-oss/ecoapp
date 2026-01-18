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
function ReplaceRegexOnce($file,$pattern,$replacement,[ref]$log,$label){
  $raw = Get-Content -Raw -Encoding UTF8 $file
  $new = [regex]::Replace($raw,$pattern,$replacement)
  if($new -ne $raw){
    WriteUtf8NoBom $file $new
    $log.Value += ("[OK]   " + $label + "`n")
    return $true
  } else {
    $log.Value += ("[SKIP] " + $label + " - no change`n")
    return $false
  }
}

EnsureDir $reports
$stamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
$tag = "eco-step-186"
$reportPath = Join-Path $reports ("eco-step-186-fix-muralpointactions-localcounts-" + $stamp + ".md")

$target = Join-Path $root "src\app\eco\mural\_components\MuralPointActionsClient.tsx"
if(!(Test-Path -LiteralPath $target)){ throw "Nao achei: src\app\eco\mural\_components\MuralPointActionsClient.tsx" }

$raw0 = Get-Content -Raw -Encoding UTF8 $target
$hasNum = [bool]($raw0 -match "function\s+num\s*\(" -or $raw0 -match "const\s+num\s*=")
$hasOptimistic = [bool]($raw0 -match "function\s+optimistic\s*\(")

$patchLog = ""
$r = @()
$r += "# eco-step-186 — fix localCounts typing (MuralPointActionsClient) — " + $stamp
$r += ""
$r += "## DIAG"
$r += "- alvo: src\app\eco\mural\_components\MuralPointActionsClient.tsx"
$r += "- tem function optimistic(): " + $hasOptimistic
$r += "- ja tem num(): " + $hasNum
$r += ""

$bak = BackupFile $target $tag
$r += "## PATCH"
$r += "- backup: " + $bak

# 1) garante helper num() antes do optimistic
if(-not $hasNum){
  $raw = Get-Content -Raw -Encoding UTF8 $target
  $ls = $raw -split "`n"
  $out = @()
  $inserted = $false
  foreach($line in $ls){
    if(-not $inserted -and $line -match "^\s*function\s+optimistic\s*\("){
      $indent = ""
      if($line -match "^(\s*)"){ $indent = $Matches[1] }
      $out += ($indent + "function num(v: any): number {")
      $out += ($indent + "  const n = Number(v);")
      $out += ($indent + "  return Number.isFinite(n) ? n : 0;")
      $out += ($indent + "}")
      $out += ""
      $inserted = $true
      $patchLog += "[OK]   inserted num() helper`n"
    }
    $out += $line
  }
  if(-not $inserted){ throw "Nao achei `function optimistic(` para inserir num() antes." }
  WriteUtf8NoBom $target ($out -join "`n")
} else {
  $patchLog += "[SKIP] num() helper already exists`n"
}

# 2) remove tipagem AnyRec do prev no setLocalCounts
$p1 = "setLocalCounts\(\(prev:\s*AnyRec\)\s*=>\s*\{"
$rep1 = "setLocalCounts((prev) => {"
ReplaceRegexOnce $target $p1 $rep1 ([ref]$patchLog) "setLocalCounts prev: AnyRec -> prev" | Out-Null

# 3) garante que next sempre tenha {confirm,support,replicar}
$p2 = "const\s+next\s*=\s*\{\s*\.\.\.prev\s*\}\s*;?"
$rep2 = "const next = { confirm: num(prev.confirm), support: num(prev.support), replicar: num(prev.replicar) };"
ReplaceRegexOnce $target $p2 $rep2 ([ref]$patchLog) "next init: { ...prev } -> typed triple" | Out-Null

$r += "### Patch log"
$r += "~~~"
$r += $patchLog.TrimEnd()
$r += "~~~"
$r += ""
$r += "## VERIFY"
$r += "Rode:"
$r += "- npm run build"

WriteUtf8NoBom $reportPath ($r -join "`n")
Write-Host ("[REPORT] " + $reportPath)
if($OpenReport){ try { Start-Process $reportPath | Out-Null } catch {} }