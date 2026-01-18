param(
  [int]$Port = 3000,
  [int]$WaitSeconds = 45,
  [switch]$OpenReport
)

$ErrorActionPreference = "Stop"

function NowStamp(){ return (Get-Date).ToString("yyyyMMdd-HHmmss") }
function EnsureDir([string]$p){ if(!(Test-Path $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function WriteUtf8NoBom([string]$path, [string]$content){ [IO.File]::WriteAllText($path, $content, [Text.UTF8Encoding]::new($false)) }

function RunCmd([string]$label, [scriptblock]$sb){
  $out = ""
  try { $out = (& $sb 2>&1 | Out-String).TrimEnd() } catch { $out = "(erro: " + $_.Exception.Message + ")" }
  return @(
    "",
    ("### " + $label),
    "~~~",
    $out,
    "~~~"
  )
}

function WaitPort([int]$port, [int]$seconds){
  $deadline = (Get-Date).AddSeconds($seconds)
  while((Get-Date) -lt $deadline){
    try {
      $r = Invoke-WebRequest -Uri ("http://localhost:" + $port + "/api/health") -UseBasicParsing -TimeoutSec 2
      return $true
    } catch {
      Start-Sleep -Milliseconds 500
    }
  }
  return $false
}

function TryHttp([string]$url){
  try {
    $r = Invoke-WebRequest -Uri $url -Method GET -Headers @{ Accept="application/json" } -UseBasicParsing -TimeoutSec 10
    return @{ ok=$true; status=[int]$r.StatusCode; body=$r.Content }
  } catch {
    return @{ ok=$false; err=$_.Exception.Message }
  }
}

if(!(Test-Path "package.json")){ throw "Rode na raiz do repo (onde tem package.json)." }

$stamp = NowStamp
EnsureDir "reports"
$reportPath = Join-Path "reports" ("eco-step-148b-verify-smoke-autodev-" + $stamp + ".md")

$r = @()
$r += ("# eco-step-148b — verify + smoke (auto dev) — " + $stamp)

# VERIFY (offline)
$r += ""
$r += "## VERIFY (offline)"
$r += (RunCmd "npm run lint" { npm run lint })
$r += (RunCmd "npm run build" { npm run build })

# Start dev
$r += ""
$r += "## DEV (auto)"
$devOk = $false
$job = $null
try {
  $job = Start-Job -ScriptBlock { npm run dev } | Out-Null
  $devOk = WaitPort -port $Port -seconds $WaitSeconds
  $r += ("- started: True")
  $r += ("- port_ready: " + $devOk)
} catch {
  $r += ("- started: False (" + $_.Exception.Message + ")")
}

# SMOKE
$r += ""
$r += "## SMOKE"
$base = "http://localhost:" + $Port
$targets = @(
  @{ name="points_list";  url=($base + "/api/eco/points/list") },
  @{ name="points_list2"; url=($base + "/api/eco/points/list2") },
  @{ name="points2";      url=($base + "/api/eco/points2") },
  @{ name="points_get_noid"; url=($base + "/api/eco/points/get") },
  @{ name="point_detail_noid"; url=($base + "/api/eco/point/detail") },
  @{ name="points_map";   url=($base + "/api/eco/points/map") },
  @{ name="points_stats"; url=($base + "/api/eco/points/stats") },
  @{ name="mural_list";   url=($base + "/api/eco/mural/list") }
)

foreach($t in $targets){
  $res = TryHttp $t.url
  $r += ""
  $r += ("### " + $t.name)
  if($res.ok){
    $r += ("- status: " + $res.status)
    $r += "~~~json"
    $body = $res.body
    if($body -and $body.Length -gt 4000){ $body = $body.Substring(0,4000) + "...(trunc)" }
    $r += $body
    $r += "~~~"
  } else {
    $r += ("- error: " + $res.err)
  }
}

# Stop dev job
$r += ""
$r += "## DEV stop"
try {
  Get-Job | Where-Object { $_.State -eq "Running" } | Stop-Job -Force | Out-Null
  Get-Job | Remove-Job -Force | Out-Null
  $r += "- stopped: True"
} catch {
  $r += ("- stopped: False (" + $_.Exception.Message + ")")
}

WriteUtf8NoBom $reportPath ($r -join "`n")
Write-Host ("[REPORT] " + $reportPath)

if($OpenReport){ try { Start-Process $reportPath | Out-Null } catch {} }