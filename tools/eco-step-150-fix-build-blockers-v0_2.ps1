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
  $bak = BackupFile $file "tools\_patch_backup\eco-step-150"
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
EnsureDir "tools\_patch_backup\eco-step-150"

$stamp = NowStamp
$reportPath = Join-Path "reports" ("eco-step-150-fix-build-blockers-" + $stamp + ".md")

$patchLog = ""
$verify = ""

# 1) MuralAcoesClient: "use client" na PRIMEIRA LINHA
UpdateFile "src\app\eco\mural-acoes\MuralAcoesClient.tsx" {
  param($raw)
  $raw = $raw -replace "^\uFEFF",""
  $noDirective = [regex]::Replace($raw, '(?m)^\s*"use client";\s*\r?\n', '')
  $noDirective = $noDirective.TrimStart()
  return '"use client";' + "`r`n" + $noDirective
} "use client na 1a linha (hard)" ([ref]$patchLog)

# 2) mutirao/finish: remover token invalido , "pointId",
UpdateFile "src\app\api\eco\mutirao\finish\route.ts" {
  param($raw)
  return [regex]::Replace($raw, ',\s*"pointId"\s*,', ', pointId: null,')
} 'remove token "pointId",' ([ref]$patchLog)

# 3) confirm/replicar/support: / \n xxx \n /i -> /xxx/i
$rxBroken = '\/\s*\r?\n\s*(confirm|replicar|support)\s*\r?\n\s*\/i'
$rpFixed  = '/$1/i'

UpdateFile "src\app\api\eco\points\confirm\route.ts" {
  param($raw)
  return [regex]::Replace($raw, $using:rxBroken, $using:rpFixed)
} "fix regex literal quebrada (confirm)" ([ref]$patchLog)

UpdateFile "src\app\api\eco\points\replicar\route.ts" {
  param($raw)
  return [regex]::Replace($raw, $using:rxBroken, $using:rpFixed)
} "fix regex literal quebrada (replicar)" ([ref]$patchLog)

UpdateFile "src\app\api\eco\points\support\route.ts" {
  param($raw)
  return [regex]::Replace($raw, $using:rxBroken, $using:rpFixed)
} "fix regex literal quebrada (support)" ([ref]$patchLog)

# VERIFY
RunCmd "npm run build" { npm run build } 300 ([ref]$verify)

$eslint = "node_modules\.bin\eslint.cmd"
if(Test-Path -LiteralPath $eslint){
  RunCmd "eslint (scopado ECO) src/app/eco + src/app/api/eco + src/lib/eco" {
    & $eslint "src/app/eco" "src/app/api/eco" "src/lib/eco" 2>&1
  } 240 ([ref]$verify)
} else {
  $verify += "### eslint (scopado)`n~~~`nSKIP: node_modules\\.bin\\eslint.cmd nao encontrado`n~~~`n`n"
}

# REPORT
$r = @()
$r += ("# eco-step-150 — fix build blockers — " + $stamp)
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