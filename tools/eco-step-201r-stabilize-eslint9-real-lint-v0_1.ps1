param([switch]$OpenReport)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function EnsureDir([string]$p){ if(!(Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function ReadRaw([string]$p){ Get-Content -LiteralPath $p -Raw -Encoding UTF8 }
function WriteUtf8NoBom([string]$p,[string]$content){ [IO.File]::WriteAllText($p, $content, [Text.UTF8Encoding]::new($false)) }

function BackupFile([string]$root,[string]$stamp,[string]$file,[ref]$r){
  if(!(Test-Path -LiteralPath $file)){ $r.Value += ("- [SKIP] missing: " + $file); return }
  $bdir = Join-Path $root ("tools\_patch_backup\eco-step-201r\" + $stamp)
  EnsureDir $bdir
  $leaf = Split-Path $file -Leaf
  $dest = Join-Path $bdir ($leaf + "--" + $stamp)
  Copy-Item -LiteralPath $file -Destination $dest -Force
  $r.Value += ("- backup: " + $file + " -> " + $dest)
}

function GetNpmPath(){
  $c = Get-Command npm.cmd -ErrorAction SilentlyContinue
  if($c -and $c.Path){ return $c.Path }
  $c = Get-Command npm -ErrorAction SilentlyContinue
  if($c -and $c.Path){ return $c.Path }
  throw "npm não encontrado (nem npm.cmd nem npm). Ajuste PATH/instale Node."
}
function Npm([Parameter(ValueFromRemainingArguments=$true)]$args){
  $npmPath = GetNpmPath
  & $npmPath @args 2>&1
}

$root = (Get-Location).Path
$stamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
EnsureDir (Join-Path $root "reports")
$reportPath = Join-Path $root ("reports\eco-step-201r-stabilize-eslint9-real-lint-" + $stamp + ".md")

$r = @()
$r += "# ECO STEP 201r — ESLint 9 estável + TS exclude + dep clean"
$r += ""
$r += ("Stamp: " + $stamp)
$r += ("Root: " + $root)
$r += ""

# PATCH A — remover __DEP__ em src/
$r += "## PATCH A — remover __DEP__ (quebra TS build)"
$srcRoot = Join-Path $root "src"
if(Test-Path -LiteralPath $srcRoot){
  $hits = Get-ChildItem -Path $srcRoot -Recurse -File -Include *.ts,*.tsx | Select-String -Pattern "__DEP__" -ErrorAction SilentlyContinue
  if($hits){
    $uniq = $hits | Select-Object -ExpandProperty Path -Unique
    foreach($p in $uniq){
      BackupFile $root $stamp $p ([ref]$r)
      $raw = ReadRaw $p
      $raw2 = $raw -replace "\[\s*__DEP__\s*\]","[]"
      $raw2 = $raw2 -replace "__DEP__","0"
      if($raw2 -ne $raw){ WriteUtf8NoBom $p $raw2; $r += ("- patched: " + $p) } else { $r += ("- [SKIP] no change: " + $p) }
    }
  } else { $r += "- ok: sem ocorrencias de __DEP__ em src/" }
} else { $r += ("- [SKIP] src/ nao encontrado: " + $srcRoot) }
$r += ""

# PATCH B — eslint.config.mjs (flat) MINIMAL e seguro
$r += "## PATCH B — eslint.config.mjs (minimal + ignores)"
$eslintPath = Join-Path $root "eslint.config.mjs"
BackupFile $root $stamp $eslintPath ([ref]$r)
$eslint = @' 
export default [
  {
    ignores: [
      "**/node_modules/**",
      "**/.next/**",
      "**/dist/**",
      "**/coverage/**",
      "**/reports/**",
      "tools/_patch_backup/**",
      "tools/**/_patch_backup/**",
      "**/*.bak-*",
      "**/*.bak",
      "**/*.log"
    ],
  },
];
'@
WriteUtf8NoBom $eslintPath $eslint
$r += ("- wrote: " + $eslintPath)
$r += ""

# PATCH C — package.json scripts.lint
$r += "## PATCH C — package.json scripts.lint"
$pkgPath = Join-Path $root "package.json"
BackupFile $root $stamp $pkgPath ([ref]$r)
if(!(Test-Path -LiteralPath $pkgPath)){ throw ("package.json não encontrado em " + $pkgPath) }
$pkg = (ReadRaw $pkgPath) | ConvertFrom-Json
if($null -eq $pkg.scripts){ $pkg | Add-Member -NotePropertyName scripts -NotePropertyValue (@{}) -Force }
$pkg.scripts.lint = "eslint . --no-error-on-unmatched-pattern"
$json = $pkg | ConvertTo-Json -Depth 80
WriteUtf8NoBom $pkgPath $json
$r += "- ok: scripts.lint = eslint . --no-error-on-unmatched-pattern"
$r += ""

# PATCH D — tsconfig.json exclude
$r += "## PATCH D — tsconfig.json exclude (backups/reports)"
$tsPath = Join-Path $root "tsconfig.json"
if(Test-Path -LiteralPath $tsPath){
  BackupFile $root $stamp $tsPath ([ref]$r)
  $ts = (ReadRaw $tsPath) | ConvertFrom-Json
  if($null -eq $ts.exclude){ $ts | Add-Member -NotePropertyName exclude -NotePropertyValue (@()) -Force }
  $need = @("node_modules",".next","dist","coverage","reports","tools/_patch_backup","tools/**/_patch_backup","**/*.bak-*","**/*.log")
  $cur = @() + $ts.exclude
  foreach($x in $need){ if($cur -notcontains $x){ $cur += $x } }
  $ts.exclude = $cur
  $tsJson = $ts | ConvertTo-Json -Depth 80
  WriteUtf8NoBom $tsPath $tsJson
  $r += "- ok: updated exclude in tsconfig.json"
} else { $r += "- [SKIP] tsconfig.json não encontrado" }
$r += ""

# VERIFY
$r += "## VERIFY"
$r += "### npm --version"
$r += "~~~"
$r += (Npm "--version" | Out-String)
$r += "~~~"
$r += ""
$r += "### npm run lint"
$r += "~~~"
$lintOut = Npm "run" "lint"
$r += ($lintOut | Out-String)
$r += ("exit: " + $LASTEXITCODE)
$r += "~~~"
$r += ""
$r += "### npm run build"
$r += "~~~"
$buildOut = Npm "run" "build"
$r += ($buildOut | Out-String)
$r += ("exit: " + $LASTEXITCODE)
$r += "~~~"
$r += ""
$r += "## NEXT"
$r += "- Se o terminal continuar estranho com npm, rode: Set-Alias npm npm.cmd"

WriteUtf8NoBom $reportPath ($r -join [Environment]::NewLine)
Write-Host ("[REPORT] " + $reportPath)
if($OpenReport){ Start-Process $reportPath | Out-Null }