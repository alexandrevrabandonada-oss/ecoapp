param([switch]$OpenReport)

$ErrorActionPreference = "Stop"

function NowStamp(){ Get-Date -Format "yyyyMMdd-HHmmss" }
function EnsureDir([string]$p){ if(-not (Test-Path $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function WriteUtf8NoBom([string]$p, [string]$s){ [IO.File]::WriteAllText($p, $s, [Text.UTF8Encoding]::new($false)) }

$root = (Resolve-Path ".").Path
$stamp = NowStamp
EnsureDir (Join-Path $root "reports")

$reportPath = Join-Path $root ("reports\eco-step-210-fix-eco-runner-tasks-argv-" + $stamp + ".md")
$r = @()
$r += "# eco-step-210 — fix eco-runner Tasks argv — $stamp"
$r += ""
$r += "Root: $root"
$r += ""

# --- backup ---
$runnerPath = Join-Path $root "tools\eco-runner.ps1"
if(Test-Path $runnerPath){
  $bkDir = Join-Path $root ("tools\_patch_backup\eco-step-210\" + $stamp)
  EnsureDir $bkDir
  $bk = Join-Path $bkDir "eco-runner.ps1"
  Copy-Item -LiteralPath $runnerPath -Destination $bk -Force
  $r += "[BACKUP] $runnerPath -> $bk"
  $r += ""
}else{
  $r += "[WARN] tools\eco-runner.ps1 não existe (vai criar do zero)"
  $r += ""
}

# --- write new eco-runner.ps1 (do zero, robusto) ---
EnsureDir (Join-Path $root "tools")

$runnerLines = @(
'param(',
'  [Parameter(Mandatory=$false)]',
'  [string[]]$Tasks = @(),',
'  [switch]$OpenReport,',
'  [string]$SmokeScript = ""',
')',
'',
'$ErrorActionPreference = "Stop"',
'',
'function NowStamp(){ Get-Date -Format "yyyyMMdd-HHmmss" }',
'function EnsureDir([string]$p){ if(-not (Test-Path $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }',
'function WriteUtf8NoBom([string]$p,[string]$s){ [IO.File]::WriteAllText($p,$s,[Text.UTF8Encoding]::new($false)) }',
'function FindExe([string]$name){',
'  $c = Get-Command $name -ErrorAction SilentlyContinue',
'  if($c){ return $c.Source }',
'  return $null',
'}',
'function RunCmd([string]$title,[string]$exe,[string[]]$args,[ref]$log){',
'  $log.Value += ""',
'  $log.Value += "## RUN: $title"',
'  $log.Value += ""',
'  $log.Value += ("exe: " + $exe)',
'  $log.Value += ("args: " + ($args -join " "))',
'  $log.Value += "~~~"',
'  $out = (& $exe @args 2>&1 | Out-String)',
'  $log.Value += $out.TrimEnd()',
'  $log.Value += "~~~"',
'  $ec = $LASTEXITCODE',
'  $log.Value += ("exit: " + $ec)',
'  if($ec -ne 0){ throw ("command failed: " + $title + " (exit " + $ec + ")") }',
'}',
'',
'$root = (Resolve-Path ".").Path',
'$stamp = NowStamp',
'EnsureDir (Join-Path $root "reports")',
'$reportPath = Join-Path $root ("reports\eco-runner-" + $stamp + ".md")',
'$r = @()',
'$r += "# eco-runner - $stamp"',
'$r += ""',
'$r += "Root: $root"',
'$r += ""',
'',
'# ---- normalize tasks ----',
'if(-not $Tasks -or $Tasks.Count -eq 0){',
'  $Tasks = @("lint","build")',
'}',
'$norm = @()',
'foreach($t in $Tasks){',
'  if([string]::IsNullOrWhiteSpace($t)){ continue }',
'  # aceita tokens tipo "lint,build" (vira 2 tasks)',
'  foreach($p in ($t -split ",")){',
'    $q = $p.Trim()',
'    if($q){ $norm += $q }',
'  }',
'}',
'$Tasks = $norm',
'',
'# aceita "lint build" em um token único (só por segurança)',
'if($Tasks.Count -eq 1 -and $Tasks[0] -match "\s"){',
'  $Tasks = $Tasks[0].Split(" ", [System.StringSplitOptions]::RemoveEmptyEntries)',
'}',
'',
'# dedupe + lowercase',
'$seen = @{}',
'$final = @()',
'foreach($t in $Tasks){',
'  $k = ($t.Trim().ToLowerInvariant())',
'  if(-not $k){ continue }',
'  if($seen.ContainsKey($k)){ continue }',
'  $seen[$k] = $true',
'  $final += $k',
'}',
'$Tasks = $final',
'',
'$allowed = @("lint","build","smoke")',
'$todo = @()',
'foreach($t in $Tasks){',
'  if($allowed -contains $t){ $todo += $t } else {',
'    $r += "WARN: task ignorada: $t (use: lint, build, smoke)"',
'  }',
'}',
'',
'# ---- executáveis ----',
'$npm = FindExe "npm.cmd"',
'if(-not $npm){ $npm = FindExe "npm" }',
'if(-not $npm){ throw "npm não encontrado no PATH" }',
'',
'$pwsh = FindExe "pwsh"',
'if(-not $pwsh){ $pwsh = FindExe "powershell" }',
'if(-not $pwsh){ throw "pwsh/powershell não encontrado no PATH" }',
'',
'# ---- tasks ----',
'foreach($t in $todo){',
'  if($t -eq "lint"){',
'    RunCmd "npm run lint" $npm @("run","lint") ([ref]$r)',
'  } elseif($t -eq "build"){',
'    RunCmd "npm run build" $npm @("run","build") ([ref]$r)',
'  } elseif($t -eq "smoke"){',
'    $smokePath = $null',
'    if($SmokeScript -and $SmokeScript.Trim()){',
'      $smokePath = (Resolve-Path $SmokeScript).Path',
'    } else {',
'      $toolsDir = Join-Path $root "tools"',
'      $cand = @()',
'      $cand += (Get-ChildItem -LiteralPath $toolsDir -File -Filter "eco-step-*-verify-smoke-*.ps1" -ErrorAction SilentlyContinue)',
'      $cand += (Get-ChildItem -LiteralPath $toolsDir -File -Filter "eco-step-*-smoke*.ps1" -ErrorAction SilentlyContinue)',
'      $cand = $cand | Sort-Object LastWriteTime -Descending',
'      if($cand -and $cand.Count -gt 0){',
'        $smokePath = $cand[0].FullName',
'      }',
'    }',
'    if(-not $smokePath){',
'      $r += ""',
'      $r += "WARN: smoke não rodou (nenhum script encontrado em tools\ com pattern eco-step-*-verify-smoke-*.ps1 / eco-step-*-smoke*.ps1)"',
'      continue',
'    }',
'',
'    # tenta passar -OpenReport só se o smoke suportar',
'    $args = @("-NoProfile","-ExecutionPolicy","Bypass","-File",$smokePath)',
'    if($OpenReport){',
'      try {',
'        $head = (Get-Content -LiteralPath $smokePath -TotalCount 120 -ErrorAction SilentlyContinue | Out-String)',
'        if($head -match "(?i)\bOpenReport\b"){ $args += "-OpenReport" }',
'      } catch { }',
'    }',
'    RunCmd ("smoke: " + $smokePath) $pwsh $args ([ref]$r)',
'  }',
'}',
'',
'WriteUtf8NoBom $reportPath ($r -join "`n")',
'Write-Host ("[REPORT] " + $reportPath)',
'if($OpenReport){ Start-Process $reportPath | Out-Null }'
)

WriteUtf8NoBom $runnerPath ($runnerLines -join "`n")
$r += "## PATCH"
$r += "- wrote: $runnerPath"
$r += ""

# --- verify (testa os 2 formatos de Tasks) ---
$pwshExe = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
if(-not $pwshExe){ $pwshExe = (Get-Command powershell -ErrorAction SilentlyContinue).Source }
if(-not $pwshExe){ throw "pwsh/powershell não encontrado no PATH" }

$r += "## VERIFY"
$r += "### -Tasks lint build (2 tokens)"
$r += "~~~"
try {
  $out = (& $pwshExe -NoProfile -ExecutionPolicy Bypass -File $runnerPath -Tasks lint build 2>&1 | Out-String).TrimEnd()
  $r += $out
} catch {
  $r += ($_ | Out-String)
}
$r += "~~~"
$r += ""

$r += "### -Tasks lint,build (1 token com vírgula)"
$r += "~~~"
try {
  $out = (& $pwshExe -NoProfile -ExecutionPolicy Bypass -File $runnerPath -Tasks "lint,build" 2>&1 | Out-String).TrimEnd()
  $r += $out
} catch {
  $r += ($_ | Out-String)
}
$r += "~~~"
$r += ""

WriteUtf8NoBom $reportPath ($r -join "`n")
Write-Host ("[REPORT] " + $reportPath)
if($OpenReport){ Start-Process $reportPath | Out-Null }