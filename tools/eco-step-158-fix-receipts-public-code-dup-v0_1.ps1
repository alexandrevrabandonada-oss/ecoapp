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
  $bak = BackupFile $file "tools\_patch_backup\eco-step-158"
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
EnsureDir "tools\_patch_backup\eco-step-158"

$stamp = NowStamp
$reportPath = Join-Path "reports" ("eco-step-158-fix-receipts-public-code-dup-" + $stamp + ".md")

$patchLog = ""
$verify = ""

$target = "src\app\api\receipts\[code]\public\route.ts"
if(!(Test-Path -LiteralPath $target)){
  throw "Arquivo alvo nao encontrado: $target"
}

UpdateFile $target {
  param($raw)
  $s = $raw

  # 1) evitar duplicidade: const { code } = await params;  -> const { code: codeParam } = await params;
  $s = [regex]::Replace(
    $s,
    'const\s*\{\s*code\s*\}\s*=\s*await\s+params\s*;',
    'const { code: codeParam } = await params;'
  )

  # 2) linha quebrada atual: const code = params?.code ? String(code) : '';
  #    vira: const code = String(codeParam || "");
  $s = [regex]::Replace(
    $s,
    'const\s+code\s*=\s*params\?\.\s*code\s*\?\s*String\(\s*code\s*\)\s*:\s*[''"]{0,1}\s*[''"]{0,1}\s*;',
    'const code = String(codeParam || "");'
  )

  # fallback (se estiver sem params?.code mas ainda errado)
  $s = [regex]::Replace(
    $s,
    'const\s+code\s*=\s*String\(\s*code\s*\)\s*;\s*',
    'const code = String(codeParam || "");'
  )

  return $s
} "rename destructure -> codeParam; normalize code string" ([ref]$patchLog)

RunCmd "npm run build" { npm run build } 520 ([ref]$verify)

$r = @()
$r += ("# eco-step-158 — fix receipts public code dup — " + $stamp)
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