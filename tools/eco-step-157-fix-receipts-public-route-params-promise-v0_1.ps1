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
  $bak = BackupFile $file "tools\_patch_backup\eco-step-157"
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

function FixHandlerWithParam([string]$s, [string]$method, [string]$paramName){
  # Ajusta assinatura: (req: Request, { params }: { params: { code: string } }) -> (req: NextRequest, { params }: { params: Promise<{ code: string }> })
  $s = [regex]::Replace(
    $s,
    ('export\s+async\s+function\s+' + $method + '\s*\(\s*req\s*:\s*Request\s*,\s*(ctx|context)\s*:\s*\{\s*params\s*:\s*\{\s*' + $paramName + '\s*:\s*string\s*;?\s*\}\s*;?\s*\}\s*\)'),
    ('export async function ' + $method + '(req: NextRequest, { params }: { params: Promise<{ ' + $paramName + ': string }> })')
  )
  $s = [regex]::Replace(
    $s,
    ('export\s+async\s+function\s+' + $method + '\s*\(\s*req\s*:\s*Request\s*,\s*\{\s*params\s*\}\s*:\s*\{\s*params\s*:\s*\{\s*' + $paramName + '\s*:\s*string\s*;?\s*\}\s*\}\s*\)'),
    ('export async function ' + $method + '(req: NextRequest, { params }: { params: Promise<{ ' + $paramName + ': string }> })')
  )
  $s = [regex]::Replace(
    $s,
    ('export\s+async\s+function\s+' + $method + '\s*\(\s*req\s*:\s*NextRequest\s*,\s*\{\s*params\s*\}\s*:\s*\{\s*params\s*:\s*\{\s*' + $paramName + '\s*:\s*string\s*;?\s*\}\s*\}\s*\)'),
    ('export async function ' + $method + '(req: NextRequest, { params }: { params: Promise<{ ' + $paramName + ': string }> })')
  )

  # injeta const { code } = await params; no topo do body (se ainda não existir)
  $sigRx = '(?s)(export\s+async\s+function\s+' + $method + '\s*\([^\)]*\)\s*\{\s*)'
  $awaitLine = 'const\s*\{\s*' + $paramName + '\s*\}\s*=\s*await\s+params\s*;'
  if(($s -match $sigRx) -and ($s -notmatch ('export\s+async\s+function\s+' + $method + '[\s\S]*?' + $awaitLine))){
    $s = [regex]::Replace($s, $sigRx, ('$1' + "  const { " + $paramName + " } = await params;`n"))
  }

  # remove declarações antigas (const code = ctx.params.code / params.code)
  $s = [regex]::Replace($s, '(?m)^\s*(const|let)\s+' + $paramName + '\s*=\s*(ctx|context)\.params\.' + $paramName + '\s*;\s*\r?\n', '')
  $s = [regex]::Replace($s, '(?m)^\s*(const|let)\s+' + $paramName + '\s*=\s*params\.' + $paramName + '\s*;\s*\r?\n', '')

  # troca usos para "code"
  $s = [regex]::Replace($s, '\b(ctx|context)\.params\.' + $paramName + '\b', $paramName)
  $s = [regex]::Replace($s, '\bparams\.' + $paramName + '\b', $paramName)

  return $s
}

if(!(Test-Path -LiteralPath "package.json")){
  throw "Rode na raiz do repo (onde tem package.json)."
}

EnsureDir "reports"
EnsureDir "tools\_patch_backup\eco-step-157"

$stamp = NowStamp
$reportPath = Join-Path "reports" ("eco-step-157-fix-receipts-public-route-params-promise-" + $stamp + ".md")

$patchLog = ""
$verify = ""

$target = "src\app\api\receipts\[code]\public\route.ts"
if(!(Test-Path -LiteralPath $target)){
  $alt = "src\app\api\receipts\[code]\public\route.tsx"
  if(Test-Path -LiteralPath $alt){ $target = $alt } else { throw "Arquivo alvo nao encontrado: $target" }
}

UpdateFile $target {
  param($raw)
  $s = $raw
  $s = EnsureNextRequestImport $s
  $s = FixHandlerWithParam $s "GET" "code"
  $s = FixHandlerWithParam $s "PATCH" "code"
  $s = FixHandlerWithParam $s "POST" "code"
  $s = FixHandlerWithParam $s "DELETE" "code"
  return $s
} "Next 16 handler signatures + params Promise (receipts/[code]/public)" ([ref]$patchLog)

RunCmd "npm run build" { npm run build } 520 ([ref]$verify)

$r = @()
$r += ("# eco-step-157 — fix receipts/[code]/public params Promise — " + $stamp)
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