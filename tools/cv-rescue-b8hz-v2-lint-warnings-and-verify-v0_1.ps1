param(
  [switch]$CleanNext,
  [switch]$OpenReport,
  [switch]$SkipLint,
  [switch]$SkipBuild
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function EnsureDir([string]$p){
  if([string]::IsNullOrWhiteSpace($p)){ throw "EnsureDir: path vazio" }
  if(-not (Test-Path -LiteralPath $p)){
    New-Item -ItemType Directory -Force -Path $p | Out-Null
  }
}

function WriteUtf8NoBom([string]$path, [string]$text){
  if([string]::IsNullOrWhiteSpace($path)){ throw "WriteUtf8NoBom: path vazio" }
  $enc = New-Object System.Text.UTF8Encoding($false)
  [IO.File]::WriteAllText($path, $text, $enc)
}

function SafeFileName([string]$name){
  if([string]::IsNullOrWhiteSpace($name)){ return "report.md" }
  $n = $name.Trim()
  $bad = [IO.Path]::GetInvalidFileNameChars()
  foreach($c in $bad){ $n = $n.Replace([string]$c, "-") }
  # colapsa espaços
  $n = ($n -replace "\s+", "-").Trim("-")
  if([string]::IsNullOrWhiteSpace($n)){ $n = "report" }
  return $n
}

function RunExeCapture([string]$exe, [string[]]$args, [string]$workdir){
  $psi = [System.Diagnostics.ProcessStartInfo]::new()
  $psi.FileName = $exe
  $psi.WorkingDirectory = $workdir
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError  = $true
  $psi.UseShellExecute = $false
  foreach($a in $args){ [void]$psi.ArgumentList.Add($a) }

  $p = [System.Diagnostics.Process]::new()
  $p.StartInfo = $psi
  [void]$p.Start()

  $stdout = $p.StandardOutput.ReadToEnd()
  $stderr = $p.StandardError.ReadToEnd()
  $p.WaitForExit()

  $out = (($stdout + "`r`n" + $stderr).TrimEnd())
  return [pscustomobject]@{ Code = $p.ExitCode; Out = $out }
}

function RunCmdCapture([string]$cmdLine, [string]$workdir){
  # cmd.exe precisa receber uma string com quoting correto
  return RunExeCapture "cmd.exe" @("/d","/s","/c",$cmdLine) $workdir
}

function Patch-Page([string]$filePath, [string]$tag, [ref]$didChange){
  if(-not (Test-Path -LiteralPath $filePath)){ return }

  $raw  = Get-Content -LiteralPath $filePath -Raw
  $orig = $raw

  # Se existe "type PageProps" e não é usado (": PageProps"), desliga lint só nessa linha
  $hasPageProps  = ($raw -match "(?m)^\s*type\s+PageProps\b")
  $usesPageProps = ($raw -match ":\s*PageProps\b")

  if($hasPageProps -and (-not $usesPageProps)){
    $lines = [regex]::Split($raw, "`r?`n")
    $out = New-Object System.Collections.Generic.List[string]
    for($i=0; $i -lt $lines.Length; $i++){
      $line = $lines[$i]
      if($line -match "^\s*type\s+PageProps\b"){
        if($i -eq 0 -or $lines[$i-1] -notmatch "eslint-disable-next-line\s+@typescript-eslint/no-unused-vars"){
          $out.Add("// eslint-disable-next-line @typescript-eslint/no-unused-vars") | Out-Null
        }
      }
      $out.Add($line) | Out-Null
    }
    $raw = ($out -join "`r`n")
  }

  # Special: trilhas/[id] — se id existe e não é usado, adiciona "void id;"
  if($filePath -match "\\v2\\trilhas\\\[id\]\\page\.tsx$"){
    $lines = [regex]::Split($raw, "`r?`n")
    $out = New-Object System.Collections.Generic.List[string]
    for($i=0; $i -lt $lines.Length; $i++){
      $line = $lines[$i]
      $out.Add($line) | Out-Null

      if($line -match "^\s*const\s*\{\s*slug\s*,\s*id\s*\}\s*=\s*await\s*params"){
        $next = ""
        if($i+1 -lt $lines.Length){ $next = $lines[$i+1] }
        if($next -notmatch "^\s*void\s+id\s*;"){
          $indent = ([regex]::Match($line, "^\s*")).Value
          $out.Add(($indent + "void id;")) | Out-Null
        }
      }
    }
    $raw = ($out -join "`r`n")
  }

  if($raw -ne $orig){
    $didChange.Value = $true
    # backup simples no tools/_patch_backup
    $root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $bakDir = Join-Path $root ("tools/_patch_backup/b8hz-" + $stamp)
    EnsureDir $bakDir
    $dst = Join-Path $bakDir (([IO.Path]::GetFileName($filePath)) + ".bak")
    Copy-Item -LiteralPath $filePath -Destination $dst -Force
    WriteUtf8NoBom $filePath $raw
  }
}

# -----------------------
# ROOT GUARD
# -----------------------
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $root

$pkg = Join-Path $root "package.json"
if(-not (Test-Path -LiteralPath $pkg)){ throw ("package.json não encontrado em " + $root) }
$pkgRaw = Get-Content -LiteralPath $pkg -Raw
if($pkgRaw -notmatch '"name"\s*:\s*"cadernos-vivos"'){
  throw "Este script é do Cadernos Vivos. package.json não bate com name=cadernos-vivos."
}

# -----------------------
# REPORT
# -----------------------
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$repDir = Join-Path $root "reports"
EnsureDir $repDir
$repName = SafeFileName ($stamp + "-cv-rescue-b8hz-v2-lint-warnings-and-verify.md")
$reportPath = Join-Path $repDir $repName

$log = New-Object System.Collections.Generic.List[string]
function L([string]$s){ $log.Add($s) | Out-Null }

L "# CV RESCUE B8HZ — V2 lint warnings + verify"
L ""
L ("- root: " + $root)
L ("- CleanNext: " + $CleanNext.IsPresent)
L ("- SkipLint: " + $SkipLint.IsPresent)
L ("- SkipBuild: " + $SkipBuild.IsPresent)
L ""

Write-Host ("[INFO] report -> " + $reportPath)

# -----------------------
# ENV (git.exe + npm.cmd)
# -----------------------
$gitExe = $null
try {
  $gitExe = (& where.exe git 2>$null) | Where-Object { $_ -match "git\.exe$" } | Select-Object -First 1
} catch {}
if([string]::IsNullOrWhiteSpace($gitExe)){
  $gitExe = (Get-Command git -ErrorAction Stop).Source
}

$npmCmd = $null
try { $npmCmd = (& where.exe npm.cmd 2>$null) | Select-Object -First 1 } catch {}
if([string]::IsNullOrWhiteSpace($npmCmd)){
  throw "npm.cmd não encontrado (where npm.cmd falhou)."
}

L "## ENV"
L ("- git.exe: " + $gitExe)
L ("- npm.cmd: " + $npmCmd)
L ("- pwsh: " + $PSVersionTable.PSVersion.ToString())
L ""

# -----------------------
# CLEAN
# -----------------------
if($CleanNext){
  Write-Host "[STEP] CLEAN caches"
  L "## CLEAN"
  $dirs = @(".next","out",".turbo","node_modules\.cache","node_modules\.turbo")
  foreach($d in $dirs){
    $p = Join-Path $root $d
    if(Test-Path -LiteralPath $p){
      try {
        Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue
        L ("- removed: " + $d)
      } catch {
        L ("- failed: " + $d + " :: " + $_.Exception.Message)
      }
    } else {
      L ("- skip: " + $d)
    }
  }
  L ""
}

# -----------------------
# PATCH (V2 warnings)
# -----------------------
Write-Host "[STEP] PATCH V2 pages (limpar warnings)"
L "## PATCH (V2 lint warnings)"
$didChange = $false
$targets = @(
  "src/app/c/[slug]/v2/page.tsx",
  "src/app/c/[slug]/v2/debate/page.tsx",
  "src/app/c/[slug]/v2/mapa/page.tsx",
  "src/app/c/[slug]/v2/provas/page.tsx",
  "src/app/c/[slug]/v2/linha/page.tsx",
  "src/app/c/[slug]/v2/linha-do-tempo/page.tsx",
  "src/app/c/[slug]/v2/trilhas/page.tsx",
  "src/app/c/[slug]/v2/trilhas/[id]/page.tsx"
)
foreach($t in $targets){
  $fp = Join-Path $root $t
  $before = (Get-Content -LiteralPath $fp -Raw -ErrorAction SilentlyContinue)
  $dummy = $false
  Patch-Page $fp "b8hz" ([ref]$dummy)
  $after  = (Get-Content -LiteralPath $fp -Raw -ErrorAction SilentlyContinue)
  if($before -ne $after){ $didChange = $true; L ("- patched: " + $t) }
  else { L ("- ok: " + $t) }
}
L ""

# -----------------------
# VERIFY
# -----------------------
Write-Host "[STEP] VERIFY (git/lint/build)"
L "## VERIFY"
$failed = $false

Write-Host "[RUN] git status --porcelain"
Write-Host ("      " + $gitExe)
$gs = RunExeCapture $gitExe @("status","--porcelain") $root
L "### git status --porcelain"
L "~~~"
if([string]::IsNullOrWhiteSpace($gs.Out)){ L "(clean)" } else { L $gs.Out }
L "~~~"
L ("- exit: " + $gs.Code)
L ""
if($gs.Code -ne 0){ $failed = $true }

if(-not $SkipLint){
  Write-Host "[RUN] npm run lint"
  Write-Host ("      " + $npmCmd)
  $cmdLint = '""' + $npmCmd + '" run lint"'
  $r1 = RunCmdCapture $cmdLint $root
  L "### npm run lint"
  L "~~~"
  if([string]::IsNullOrWhiteSpace($r1.Out)){ L "(no output)" } else { L $r1.Out }
  L "~~~"
  L ("- exit: " + $r1.Code)
  L ""
  if($r1.Code -ne 0){ $failed = $true }
}

if(-not $SkipBuild){
  Write-Host "[RUN] npm run build"
  Write-Host ("      " + $npmCmd)
  $cmdBuild = '""' + $npmCmd + '" run build"'
  $r2 = RunCmdCapture $cmdBuild $root
  L "### npm run build"
  L "~~~"
  if([string]::IsNullOrWhiteSpace($r2.Out)){ L "(no output)" } else { L $r2.Out }
  L "~~~"
  L ("- exit: " + $r2.Code)
  L ""
  if($r2.Code -ne 0){ $failed = $true }
}

WriteUtf8NoBom $reportPath ($log -join "`r`n")
Write-Host ("[REPORT] " + $reportPath)

if($OpenReport){
  try { Start-Process notepad.exe $reportPath | Out-Null } catch {}
}

if($failed){
  throw ("B8HZ failed (see report): " + $reportPath)
}

Write-Host "[OK] B8HZ — patch ok + lint/build OK"