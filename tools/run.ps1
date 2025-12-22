param(
  [Parameter(Mandatory=$true)][string]$Name,
  [string]$Arg1 = ""
)

$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$path = Join-Path $toolsDir $Name

if(!(Test-Path $path)){
  Write-Host "❌ Não achei: $path" -ForegroundColor Red
  Write-Host "Disponíveis em tools/:" -ForegroundColor Yellow
  Get-ChildItem $toolsDir -Filter "*.ps1" | ForEach-Object { " - " + $_.Name } | Out-Host
  exit 1
}

Write-Host "▶ Rodando: $Name" -ForegroundColor Cyan
if($Arg1){
  pwsh -NoProfile -ExecutionPolicy Bypass -File $path $Arg1
} else {
  pwsh -NoProfile -ExecutionPolicy Bypass -File $path
}