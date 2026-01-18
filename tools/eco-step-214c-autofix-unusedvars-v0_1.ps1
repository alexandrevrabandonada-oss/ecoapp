param(
  [switch]$OpenReport
)

$ErrorActionPreference = "Stop"

$ToolsDir = $PSScriptRoot
$Root = (Resolve-Path (Join-Path $ToolsDir "..")).Path

function EnsureDir([string]$p){
  if([string]::IsNullOrWhiteSpace($p)){ return }
  if(-not (Test-Path $p)){
    New-Item -ItemType Directory -Force -Path $p | Out-Null
  }
}

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$reportPath = Join-Path $Root ("reports\eco-step-214c-unusedvars-autofix-" + $stamp + ".md")
EnsureDir (Split-Path -Parent $reportPath)

$r = New-Object System.Collections.Generic.List[string]
function Log([string]$s){ $r.Add($s) | Out-Null }

function BackupFileLocal([string]$fullPath){
  if(-not (Test-Path $fullPath)){ return $null }
  $rel = $fullPath
  if($fullPath.StartsWith($Root, [System.StringComparison]::OrdinalIgnoreCase)){
    $rel = $fullPath.Substring($Root.Length).TrimStart('\','/')
  }
  $backupBase = Join-Path $Root ("tools\_patch_backup\eco-step-214c-" + $stamp)
  $dest = Join-Path $backupBase $rel
  EnsureDir (Split-Path -Parent $dest)
  Copy-Item -LiteralPath $fullPath -Destination $dest -Force
  Log ("- backup: " + $rel + " -> tools/_patch_backup/eco-step-214c-" + $stamp + "/" + $rel)
  return $dest
}

function ReadLinesUtf8([string]$p){
  return [IO.File]::ReadAllLines($p, [Text.UTF8Encoding]::new($false))
}

function WriteLinesUtf8([string]$p, [string[]]$lines){
  [IO.File]::WriteAllLines($p, $lines, [Text.UTF8Encoding]::new($false))
}

function IsInsideImportBraces([string[]]$lines, [int]$idx){
  # scan upward to find "import {" without a closing "}" between it and idx
  $start = [Math]::Max(0, $idx - 25)
  for($i=$idx; $i -ge $start; $i--){
    $ln = $lines[$i]
    if($ln -match "^\s*import\b" -and $ln -match "\{"){
      # ensure no closing brace between i and idx before "from"
      $closed = $false
      for($k=$i; $k -le $idx; $k++){
        if($lines[$k] -match "\}"){
          $closed = $true
          break
        }
      }
      if(-not $closed){
        return $true
      }
      return $false
    }
    if($ln -match "^\s*import\b" -and $ln -match "\}"){
      return $false
    }
    if($ln -match "^\s*(const|let|var)\b"){ break }
  }
  return $false
}

function IsInsideObjectDestructure([string[]]$lines, [int]$idx){
  # scan upward for "const {" / "let {" / "var {" without encountering a closing "}" before idx
  $start = [Math]::Max(0, $idx - 25)
  for($i=$idx; $i -ge $start; $i--){
    $ln = $lines[$i]
    if($ln -match "^\s*(const|let|var)\s*\{"){
      $closed = $false
      for($k=$i; $k -le $idx; $k++){
        if($lines[$k] -match "\}"){
          $closed = $true
          break
        }
      }
      if(-not $closed){
        return $true
      }
      return $false
    }
    if($ln -match "^\s*import\b"){ break }
  }
  return $false
}

function IsInsideArrayDestructure([string[]]$lines, [int]$idx){
  $start = [Math]::Max(0, $idx - 25)
  for($i=$idx; $i -ge $start; $i--){
    $ln = $lines[$i]
    if($ln -match "^\s*(const|let|var)\s*\["){
      $closed = $false
      for($k=$i; $k -le $idx; $k++){
        if($lines[$k] -match "\]"){
          $closed = $true
          break
        }
      }
      if(-not $closed){
        return $true
      }
      return $false
    }
    if($ln -match "^\s*import\b"){ break }
  }
  return $false
}

function FixUnusedVarAtLine([string[]]$lines, [int]$idx0, [string]$name){
  $line = $lines[$idx0]
  if($name.StartsWith("_")){ return $false }

  # 1) catch (e) -> catch (_e)
  if($line -match "catch\s*\(\s*" + [Regex]::Escape($name) + "\s*\)"){
    $new = [Regex]::Replace($line, "catch\s*\(\s*" + [Regex]::Escape($name) + "\s*\)", ("catch (_" + $name + ")"))
    if($new -ne $line){
      $lines[$idx0] = $new
      return $true
    }
  }

  $inImport = IsInsideImportBraces $lines $idx0
  $inObj    = IsInsideObjectDestructure $lines $idx0
  $inArr    = IsInsideArrayDestructure $lines $idx0

  # 2) import specifier line: Name -> Name as _Name
  if($inImport){
    if($line -match "\b" + [Regex]::Escape($name) + "\s+as\s+_"){ return $false }
    $new = [Regex]::Replace($line, "\b" + [Regex]::Escape($name) + "\b(?!\s+as\b)", ($name + " as _" + $name), 1)
    if($new -ne $line){
      $lines[$idx0] = $new
      return $true
    }
  }

  # 3) object destructuring line: { x } -> { x: _x }
  if($inObj){
    # line like "x," or "x }" or "x ="
    if($line -match "\b" + [Regex]::Escape($name) + "\s*:"){ return $false } # already renamed
    $new = [Regex]::Replace($line, "\b" + [Regex]::Escape($name) + "\b(?!\s*:)", ($name + ": _" + $name), 1)
    if($new -ne $line){
      $lines[$idx0] = $new
      return $true
    }
  }

  # 4) array destructuring or general: prefix underscore
  if($inArr -or $true){
    $new = [Regex]::Replace($line, "\b" + [Regex]::Escape($name) + "\b", ("_" + $name), 1)
    if($new -ne $line){
      $lines[$idx0] = $new
      return $true
    }
  }

  return $false
}

function RunCapture([string]$cmd, [string[]]$args){
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = $cmd
  $psi.Arguments = ($args -join " ")
  $psi.WorkingDirectory = $Root
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError  = $true
  $psi.UseShellExecute = $false
  $p = New-Object System.Diagnostics.Process
  $p.StartInfo = $psi
  [void]$p.Start()
  $stdout = $p.StandardOutput.ReadToEnd()
  $stderr = $p.StandardError.ReadToEnd()
  $p.WaitForExit()
  return [pscustomobject]@{ ExitCode=$p.ExitCode; StdOut=$stdout; StdErr=$stderr }
}

Log "# ECO STEP 214c — autofix unused-vars via eslint output — $stamp"
Log ""
Log "Root: $Root"
Log ""

$runner = Join-Path $Root "tools\eco-runner.ps1"
if(-not (Test-Path $runner)){
  Log "## ERR"
  Log "- tools/eco-runner.ps1 not found"
  [IO.File]::WriteAllText($reportPath, ($r -join "`n"), [Text.UTF8Encoding]::new($false))
  throw "eco-runner.ps1 not found"
}

Log "## DIAG"
Log "- Running: eco-runner -Tasks lint (capture output)"
Log ""

# run lint (capture)
$res = RunCapture "pwsh" @("-NoProfile","-ExecutionPolicy","Bypass","-File", "`"$runner`"", "-Tasks", "lint")
$lintOut = ($res.StdOut + "`n" + $res.StdErr)

Log "### lint output (truncated)"
Log "~~~"
$lintOut.Split("`n") | Select-Object -First 220 | ForEach-Object { Log $_.TrimEnd("`r") }
if(($lintOut.Split("`n").Count) -gt 220){ Log "... (truncated) ..." }
Log "~~~"
Log ("lint exit: " + $res.ExitCode)
Log ""

# parse warnings @typescript-eslint/no-unused-vars
$entries = New-Object System.Collections.Generic.List[object]
$curFile = $null

$linesOut = $lintOut.Split("`n") | ForEach-Object { $_.TrimEnd("`r") }

foreach($ln in $linesOut){
  # detect file path
  $mFile = [Regex]::Match($ln, "((?:[A-Za-z]:\\)?(?:\.\.\\|\.\\)?src[\\/].+\.(?:ts|tsx|js|jsx))")
  if($mFile.Success){
    $curFile = $mFile.Groups[1].Value
    continue
  }

  if($ln -match "no-unused-vars"){
    # try parse "6:9" and "'name'"
    $mPos = [Regex]::Match($ln, "(\d+):(\d+)")
    $mVar = [Regex]::Match($ln, "'([^']+)'")
    if($curFile -and $mPos.Success -and $mVar.Success){
      $entries.Add([pscustomobject]@{
        File=$curFile
        Line=[int]$mPos.Groups[1].Value
        Col=[int]$mPos.Groups[2].Value
        Name=$mVar.Groups[1].Value
        Raw=$ln
      }) | Out-Null
    }
  }
}

Log "## PLAN"
Log ("- Found no-unused-vars entries: " + $entries.Count)
Log ""

if($entries.Count -eq 0){
  Log "## PATCH"
  Log "- Nothing to do."
} else {

  Log "## PATCH"
  $patchedFiles = @{}
  $changedCount = 0

  foreach($e in $entries){
    $rel = $e.File
    # normalize ./src/... or src\...
    $rel = $rel -replace "^\.\.?[\\/]", ""
    $full = Join-Path $Root $rel

    if(-not (Test-Path $full)){
      Log ("- [SKIP] missing: " + $rel + " (" + $e.Raw + ")")
      continue
    }

    $idx0 = $e.Line - 1
    $name = $e.Name

    $fileLines = ReadLinesUtf8 $full
    if($idx0 -lt 0 -or $idx0 -ge $fileLines.Length){
      Log ("- [SKIP] OOR: " + $rel + ":" + $e.Line + " name=" + $name)
      continue
    }

    $before = $fileLines[$idx0]

    $did = FixUnusedVarAtLine $fileLines $idx0 $name
    if(-not $did){
      Log ("- [OK]   no change: " + $rel + ":" + $e.Line + " '" + $name + "'")
      continue
    }

    # backup once per file
    if(-not $patchedFiles.ContainsKey($full)){
      BackupFileLocal $full | Out-Null
      $patchedFiles[$full] = $true
    }

    WriteLinesUtf8 $full $fileLines
    $after = $fileLines[$idx0]

    $changedCount++
    Log ("- [PATCH] " + $rel + ":" + $e.Line + " '" + $name + "'")
    Log ("  - old: ``" + $before + "``")
    Log ("  - new: ``" + $after + "``")
  }

  Log ""
  Log ("Patched entries: " + $changedCount)
}

Log ""
Log "## VERIFY"
Log "- Running: eco-runner -Tasks lint build"
Log ""

$res2 = RunCapture "pwsh" @("-NoProfile","-ExecutionPolicy","Bypass","-File", "`"$runner`"", "-Tasks", "lint", "build")
$verifyOut = ($res2.StdOut + "`n" + $res2.StdErr)

Log "~~~"
$verifyOut.Split("`n") | Select-Object -First 260 | ForEach-Object { Log $_.TrimEnd("`r") }
if(($verifyOut.Split("`n").Count) -gt 260){ Log "... (truncated) ..." }
Log "~~~"
Log ("verify exit: " + $res2.ExitCode)
Log ""

[IO.File]::WriteAllText($reportPath, ($r -join "`n"), [Text.UTF8Encoding]::new($false))
Write-Host ("[REPORT] " + $reportPath)

if($OpenReport){
  try { ii $reportPath } catch {}
}

if($res2.ExitCode -ne 0){
  throw ("STEP 214c failed verify (see report): " + $reportPath)
}