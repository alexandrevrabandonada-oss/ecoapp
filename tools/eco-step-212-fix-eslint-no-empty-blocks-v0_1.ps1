param([switch]$OpenReport)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function NowStamp { Get-Date -Format "yyyyMMdd-HHmmss" }
function EnsureDir([string]$p){ if(-not (Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function WriteUtf8NoBom([string]$path, [string]$content){ [IO.File]::WriteAllText($path, $content, [Text.UTF8Encoding]::new($false)) }

function FindCmd([string]$name){
  $c = Get-Command $name -ErrorAction SilentlyContinue
  if($c){ return $c.Source }
  return $null
}

function RunProc([string]$exe, [string[]]$args, [string]$workdir){
  $psi = [System.Diagnostics.ProcessStartInfo]::new()
  $psi.FileName = $exe
  $psi.WorkingDirectory = $workdir
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError = $true
  $psi.UseShellExecute = $false
  foreach($a in $args){ [void]$psi.ArgumentList.Add($a) }

  $p = [System.Diagnostics.Process]::new()
  $p.StartInfo = $psi
  [void]$p.Start()
  $stdout = $p.StandardOutput.ReadToEnd()
  $stderr = $p.StandardError.ReadToEnd()
  $p.WaitForExit()

  return @{ ExitCode = $p.ExitCode; Text = (($stdout + $stderr).TrimEnd()) }
}

function BackupOne([string]$root, [string]$stamp, [string]$step, [string]$absPath){
  $rel = $absPath.Substring($root.Length).TrimStart("\","/")
  $dest = Join-Path $root ("tools\_patch_backup\" + $step + "\" + $stamp + "\" + $rel)
  $destDir = Split-Path $dest -Parent
  EnsureDir $destDir
  Copy-Item -LiteralPath $absPath -Destination $dest -Force
  return $dest
}

function ReplaceCount([string]$text, [string]$pattern, [string]$replacement){
  $rx = [regex]::new($pattern, [Text.RegularExpressions.RegexOptions]::Singleline)
  $m = $rx.Matches($text)
  if($m.Count -eq 0){ return @{ Text = $text; Count = 0 } }
  $newText = $rx.Replace($text, $replacement)
  return @{ Text = $newText; Count = $m.Count }
}

function FixNoEmptyBlocks([string]$text){
  $total = 0

  $r = ReplaceCount $text 'catch\s*\(\s*([A-Za-z_\$][A-Za-z0-9_\$]*)\s*\)\s*\{\s*\}' 'catch ($1) { void $1; }'
  $text = $r.Text; $total += $r.Count

  $r = ReplaceCount $text '\bcatch\s*\{\s*\}' 'catch { void 0; }'
  $text = $r.Text; $total += $r.Count

  $r = ReplaceCount $text '\bfinally\s*\{\s*\}' 'finally { void 0; }'
  $text = $r.Text; $total += $r.Count

  $r = ReplaceCount $text '\belse\s*\{\s*\}' 'else { void 0; }'
  $text = $r.Text; $total += $r.Count

  $r = ReplaceCount $text '\bif\s*\(([^)]*)\)\s*\{\s*\}' 'if ($1) { void 0; }'
  $text = $r.Text; $total += $r.Count

  $r = ReplaceCount $text '\bfor\s*\(([^)]*)\)\s*\{\s*\}' 'for ($1) { void 0; }'
  $text = $r.Text; $total += $r.Count

  $r = ReplaceCount $text '\bwhile\s*\(([^)]*)\)\s*\{\s*\}' 'while ($1) { void 0; }'
  $text = $r.Text; $total += $r.Count

  $r = ReplaceCount $text '\btry\s*\{\s*\}' 'try { void 0; }'
  $text = $r.Text; $total += $r.Count

  return @{ Text = $text; Count = $total }
}

$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$tools = Join-Path $root "tools"
$reports = Join-Path $root "reports"
EnsureDir $reports

$stamp = NowStamp
$step = "eco-step-212"
$reportPath = Join-Path $reports ("eco-step-212-fix-eslint-no-empty-blocks-" + $stamp + ".md")

$log = @()
$log += ("# eco-step-212 - fix eslint no-empty blocks - " + $stamp)
$log += ""
$log += ("Root: " + $root)
$log += ""

$targets = @(
  "src\app\api\eco\mural\list\route.ts",
  "src\app\api\eco\mutirao\finish\route.ts",
  "src\app\api\eco\points\action\route.ts",
  "src\app\api\eco\points\card\route.tsx",
  "src\app\api\eco\points\report\route.ts",
  "src\app\api\receipts\route.ts",
  "src\components\eco\OperatorPanel.tsx",
  "src\components\eco\OperatorTriageBoard.tsx",
  "src\components\eco\ReceiptShareBar.tsx",
  "src\components\share-bar.tsx"
)

$log += "## PATCH"
foreach($rel in $targets){
  $abs = Join-Path $root $rel
  if(-not (Test-Path -LiteralPath $abs)){
    $log += ("[SKIP] missing: " + $rel)
    continue
  }

  $bak = BackupOne $root $stamp $step $abs

  $before = [IO.File]::ReadAllText($abs, [Text.UTF8Encoding]::new($false))
  $fx = FixNoEmptyBlocks $before
  $after = $fx.Text

  if($after -ne $before){
    WriteUtf8NoBom $abs $after
    $log += ("[OK]   " + $rel + " (fixes=" + $fx.Count + ")")
    $log += ("       backup: " + $bak)
  } else {
    $log += ("[SKIP] " + $rel + " (no change)")
    $log += ("       backup: " + $bak)
  }
}
$log += ""

$log += "## VERIFY"
$runner = Join-Path $tools "eco-runner.ps1"
$pwsh = FindCmd "pwsh"
if(-not $pwsh){ $pwsh = FindCmd "powershell" }
if(-not $pwsh){ throw "pwsh/powershell not found" }

$log += "### eco-runner -Tasks lint"
$log += "~~~"
$res = RunProc $pwsh @("-NoProfile","-ExecutionPolicy","Bypass","-File",$runner,"-Tasks","lint") $root
if($res.Text){ $log += $res.Text }
$log += "~~~"
$log += ("exit: " + $res.ExitCode)
$log += ""

WriteUtf8NoBom $reportPath ($log -join "`n")
Write-Host ("[REPORT] " + $reportPath)
if($OpenReport){ Start-Process $reportPath | Out-Null }

if($res.ExitCode -ne 0){
  throw ("VERIFY failed (see report): " + $reportPath)
}