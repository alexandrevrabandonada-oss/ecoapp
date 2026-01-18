param([switch]$OpenReport)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Root robusto: se rodar como arquivo em tools/, pega o pai; senão usa o diretório atual
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

EnsureDir (Join-Path $root "tools")
EnsureDir (Join-Path $root "reports")

$reportPath = Join-Path $root ("reports\eco-step-205-eslint9-bootstrap-runner-" + $stamp + ".md")
$r = @()
$r += "# ECO STEP 205 — ESLint 9 (flat) + bootstrap + runner (REAL em src/)"
$r += ""
$r += ("Stamp: " + $stamp)
$r += ("Root: " + $root)
$r += ""

# -----------------------------
# PATCH 0 — tools/_bootstrap.ps1 (canônico)
# -----------------------------
$r += "## PATCH 0 — tools/_bootstrap.ps1"
$bootstrapPath = Join-Path $root "tools/_bootstrap.ps1"
BackupFile $root $stamp $bootstrapPath ([ref]$r)

$bootstrap = @(
'Set-StrictMode -Version Latest',
'$ErrorActionPreference = "Stop"',
'function EnsureDir([string]$p){ if(!(Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }',
'function WriteUtf8NoBom([string]$p,[string]$content){ [IO.File]::WriteAllText($p, $content, [Text.UTF8Encoding]::new($false)) }',
'function ReadRaw([string]$p){ return [IO.File]::ReadAllText($p, [Text.UTF8Encoding]::new($false)) }',
'function BackupFile([string]$root,[string]$stamp,[string]$file,[ref]$r){',
'  if(!(Test-Path -LiteralPath $file)){ $r.Value += ("- skip backup (nao existe): " + $file); return }',
'  $bkDir = Join-Path $root "tools/_patch_backup"; EnsureDir $bkDir',
'  $name = [IO.Path]::GetFileName($file)',
'  $dest = Join-Path $bkDir ($name + ".bak-" + $stamp)',
'  Copy-Item -LiteralPath $file -Destination $dest -Force',
'  $r.Value += ("- backup: " + $dest)',
'}',
'function FindNpmCmd(){ $c = Get-Command npm.cmd -ErrorAction SilentlyContinue; if($c){ return $c.Source }; return "npm.cmd" }',
'function RunNpm([string[]]$args){ $npm = FindNpmCmd; return (& $npm @args 2>&1 | Out-String) }'
)

WriteUtf8NoBom $bootstrapPath ($bootstrap -join "`n")
$r += ("- wrote: " + $bootstrapPath)
$r += ""

# -----------------------------
# DIAG
# -----------------------------
$r += "## DIAG"
$r += "### node --version"
$r += "~~~"
$r += ((& node --version 2>&1) | Out-String).TrimEnd()
$r += "~~~"
$r += ""
$npmCmd = FindNpmCmd
$r += ("### npm.cmd: " + $npmCmd)
$r += ""

# -----------------------------
# PATCH A — deps (best-effort)
# -----------------------------
$r += "## PATCH A — deps (best-effort)"
$deps = @("@eslint/js","@typescript-eslint/parser","@typescript-eslint/eslint-plugin","eslint-plugin-react-hooks","@next/eslint-plugin-next")
$missing = @()
foreach($d in $deps){
  $p = Join-Path $root ("node_modules/" + $d + "/package.json")
  if(!(Test-Path -LiteralPath $p)){ $missing += $d }
}
if($missing.Count -gt 0){
  $r += ("- install: " + ($missing -join ", "))
  $r += "~~~"
  $r += (RunNpm (@("i","-D") + $missing)).TrimEnd()
  $r += "~~~"
} else {
  $r += "- ok: deps presentes"
}
$r += ""

# -----------------------------
# PATCH B — eslint.config.mjs
# -----------------------------
$r += "## PATCH B — eslint.config.mjs (src/ + plugins Next + React Hooks + TS)"
$eslintPath = Join-Path $root "eslint.config.mjs"
BackupFile $root $stamp $eslintPath ([ref]$r)

$eslint = @(
'import js from "@eslint/js";',
'import tsParser from "@typescript-eslint/parser";',
'import tsPlugin from "@typescript-eslint/eslint-plugin";',
'import reactHooks from "eslint-plugin-react-hooks";',
'import nextPlugin from "@next/eslint-plugin-next";',
'',
'export default [',
'  {',
'    ignores: [',
'      "**/node_modules/**",',
'      "**/.next/**",',
'      "**/dist/**",',
'      "**/coverage/**",',
'      "**/reports/**",',
'      "tools/_patch_backup/**",',
'      "tools/**/_patch_backup/**",',
'      "**/*.bak-*",',
'      "**/*.bak",',
'      "**/*.log"',
'    ],',
'  },',
'',
'  // JS base (somente src/)',
'  {',
'    ...js.configs.recommended,',
'    files: ["src/**/*.{js,jsx,ts,tsx}"],',
'  },',
'',
'  // TS/TSX + Next + React Hooks (somente src/)',
'  {',
'    files: ["src/**/*.{ts,tsx}"],',
'    languageOptions: {',
'      parser: tsParser,',
'      parserOptions: {',
'        ecmaVersion: "latest",',
'        sourceType: "module",',
'        ecmaFeatures: { jsx: true },',
'      },',
'    },',
'    plugins: {',
'      "@typescript-eslint": tsPlugin,',
'      "react-hooks": reactHooks,',
'      "@next/next": nextPlugin,',
'    },',
'    rules: {',
'      ...tsPlugin.configs.recommended.rules,',
'',
'      // minsafe:',
'      "no-undef": "off",',
'      "no-unused-vars": "off",',
'      "@typescript-eslint/no-unused-vars": ["warn", { "argsIgnorePattern": "^_", "varsIgnorePattern": "^_" }],',
'      "@typescript-eslint/no-explicit-any": "off",',
'',
'      // hooks + next:',
'      "react-hooks/rules-of-hooks": "error",',
'      "react-hooks/exhaustive-deps": "warn",',
'      "@next/next/no-img-element": "warn",',
'    },',
'  },',
'];',
'')

WriteUtf8NoBom $eslintPath ($eslint -join "`n")
$r += ("- wrote: " + $eslintPath)
$r += ""

# -----------------------------
# PATCH C — package.json scripts
# -----------------------------
$r += "## PATCH C — package.json scripts (lint REAL em src/)"
$pkgPath = Join-Path $root "package.json"
BackupFile $root $stamp $pkgPath ([ref]$r)

if(!(Test-Path -LiteralPath $pkgPath)){
  throw ("package.json nao encontrado em: " + $pkgPath)
}
$pkg = (ReadRaw $pkgPath) | ConvertFrom-Json
if($null -eq $pkg.scripts){ $pkg | Add-Member -NotePropertyName scripts -NotePropertyValue (@{}) -Force }

$pkg.scripts.lint = "node ./node_modules/eslint/bin/eslint.js src --max-warnings 9999"
$pkg.scripts."lint:fix" = "node ./node_modules/eslint/bin/eslint.js src --fix"
$pkg.scripts."lint:debug" = "node ./node_modules/eslint/bin/eslint.js src --print-config src/app/page.tsx"
$pkg.scripts.verify = "npm run lint && npm run build"

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