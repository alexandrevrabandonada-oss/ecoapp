$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

# bootstrap
$boot = Join-Path $root "tools\_bootstrap.ps1"
if (Test-Path $boot) { . $boot }
else {
  function EnsureDir([string]$p){ if(!(Test-Path $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
  function WriteUtf8NoBom([string]$p,[string]$s){ [IO.File]::WriteAllText($p,$s,[Text.UTF8Encoding]::new($false)) }
  function BackupFile([string]$file,[string]$dir){ EnsureDir $dir; $name = (Split-Path $file -Leaf); $dst = Join-Path $dir ($name + ".bak"); Copy-Item -Force $file $dst; return $dst }
}

param([switch]$OpenReport)
$stamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
$nl = "`n"

$target = Join-Path $root "src\app\api\pickup-requests\triage\route.ts"
if (!(Test-Path $target)) { throw ("Nao achei: " + $target) }

$raw = Get-Content -Raw -LiteralPath $target
$beforeShare = ([regex]::Matches($raw, "\.shareCode\b")).Count
$beforeSel   = ([regex]::Matches($raw, "\bshareCode\s*:\s*true")).Count

# 1) prisma select: shareCode -> code (somente dentro do receipt.select)
$patternSel = "(receipt\s*:\s*{\s*select\s*:\s*{\s*)([^}]*?)\bshareCode\b"
$raw2 = [regex]::Replace($raw, $patternSel, '${1}${2}code', [System.Text.RegularExpressions.RegexOptions]::Singleline)

# 2) acessos: .shareCode -> .code
$raw2 = $raw2 -replace "\.shareCode\b", ".code"

$afterShare = ([regex]::Matches($raw2, "\.shareCode\b")).Count
$afterSel   = ([regex]::Matches($raw2, "\bshareCode\s*:\s*true")).Count

# backup + write
$backupDir = Join-Path $root ("tools\_patch_backup\eco-step-176\" + $stamp)
$bak = BackupFile $target $backupDir
WriteUtf8NoBom $target $raw2

# report
EnsureDir (Join-Path $root "reports")
$reportPath = Join-Path $root ("reports\eco-step-176-fix-pickuprequests-triage-sharecode-" + $stamp + ".md")
$r = @()
$r += "# eco-step-176 — fix pickup-requests/triage Receipt.select shareCode -> code — $stamp"
$r += ""
$r += "## DIAG"
$r += "- alvo: src/app/api/pickup-requests/triage/route.ts"
$r += "- antes: occurrences `.shareCode` = $beforeShare; `shareCode: true` = $beforeSel"
$r += ""
$r += "## PATCH"
$r += "- dentro de `receipt: { select: { ... } }`: trocou `shareCode` por `code`"
$r += "- trocou acessos `.shareCode` -> `.code` (só nesse arquivo)"
$r += "- backup: $bak"
$r += ""
$r += "## POS"
$r += "- depois: occurrences `.shareCode` = $afterShare; `shareCode: true` = $afterSel"
$r += ""
$r += "## VERIFY"
$r += "Rode:"
$r += "- npm run build"
$r += "- (se passar) dir tools\eco-step-148*   # pra achar o smoke certinho"

WriteUtf8NoBom $reportPath ($r -join $nl)
Write-Host ("[OK] patched: " + $target)
Write-Host ("[REPORT] " + $reportPath)
if ($OpenReport) { try { Start-Process $reportPath | Out-Null } catch {} }