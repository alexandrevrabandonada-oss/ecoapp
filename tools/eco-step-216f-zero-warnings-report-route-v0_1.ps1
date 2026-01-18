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

$reportsDir = Join-Path $Root "reports"
EnsureDir $reportsDir
$reportPath = Join-Path $reportsDir ("eco-step-216f-zero-warnings-" + $stamp + ".md")

$rel = "src\app\api\eco\points\report\route.ts"
$file = Join-Path $Root $rel

$r = New-Object System.Collections.Generic.List[string]
$r.Add("# ECO STEP 216f — zero warnings in points/report — $stamp")
$r.Add("")
$r.Add("Root: $Root")
$r.Add("Target: $rel")
$r.Add("")

if(-not (Test-Path -LiteralPath $file)){
  $r.Add("ERR: missing file.")
  WriteUtf8NoBom $reportPath ($r -join "`n")
  throw ("Missing: " + $file)
}

# Backup
$backupBase = Join-Path $Root ("tools\_patch_backup\eco-step-216f-" + $stamp)
$backupPath = Join-Path $backupBase $rel
EnsureDir (Split-Path -Parent $backupPath)
Copy-Item -LiteralPath $file -Destination $backupPath -Force
$r.Add("Backup: " + $backupPath)
$r.Add("")

# Patch: for every line "catch (_e) {" ensure the next non-empty line includes "void _e;"
$lines = [IO.File]::ReadAllLines($file, [Text.UTF8Encoding]::new($false))
$out = New-Object System.Collections.Generic.List[string]
$inserted = 0

for($i=0; $i -lt $lines.Length; $i++){
  $ln = $lines[$i]
  $out.Add($ln) | Out-Null

  if($ln -match "\bcatch\s*\(\s*_e\s*\)\s*\{"){
    # look ahead to see if void _e already exists in the next few lines
    $has = $false
    for($j=$i+1; $j -lt [Math]::Min($lines.Length, $i+6); $j++){
      $t = $lines[$j].Trim()
      if($t.Length -eq 0){ continue }
      if($t -eq "void _e;" -or $t -eq "void(_e);" -or $t -eq "void (_e);"){ $has = $true }
      break
    }

    if(-not $has){
      # indent: keep 4 spaces by default; if next line has more indentation, match it
      $indent = "    "
      if($i+1 -lt $lines.Length){
        $m = [regex]::Match($lines[$i+1], "^(?<ws>\s+)")
        if($m.Success){ $indent = $m.Groups["ws"].Value }
      }
      $out.Add(($indent + "void _e;")) | Out-Null
      $inserted++
    }
  }
}

[IO.File]::WriteAllLines($file, $out.ToArray(), [Text.UTF8Encoding]::new($false))

$r.Add("## PATCH")
$r.Add("- inserted `void _e;` lines: $inserted")
$r.Add("")

function RunCmd([string]$label, [string]$cmdLine, [string]$logPath){
  Write-Host ("[216f] " + $label + " ...")
  $full = "cd /d `"$Root`" && " + $cmdLine + " 2^>^&1"
  cmd.exe /c $full | Tee-Object -FilePath $logPath | Out-Host
  return $LASTEXITCODE
}

function CountWarnings([string]$logPath){
  if(-not (Test-Path -LiteralPath $logPath)){ return 0 }
  $m = Select-String -LiteralPath $logPath -Pattern "\bwarning\b" -ErrorAction SilentlyContinue
  if(-not $m){ return 0 }
  return @($m).Count
}

$lintLog  = Join-Path $reportsDir ("eco-step-216f-lint-"  + $stamp + ".log")
$buildLog = Join-Path $reportsDir ("eco-step-216f-build-" + $stamp + ".log")

$r.Add("## VERIFY")
$lintExit  = RunCmd "npm run lint"  "npm run lint"  $lintLog
$warnCount = CountWarnings $lintLog
$r.Add("- lint exit: $lintExit")
$r.Add("- lint warnings (count): $warnCount")
$r.Add("- lint log: $lintLog")
$r.Add("")

$buildExit = RunCmd "npm run build" "npm run build" $buildLog
$r.Add("- build exit: $buildExit")
$r.Add("- build log: $buildLog")
$r.Add("")

WriteUtf8NoBom $reportPath ($r -join "`n")
Write-Host ("[REPORT] " + $reportPath)
if($OpenReport){ try { ii $reportPath } catch {} }

if($lintExit -ne 0){ throw ("LINT failed. See: " + $lintLog) }
if($warnCount -ne 0){ throw ("LINT still has warnings=" + $warnCount + " (see: " + $lintLog + ")") }
if($buildExit -ne 0){ throw ("BUILD failed. See: " + $buildLog) }

Write-Host "[216f] OK — zero warnings + build passou."