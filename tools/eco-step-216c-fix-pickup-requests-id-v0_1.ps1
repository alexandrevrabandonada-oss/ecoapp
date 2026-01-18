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
function Rel([string]$full,[string]$root){
  if($full.StartsWith($root,[System.StringComparison]::OrdinalIgnoreCase)){
    return $full.Substring($root.Length).TrimStart('\','/')
  }
  return $full
}

$reportsDir = Join-Path $Root "reports"
EnsureDir $reportsDir
$reportPath = Join-Path $reportsDir ("eco-step-216c-fix-pickup-id-" + $stamp + ".md")

$targetRel = "src\app\api\pickup-requests\[id]\route.ts"
$target = Join-Path $Root $targetRel

$r = New-Object System.Collections.Generic.List[string]
$r.Add("# ECO STEP 216c — fix pickup-requests id var — $stamp")
$r.Add("")
$r.Add("Root: $Root")
$r.Add("")
$r.Add("Target: $targetRel")
$r.Add("")

if(-not (Test-Path -LiteralPath $target)){
  $r.Add("ERR: file not found: $targetRel")
  WriteUtf8NoBom $reportPath ($r -join "`n")
  throw ("Missing file: " + $target)
}

# Backup
$backupBase = Join-Path $Root ("tools\_patch_backup\eco-step-216c-" + $stamp)
$backupPath = Join-Path $backupBase $targetRel
EnsureDir (Split-Path -Parent $backupPath)
Copy-Item -LiteralPath $target -Destination $backupPath -Force

# Patch
$raw = Get-Content -LiteralPath $target -Raw -Encoding UTF8

# 1) const _id = ...  -> const id = ...
$new = [regex]::Replace($raw, "(?m)^\s*const\s+_id\s*=", "const id =")

# 2) any remaining _id token -> id
$new = [regex]::Replace($new, "\b_id\b", "id")

if($new -ne $raw){
  [IO.File]::WriteAllText($target, $new, [Text.UTF8Encoding]::new($false))
  $r.Add("## PATCH")
  $r.Add("- updated: $targetRel")
  $r.Add("- backup:  " + (Rel $backupPath $Root))
} else {
  $r.Add("## PATCH")
  $r.Add("- no changes needed (already ok)")
  $r.Add("- backup kept: " + (Rel $backupPath $Root))
}

$r.Add("")
$r.Add("## VERIFY")

$lintLog  = Join-Path $reportsDir ("eco-step-216c-lint-"  + $stamp + ".log")
$buildLog = Join-Path $reportsDir ("eco-step-216c-build-" + $stamp + ".log")

function RunCmd([string]$label, [string]$cmdLine, [string]$logPath){
  Write-Host ("[216c] " + $label + " ...")
  $full = "cd /d `"$Root`" && " + $cmdLine + " 2^>^&1"
  cmd.exe /c $full | Tee-Object -FilePath $logPath | Out-Host
  return $LASTEXITCODE
}

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

Write-Host "[216c] OK — lint+build passaram."