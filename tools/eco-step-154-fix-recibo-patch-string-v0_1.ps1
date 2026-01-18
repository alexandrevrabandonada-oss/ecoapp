param([switch]$OpenReport)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function NowStamp(){ (Get-Date).ToString("yyyyMMdd-HHmmss") }
function EnsureDir([string]$p){ if($p -and !(Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function WriteUtf8NoBom([string]$path, [string]$content){ [IO.File]::WriteAllText($path, $content, [Text.UTF8Encoding]::new($false)) }
function BackupFile([string]$file, [string]$bakRoot){
  if(!(Test-Path -LiteralPath $file)){ return $null }
  EnsureDir $bakRoot
  $safe = ($file -replace "[:\\\/\[\]\s]", "_")
  $dst = Join-Path $bakRoot ((NowStamp) + "-" + $safe)
  Copy-Item -LiteralPath $file -Destination $dst -Force
  return $dst
}

function UpdateFile([string]$file, [scriptblock]$transform){
  if(!(Test-Path -LiteralPath $file)){ throw "Arquivo nao encontrado: $file" }
  $raw = Get-Content -LiteralPath $file -Raw
  $new = & $transform $raw
  if($null -eq $new -or $new -eq $raw){ return @{ changed=$false; path=$file } }
  BackupFile $file "tools\_patch_backup\eco-step-154" | Out-Null
  WriteUtf8NoBom $file $new
  return @{ changed=$true; path=$file }
}

function RunCmd([string]$label, [scriptblock]$sb, [int]$maxLines){
  $out = @()
  $out += ("### " + $label)
  $out += "~~~"
  try {
    $res = (& $sb 2>&1 | Out-String)
    if($maxLines -gt 0){
      $lines = $res -split "(`r`n|`n|`r)"
      if($lines.Count -gt $maxLines){
        $res = (($lines | Select-Object -First $maxLines) -join "`n") + "`n... (truncado)"
      }
    }
    $out += $res.TrimEnd()
  } catch {
    $out += ("[ERR] " + $_.Exception.Message)
  }
  $out += "~~~"
  return ($out -join "`n")
}

if(!(Test-Path -LiteralPath "package.json")){ throw "Rode na raiz do repo (onde tem package.json)." }
EnsureDir "reports"
EnsureDir "tools\_patch_backup\eco-step-154"

$stamp = NowStamp
$reportPath = Join-Path "reports" ("eco-step-154-fix-recibo-patch-string-" + $stamp + ".md")

$target = "src\app\recibo\[code]\recibo-client.tsx"
$patchLog = @()

$resp = UpdateFile $target {
  param($raw)

  $raw2 = $raw

  # Caso exato do erro: json?.error ?? PATCH /api/receipts falhou ()
  $raw2 = [regex]::Replace(
    $raw2,
    'throw\s+new\s+Error\(\s*json\?\.\s*error\s*\?\?\s*PATCH\s+\/api\/receipts\s+falhou\s*\(\s*\)\s*\)\s*;?',
    'throw new Error(json?.error ?? "PATCH /api/receipts falhou");'
  )

  # Fallback: se houver "?? PATCH /api/receipts ..." sem aspas
  $raw2 = [regex]::Replace(
    $raw2,
    'json\?\.\s*error\s*\?\?\s*PATCH\s+\/api\/receipts\s+falhou\s*(\(\s*\))?',
    'json?.error ?? "PATCH /api/receipts falhou"'
  )

  return $raw2
}

if($resp.changed){ $patchLog += "[OK]   patched: $target" } else { $patchLog += "[SKIP] no change: $target" }

$verify = RunCmd "npm run build" { npm run build } 380

$r = @()
$r += ("# eco-step-154 — fix recibo PATCH string — " + $stamp)
$r += ""
$r += "## Patch log"
$r += "~~~"
$r += ($patchLog -join "`n")
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