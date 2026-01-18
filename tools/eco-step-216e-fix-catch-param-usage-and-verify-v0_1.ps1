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
function BackupRel([string]$rel){
  $src = Join-Path $Root $rel
  if(-not (Test-Path -LiteralPath $src)){ return $null }
  $base = Join-Path $Root ("tools\_patch_backup\eco-step-216e-" + $stamp)
  $dst = Join-Path $base $rel
  EnsureDir (Split-Path -Parent $dst)
  Copy-Item -LiteralPath $src -Destination $dst -Force
  return $dst
}
function BraceDelta([string]$line){
  $o = ([regex]::Matches($line, "\{")).Count
  $c = ([regex]::Matches($line, "\}")).Count
  return ($o - $c)
}

function PatchCatchBlocks([string]$relPath, [switch]$FixAsMsgEInsideUnderscoreCatch, [switch]$InsertVoidIfUnused){
  $full = Join-Path $Root $relPath
  if(-not (Test-Path -LiteralPath $full)){ return @{ changed=$false; note="missing" } }

  $rawLines = [IO.File]::ReadAllLines($full, [Text.UTF8Encoding]::new($false))
  $lines = New-Object System.Collections.Generic.List[string]
  foreach($x in $rawLines){ $lines.Add($x) | Out-Null }

  $changed = $false

  $inCatch = $false
  $param = ""
  $depth = 0
  $startBodyIndex = -1
  $paramUsed = $false

  for($i=0; $i -lt $lines.Count; $i++){
    $ln = $lines[$i]

    if(-not $inCatch){
      $m = [regex]::Match($ln, "\bcatch\s*\(\s*(?<p>[A-Za-z_][A-Za-z0-9_]*)\s*\)")
      if($m.Success){
        $inCatch = $true
        $param = $m.Groups["p"].Value
        $paramUsed = $false
        $startBodyIndex = $i + 1

        $d0 = BraceDelta $ln
        if($d0 -le 0){ $depth = 1 } else { $depth = $d0 }

        continue
      }
    } else {
      if($FixAsMsgEInsideUnderscoreCatch){
        if($param -eq "_e"){
          if($ln -match "asMsg\(\s*e\s*\)"){
            $lines[$i] = [regex]::Replace($ln, "asMsg\(\s*e\s*\)", "asMsg(_e)")
            $ln = $lines[$i]
            $changed = $true
          }
        }
      }

      if(-not [string]::IsNullOrWhiteSpace($param)){
        if([regex]::IsMatch($ln, "(?<![A-Za-z0-9_])" + [regex]::Escape($param) + "(?![A-Za-z0-9_])")){
          $paramUsed = $true
        }
      }

      $depth += (BraceDelta $ln)
      if($depth -le 0){
        if($InsertVoidIfUnused -and (-not $paramUsed) -and (-not [string]::IsNullOrWhiteSpace($param))){
          if($startBodyIndex -ge 0 -and $startBodyIndex -lt $lines.Count){
            $next = $lines[$startBodyIndex].Trim()
            $voidLine = ("    void " + $param + ";")
            if($next -ne $voidLine.Trim()){
              $lines.Insert($startBodyIndex, $voidLine)
              $changed = $true
              $i++
            }
          }
        }

        $inCatch = $false
        $param = ""
        $depth = 0
        $startBodyIndex = -1
        $paramUsed = $false
      }
    }
  }

  if($changed){
    BackupRel $relPath | Out-Null
    [IO.File]::WriteAllLines($full, $lines.ToArray(), [Text.UTF8Encoding]::new($false))
  }

  return @{ changed=$changed; note="ok" }
}

$reportsDir = Join-Path $Root "reports"
EnsureDir $reportsDir
$reportPath = Join-Path $reportsDir ("eco-step-216e-fix-catch-param-usage-" + $stamp + ".md")

$r = New-Object System.Collections.Generic.List[string]
$r.Add("# ECO STEP 216e — fix catch param usage + verify — $stamp")
$r.Add("")
$r.Add("Root: $Root")
$r.Add("")

$targets = @(
  "src\app\api\eco\points\report\route.ts",
  "src\app\api\eco\point\reopen\route.ts"
)

$r.Add("## PATCH")
foreach($t in $targets){
  if($t -like "*\points\report\*"){
    $res = PatchCatchBlocks $t -FixAsMsgEInsideUnderscoreCatch -InsertVoidIfUnused
  } else {
    $res = PatchCatchBlocks $t -InsertVoidIfUnused
  }
  $r.Add(("- " + $t + " => changed=" + $res.changed + " (" + $res.note + ")"))
}
$r.Add("")

function RunCmd([string]$label, [string]$cmdLine, [string]$logPath){
  Write-Host ("[216e] " + $label + " ...")
  $full = "cd /d `"$Root`" && " + $cmdLine + " 2^>^&1"
  cmd.exe /c $full | Tee-Object -FilePath $logPath | Out-Host
  return $LASTEXITCODE
}

function CountWarnings([string]$logPath){
  if(-not (Test-Path -LiteralPath $logPath)){ return 0 }
  $m = Select-String -LiteralPath $logPath -Pattern "^\s*\d+:\d+\s+warning\b" -ErrorAction SilentlyContinue
  if(-not $m){ return 0 }
  return @($m).Count
}

$lintLog  = Join-Path $reportsDir ("eco-step-216e-lint-"  + $stamp + ".log")
$buildLog = Join-Path $reportsDir ("eco-step-216e-build-" + $stamp + ".log")

$r.Add("## VERIFY")
$lintExit  = RunCmd "npm run lint"  "npm run lint"  $lintLog
$warnCount = CountWarnings $lintLog
$r.Add("- lint exit: $lintExit")
$r.Add("- lint warnings: $warnCount")
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

Write-Host "[216e] OK — zero warnings + build passou."