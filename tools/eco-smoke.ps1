param([string]$BaseUrl = "http://localhost:3000")
$ErrorActionPreference = "Stop"

function Hit([string]$Path){
  $url = "$BaseUrl$Path"
  $res = Invoke-WebRequest -Uri $url -TimeoutSec 10 -SkipHttpErrorCheck
  if($res.StatusCode -ge 200 -and $res.StatusCode -lt 300){
    Write-Host "✅ $Path -> $($res.StatusCode)" -ForegroundColor Green
    return
  }
  $body = ""
  try { $body = $res.Content } catch {}
  Write-Host "❌ $Path -> $($res.StatusCode)" -ForegroundColor Red
  if($body){
    Write-Host "---- body ----" -ForegroundColor DarkYellow
    Write-Host $body
    Write-Host "-------------" -ForegroundColor DarkYellow
  }
  throw "Smoke falhou em $Path"
}

Write-Host "== ECO SMOKE ==" -ForegroundColor Cyan
Hit "/"
Hit "/servicos"
Hit "/coleta"
Hit "/chamar-coleta"
Hit "/chamar-coleta/novo"
Hit "/recibos"
  '/operador/triagem'
Hit "/operador"
Hit "/api/services"
Hit "/api/points"
Hit "/api/pickup-requests"
Hit "/api/receipts"
Write-Host "✅ SMOKE OK" -ForegroundColor Green