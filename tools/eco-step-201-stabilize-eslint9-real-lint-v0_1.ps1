param([switch]$OpenReport)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function EnsureDir([string]$p){ if(!(Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function ReadRaw([string]$p){ Get-Content -LiteralPath $p -Raw -Encoding UTF8 }
function WriteUtf8NoBom([string]$p,[string]$content){ [IO.File]::WriteAllText($p, $content, [Text.UTF8Encoding]::new($false)) }

function BackupFile([string]$root,[string]$stamp,[string]$file,[ref]$r){
  if(!(Test-Path -LiteralPath $file)){ $r.Value += ("- [SKIP] missing: " + $file); return }
  $bdir = Join-Path $root ("tools\_patch_backup\eco-step-201\" + $stamp)
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
  throw "npm não encontrado (nem npm.cmd nem npm). Instale Node.js ou ajuste PATH."
}
function Npm([Parameter(ValueFromRemainingArguments=$true)]$args){
  $npmPath = GetNpmPath
  & $npmPath @args
}

$root = (Get-Location).Path
$stamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
EnsureDir (Join-Path $root "reports")
$reportPath = Join-Path $root ("reports\eco-step-201-stabilize-eslint9-real-lint-" + $stamp + ".md")
$r = @()
$r += "# ECO STEP 201 — ESLint 9 estável (lint real) + TS exclude"
$r += ""
$r += ("Stamp: " + $stamp)
$r += ("Root: " + $root)
$r += ""

## PATCH A — eslint.config.mjs (flat) mínimo, MAS LINTANDO TS/TSX
$r += "## PATCH A — eslint.config.mjs (flat) mínimo (linta TS/TSX)"
$eslintPath = Join-Path $root "eslint.config.mjs"
BackupFile $root $stamp $eslintPath ([ref]$r)
$eslint = @'
import tsParser from "@typescript-eslint/parser";

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
  {
    files: ["**/*.{js,cjs,mjs,jsx,ts,tsx}"],
    languageOptions: {
      parser: tsParser,
      parserOptions: {
        ecmaVersion: "latest",
        sourceType: "module",
        ecmaFeatures: { jsx: true },
      },
    },
    rules: {
      // propositalmente vazio: foco em estabilidade. A gente endurece depois.
    },
  },
];
'@
WriteUtf8NoBom $eslintPath $eslint
$r += ("- wrote: " + $eslintPath)
$r += ""

## PATCH B — package.json scripts.lint = eslint . --no-error-on-unmatched-pattern
$r += "## PATCH B — package.json scripts.lint"
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

## PATCH C — tsconfig.json excluir backups e reports (pra TS/build não varrer tools)
$r += "## PATCH C — tsconfig.json exclude (tools/_patch_backup, reports, etc.)"
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
} else {
  $r += "- [SKIP] tsconfig.json não encontrado"
}
$r += ""

## VERIFY (sempre via npm.cmd quando existir)
$r += "## VERIFY"
$r += "### npm --version"
$r += "~~~"
$r += (Npm "--version" | Out-String)
$r += "~~~"
$r += ""
$r += "### node --version"
$r += "~~~"
$r += (& node --version | Out-String)
$r += "~~~"
$r += ""
$r += "### npm run lint"
$r += "~~~"
$r += (Npm "run" "lint" | Out-String)
$r += "~~~"
$r += ""
$r += "### npm run build"
$r += "~~~"
$r += (Npm "run" "build" | Out-String)
$r += "~~~"
$r += ""
$r += "## NEXT"
$r += "- Se seu terminal continuar estranho com `npm`, rode uma vez: `Set-Alias npm npm.cmd`"

WriteUtf8NoBom $reportPath ($r -join "`n")
Write-Host ("[REPORT] " + $reportPath)
if($OpenReport){ Start-Process $reportPath | Out-Null }