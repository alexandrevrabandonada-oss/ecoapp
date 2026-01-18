$ErrorActionPreference = "Stop"

Write-Host "== ECO SMOKE — SHARE DAY ==" -ForegroundColor Cyan
$BaseUrl = "http://localhost:3000"
$today = (Get-Date -Format "yyyy-MM-dd")

$paths = @(
  "/s/dia",
  "/s/dia/$today",
  "/api/share/route-day-card?day=$today&format=3x4",
  "/api/share/route-day-card?day=$today&format=1x1",
  "/operador/triagem"
)

foreach($p in $paths){
  $url = $BaseUrl + $p
  try {
    $res = Invoke-WebRequest -Uri $url -Method GET -UseBasicParsing
    $sc = [int]$res.StatusCode
    if($sc -ge 200 -and $sc -lt 300){
      Write-Host ("OK {0} -> {1}" -f $sc, $p) -ForegroundColor Green
    } else {
      Write-Host ("FAIL {0} -> {1}" -f $sc, $p) -ForegroundColor Red
      exit 1
    }
  } catch {
    Write-Host ("ERR -> {0}" -f $p) -ForegroundColor Red
    Write-Host ($_.Exception.Message) -ForegroundColor DarkRed
    exit 1
  }
}

Write-Host "OK: smoke share day concluído" -ForegroundColor Green