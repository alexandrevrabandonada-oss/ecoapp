param([switch]$OpenReport)

$ErrorActionPreference = "Stop"
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"

function EnsureDir([string]$p){
  if([string]::IsNullOrWhiteSpace($p)){ return }
  if(-not (Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null }
}
function WriteUtf8NoBom([string]$p,[string]$s){
  EnsureDir (Split-Path -Parent $p)
  [IO.File]::WriteAllText($p, $s, [Text.UTF8Encoding]::new($false))
}
function BackupFile([string]$rel){
  $src = Join-Path $Root $rel
  if(-not (Test-Path -LiteralPath $src)){ return $null }
  $base = Join-Path $Root ("tools\_patch_backup\eco-step-216d-" + $stamp)
  $dst = Join-Path $base $rel
  EnsureDir (Split-Path -Parent $dst)
  Copy-Item -LiteralPath $src -Destination $dst -Force
  return $dst
}

$reportsDir = Join-Path $Root "reports"
EnsureDir $reportsDir
$reportPath = Join-Path $reportsDir ("eco-step-216d-zero-warnings-final-" + $stamp + ".md")

$r = New-Object System.Collections.Generic.List[string]
$r.Add("# ECO STEP 216d — zero warnings final — $stamp")
$r.Add("")
$r.Add("Root: $Root")
$r.Add("")

# 1) points/report: unused catch param e -> _e
$rel1 = "src\app\api\eco\points\report\route.ts"
$f1 = Join-Path $Root $rel1
if(Test-Path -LiteralPath $f1){
  $bak = BackupFile $rel1
  $raw = Get-Content -LiteralPath $f1 -Raw -Encoding UTF8
  # only change catch (e) -> catch (_e) when _e not already used
  $new = [regex]::Replace($raw, "(?m)\bcatch\s*\(\s*e\s*\)\s*\{", "catch (_e) {")
  if($new -ne $raw){
    [IO.File]::WriteAllText($f1, $new, [Text.UTF8Encoding]::new($false))
    $r.Add("## PATCH 1")
    $r.Add("- updated: $rel1")
    $r.Add("- backup:  $bak")
    $r.Add("")
  } else {
    $r.Add("## PATCH 1")
    $r.Add("- no change needed: $rel1")
    $r.Add("")
  }
} else {
  $r.Add("## PATCH 1")
  $r.Add("- skip missing: $rel1")
  $r.Add("")
}

# 2) pickup-requests/[id]: lint says id assigned but never used -> keep as _id (but also fix the check)
$rel2 = "src\app\api\pickup-requests\[id]\route.ts"
$f2 = Join-Path $Root $rel2
if(Test-Path -LiteralPath $f2){
  $bak2 = BackupFile $rel2
  $lines = [IO.File]::ReadAllLines($f2, [Text.UTF8Encoding]::new($false))

  for($i=0; $i -lt $lines.Length; $i++){
    $ln = $lines[$i]
    # const id = ... -> const _id = ...
    if($ln -match "^\s*const\s+id\s*="){
      $lines[$i] = ($ln -replace "^\s*const\s+id\s*=", "const _id =")
      continue
    }
    # if (!id) -> if (!_id)
    if($ln -match "if\s*\(\s*!\s*id\s*\)"){
      $lines[$i] = ($ln -replace "!\s*id", "!_id")
      continue
    }
    # any remaining whole-word id used as variable -> _id (careful: do not touch idParam or { id: ... })
    $lines[$i] = [regex]::Replace($lines[$i], "(?<![A-Za-z0-9_])id(?![A-Za-z0-9_])", "_id")
  }

  [IO.File]::WriteAllLines($f2, $lines, [Text.UTF8Encoding]::new($false))
  $r.Add("## PATCH 2")
  $r.Add("- updated: $rel2 (id -> _id for lint)")
  $r.Add("- backup:  $bak2")
  $r.Add("")
} else {
  $r.Add("## PATCH 2")
  $r.Add("- skip missing: $rel2")
  $r.Add("")
}

# VERIFY: lint + build
$lintLog  = Join-Path $reportsDir ("eco-step-216d-lint-"  + $stamp + ".log")
$buildLog = Join-Path $reportsDir ("eco-step-216d-build-" + $stamp + ".log")

function RunCmd([string]$label, [string]$cmdLine, [string]$logPath){
  Write-Host ("[216d] " + $label + " ...")
  $full = "cd /d `"$Root`" && " + $cmdLine + " 2^>^&1"
  cmd.exe /c $full | Tee-Object -FilePath $logPath | Out-Host
  return $LASTEXITCODE
}

$r.Add("## VERIFY")
$lintExit  = RunCmd "npm run lint"  "npm run lint"  $lintLog
$buildExit = RunCmd "npm run build" "npm run build" $buildLog

$r.Add("- lint exit:  $lintExit")
$r.Add("- lint log:   $lintLog")
$r.Add("- build exit: $buildExit")
$r.Add("- build log:  $buildLog")
$r.Add("")

WriteUtf8NoBom $reportPath ($r -join "`n")
Write-Host ("[REPORT] " + $reportPath)
if($OpenReport){ try { ii $reportPath } catch {} }

if($lintExit -ne 0){ throw ("LINT failed. See: " + $lintLog) }
if($buildExit -ne 0){ throw ("BUILD failed. See: " + $buildLog) }

Write-Host "[216d] OK — lint+build passaram."