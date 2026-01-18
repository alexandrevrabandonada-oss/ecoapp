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

$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
$apiRoot  = Join-Path $repoRoot "src\app\api"
if(!(Test-Path -LiteralPath $apiRoot)){ throw "Nao achei src/app/api" }

$stamp    = NowStamp
$bakDir   = Join-Path $repoRoot ("tools\_patch_backup\eco-step-181\" + $stamp)
$repDir   = Join-Path $repoRoot "reports"
EnsureDir $bakDir
EnsureDir $repDir

$reportPath = Join-Path $repDir ("eco-step-181-fix-api-any-fieldnames-includes-global-" + $stamp + ".md")

# pega route.ts / route.tsx
$files = Get-ChildItem -LiteralPath $apiRoot -Recurse -File | Where-Object { $_.Name -match '^route\.tsx?$' }

# substitui: <var>.fieldNames.includes("x")  =>  (<var>.fieldNames as any).includes("x")
$rxDq = '\b([A-Za-z0-9_]+)\.fieldNames\.includes\("([^"]+)"\)'
$rpDq = '($1.fieldNames as any).includes("$2")'

# também cobre single quotes: includes('x')
$rxSq = "\b([A-Za-z0-9_]+)\.fieldNames\.includes\('([^']+)'\)"
$rpSq = '($1.fieldNames as any).includes("$2")'

$changed = 0
$totalBefore = 0
$totalAfter  = 0
$patchLog = @()

foreach($f in $files){
  $raw = Get-Content -LiteralPath $f.FullName -Raw

  $b1 = ([regex]::Matches($raw, $rxDq)).Count
  $b2 = ([regex]::Matches($raw, $rxSq)).Count
  $before = $b1 + $b2
  if($before -le 0){ continue }

  $totalBefore += $before

  $new = [regex]::Replace($raw, $rxDq, $rpDq)
  $new = [regex]::Replace($new, $rxSq, $rpSq)

  $a1 = ([regex]::Matches($new, $rxDq)).Count
  $a2 = ([regex]::Matches($new, $rxSq)).Count
  $after = $a1 + $a2
  $totalAfter += $after

  if($new -ne $raw){
    $bak = BackupFile $f.FullName $bakDir
    WriteUtf8NoBom $f.FullName $new
    $changed++
    $patchLog += ("[OK] " + ($f.FullName.Substring($repoRoot.Length+1)) + " (before " + $before + " -> after " + $after + ") backup: " + $bak)
  }
}

$r = @()
$r += ("# eco-step-181 — fix api fieldNames.includes global — " + $stamp)
$r += ""
$r += "## DIAG"
$r += ("files route.* encontrados: " + $files.Count)
$r += ("matches antes (somando arquivos): " + $totalBefore)
$r += ""
$r += "## PATCH"
if($patchLog.Count -eq 0){
  $r += "[SKIP] nenhum .fieldNames.includes(...) encontrado."
} else {
  $r += ("arquivos alterados: " + $changed)
  $r += "~~~"
  $r += ($patchLog -join "`n")
  $r += "~~~"
}
$r += ""
$r += "## POS"
$r += ("matches depois (somando arquivos): " + $totalAfter)
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