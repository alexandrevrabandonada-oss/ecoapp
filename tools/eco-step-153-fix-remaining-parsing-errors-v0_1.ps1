param([switch]$OpenReport)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function NowStamp(){ (Get-Date).ToString("yyyyMMdd-HHmmss") }
function EnsureDir([string]$p){
  if([string]::IsNullOrWhiteSpace($p)){ return }
  if(!(Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null }
}
function WriteUtf8NoBom([string]$path, [string]$content){
  [IO.File]::WriteAllText($path, $content, [Text.UTF8Encoding]::new($false))
}
function BackupFile([string]$file, [string]$bakRoot){
  if(!(Test-Path -LiteralPath $file)){ return $null }
  EnsureDir $bakRoot
  $safe = ($file -replace "[:\\\/\[\]\s]", "_")
  $dst = Join-Path $bakRoot ((NowStamp) + "-" + $safe)
  Copy-Item -LiteralPath $file -Destination $dst -Force
  return $dst
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
  $bak = BackupFile $file "tools\_patch_backup\eco-step-153"
  WriteUtf8NoBom $file $new
  $log.Value += ("[OK]   " + $file + " (" + $label + ")`n")
  if($bak){ $log.Value += ("       backup: " + $bak + "`n") }
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

if(!(Test-Path -LiteralPath "package.json")){
  throw "Rode na raiz do repo (onde tem package.json)."
}

EnsureDir "reports"
EnsureDir "tools\_patch_backup\eco-step-153"

$stamp = NowStamp
$reportPath = Join-Path "reports" ("eco-step-153-fix-remaining-parsing-errors-" + $stamp + ".md")
$patchLog = ""
$verify = ""

# ------------------------------------------------------------
# 1) mutirao/finish: call resolvePoint(..., pointId: null, ...) -> resolvePoint(..., pointId, ...)
# ------------------------------------------------------------
UpdateFile "src\app\api\eco\mutirao\finish\route.ts" {
  param($raw)
  return [regex]::Replace(
    $raw,
    'resolvePoint\(\s*pm\s*,\s*pointId\s*:\s*null\s*,',
    'resolvePoint(pm, pointId,'
  )
} "fix resolvePoint arg (pointId: null)" ([ref]$patchLog)

# ------------------------------------------------------------
# 2) pedidos/page.tsx: links sem aspas virando regex
#    const fecharHref = id ? /pedidos/fechar/ : null;
#    const reciboHref = receiptCode ? /recibo/ : null;
# ------------------------------------------------------------
UpdateFile "src\app\pedidos\page.tsx" {
  param($raw)
  $raw2 = $raw

  $raw2 = [regex]::Replace(
    $raw2,
    'const\s+fecharHref\s*=\s*id\s*\?\s*\/pedidos\/fechar\/\s*:\s*null\s*;',
    'const fecharHref = id ? ("/pedidos/fechar/" + encodeURIComponent(String(id))) : null;'
  )

  $raw2 = [regex]::Replace(
    $raw2,
    'const\s+reciboHref\s*=\s*receiptCode\s*\?\s*\/recibo\/\s*:\s*null\s*;',
    'const reciboHref = receiptCode ? ("/recibo/" + encodeURIComponent(String(receiptCode))) : null;'
  )

  return $raw2
} "fix href strings (pedidos)" ([ref]$patchLog)

# ------------------------------------------------------------
# 3) recibo-client.tsx: waLink quebrado + garantir "use client" 1a linha
# ------------------------------------------------------------
UpdateFile "src\app\recibo\[code]\recibo-client.tsx" {
  param($raw)

  # garante "use client" na primeira linha
  $raw = $raw -replace "^\uFEFF",""
  $rawNo = [regex]::Replace($raw, '(?m)^\s*"use client";\s*\r?\n', '')
  $rawNo = $rawNo.TrimStart()
  $out = '"use client";' + "`r`n" + $rawNo

  # reescreve function waLink() { ... }
  $replacement = @(
    'function waLink() {',
    '  const link = (typeof window !== "undefined" && window.location) ? window.location.href : "";',
    '  const text = "Recibo ECO: " + link;',
    '  return "https://wa.me/?text=" + encodeURIComponent(text);',
    '}'
  ) -join "`n"

  $out = [regex]::Replace(
    $out,
    '(?s)function\s+waLink\s*\(\)\s*\{.*?\n\s*\}',
    $replacement
  )

  return $out
} "fix waLink + use client (recibo-client)" ([ref]$patchLog)

# ------------------------------------------------------------
# VERIFY
# ------------------------------------------------------------
RunCmd "npm run build" { npm run build } 380 ([ref]$verify)

# REPORT
$r = @()
$r += ("# eco-step-153 — fix remaining parsing errors — " + $stamp)
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