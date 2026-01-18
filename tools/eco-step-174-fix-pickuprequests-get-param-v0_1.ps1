param([switch]$OpenReport)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function NowStamp(){ (Get-Date).ToString("yyyyMMdd-HHmmss") }
function EnsureDir([string]$p){ if(!(Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function WriteUtf8NoBom([string]$path, [string]$text){ [IO.File]::WriteAllText($path, $text, [Text.UTF8Encoding]::new($false)) }
function BackupFile([string]$file, [string]$bakRoot){
  if(!(Test-Path -LiteralPath $file)){ return $null }
  EnsureDir $bakRoot
  $safe = ($file -replace "[:\\\/\[\]\s]", "_")
  $dst = Join-Path $bakRoot ((NowStamp) + "-" + $safe)
  Copy-Item -LiteralPath $file -Destination $dst -Force
  return $dst
}

if(!(Test-Path -LiteralPath "package.json")){ throw "Rode na raiz do repo (onde tem package.json)." }

$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
EnsureDir (Join-Path $repoRoot "reports")
EnsureDir (Join-Path $repoRoot "tools\_patch_backup\eco-step-174")

$stamp = NowStamp
$reportPath = Join-Path $repoRoot ("reports\eco-step-174-fix-pickuprequests-get-param-" + $stamp + ".md")

$targetRel = "src\app\api\pickup-requests\route.ts"
$target = Join-Path $repoRoot $targetRel
if(!(Test-Path -LiteralPath $target)){ throw ("missing: " + $targetRel) }

$raw = Get-Content -LiteralPath $target -Raw

# DIAG
$diag = @()
$diag += ("# eco-step-174 — fix GET(req: Request) — " + $stamp)
$diag += ""
$diag += "## DIAG"
$diag += ("alvo: " + $targetRel)

$patchLog = ""

# PATCH: export async function GET() {  -> export async function GET(req: Request) {
$rxEmpty = "(?s)export\s+async\s+function\s+GET\s*\(\s*\)\s*\{"
$m = [regex]::Match($raw, $rxEmpty)
if($m.Success){
  $bk = BackupFile $target (Join-Path $repoRoot "tools\_patch_backup\eco-step-174")
  $raw2 = [regex]::Replace($raw, $rxEmpty, "export async function GET(req: Request) {")
  WriteUtf8NoBom $target $raw2
  $patchLog += "[OK]   GET() -> GET(req: Request)`n"
  if($bk){ $patchLog += ("       backup: " + $bk + "`n") }
} else {
  $patchLog += "[SKIP] nao encontrei GET() vazio (talvez ja tenha parametro)`n"
}

$diag += "## PATCH LOG"
$diag += "~~~"
$diag += $patchLog.TrimEnd()
$diag += "~~~"
$diag += ""

# VERIFY
$verify = @()
$verify += "## VERIFY"
$verify += ""
$verify += "Rode:"
$verify += "- npm run build"
$verify += "- (se passar) tente localizar o smoke com: dir tools\eco-step-148b* -ErrorAction SilentlyContinue"
$verify += ""

WriteUtf8NoBom $reportPath (($diag + $verify) -join "`n")
Write-Host ("[REPORT] " + $reportPath)
if($OpenReport){ try { Start-Process $reportPath | Out-Null } catch {} }

Write-Host ""
Write-Host "[NEXT] rode em LINHAS SEPARADAS:"
Write-Host "  npm run build"
Write-Host "  dir tools\eco-step-148b*  (pra achar o arquivo do smoke certinho)"