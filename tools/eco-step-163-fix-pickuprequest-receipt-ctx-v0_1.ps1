param([switch]$OpenReport)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function NowStamp(){ (Get-Date).ToString("yyyyMMdd-HHmmss") }

# bootstrap preferencial (dentro do script $PSScriptRoot funciona)
$bootstrap = Join-Path $PSScriptRoot "_bootstrap.ps1"
if(Test-Path -LiteralPath $bootstrap){ . $bootstrap }

# fallbacks mínimos (caso bootstrap não esteja carregado)
if (-not (Get-Command EnsureDir -ErrorAction SilentlyContinue)) {
  function EnsureDir([string]$p){
    if([string]::IsNullOrWhiteSpace($p)){ return }
    if(!(Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null }
  }
}
if (-not (Get-Command WriteUtf8NoBom -ErrorAction SilentlyContinue)) {
  function WriteUtf8NoBom([string]$path, [string]$content){
    [IO.File]::WriteAllText($path, $content, [Text.UTF8Encoding]::new($false))
  }
}
if (-not (Get-Command BackupFile -ErrorAction SilentlyContinue)) {
  function BackupFile([string]$file, [string]$bakRoot){
    if(!(Test-Path -LiteralPath $file)){ return $null }
    EnsureDir $bakRoot
    $safe = ($file -replace "[:\\\/\[\]\s]", "_")
    $dst = Join-Path $bakRoot ((NowStamp) + "-" + $safe)
    Copy-Item -LiteralPath $file -Destination $dst -Force
    return $dst
  }
}

function UpdateFile([string]$file, [scriptblock]$transform, [string]$label, [ref]$log){
  if(!(Test-Path -LiteralPath $file)){
    $log.Value += ("[MISS] " + $file + " (" + $label + ")`n")
    return
  }
  $raw = Get-Content -LiteralPath $file -Raw
  $new = & $transform $raw
  if($null -eq $new -or $new -eq $raw){
    $log.Value += ("[SKIP] " + $file + " (" + $label + ": no change)`n")
    return
  }
  $bk = BackupFile $file "tools\_patch_backup\eco-step-163"
  WriteUtf8NoBom $file $new
  $log.Value += ("[OK]   " + $file + " (" + $label + ")`n")
  if($bk){ $log.Value += ("       backup: " + $bk + "`n") }
}

function RunCmd([string]$label, [scriptblock]$sb, [int]$maxLines, [ref]$out){
  $out.Value += ("### " + $label + "`n~~~`n")
  try {
    $res = (& $sb 2>&1 | Out-String)
    if($maxLines -gt 0){
      $lines = $res -split "(`r`n|`n|`r)"
      if($lines.Count -gt $maxLines){
        $res = (($lines | Select-Object -First $maxLines) -join "`n") + "`n... (truncado)"
      }
    }
    $out.Value += ($res.TrimEnd() + "`n")
  } catch {
    $out.Value += ("[ERR] " + $_.Exception.Message + "`n")
  }
  $out.Value += "~~~`n`n"
}

if(!(Test-Path -LiteralPath "package.json")){ throw "Rode na raiz do repo (onde tem package.json)." }

EnsureDir "reports"
EnsureDir "tools\_patch_backup\eco-step-163"

$stamp = NowStamp
$reportPath = Join-Path "reports" ("eco-step-163-fix-pickuprequest-receipt-ctx-" + $stamp + ".md")

$patchLog = ""
$verify = ""

$target = "src\app\api\pickup-requests\[id]\receipt\route.ts"

UpdateFile $target {
  param($raw)
  $s = $raw

  # 1) garantir que não tentamos redefinir const id: trocar destructure para idParam
  $s = [regex]::Replace(
    $s,
    'const\s*\{\s*id\s*\}\s*=\s*await\s+params\s*;',
    'const { id: idParam } = await params;'
  )

  # 2) remover a linha que usa ctx (causa do erro)
  $s = [regex]::Replace(
    $s,
    '(?m)^\s*const\s+id\s*=\s*String\(\s*\(ctx\s+as\s+any\)\?\.\s*params\?\.\s*id\s*\?\?\s*""\s*\)\s*;\s*\r?\n',
    ''
  )

  # 3) se não houver uma linha que normalize o id para string, inserir logo após o destructure
  if($s -notmatch '(?m)^\s*const\s+id\s*=\s*String\(\s*idParam\s*\?\?\s*""\s*\)\s*;\s*$'){
    $s2 = [regex]::Replace(
      $s,
      '(?m)^(?<indent>\s*)const\s*\{\s*id\s*:\s*idParam\s*\}\s*=\s*await\s+params\s*;\s*$',
      '${indent}const { id: idParam } = await params;' + "`n" + '${indent}const id = String(idParam ?? "");'
    )
    $s = $s2
  end

  # 4) limpar qualquer sobra de "ctx" solto (segurança)
  $s = [regex]::Replace($s, '(?m)^\s*ctx\s*;\s*\r?\n', '')
  return $s
} "remove ctx usage; normalize id via params" ([ref]$patchLog)

RunCmd "npm run build" { npm run build } 520 ([ref]$verify)

$r = @()
$r += ("# eco-step-163 — fix pickup-requests/[id]/receipt ctx — " + $stamp)
$r += ""
$r += "## Patch log"
$r += "~~~"
$r += $patchLog.TrimEnd()
$r += "~~~"
$r += ""
$r += "## VERIFY"
$r += $verify

WriteUtf8NoBom $reportPath ($r -join "`n")
Write-Host ("[REPORT] " + $reportPath)
if($OpenReport){ try { Start-Process $reportPath | Out-Null } catch {} }

Write-Host ""
Write-Host "[NEXT] Se o build passar, rode o smoke:"
Write-Host "  pwsh -NoProfile -ExecutionPolicy Bypass -File tools\eco-step-148b-verify-smoke-autodev-v0_1.ps1 -OpenReport"