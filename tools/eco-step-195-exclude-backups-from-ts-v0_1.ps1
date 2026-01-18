param([switch]$OpenReport)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function NowStamp(){ (Get-Date).ToString("yyyyMMdd-HHmmss") }
function EnsureDir([string]$p){ if(!(Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function WriteUtf8NoBom([string]$path, [string]$text){ [IO.File]::WriteAllText($path, $text, [Text.UTF8Encoding]::new($false)) }
function BackupFile([string]$file, [string]$bakDir){
  EnsureDir $bakDir
  $safe = ($file -replace "[:\\\/\[\]\s]", "_")
  $dst = Join-Path $bakDir ((NowStamp) + "-" + $safe)
  Copy-Item -LiteralPath $file -Destination $dst -Force
  return $dst
}

if(!(Test-Path -LiteralPath "package.json")){ throw "Rode na raiz do repo (onde tem package.json)." }

$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
$stamp = NowStamp

# ---------- 1) tsconfig.json: garantir exclude para tools/_patch_backup e tools
$tsCandidates = @(
  (Join-Path $repoRoot "tsconfig.json"),
  (Join-Path $repoRoot "tsconfig.base.json"),
  (Join-Path $repoRoot "tsconfig.app.json")
)
$tsPath = $tsCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if(!$tsPath){
  $any = Get-ChildItem -LiteralPath $repoRoot -Filter "tsconfig*.json" -File -ErrorAction SilentlyContinue | Select-Object -First 1
  if($any){ $tsPath = $any.FullName }
}
if(!$tsPath){ throw "Nao achei tsconfig*.json na raiz." }

$tsRaw = Get-Content -LiteralPath $tsPath -Raw
$tsObj = $tsRaw | ConvertFrom-Json

$needExclude = @(
  "tools/_patch_backup",
  "tools/_patch_backup/**",
  "tools/**",
  "reports/**"
)

$changedTs = $false
if(-not ($tsObj.PSObject.Properties.Name -contains "exclude")){
  $tsObj | Add-Member -NotePropertyName "exclude" -NotePropertyValue @()
  $changedTs = $true
}
# garante array
if($tsObj.exclude -isnot [System.Collections.IEnumerable] -or $tsObj.exclude -is [string]){
  $tsObj.exclude = @($tsObj.exclude)
  $changedTs = $true
}
foreach($p in $needExclude){
  if(($tsObj.exclude | ForEach-Object { "$_" }) -notcontains $p){
    $tsObj.exclude += $p
    $changedTs = $true
  }
}

$bakDir = Join-Path $repoRoot ("tools\_patch_backup\eco-step-195\" + $stamp)
EnsureDir $bakDir
$bakTs = BackupFile $tsPath $bakDir

if($changedTs){
  $newTs = ($tsObj | ConvertTo-Json -Depth 80)
  WriteUtf8NoBom $tsPath ($newTs + "`n")
}

# ---------- 2) .eslintignore: ignorar backups (evita ruído no lint)
$eslintIgnore = Join-Path $repoRoot ".eslintignore"
$eiChanged = $false
$eiNeed = @(
  "tools/_patch_backup/",
  "tools/_patch_backup/**",
  "reports/",
  "reports/**"
)

if(Test-Path -LiteralPath $eslintIgnore){
  $ei = Get-Content -LiteralPath $eslintIgnore -Raw
} else {
  $ei = ""
  $eiChanged = $true
}

foreach($line in $eiNeed){
  if($ei -notmatch [regex]::Escape($line)){
    if($ei.Length -gt 0 -and !$ei.EndsWith("`n")){ $ei += "`n" }
    $ei += ($line + "`n")
    $eiChanged = $true
  }
}

if($eiChanged){
  if(Test-Path -LiteralPath $eslintIgnore){ BackupFile $eslintIgnore $bakDir | Out-Null }
  WriteUtf8NoBom $eslintIgnore $ei
}

# ---------- 3) Neutralizar backups .ts/.tsx/.js/.jsx dentro de tools/_patch_backup (renomeia para .bak)
$pb = Join-Path $repoRoot "tools\_patch_backup"
$renamed = 0
if(Test-Path -LiteralPath $pb){
  $files = Get-ChildItem -LiteralPath $pb -Recurse -File -Include *.ts,*.tsx,*.js,*.jsx -ErrorAction SilentlyContinue
  foreach($f in $files){
    if($f.Name -match "\.bak$"){ continue }
    $newName = $f.Name + ".bak"
    try {
      Rename-Item -LiteralPath $f.FullName -NewName $newName -Force
      $renamed++
    } catch {}
  }
}

# ---------- REPORT
EnsureDir (Join-Path $repoRoot "reports")
$reportPath = Join-Path $repoRoot ("reports\eco-step-195-exclude-backups-from-ts-" + $stamp + ".md")

$r = @()
$r += ("# eco-step-195 — exclude backups from TS/lint — " + $stamp)
$r += ""
$r += "## DIAG"
$r += ("- tsconfig: " + (Split-Path -Leaf $tsPath))
$r += ("- backup tsconfig: " + $bakTs)
$r += ("- rename backups (.ts/.tsx/.js/.jsx -> .bak): " + $renamed)
$r += ""
$r += "## PATCH"
$r += ("- tsconfig.exclude += " + ($needExclude -join ", "))
$r += ("- .eslintignore += " + ($eiNeed -join ", "))
$r += ""
$r += "## VERIFY"
$r += "- npm run build"
$r += ""

WriteUtf8NoBom $reportPath ($r -join "`n")
Write-Host ("[REPORT] " + $reportPath)
if($OpenReport){ try{ Start-Process $reportPath | Out-Null } catch {} }

Write-Host ""
Write-Host "[NEXT] rode:"
Write-Host "  npm run build"