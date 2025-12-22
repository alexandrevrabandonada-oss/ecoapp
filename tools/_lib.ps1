$ErrorActionPreference = "Stop"

function Ensure-Dir([string]$p){ if(!(Test-Path $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }

function WriteUtf8NoBom([string]$path, [string]$content){
  $dir = Split-Path $path -Parent
  if($dir){ Ensure-Dir $dir }
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
}

function Backup-File([string]$path){
  if(!(Test-Path $path)){ return $null }
  Ensure-Dir "tools/_patch_backup"
  $ts = Get-Date -Format "yyyyMMdd-HHmmss"
  $safe = ($path -replace '[\\/:*?"<>|]', '_')
  $dst = "tools/_patch_backup/$ts-$safe"
  Copy-Item -Force $path $dst
  return $dst
}

function New-Report([string]$name){
  Ensure-Dir "reports"
  $ts = Get-Date -Format "yyyyMMdd-HHmmss"
  return "reports/$ts-$name.md"
}

function RelPath([string]$full){
  $root = (Get-Location).Path.TrimEnd('\')
  return $full.Replace($root + "\","")
}

function List-Routes(){
  $pages = Get-ChildItem -Recurse -File "src/app" -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -in @("page.tsx","page.jsx","page.ts","page.js") } |
    ForEach-Object { RelPath $_.FullName }

  $apis = Get-ChildItem -Recurse -File "src/app/api" -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -in @("route.ts","route.js") } |
    ForEach-Object { RelPath $_.FullName }

  return [pscustomobject]@{ pages = $pages; apis = $apis }
}

function List-Prisma-Models(){
  $schema = "prisma/schema.prisma"
  if(!(Test-Path $schema)){ return @() }
  $txt = Get-Content $schema -Raw
  $models = @()
  foreach($m in [regex]::Matches($txt, '(?m)^\s*model\s+([A-Za-z_]\w*)\s*\{')){
    $models += $m.Groups[1].Value
  }
  return $models | Sort-Object -Unique
}