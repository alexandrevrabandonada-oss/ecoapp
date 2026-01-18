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
  $bk = BackupFile $file "tools\_patch_backup\eco-step-165"
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
EnsureDir "tools\_patch_backup\eco-step-165"

$stamp = NowStamp
$reportPath = Join-Path "reports" ("eco-step-165-fix-pickuprequest-receipt-nested-create-" + $stamp + ".md")

$patchLog = ""
$verify = ""

$target = "src\app\api\pickup-requests\[id]\receipt\route.ts"

UpdateFile $target {
  param($raw)
  $s = $raw

  $isNested = ($s -match 'prisma\.\s*pickupRequest\.\s*(update|upsert|create)\s*\(') -and ($s -match '(?s)receipt\s*:\s*\{\s*create\s*:\s*\{')
  $isDirect = ($s -match 'prisma\.\s*receipt\.\s*create\s*\(')

  if($isNested){
    # remove request connect line (our previous patch)
    $s = [regex]::Replace($s, '(?m)^\s*request\s*:\s*\{\s*connect\s*:\s*\{\s*id\s*\}\s*\}\s*,\s*\r?\n', '')
    $s = [regex]::Replace($s, '(?m)^\s*pickupRequest\s*:\s*\{\s*connect\s*:\s*\{\s*id\s*\}\s*\}\s*,\s*\r?\n', '')

    # remove any requestId scalar line (legacy)
    $s = [regex]::Replace($s, '(?m)^\s*requestId\s*:\s*[^,\r\n]+,\s*\r?\n', '')

    return $s
  }

  if($isDirect){
    # If it's direct create, keep request connect (do nothing here)
    return $s
  }

  # Unknown shape: still remove the exact request connect line if present (safe)
  $s = [regex]::Replace($s, '(?m)^\s*request\s*:\s*\{\s*connect\s*:\s*\{\s*id\s*\}\s*\}\s*,\s*\r?\n', '')
  $s = [regex]::Replace($s, '(?m)^\s*requestId\s*:\s*[^,\r\n]+,\s*\r?\n', '')
  return $s
} "remove request/connect for nested create" ([ref]$patchLog)

RunCmd "npm run build" { npm run build } 520 ([ref]$verify)

$r = @()
$r += ("# eco-step-165 — fix pickup-requests/[id]/receipt nested create — " + $stamp)
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