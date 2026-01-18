param([switch]$OpenReport)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function NowStamp(){ (Get-Date).ToString("yyyyMMdd-HHmmss") }

# tenta carregar bootstrap (dentro de script $PSScriptRoot funciona)
$bootstrap = Join-Path $PSScriptRoot "_bootstrap.ps1"
if (Test-Path -LiteralPath $bootstrap) { . $bootstrap }

# fallback mínimo (caso bootstrap não exista)
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

function PatchPointsRoute([string]$file, [ref]$log){
  if(!(Test-Path -LiteralPath $file)){
    $log.Value += ("[MISS] " + $file + "`n")
    return
  }

  $raw = Get-Content -LiteralPath $file -Raw

  # só mexe se realmente usa prisma
  if($raw -notmatch '\bprisma\b'){
    $log.Value += ("[SKIP] " + $file + " (no prisma usage)`n")
    return
  }

  # já tem import?
  if($raw -match '(?m)^\s*import\s*\{\s*prisma\s*\}\s*from\s*["'']@/lib/prisma["'']\s*;\s*$'){
    $log.Value += ("[SKIP] " + $file + " (prisma import already present)`n")
    return
  }

  $bk = BackupFile $file "tools\_patch_backup\eco-step-162"

  $lines = $raw -split "(`r`n|`n|`r)"
  $insertAt = 0

  # se já existe import de next/server, coloca logo abaixo dele
  for($i=0; $i -lt $lines.Length; $i++){
    if($lines[$i] -match '^\s*import\s+.*from\s+["'']next/server["'']\s*;'){
      $insertAt = $i + 1
      break
    }
    if($lines[$i] -match '^\s*import\s'){
      $insertAt = $i + 1
      break
    }
  }

  $importLine = 'import { prisma } from "@/lib/prisma";'
  $newLines = @()
  for($i=0; $i -lt $lines.Length; $i++){
    $newLines += $lines[$i]
    if($i -eq ($insertAt - 1)){
      $newLines += $importLine
    }
  }

  $new = ($newLines -join "`n")

  WriteUtf8NoBom $file $new
  $log.Value += ("[OK]   " + $file + " (added prisma import)`n")
  if($bk){ $log.Value += ("       backup: " + $bk + "`n") }
}

function RunCmd([string]$label, [scriptblock]$sb, [int]$maxLines, [ref]$out){
  $out.Value += ("### " + $label + "`n~~~`n")
  try {
    $res = (& $sb 2>&1 | Out-String)
    if($maxLines -gt 0){
      $ls = $res -split "(`r`n|`n|`r)"
      if($ls.Count -gt $maxLines){
        $res = (($ls | Select-Object -First $maxLines) -join "`n") + "`n... (truncado)"
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
EnsureDir "tools\_patch_backup\eco-step-162"

$stamp = NowStamp
$reportPath = Join-Path "reports" ("eco-step-162-fix-prisma-import-" + $stamp + ".md")

$patchLog = ""
$verify = ""

PatchPointsRoute "src\app\api\eco\points\route.ts" ([ref]$patchLog)

RunCmd "npm run build" { npm run build } 520 ([ref]$verify)

$r = @()
$r += ("# eco-step-162 — fix prisma import (points route) — " + $stamp)
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