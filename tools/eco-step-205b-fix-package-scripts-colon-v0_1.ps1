param([switch]$OpenReport)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = if($PSScriptRoot -and $PSScriptRoot.Trim().Length -gt 0) { Split-Path -Parent $PSScriptRoot } else { (Get-Location).Path }
$stamp = (Get-Date).ToString("yyyyMMdd-HHmmss")

function EnsureDir([string]$p){
  if(!(Test-Path -LiteralPath $p)){
    New-Item -ItemType Directory -Force -Path $p | Out-Null
  }
}
function WriteUtf8NoBom([string]$p,[string]$content){
  [IO.File]::WriteAllText($p, $content, [Text.UTF8Encoding]::new($false))
}
function ReadRaw([string]$p){
  return [IO.File]::ReadAllText($p, [Text.UTF8Encoding]::new($false))
}
function BackupFile([string]$root,[string]$stamp,[string]$file,[ref]$r){
  if(!(Test-Path -LiteralPath $file)){
    $r.Value += ("- skip backup (nao existe): " + $file)
    return
  }
  $bkDir = Join-Path $root "tools/_patch_backup"
  EnsureDir $bkDir
  $name = [IO.Path]::GetFileName($file)
  $dest = Join-Path $bkDir ($name + ".bak-" + $stamp)
  Copy-Item -LiteralPath $file -Destination $dest -Force
  $r.Value += ("- backup: " + $dest)
}
function FindNpmCmd(){
  $c = Get-Command npm.cmd -ErrorAction SilentlyContinue
  if($c){ return $c.Source }
  return "npm.cmd"
}
function RunNpm([string[]]$args){
  $npm = FindNpmCmd
  return (& $npm @args 2>&1 | Out-String)
}

EnsureDir (Join-Path $root "reports")
$reportPath = Join-Path $root ("reports\eco-step-205b-fix-scripts-colon-" + $stamp + ".md")

$r = @()
$r += "# ECO STEP 205b — Fix scripts com ':' no package.json"
$r += ""
$r += ("Stamp: " + $stamp)
$r += ("Root: " + $root)
$r += ""

# -----------------------------
# PATCH — package.json scripts as Hashtable (suporta lint:debug)
# -----------------------------
$r += "## PATCH — package.json scripts"
$pkgPath = Join-Path $root "package.json"
BackupFile $root $stamp $pkgPath ([ref]$r)

if(!(Test-Path -LiteralPath $pkgPath)){
  throw ("package.json nao encontrado: " + $pkgPath)
}

$pkg = (ReadRaw $pkgPath) | ConvertFrom-Json

# garante scripts
if($null -eq $pkg.scripts){
  $pkg | Add-Member -NotePropertyName scripts -NotePropertyValue (@{}) -Force
}

# converte scripts PSCustomObject -> Hashtable (pra aceitar keys com ':')
if($pkg.scripts -is [System.Management.Automation.PSCustomObject]){
  $h = @{}
  foreach($p in $pkg.scripts.PSObject.Properties){
    $h[$p.Name] = $p.Value
  }
  $pkg.scripts = $h
} elseif($pkg.scripts -isnot [hashtable]){
  # fallback: força hashtable
  $pkg.scripts = @{}
}

$pkg.scripts["lint"] = "node ./node_modules/eslint/bin/eslint.js src --max-warnings 9999"
$pkg.scripts["lint:fix"] = "node ./node_modules/eslint/bin/eslint.js src --fix"
$pkg.scripts["lint:debug"] = "node ./node_modules/eslint/bin/eslint.js src --print-config src/app/page.tsx"
$pkg.scripts["verify"] = "npm run lint && npm run build"

WriteUtf8NoBom $pkgPath ($pkg | ConvertTo-Json -Depth 80)
$r += "- ok: scripts.lint / lint:fix / lint:debug / verify"
$r += ""

# -----------------------------
# VERIFY
# -----------------------------
$r += "## VERIFY"
$r += "### npm.cmd run lint"
$r += "~~~"
$r += (RunNpm @("run","lint")).TrimEnd()
$r += "~~~"
$r += ""
$r += "### npm.cmd run build"
$r += "~~~"
$r += (RunNpm @("run","build")).TrimEnd()
$r += "~~~"
$r += ""

WriteUtf8NoBom $reportPath ($r -join "`n")
Write-Host ("[REPORT] " + $reportPath)
if($OpenReport){ Start-Process $reportPath | Out-Null }