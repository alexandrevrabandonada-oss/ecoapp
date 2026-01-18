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
  $bk = BackupFile $file "tools\_patch_backup\eco-step-161"
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
EnsureDir "tools\_patch_backup\eco-step-161"

$stamp = NowStamp
$reportPath = Join-Path "reports" ("eco-step-161-fix-nextresponse-import-" + $stamp + ".md")

$patchLog = ""
$verify = ""

$target = "src\app\api\eco\points\route.ts"

UpdateFile $target {
  param($raw)
  $s = $raw

  $usesNextResponse = ($s -match '\bNextResponse\b')
  if(-not $usesNextResponse){ return $s }

  $hasImportDouble = ($s -match '(?m)^\s*import\s*\{\s*[^}]*\s*\}\s*from\s*"next/server"\s*;')
  $hasImportSingle = ($s -match "(?m)^\s*import\s*\{\s*[^}]*\s*\}\s*from\s*'next/server'\s*;")

  if($hasImportDouble -or $hasImportSingle){
    $rx = $(if($hasImportDouble){
      '(?m)^\s*import\s*\{\s*([^}]+)\s*\}\s*from\s*"next/server"\s*;\s*$'
    } else {
      "(?m)^\s*import\s*\{\s*([^}]+)\s*\}\s*from\s*'next/server'\s*;\s*$"
    })

    $quote = $(if($hasImportDouble){ '"' } else { "'" })

    $s = [regex]::Replace($s, $rx, {
      param($m)
      $inside = $m.Groups[1].Value
      $parts = $inside.Split(",") | ForEach-Object { $_.Trim() } | Where-Object { $_ }
      if($parts -notcontains "NextResponse"){ $parts = @("NextResponse") + $parts }

      # se o arquivo usa NextRequest e não está no import, adiciona também
      if(($s -match '\bNextRequest\b') -and ($parts -notcontains "NextRequest")){
        $parts = @("NextRequest") + $parts
      }

      $newInside = ($parts -join ", ")
      return ('import { ' + $newInside + ' } from ' + $quote + 'next/server' + $quote + ';')
    })
    return $s
  }

  # sem import de next/server: insere no topo após bloco de imports (se existir)
  $ins = 'import { NextResponse } from "next/server";' + "`n"
  $m2 = [regex]::Match($s, '(?s)\A((?:\s*import[^\n]*\r?\n)+)')
  if($m2.Success){
    return ($m2.Groups[1].Value + $ins + $s.Substring($m2.Groups[1].Length))
  }
  return ($ins + $s)
} "add NextResponse import (and NextRequest if used)" ([ref]$patchLog)

RunCmd "npm run build" { npm run build } 520 ([ref]$verify)

$r = @()
$r += ("# eco-step-161 — fix NextResponse import — " + $stamp)
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