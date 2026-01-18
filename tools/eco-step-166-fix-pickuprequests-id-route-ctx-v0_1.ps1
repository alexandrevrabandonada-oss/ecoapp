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
  $bk = BackupFile $file "tools\_patch_backup\eco-step-166"
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
EnsureDir "tools\_patch_backup\eco-step-166"

$stamp = NowStamp
$reportPath = Join-Path "reports" ("eco-step-166-fix-pickuprequests-id-route-ctx-" + $stamp + ".md")

$patchLog = ""
$verify = ""

$target = "src\app\api\pickup-requests\[id]\route.ts"

UpdateFile $target {
  param($raw)
  $s = $raw

  # 1) Se existir assinatura com ctx, troca para { params }: { params: Promise<{ id: string }> }
  $s = [regex]::Replace(
    $s,
    'export\s+async\s+function\s+(\w+)\s*\(\s*([^\),]+)\s*,\s*ctx\s*:\s*[^)\r\n]+\)',
    'export async function $1($2, { params }: { params: Promise<{ id: string }> })'
  )
  $s = [regex]::Replace(
    $s,
    'export\s+async\s+function\s+(\w+)\s*\(\s*([^\),]+)\s*,\s*ctx\s*\)',
    'export async function $1($2, { params }: { params: Promise<{ id: string }> })'
  )

  # 2) Troca a linha do id que usa ctx por params (Promise)
  $repl = '    const { id: idParam } = await params;' + "`n" +
          '    const id = String(idParam ?? "").trim();'

  # caso exato do erro
  $s = [regex]::Replace(
    $s,
    '(?m)^\s*const\s+id\s*=\s*String\(\s*ctx\?\.\s*params\?\.\s*id\s*\?\?\s*(?:''|\"\")\s*\)\.trim\(\)\s*;\s*$',
    $repl
  )

  # variante com (ctx as any)
  $s = [regex]::Replace(
    $s,
    '(?m)^\s*const\s+id\s*=\s*String\(\s*\(\s*ctx\s+as\s+any\s*\)\?\.\s*params\?\.\s*id\s*\?\?\s*(?:''|\"\")\s*\)\.trim\(\)\s*;\s*$',
    $repl
  )

  return $s
} "remove ctx; use params Promise for id" ([ref]$patchLog)

RunCmd "npm run build" { npm run build } 520 ([ref]$verify)

$r = @()
$r += ("# eco-step-166 — fix pickup-requests/[id] ctx — " + $stamp)
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