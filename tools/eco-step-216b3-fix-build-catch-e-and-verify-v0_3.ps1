param([switch]$OpenReport)

$ErrorActionPreference = "Stop"

function EnsureDir([string]$p){
  if([string]::IsNullOrWhiteSpace($p)){ return }
  if(-not (Test-Path -LiteralPath $p)){
    New-Item -ItemType Directory -Force -Path $p | Out-Null
  }
}

function WriteUtf8NoBom([string]$p, [string]$s){
  EnsureDir (Split-Path -Parent $p)
  [IO.File]::WriteAllText($p, $s, [Text.UTF8Encoding]::new($false))
}

function RelPath([string]$full, [string]$root){
  if($full.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)){
    return $full.Substring($root.Length).TrimStart('\','/')
  }
  return $full
}

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"

$reportsDir = Join-Path $Root "reports"
EnsureDir $reportsDir
$reportPath = Join-Path $reportsDir ("eco-step-216b3-fix-build-catch-e-" + $stamp + ".md")

$backupBase = Join-Path $Root ("tools\_patch_backup\eco-step-216b3-" + $stamp)
EnsureDir $backupBase

$r = New-Object System.Collections.Generic.List[string]
$r.Add("# ECO STEP 216b3 — fix build blocker (catch param e) + verify — $stamp")
$r.Add("")
$r.Add("Root: $Root")
$r.Add("")

$ecoApiDir = Join-Path $Root "src\app\api\eco"
if(-not (Test-Path -LiteralPath $ecoApiDir)){
  $r.Add("ERR: missing dir: $ecoApiDir")
  WriteUtf8NoBom $reportPath ($r -join "`n")
  throw ("Missing: " + $ecoApiDir)
}

# Find files that contain asMsg(e)
$targets = @()
$files = Get-ChildItem -LiteralPath $ecoApiDir -Recurse -File -ErrorAction SilentlyContinue |
  Where-Object { $_.Extension -in @(".ts",".tsx",".js",".jsx") }

if($files){
  $hits = $files | Select-String -Pattern "asMsg\(\s*e\s*\)" -List -ErrorAction SilentlyContinue
  if($hits){ $targets = $hits | Select-Object -ExpandProperty Path }
}

# Always include known failing file if present
$fallback = Join-Path $Root "src\app\api\eco\points\react\route.ts"
if((Test-Path -LiteralPath $fallback) -and (-not ($targets -contains $fallback))){
  $targets += $fallback
}

$r.Add("## DIAG")
$r.Add("- targets: " + $targets.Count)
foreach($t in $targets){ $r.Add("  - " + (RelPath $t $Root)) }
$r.Add("")

if(-not $targets -or $targets.Count -eq 0){
  $r.Add("ERR: no targets found (no asMsg(e)).")
  WriteUtf8NoBom $reportPath ($r -join "`n")
  throw ("No targets found. See report: " + $reportPath)
}

# Patch: change "catch {" to "catch (e) {" ONLY when next lines reference asMsg(e)
$changedFiles = 0
$r.Add("## PATCH")

foreach($file in $targets){
  if(-not (Test-Path -LiteralPath $file)){
    $r.Add("- skip missing: " + $file)
    continue
  }

  $lines = [IO.File]::ReadAllLines($file, [Text.UTF8Encoding]::new($false))
  $changed = $false

  for($i=0; $i -lt $lines.Length; $i++){
    $ln = $lines[$i]

    # detect catch line (with or without spaces)
    if($ln -match "\bcatch\s*\{\s*$" -or $ln -match "\bcatch\{\s*$"){
      # look ahead up to 20 lines for asMsg(e)
      $max = [Math]::Min($lines.Length-1, $i + 20)
      $usesE = $false
      for($j=$i+1; $j -le $max; $j++){
        if($lines[$j] -match "asMsg\(\s*e\s*\)"){ $usesE = $true; break }
      }

      if($usesE){
        $lines[$i] = ($ln -replace "\bcatch\s*\{\s*$","catch (e) {" -replace "\bcatch\{\s*$","catch (e) {")
        $changed = $true
      }
    }
  }

  if($changed){
    $rel = RelPath $file $Root
    $bak = Join-Path $backupBase $rel
    EnsureDir (Split-Path -Parent $bak)
    Copy-Item -LiteralPath $file -Destination $bak -Force

    [IO.File]::WriteAllLines($file, $lines, [Text.UTF8Encoding]::new($false))
    $changedFiles++
    $r.Add("- patched: " + $rel)
    $r.Add("  backup: " + $bak)
  } else {
    $r.Add("- ok: " + (RelPath $file $Root))
  }
}

$r.Add("")
$r.Add("Patched files: $changedFiles")
$r.Add("")

# VERIFY: npm run lint + npm run build via cmd (streams merged)
$lintLog  = Join-Path $reportsDir ("eco-step-216b3-lint-"  + $stamp + ".log")
$buildLog = Join-Path $reportsDir ("eco-step-216b3-build-" + $stamp + ".log")

function RunCmd([string]$what, [string]$cmdLine, [string]$logPath){
  Write-Host ("[216b3] " + $what + " ...")
  $full = "cd /d `"$Root`" && " + $cmdLine + " 2^>^&1"
  cmd.exe /c $full | Tee-Object -FilePath $logPath | Out-Host
  return $LASTEXITCODE
}

$r.Add("## VERIFY")

$lintExit  = RunCmd "npm run lint"  "npm run lint"  $lintLog
$r.Add("- lint exit: $lintExit")
$r.Add("- lint log: $lintLog")

$buildExit = RunCmd "npm run build" "npm run build" $buildLog
$r.Add("- build exit: $buildExit")
$r.Add("- build log: $buildLog")

$r.Add("")
WriteUtf8NoBom $reportPath ($r -join "`n")
Write-Host ("[REPORT] " + $reportPath)

if($OpenReport){ try { ii $reportPath } catch {} }

if($lintExit -ne 0){ throw ("LINT failed. See: " + $lintLog) }
if($buildExit -ne 0){ throw ("BUILD failed. See: " + $buildLog) }

Write-Host "[216b3] OK — lint+build passaram."