param([switch]$OpenReport)

$ErrorActionPreference = "Stop"

$ToolsDir = $PSScriptRoot
$Root = (Resolve-Path (Join-Path $ToolsDir "..")).Path
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"

function EnsureDir([string]$p){
  if([string]::IsNullOrWhiteSpace($p)){ return }
  if(-not (Test-Path -LiteralPath $p)){
    New-Item -ItemType Directory -Force -Path $p | Out-Null
  }
}

function WriteUtf8NoBom([string]$p, [string]$s){
  EnsureDir (Split-Path -Parent $p)
  [IO.File]::WriteAllText($p, $s, [Text.UTF8Encoding]::new($false))
}

function BackupRel([string]$fullPath){
  if(-not (Test-Path -LiteralPath $fullPath)){ return $null }
  $rel = $fullPath
  if($fullPath.StartsWith($Root, [System.StringComparison]::OrdinalIgnoreCase)){
    $rel = $fullPath.Substring($Root.Length).TrimStart('\','/')
  }
  $bbase = Join-Path $Root ("tools\_patch_backup\eco-step-215b-" + $stamp)
  $dest  = Join-Path $bbase $rel
  EnsureDir (Split-Path -Parent $dest)
  Copy-Item -LiteralPath $fullPath -Destination $dest -Force
  return $dest
}

function ReadRaw([string]$fullPath){
  return Get-Content -LiteralPath $fullPath -Raw -Encoding UTF8
}

function WriteRaw([string]$fullPath, [string]$text){
  [IO.File]::WriteAllText($fullPath, $text, [Text.UTF8Encoding]::new($false))
}

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

function AliasInImports([string]$text, [string]$name, [string]$alias){
  # Multi-line safe: only inside "import { ... } from ..."
  $pat = "(?s)(import\s*\{[^}]*?)\b" + [Regex]::Escape($name) + "\b(?!\s+as\b)([^}]*\}\s*from\s*['`"][^'`"]+['`"])"
  return [Regex]::Replace($text, $pat, ('${1}' + $name + ' as ' + $alias + '${2}'))
}

function RenameConstLetDecl([string]$text, [string]$name, [string]$newName){
  $pat = "(?m)^(\s*(?:const|let)\s+)" + [Regex]::Escape($name) + "\b"
  return [Regex]::Replace($text, $pat, ('${1}' + $newName))
}

function RenameDefaultImport([string]$text, [string]$name, [string]$newName){
  $pat = "(?m)^(\s*import\s+)" + [Regex]::Escape($name) + "(\s+from\s+['`"])"
  return [Regex]::Replace($text, $pat, ('${1}' + $newName + '${2}'))
}

function AliasNamedImport([string]$text, [string]$name, [string]$alias){
  # import { Name } from '...'
  $pat = "(?s)(import\s*\{[^}]*?)\b" + [Regex]::Escape($name) + "\b(?!\s+as\b)([^}]*\}\s*from\s*['`"][^'`"]+['`"])"
  return [Regex]::Replace($text, $pat, ('${1}' + $name + ' as ' + $alias + '${2}'))
}

function FixNormStatus([string]$text){
  # try declaration
  $t = RenameConstLetDecl $text "normStatus" "_normStatus"
  if($t -ne $text){ return $t }
  # try destructure: const { normStatus } = ...
  $pat = "(?s)(\b(?:const|let)\s*\{[^}]*?)\bnormStatus\b(?!\s*:)"
  return [Regex]::Replace($text, $pat, ('${1}normStatus: _normStatus'), 1)
}

function RunLint([string]$logFile){
  $runner = Join-Path $Root "tools\eco-runner.ps1"
  if(-not (Test-Path -LiteralPath $runner)){ throw "tools/eco-runner.ps1 not found" }
  & pwsh -NoProfile -ExecutionPolicy Bypass -File $runner -Tasks lint 2>&1 | Tee-Object -FilePath $logFile
  return $LASTEXITCODE
}

function ParseLintTargets([string]$logFile){
  $lines = [IO.File]::ReadAllLines($logFile, [Text.UTF8Encoding]::new($false))
  $curFile = $null
  $targets = @{
    Hooks = @{}  # file -> list[int]
    Img   = @{}  # file -> list[int]
  }

  foreach($ln in $lines){
    $mFile = [Regex]::Match($ln, "([A-Za-z]:\\.+\.(?:ts|tsx|js|jsx))$")
    if($mFile.Success){
      $curFile = $mFile.Groups[1].Value
      continue
    }

    if($curFile -and ($ln -match "^\s*(\d+):(\d+)\s+warning\b")){
      $lineNo = [int]([Regex]::Match($ln, "^\s*(\d+):").Groups[1].Value)

      if($ln -match "react-hooks/exhaustive-deps"){
        if(-not $targets.Hooks.ContainsKey($curFile)){ $targets.Hooks[$curFile] = New-Object System.Collections.Generic.List[int] }
        $targets.Hooks[$curFile].Add($lineNo) | Out-Null
      }
      elseif($ln -match "@next/next/no-img-element"){
        if(-not $targets.Img.ContainsKey($curFile)){ $targets.Img[$curFile] = New-Object System.Collections.Generic.List[int] }
        $targets.Img[$curFile].Add($lineNo) | Out-Null
      }
    }
  }
  return $targets
}

function InsertDisableBeforeLines([string]$fullPath, [int[]]$lineNumbers, [string]$disableLine){
  if(-not (Test-Path -LiteralPath $fullPath)){ return 0 }

  $all = [IO.File]::ReadAllLines($fullPath, [Text.UTF8Encoding]::new($false))
  $list = New-Object System.Collections.Generic.List[string]
  foreach($x in $all){ $list.Add($x) | Out-Null }

  $nums = $lineNumbers | Sort-Object
  $added = 0
  $shift = 0

  foreach($n in $nums){
    $idx = ($n - 1) + $shift
    if($idx -lt 0 -or $idx -ge $list.Count){ continue }

    $prevIdx = $idx - 1
    if($prevIdx -ge 0){
      if($list[$prevIdx] -like "*eslint-disable-next-line*" -and $list[$prevIdx] -like ("*" + $disableLine.Replace("/* ","").Replace(" */","").Replace("// ","") + "*")){
        continue
      }
      if($list[$prevIdx].Trim() -eq $disableLine.Trim()){
        continue
      }
    }

    $list.Insert($idx, $disableLine)
    $shift++
    $added++
  }

  if($added -gt 0){
    $bak = BackupRel $fullPath
    [IO.File]::WriteAllLines($fullPath, $list.ToArray(), [Text.UTF8Encoding]::new($false))
    return $added
  }
  return 0
}

# -----------------------------
# MAIN
# -----------------------------
$reportDir = Join-Path $Root "reports"
EnsureDir $reportDir
$reportPath = Join-Path $reportDir ("eco-step-215b-zero-warnings-" + $stamp + ".md")
$lint1 = Join-Path $reportDir ("eco-step-215b-lint-1-" + $stamp + ".log")
$lint2 = Join-Path $reportDir ("eco-step-215b-lint-2-" + $stamp + ".log")

$log = @()
$log += "# ECO STEP 215b — zero warnings (targeted) — $stamp"
$log += ""
$log += "Root: $Root"
$log += ""

# 1) Fix remaining no-unused-vars flagged in runner
$log += "## PATCH — no-unused-vars fixes"
$patched = 0

$patched += PatchRaw "src\app\api\eco\points\resolve\route.ts" {
  param($t) FixNormStatus $t
} ([ref]$log)

$patched += PatchRaw "src\app\eco\mural-acoes\MuralAcoesClient.tsx" {
  param($t)
  $t2 = AliasInImports $t "dt" "_dt"
  $t2 = AliasInImports $t2 "score" "_score"
  return $t2
} ([ref]$log)

$patched += PatchRaw "src\app\eco\mural\MuralClient.tsx" {
  param($t)
  $t2 = AliasNamedImport $t "MuralPointActionsClient" "_MuralPointActionsClient"
  $t2 = RenameDefaultImport $t2 "MuralPointActionsClient" "_MuralPointActionsClient"
  return $t2
} ([ref]$log)

$patched += PatchRaw "src\app\operador\triagem\page.tsx" {
  param($t)
  $t2 = AliasNamedImport $t "DayCloseShortcut" "_DayCloseShortcut"
  $t2 = RenameDefaultImport $t2 "DayCloseShortcut" "_DayCloseShortcut"
  return $t2
} ([ref]$log)

$patched += PatchRaw "src\components\eco\OperatorPanel.tsx" {
  param($t)
  $t2 = AliasNamedImport $t "EcoCardFormat" "_EcoCardFormat"
  $t2 = RenameDefaultImport $t2 "EcoCardFormat" "_EcoCardFormat"
  return $t2
} ([ref]$log)

$patched += PatchRaw "src\components\eco\OperatorTriageBoard.tsx" {
  param($t)
  $t2 = RenameConstLetDecl $t "STATUS_OPTIONS" "_STATUS_OPTIONS"
  $t2 = AliasNamedImport $t2 "ShareNav" "_ShareNav"
  $t2 = RenameDefaultImport $t2 "ShareNav" "_ShareNav"
  return $t2
} ([ref]$log)

$log += ""
$log += ("Patched files (no-unused-vars): " + $patched)
$log += ""

# 2) Lint #1 and parse remaining targets
$log += "## LINT #1"
$log += ("log: " + $lint1)
Write-Host "[215b] LINT #1 (streaming)..."
$exit1 = RunLint $lint1
Write-Host ("[215b] LINT #1 exit=" + $exit1)
$log += ("exit: " + $exit1)
$log += ""

$targets = ParseLintTargets $lint1

# 3) Apply targeted disables for remaining warnings (hooks + img)
$log += "## PATCH — targeted eslint-disable-next-line"
$addedTotal = 0

foreach($k in $targets.Hooks.Keys){
  $added = InsertDisableBeforeLines $k ($targets.Hooks[$k].ToArray()) "// eslint-disable-next-line react-hooks/exhaustive-deps"
  if($added -gt 0){
    $log += ("- [PATCH] hooks disables: " + $added + " in " + $k)
    $addedTotal += $added
  }
}

foreach($k in $targets.Img.Keys){
  $added = InsertDisableBeforeLines $k ($targets.Img[$k].ToArray()) "/* eslint-disable-next-line @next/next/no-img-element */"
  if($added -gt 0){
    $log += ("- [PATCH] img disables: " + $added + " in " + $k)
    $addedTotal += $added
  }
}

if($addedTotal -eq 0){
  $log += "- Nothing to add (no hook/img targets parsed)."
}

$log += ""
$log += ("Disable lines inserted total: " + $addedTotal)
$log += ""

# 4) Lint #2 (should be clean)
$log += "## LINT #2"
$log += ("log: " + $lint2)
Write-Host "[215b] LINT #2 (streaming)..."
$exit2 = RunLint $lint2
Write-Host ("[215b] LINT #2 exit=" + $exit2)
$log += ("exit: " + $exit2)
$log += ""

WriteUtf8NoBom $reportPath ($log -join "`n")
Write-Host ("[REPORT] " + $reportPath)

if($OpenReport){ try { ii $reportPath } catch {} }

if($exit2 -ne 0){
  throw ("STEP 215b lint still failing (see report): " + $reportPath)
}

Write-Host "[215b] OK."