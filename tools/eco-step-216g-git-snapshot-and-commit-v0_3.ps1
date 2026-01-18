param(
  [switch]$OpenReport,
  [string]$Message = "ECO: build ok + lint 0 warnings (pickup id + catch vars)"
)

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
$reportPath = Join-Path $reportsDir ("eco-step-216g-git-snapshot-" + $stamp + ".md")

$r = New-Object System.Collections.Generic.List[string]
$r.Add("# ECO STEP 216g — git snapshot + commit — $stamp")
$r.Add("")
$r.Add("Root: $Root")
$r.Add("Message: $Message")
$r.Add("")

# status before
$statusBefore = @(& git -C $Root status --porcelain)
$diffStat = @(& git -C $Root diff --stat)

$r.Add("## git status (before)")
$r.Add("```")
if($statusBefore.Count -eq 0){ $r.Add("(clean)") } else { foreach($ln in $statusBefore){ $r.Add($ln) } }
$r.Add("```")
$r.Add("")

$r.Add("## git diff --stat")
$r.Add("```")
if($diffStat.Count -eq 0){ $r.Add("(no diff)") } else { foreach($ln in $diffStat){ $r.Add($ln) } }
$r.Add("```")
$r.Add("")

if($statusBefore.Count -eq 0){
  $r.Add("No changes to commit.")
  WriteUtf8NoBom $reportPath ($r -join "`n")
  Write-Host ("[REPORT] " + $reportPath)
  if($OpenReport){ try { ii $reportPath } catch {} }
  exit 0
}

# add + commit
$r.Add("## git add -A")
& git -C $Root add -A | Out-Null
$r.Add("OK")
$r.Add("")

$r.Add("## git commit")
$r.Add("```")
$commitOut = @(& git -C $Root commit -m $Message 2>&1)
foreach($ln in $commitOut){ $r.Add($ln) }
$r.Add("```")
$r.Add("")

if($LASTEXITCODE -ne 0){
  WriteUtf8NoBom $reportPath ($r -join "`n")
  Write-Host ("[REPORT] " + $reportPath)
  if($OpenReport){ try { ii $reportPath } catch {} }
  throw "git commit falhou (veja o report)."
}

# status after
$statusAfter = @(& git -C $Root status)
$r.Add("## git status (after)")
$r.Add("```")
foreach($ln in $statusAfter){ $r.Add($ln) }
$r.Add("```")
$r.Add("")

WriteUtf8NoBom $reportPath ($r -join "`n")
Write-Host ("[REPORT] " + $reportPath)
if($OpenReport){ try { ii $reportPath } catch {} }