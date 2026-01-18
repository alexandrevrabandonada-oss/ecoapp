$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

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

$rep = NewReport "eco-step-49-bootstrap-tijolos"
$log = @()
$log += "# ECO — STEP 49 — Bootstrap dos tijolos (tools/_bootstrap.ps1 + template)"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

try {
  # GUARD repo
  if(!(Test-Path -LiteralPath "src/app")){
    throw "GUARD: não achei src/app — rode no repo ECO (C:\Projetos\App ECO\eluta-servicos)."
  }

  # -------------------------
  # PATCH 1) tools/_bootstrap.ps1
  # -------------------------
  $bootPath = "tools/_bootstrap.ps1"
  $bkBoot = BackupFile $bootPath

  $bootLines = @(
    '$ErrorActionPreference = "Stop"'
    'Set-StrictMode -Version Latest'
    ''
    'function EnsureDir([string]$p){'
    '  if($p -and !(Test-Path -LiteralPath $p)){'
    '    New-Item -ItemType Directory -Force -Path $p | Out-Null'
    '  }'
    '}'
    ''
    'function WriteUtf8NoBom([string]$path, [string]$content){'
    '  $dir = Split-Path -Parent $path'
    '  if($dir){ EnsureDir $dir }'
    '  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)'
    '  [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)'
    '}'
    ''
    'function ReadUtf8Raw([string]$path){'
    '  if(!(Test-Path -LiteralPath $path)){ return $null }'
    '  return Get-Content -LiteralPath $path -Raw'
    '}'
    ''
    'function BackupFile([string]$path){'
    '  if(!(Test-Path -LiteralPath $path)){ return $null }'
    '  EnsureDir "tools/_patch_backup"'
    '  $ts = Get-Date -Format "yyyyMMdd-HHmmss"'
    '  $safe = ($path -replace ''[\\/:*?"<>|]'',''_'')'
    '  $dst = "tools/_patch_backup/$ts-$safe"'
    '  Copy-Item -Force -LiteralPath $path $dst'
    '  return $dst'
    '}'
    ''
    'function NewReport([string]$name){'
    '  EnsureDir "reports"'
    '  $ts = Get-Date -Format "yyyyMMdd-HHmmss"'
    '  return "reports/$ts-$name.md"'
    '}'
    ''
    'function FindFirstFileLike([string]$root, [string]$endsWith){'
    '  if(!(Test-Path -LiteralPath $root)){ return $null }'
    '  $target = $endsWith.ToLower()'
    '  $f = Get-ChildItem -Path $root -Recurse -File -ErrorAction SilentlyContinue |'
    '    Where-Object { $_.FullName.Replace(''\'',''/'').ToLower().EndsWith($target) } |'
    '    Select-Object -First 1'
    '  if($f){ return $f.FullName }'
    '  return $null'
    '}'
    ''
    'function AssertFile([string]$path, [string]$msg){'
    '  if(!(Test-Path -LiteralPath $path)){ throw $msg }'
    '}'
    ''
    'function AssertNotNull($v, [string]$msg){'
    '  if($null -eq $v){ throw $msg }'
    '  if($v -is [string] -and [string]::IsNullOrWhiteSpace($v)){ throw $msg }'
    '}'
  )

  WriteUtf8NoBom $bootPath ($bootLines -join "`n")

  $log += "## PATCH — tools/_bootstrap.ps1"
  $log += ("Arquivo: {0}" -f $bootPath)
  $log += ("Backup : {0}" -f ($(if($bkBoot){$bkBoot}else{"(novo)"})))
  $log += "- OK: bootstrap criado (funções comuns para todos os tijolos)."
  $log += ""

  # -------------------------
  # PATCH 2) tools/_tijolo-template.ps1
  # -------------------------
  $tplPath = "tools/_tijolo-template.ps1"
  $bkTpl = BackupFile $tplPath

  $tplLines = @(
    '$ErrorActionPreference = "Stop"'
    'Set-StrictMode -Version Latest'
    ''
    '# Carrega funções comuns: EnsureDir / WriteUtf8NoBom / BackupFile / NewReport / FindFirstFileLike / AssertNotNull'
    '. "$PSScriptRoot/_bootstrap.ps1"'
    ''
    '$rep = NewReport "eco-STEP-NN-NOME"'
    '$log = @()'
    '$log += "# ECO — STEP NN — NOME"'
    '$log += ""'
    '$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))'
    '$log += ("PWD : {0}" -f (Get-Location).Path)'
    '$log += ""'
    ''
    'try {'
    '  # DIAG'
    '  $log += "## DIAG"'
    '  $log += ("Node: {0}" -f (node -v))'
    '  $log += ("Npm : {0}" -f (npm -v))'
    '  $log += ""'
    ''
    '  # PATCH'
    '  # - sempre BackupFile antes de editar'
    '  # - sempre Test-Path + AssertNotNull antes de Replace/Insert'
    ''
    '  # VERIFY (opcional)'
    '  # npm run lint'
    '  # npm run dev'
    ''
    '  WriteUtf8NoBom $rep ($log -join "`n")'
    '  Write-Host ("✅ OK. Report -> {0}" -f $rep) -ForegroundColor Green'
    '} catch {'
    '  try { WriteUtf8NoBom $rep ($log -join "`n") } catch {}'
    '  throw'
    '}'
  )

  WriteUtf8NoBom $tplPath ($tplLines -join "`n")

  $log += "## PATCH — tools/_tijolo-template.ps1"
  $log += ("Arquivo: {0}" -f $tplPath)
  $log += ("Backup : {0}" -f ($(if($bkTpl){$bkTpl}else{"(novo)"})))
  $log += "- OK: template criado (comece todo novo step por aqui)."
  $log += ""

  # -------------------------
  # PATCH 3) docs rápido
  # -------------------------
  $docPath = "tools/TIJOLOS.md"
  $bkDoc = BackupFile $docPath

  $doc = @(
    '# Tijolos PowerShell — Regras de Ouro'
    ''
    '## 1) Sempre rode o arquivo .ps1'
    '- Gere o .ps1 e execute: `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\seu-script.ps1`'
    '- **Nunca** cole blocos internos no prompt.'
    ''
    '## 2) Se o prompt virar `>>`, pare'
    '- `>>` = bloco aberto. Feche o bloco (ou CTRL+C) antes de qualquer coisa.'
    ''
    '## 3) Funções comuns ficam no bootstrap'
    '- Todo tijolo deve começar com: `. "$PSScriptRoot/_bootstrap.ps1"`'
    ''
    '## 4) Antes de Replace/Insert'
    '- Garanta `Test-Path` + `AssertNotNull $raw "..."`
    ''
    '## 5) Here-strings (anti-bomba)'
    '- Se o wrapper usa `$code = @'' ... ''@`, não use `@'' ... ''@` dentro.'
    '- Prefira `@(...) -join "`n"` para gerar conteúdo.'
    ''
  ) -join "`n"

  WriteUtf8NoBom $docPath $doc

  $log += "## PATCH — tools/TIJOLOS.md"
  $log += ("Arquivo: {0}" -f $docPath)
  $log += ("Backup : {0}" -f ($(if($bkDoc){$bkDoc}else{"(novo)"})))
  $log += "- OK: doc criado."
  $log += ""

  WriteUtf8NoBom $rep ($log -join "`n")
  Write-Host ("✅ STEP 49 aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
  Write-Host "VERIFY:" -ForegroundColor Yellow
  Write-Host "1) dir tools\_bootstrap.ps1" -ForegroundColor Yellow
  Write-Host "2) dir tools\_tijolo-template.ps1" -ForegroundColor Yellow
  Write-Host "3) Abra tools\TIJOLOS.md" -ForegroundColor Yellow

} catch {
  try { WriteUtf8NoBom $rep ($log -join "`n") } catch {}
  throw
}