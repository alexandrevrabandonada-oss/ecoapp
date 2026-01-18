$ErrorActionPreference = "Stop"

function EnsureDir([string]$p){
  if($p -and !(Test-Path -LiteralPath $p)){
    New-Item -ItemType Directory -Force -Path $p | Out-Null
  }
}

function WriteUtf8NoBom([string]$path, [string]$content){
  $dir = Split-Path -Parent $path
  if($dir){ EnsureDir $dir }
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
}

function BackupFile([string]$path){
  if(!(Test-Path -LiteralPath $path)){ return $null }
  EnsureDir "tools/_patch_backup"
  $ts = Get-Date -Format "yyyyMMdd-HHmmss"
  $safe = ($path -replace '[\\/:*?"<>|]', '_')
  $dst = "tools/_patch_backup/$ts-$safe"
  Copy-Item -Force -LiteralPath $path $dst
  return $dst
}

function NewReport([string]$name){
  EnsureDir "reports"
  $ts = Get-Date -Format "yyyyMMdd-HHmmss"
  return "reports/$ts-$name.md"
}

function FindFirst([string]$root, [string]$pattern){
  if(!(Test-Path -LiteralPath $root)){ return $null }
  $f = Get-ChildItem -Recurse -File -Path $root -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -match $pattern } |
    Select-Object -First 1
  if($f){ return $f.FullName }
  return $null
}

function InsertAfterLastImport([string]$txt, [string]$snippet){
  $m = [regex]::Matches($txt, '^\s*import\s+.*?;\s*$', 'Multiline')
  if($m.Count -gt 0){
    $last = $m[$m.Count-1]
    $at = $last.Index + $last.Length
    return $txt.Insert($at, "`n" + $snippet + "`n")
  }
  return $snippet + "`n" + $txt
}

# === write tools/_eco-lib.ps1 ===
$lib = @()
$lib += '$ErrorActionPreference = "Stop"'
$lib += ''
$lib += 'function EnsureDir([string]$p){'
$lib += '  if($p -and !(Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null }'
$lib += '}'
$lib += ''
$lib += 'function WriteUtf8NoBom([string]$path, [string]$content){'
$lib += '  $dir = Split-Path -Parent $path'
$lib += '  if($dir){ EnsureDir $dir }'
$lib += '  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)'
$lib += '  [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)'
$lib += '}'
$lib += ''
$lib += 'function BackupFile([string]$path){'
$lib += '  if(!(Test-Path -LiteralPath $path)){ return $null }'
$lib += '  EnsureDir "tools/_patch_backup"'
$lib += '  $ts = Get-Date -Format "yyyyMMdd-HHmmss"'
$lib += '  $safe = ($path -replace ''[\\/:*?"<>|]'', ''_'')'
$lib += '  $dst = "tools/_patch_backup/$ts-$safe"'
$lib += '  Copy-Item -Force -LiteralPath $path $dst'
$lib += '  return $dst'
$lib += '}'
$lib += ''
$lib += 'function NewReport([string]$name){'
$lib += '  EnsureDir "reports"'
$lib += '  $ts = Get-Date -Format "yyyyMMdd-HHmmss"'
$lib += '  return "reports/$ts-$name.md"'
$lib += '}'
$lib += ''
$lib += 'function FindFirst([string]$root, [string]$pattern){'
$lib += '  if(!(Test-Path -LiteralPath $root)){ return $null }'
$lib += '  $f = Get-ChildItem -Recurse -File -Path $root -ErrorAction SilentlyContinue |'
$lib += '    Where-Object { $_.FullName -match $pattern } |'
$lib += '    Select-Object -First 1'
$lib += '  if($f){ return $f.FullName }'
$lib += '  return $null'
$lib += '}'
$lib += ''
$lib += 'function InsertAfterLastImport([string]$txt, [string]$snippet){'
$lib += '  $m = [regex]::Matches($txt, ''^\s*import\s+.*?;\s*$'', ''Multiline'')'
$lib += '  if($m.Count -gt 0){'
$lib += '    $last = $m[$m.Count-1]'
$lib += '    $at = $last.Index + $last.Length'
$lib += '    return $txt.Insert($at, "`n" + $snippet + "`n")'
$lib += '  }'
$lib += '  return $snippet + "`n" + $txt'
$lib += '}'

WriteUtf8NoBom "tools/_eco-lib.ps1" ($lib -join "`n")

# === write tools/_step-template.ps1 ===
$t = @()
$t += '$ErrorActionPreference = "Stop"'
$t += '. "$PSScriptRoot/_eco-lib.ps1"'
$t += ''
$t += '$rep = NewReport "eco-step-XX-NOME"'
$t += '$log = @()'
$t += '$log += "# ECO — STEP XX — Nome do passo"'
$t += '$log += ""'
$t += '$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))'
$t += '$log += ("PWD : {0}" -f (Get-Location).Path)'
$t += '$log += ""'
$t += ''
$t += '# DIAG -> localizar arquivos com FindFirst / Contains'
$t += '# PATCH -> BackupFile + WriteUtf8NoBom'
$t += '# VERIFY -> (orientar smoke)'
$t += ''
$t += 'WriteUtf8NoBom $rep ($log -join "`n")'
$t += 'Write-Host ("✅ STEP XX pronto. Report -> {0}" -f $rep) -ForegroundColor Green'

WriteUtf8NoBom "tools/_step-template.ps1" ($t -join "`n")

Write-Host "✅ Foundation criada:" -ForegroundColor Green
Write-Host " - tools/_eco-lib.ps1" -ForegroundColor Green
Write-Host " - tools/_step-template.ps1" -ForegroundColor Green