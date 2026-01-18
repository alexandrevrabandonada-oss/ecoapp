param([switch]$OpenReport)

$ErrorActionPreference = "Stop"
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"

function EnsureDir([string]$p){
  if([string]::IsNullOrWhiteSpace($p)){ return }
  if(-not (Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null }
}
function WriteUtf8NoBom([string]$p,[string]$text){
  EnsureDir (Split-Path -Parent $p)
  [IO.File]::WriteAllText($p, $text, [Text.UTF8Encoding]::new($false))
}
function BackupFileLocal([string]$file,[string]$backupDir){
  EnsureDir $backupDir
  if(Test-Path -LiteralPath $file){
    $name = (Split-Path -Leaf $file)
    $dst = Join-Path $backupDir ($name + ".bak-" + $stamp)
    Copy-Item -LiteralPath $file -Destination $dst -Force
    return $dst
  }
  return $null
}

$bootstrap = Join-Path $Root "tools\_bootstrap.ps1"
if(-not (Test-Path -LiteralPath $bootstrap)){
  throw ("Nao achei: " + $bootstrap)
}

$backupDir = Join-Path $Root "tools\_patch_backup\eco-step-217"
$bak = BackupFileLocal $bootstrap $backupDir

$raw = Get-Content -LiteralPath $bootstrap -Raw
$occ = [int]([regex]::Matches($raw, "\$r\.Value\s*\+=").Count)

$addFunc = @"
function AddReportLine(`$r, `$line){
  if(`$null -eq `$r){ return }
  `$s = [string]`$line
  if(`$r -is [ref]){
    `$r.Value += `$s
    return
  }
  if(`$r -is [System.Collections.Generic.List[string]]){
    `$null = `$r.Add(`$s)
    return
  }
  if(`$r -is [System.Collections.IList]){
    `$null = `$r.Add(`$s)
    return
  }
  try {
    `$script:__bootstrap_report = @(`$script:__bootstrap_report) + @(`$s)
  } catch { }
}
"@

$hadAdd = [bool]([regex]::IsMatch($raw, "function\s+AddReportLine\("))

if($occ -gt 0){
  $raw2 = [regex]::Replace($raw, "\$r\.Value\s*\+=", "AddReportLine `$r")
} else {
  $raw2 = $raw
}

if(-not $hadAdd){
  $idx = $raw2.IndexOf("function ")
  if($idx -gt 0){
    $raw2 = $raw2.Substring(0,$idx) + $addFunc + "`n" + $raw2.Substring($idx)
  } else {
    $raw2 = $addFunc + "`n" + $raw2
  }
}

if($raw2 -ne $raw){
  WriteUtf8NoBom $bootstrap $raw2
}

# VERIFY
$verify = @()
$verify += "ECO STEP 217 - fix tools/_bootstrap.ps1 - $stamp"
$verify += ""
$verify += ("bootstrap: " + $bootstrap)
$verify += ("backup: " + ($(if($bak){$bak}else{"(none)"})))
$verify += ("replaced occurrences: " + $occ)
$verify += ("AddReportLine existed before: " + $hadAdd)
$verify += ""

try{
  . $bootstrap
  $verify += "[OK] dot-sourced _bootstrap.ps1"

  $cmd = Get-Command BackupFile -ErrorAction SilentlyContinue
  if($cmd){
    $pCount = $cmd.Parameters.Count
    $lst = [System.Collections.Generic.List[string]]::new()
    $fake = Join-Path $Root "__no_such_file__217.txt"
    try{
      if($pCount -eq 2){
        BackupFile $fake $lst | Out-Null
      } elseif($pCount -eq 3){
        BackupFile $fake (Join-Path $Root "tools\_patch_backup") $lst | Out-Null
      } else {
        BackupFile $fake (Join-Path $Root "tools\_patch_backup") "x" $lst | Out-Null
      }
      $verify += ("[OK] BackupFile called (paramCount=" + $pCount + ") without r.Value crash")
    } catch {
      $verify += ("[WARN] BackupFile call failed: " + $_.Exception.Message)
    }
  } else {
    $verify += "[INFO] BackupFile function not found (ok)."
  }
} catch {
  $verify += ("[ERR] dot-source failed: " + $_.Exception.Message)
}

$reportPath = Join-Path $Root ("reports\eco-step-217-fix-bootstrap-" + $stamp + ".md")
WriteUtf8NoBom $reportPath ($verify -join "`n")
Write-Host ("[REPORT] " + $reportPath)
if($OpenReport){ try { ii $reportPath } catch {} }