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
  $bak = BackupFile $file "tools\_patch_backup\eco-step-156"
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

function EnsureNextRequestImport([string]$s){
  # garante NextRequest no import { ... } from "next/server";
  return [regex]::Replace($s, 'import\s*\{\s*([^}]+)\s*\}\s*from\s*["'']next\/server["''];', {
    param($m)
    $inside = $m.Groups[1].Value
    $parts = $inside.Split(",") | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    if($parts -notcontains "NextRequest"){ $parts = @("NextRequest") + $parts }
    $newInside = ($parts -join ", ")
    return 'import { ' + $newInside + ' } from "next/server";'
  })
}

function FixHandler([string]$s, [string]$method){
  # 1) assinatura (Request + params objeto) -> (NextRequest + params Promise)
  $s = [regex]::Replace(
    $s,
    ('export\s+async\s+function\s+' + $method + '\s*\(\s*req\s*:\s*Request\s*,\s*(ctx|context)\s*:\s*\{\s*params\s*:\s*\{\s*id\s*:\s*string\s*;?\s*\}\s*;?\s*\}\s*\)'),
    ('export async function ' + $method + '(req: NextRequest, { params }: { params: Promise<{ id: string }> })')
  )
  $s = [regex]::Replace(
    $s,
    ('export\s+async\s+function\s+' + $method + '\s*\(\s*req\s*:\s*Request\s*,\s*\{\s*params\s*\}\s*:\s*\{\s*params\s*:\s*\{\s*id\s*:\s*string\s*;?\s*\}\s*\}\s*\)'),
    ('export async function ' + $method + '(req: NextRequest, { params }: { params: Promise<{ id: string }> })')
  )
  $s = [regex]::Replace(
    $s,
    ('export\s+async\s+function\s+' + $method + '\s*\(\s*req\s*:\s*NextRequest\s*,\s*\{\s*params\s*\}\s*:\s*\{\s*params\s*:\s*\{\s*id\s*:\s*string\s*;?\s*\}\s*\}\s*\)'),
    ('export async function ' + $method + '(req: NextRequest, { params }: { params: Promise<{ id: string }> })')
  )

  # 2) injeta const { id } = await params; no topo do body, se o handler existir e ainda não tiver
  $sigRx = '(?s)(export\s+async\s+function\s+' + $method + '\s*\([^\)]*\)\s*\{\s*)'
  if(($s -match $sigRx) -and ($s -notmatch ('export\s+async\s+function\s+' + $method + '[\s\S]*?const\s*\{\s*id\s*\}\s*=\s*await\s+params\s*;'))){
    $s = [regex]::Replace($s, $sigRx, ('$1' + "  const { id } = await params;`n"))
  }

  # 3) remove declarações antigas de id (ctx.params.id / params.id)
  $s = [regex]::Replace($s, '(?m)^\s*(const|let)\s+id\s*=\s*(ctx|context)\.params\.id\s*;\s*\r?\n', '')
  $s = [regex]::Replace($s, '(?m)^\s*(const|let)\s+id\s*=\s*params\.id\s*;\s*\r?\n', '')

  # 4) troca usos para "id"
  $s = [regex]::Replace($s, '\b(ctx|context)\.params\.id\b', 'id')
  $s = [regex]::Replace($s, '\bparams\.id\b', 'id')

  return $s
}

if(!(Test-Path -LiteralPath "package.json")){
  throw "Rode na raiz do repo (onde tem package.json)."
}

EnsureDir "reports"
EnsureDir "tools\_patch_backup\eco-step-156"

$stamp = NowStamp
$reportPath = Join-Path "reports" ("eco-step-156-fix-pickuprequests-id-route-params-promise-" + $stamp + ".md")

$patchLog = ""
$verify = ""

$target = "src\app\api\pickup-requests\[id]\route.ts"
if(!(Test-Path -LiteralPath $target)){
  throw "Arquivo alvo nao encontrado: $target"
}

UpdateFile $target {
  param($raw)
  $s = $raw
  $s = EnsureNextRequestImport $s

  # Corrige handlers que existirem nesse arquivo
  $s = FixHandler $s "GET"
  $s = FixHandler $s "PATCH"
  $s = FixHandler $s "DELETE"
  $s = FixHandler $s "POST"

  return $s
} "Next 16 handler signatures (GET/PATCH/DELETE/POST) + params Promise" ([ref]$patchLog)

RunCmd "npm run build" { npm run build } 460 ([ref]$verify)

$r = @()
$r += ("# eco-step-156 — fix pickup-requests/[id] params Promise — " + $stamp)
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