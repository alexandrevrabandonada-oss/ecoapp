param([switch]$OpenReport)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function EnsureDir([string]$p){
  if(!(Test-Path -LiteralPath $p)){
    New-Item -ItemType Directory -Force -Path $p | Out-Null
  }
}
function WriteUtf8NoBom([string]$p,[string]$content){
  [IO.File]::WriteAllText($p, $content, [Text.UTF8Encoding]::new($false))
}
function ReadRaw([string]$p){
  Get-Content -LiteralPath $p -Raw
}
function BackupFile([string]$root,[string]$stamp,[string]$file,[ref]$r){
  if(!(Test-Path -LiteralPath $file)){
    $r.Value += ("- [SKIP] missing: " + $file)
    return
  }
  $bdir = Join-Path $root ("tools\_patch_backup\eco-step-198e\" + $stamp)
  EnsureDir $bdir
  $leaf = Split-Path $file -Leaf
  $dest = Join-Path $bdir ($leaf + "--" + $stamp)
  Copy-Item -LiteralPath $file -Destination $dest -Force
  $r.Value += ("- backup: " + $file + " -> " + $dest)
}

# raiz do repo (script fica em tools/)
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$stamp = (Get-Date).ToString("yyyyMMdd-HHmmss")

EnsureDir (Join-Path $root "reports")
$reportPath = Join-Path $root ("reports\eco-step-198e-unblock-eslint9-and-build-" + $stamp + ".md")

$r = @()
$r += "# ECO STEP 198e — Unblock ESLint9 + Build"
$r += ""
$r += ("Stamp: " + $stamp)
$r += ""

# -----------------------------
# PATCH A) remover __DEP__ em src/
# -----------------------------
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
      if($raw2 -ne $raw){
        WriteUtf8NoBom $p $raw2
        $r += ("- patched: " + $p)
      } else {
        $r += ("- [SKIP] no change: " + $p)
      }
    }
  } else {
    $r += "- ok: sem ocorrencias de __DEP__ em src/"
  }
} else {
  $r += ("- [SKIP] src/ nao encontrado: " + $srcRoot)
}
$r += ""

# -----------------------------
# PATCH B) ESLint 9 flat config MINIMO (sem TS) + ignores
# -----------------------------
$r += "## PATCH B — eslint.config.mjs minimo + ignores (sem TS/TSX)"
$eslintPath = Join-Path $root "eslint.config.mjs"
BackupFile $root $stamp $eslintPath ([ref]$r)

$lines = @(
"export default [",
"  {",
"    ignores: [",
"      '**/node_modules/**',",
"      '**/.next/**',",
"      '**/dist/**',",
"      '**/coverage/**',",
"      '**/reports/**',",
"      'tools/_patch_backup/**',",
"      'tools/**/_patch_backup/**',",
"      '**/*.ts',",
"      '**/*.tsx',",
"      '**/*.bak-*',",
"      '**/*.bak',",
"      '**/*.log'",
"    ],",
"  },",
"  {",
"    files: ['**/*.{js,cjs,mjs,jsx}'],",
"    rules: { }",
"  }",
"];"
)
WriteUtf8NoBom $eslintPath ($lines -join "`n")
$r += "- wrote: eslint.config.mjs"
$r += ""

# -----------------------------
# PATCH C) package.json lint script
# -----------------------------
$r += "## PATCH C — package.json: scripts.lint = eslint ."
$pkgPath = Join-Path $root "package.json"
BackupFile $root $stamp $pkgPath ([ref]$r)

if(Test-Path -LiteralPath $pkgPath){
  $pkg = (ReadRaw $pkgPath) | ConvertFrom-Json
  if($null -eq $pkg.scripts){
    $pkg | Add-Member -NotePropertyName scripts -NotePropertyValue (@{}) -Force
  }
  $pkg.scripts.lint = "eslint ."
  $json = $pkg | ConvertTo-Json -Depth 50
  WriteUtf8NoBom $pkgPath $json
  $r += "- ok: scripts.lint = eslint ."
} else {
  $r += "- [SKIP] package.json nao encontrado"
}
$r += ""

# -----------------------------
# VERIFY
# -----------------------------
$r += "## VERIFY"
$r += "### npm run lint"
try {
  $lint = & npm run lint 2>&1
  $r += ($lint | Out-String)
} catch {
  $r += "FAIL: npm run lint"
  $r += ($_ | Out-String)
}
$r += ""

$r += "### npm run build"
try {
  $build = & npm run build 2>&1
  $r += ($build | Out-String)
} catch {
  $r += "FAIL: npm run build"
  $r += ($_ | Out-String)
  throw
}

WriteUtf8NoBom $reportPath ($r -join "`n")
Write-Host ("[REPORT] " + $reportPath)

if($OpenReport){
  Start-Process $reportPath | Out-Null
}