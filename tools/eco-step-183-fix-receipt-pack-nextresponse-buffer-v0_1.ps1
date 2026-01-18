param([switch]$OpenReport)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function NowStamp(){ (Get-Date).ToString("yyyyMMdd-HHmmss") }
function EnsureDir([string]$p){ if(!(Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function WriteUtf8NoBom([string]$path, [string]$text){ [IO.File]::WriteAllText($path, $text, [Text.UTF8Encoding]::new($false)) }
function BackupFile([string]$file, [string]$bakDir){
  EnsureDir $bakDir
  $safe = ($file -replace "[:\\\/\[\]\s]", "_")
  $dst = Join-Path $bakDir ((NowStamp) + "-" + $safe)
  Copy-Item -LiteralPath $file -Destination $dst -Force
  return $dst
}

if(!(Test-Path -LiteralPath "package.json")){ throw "Rode na raiz do repo (onde tem package.json)." }

$repoRoot  = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
$targetRel = "src\app\api\share\receipt-pack\route.ts"
$target    = Join-Path $repoRoot $targetRel
if(!(Test-Path -LiteralPath $target)){ throw ("Nao achei: " + $targetRel) }

$raw = Get-Content -LiteralPath $target -Raw

# PATCH: return new NextResponse(out, { ... })  ->  return new NextResponse(new Uint8Array(out), { ... })
$rx  = 'return\s+new\s+NextResponse\(\s*out\s*,'
$rep = 'return new NextResponse(new Uint8Array(out),'

$before = ([regex]::Matches($raw, $rx)).Count
$raw2   = [regex]::Replace($raw, $rx, $rep)
$after  = ([regex]::Matches($raw2, $rx)).Count

$stamp = NowStamp
EnsureDir (Join-Path $repoRoot "reports")
$bakDir = Join-Path $repoRoot ("tools\_patch_backup\eco-step-183\" + $stamp)
EnsureDir $bakDir

$reportPath = Join-Path $repoRoot ("reports\eco-step-183-fix-receipt-pack-nextresponse-buffer-" + $stamp + ".md")

if($raw2 -eq $raw){
  $patchLog = "[SKIP] nao achei o padrao: return new NextResponse(out,"
} else {
  $bak = BackupFile $target $bakDir
  WriteUtf8NoBom $target $raw2
  $patchLog = "[OK]  NextResponse body: out -> new Uint8Array(out). Backup: " + $bak
}

$r = @()
$r += ("# eco-step-183 — fix receipt-pack NextResponse(Buffer) — " + $stamp)
$r += ""
$r += "## DIAG"
$r += ("alvo: " + $targetRel)
$r += ("matches antes: " + $before)
$r += ""
$r += "## PATCH"
$r += $patchLog
$r += ""
$r += "## POS"
$r += ("matches depois: " + $after)
$r += ""
$r += "## VERIFY"
$r += "- npm run build"
$r += ""

WriteUtf8NoBom $reportPath ($r -join "`n")
Write-Host ("[REPORT] " + $reportPath)
if($OpenReport){ try{ Start-Process $reportPath | Out-Null } catch {} }

Write-Host ""
Write-Host "[NEXT] rode:"
Write-Host "  npm run build"