$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# helpers aqui dentro...
function WriteUtf8NoBom([string]$path,[string]$content){
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
}

# ...seu patch aqui...
Write-Host "OK: rodou"