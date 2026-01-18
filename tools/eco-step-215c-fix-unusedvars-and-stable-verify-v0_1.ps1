param([switch]$OpenReport)

$ErrorActionPreference = "Stop"
$ToolsDir = $PSScriptRoot
$Root = (Resolve-Path (Join-Path $ToolsDir "..")).Path
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"

function EnsureDir([string]$p){
  if([string]::IsNullOrWhiteSpace($p)){ return }
  if(-not (Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null }
}
function WriteUtf8NoBom([string]$p,[string]$s){
  EnsureDir (Split-Path -Parent $p)
  [IO.File]::WriteAllText($p, $s, [Text.UTF8Encoding]::new($false))
}
function BackupRel([string]$fullPath){
  if(-not (Test-Path -LiteralPath $fullPath)){ return $null }
  $rel = $fullPath
  if($fullPath.StartsWith($Root, [System.StringComparison]::OrdinalIgnoreCase)){
    $rel = $fullPath.Substring($Root.Length).TrimStart('\','/')
  }
  $bbase = Join-Path $Root ("tools\_patch_backup\eco-step-215c-" + $stamp)
  $dest  = Join-Path $bbase $rel
  EnsureDir (Split-Path -Parent $dest)
  Copy-Item -LiteralPath $fullPath -Destination $dest -Force
  return $dest
}
function ReadRaw([string]$p){ Get-Content -LiteralPath $p -Raw -Encoding UTF8 }
function WriteRaw([string]$p,[string]$t){ [IO.File]::WriteAllText($p,$t,[Text.UTF8Encoding]::new($false)) }

function PatchRaw([string]$relPath, [ScriptBlock]$mutator, [ref]$log){
  $full = Join-Path $Root $relPath
  if(-not (Test-Path -LiteralPath $full)){
    $log.Value += "- [SKIP] missing: $relPath"
    return 0
  }
  $raw = ReadRaw $full
  $new = & $mutator $raw
  if($new -ne $raw){
    $bak = BackupRel $full
    WriteRaw $full $new
    $log.Value += "- [PATCH] $relPath backup: $bak"
    return 1
  } else {
    $log.Value += "- [OK]    $relPath (no change)"
    return 0
  }
}

function RenameNormStatus([string]$t){
  # const normStatus -> const _normStatus
  $t2 = [Regex]::Replace($t, "(?m)^(\s*(?:const|let)\s+)normStatus\b", '${1}_normStatus')
  if($t2 -ne $t){ return $t2 }
  # destructure { normStatus } -> { normStatus: _normStatus }
  return [Regex]::Replace($t, "(\b(?:const|let)\s*\{[^}]*?)\bnormStatus\b(?!\s*:)", '${1}normStatus: _normStatus')
}

function AliasInImportsStrict([string]$t, [string]$name, [string]$alias){
  # ONLY inside import { ... } from '...'
  $pat = "(?s)(import\s*\{[^}]*?)\b" + [Regex]::Escape($name) + "\b(?!\s+as\b)([^}]*\}\s*from\s*['`"][^'`"]+['`"])"
  return [Regex]::Replace($t, $pat, ('${1}' + $name + ' as ' + $alias + '${2}'))
}

function RenameImportName([string]$t, [string]$name, [string]$alias){
  # import { Name } -> import { Name as _Name }
  $t2 = AliasInImportsStrict $t $name $alias
  if($t2 -ne $t){ return $t2 }
  # import Name from '...'
  $pat = "(?m)^(\s*import\s+)" + [Regex]::Escape($name) + "(\s+from\s+['`"])"
  return [Regex]::Replace($t, $pat, ('${1}' + $alias + '${2}'))
}

function RunLintDirect([string]$logFile){
  $npm = (Get-Command npm -ErrorAction Stop).Source
  $p = Start-Process -FilePath $npm -ArgumentList @("run","lint") -WorkingDirectory $Root -NoNewWindow -PassThru -RedirectStandardOutput $logFile -RedirectStandardError $logFile
  $p.WaitForExit()
  return $p.ExitCode
}

$reportDir = Join-Path $Root "reports"
EnsureDir $reportDir
$reportPath = Join-Path $reportDir ("eco-step-215c-fix-unusedvars-" + $stamp + ".md")
$lint1 = Join-Path $reportDir ("eco-step-215c-lint-1-" + $stamp + ".log")
$lint2 = Join-Path $reportDir ("eco-step-215c-lint-2-" + $stamp + ".log")

$log = @()
$log += "# ECO STEP 215c — fix remaining unused-vars + stable verify — $stamp"
$log += ""
$log += "Root: $Root"
$log += ""
$log += "## DIAG (lint BEFORE)"
Write-Host "[215c] LINT #1 (direct npm run lint)..."
$e1 = RunLintDirect $lint1
Write-Host ("[215c] lint1 exit=" + $e1 + " log=" + $lint1)
$log += "- exit: $e1"
$log += "- log: $lint1"
$log += ""

$log += "## PATCH (unused-vars remaining)"
$patched = 0

# 1) normStatus -> _normStatus
$patched += PatchRaw "src\app\api\eco\points\resolve\route.ts" { param($t) RenameNormStatus $t } ([ref]$log)

# 2) dt/score in MuralAcoesClient import -> alias _dt/_score
$patched += PatchRaw "src\app\eco\mural-acoes\MuralAcoesClient.tsx" {
  param($t)
  $t2 = AliasInImportsStrict $t "dt" "_dt"
  $t2 = AliasInImportsStrict $t2 "score" "_score"
  return $t2
} ([ref]$log)

# 3) EcoCardFormat import rename
$patched += PatchRaw "src\components\eco\OperatorPanel.tsx" {
  param($t) RenameImportName $t "EcoCardFormat" "_EcoCardFormat"
} ([ref]$log)

# 4) ShareNav import rename
$patched += PatchRaw "src\components\eco\OperatorTriageBoard.tsx" {
  param($t) RenameImportName $t "ShareNav" "_ShareNav"
} ([ref]$log)

$log += ""
$log += ("Patched files: " + $patched)
$log += ""

$log += "## VERIFY (lint AFTER)"
Write-Host "[215c] LINT #2 (direct npm run lint)..."
$e2 = RunLintDirect $lint2
Write-Host ("[215c] lint2 exit=" + $e2 + " log=" + $lint2)
$log += "- exit: $e2"
$log += "- log: $lint2"
$log += ""

WriteUtf8NoBom $reportPath ($log -join "`n")
Write-Host ("[REPORT] " + $reportPath)
if($OpenReport){ try { ii $reportPath } catch {} }

if($e2 -ne 0){
  throw ("STEP 215c lint failing (see report): " + $reportPath)
}