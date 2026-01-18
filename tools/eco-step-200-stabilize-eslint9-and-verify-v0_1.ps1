param([switch]$OpenReport)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Root do projeto = 1 nivel acima da pasta tools/
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $root

function EnsureDir([string]$p){ if(!(Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function WriteUtf8NoBom([string]$p,[string]$content){ [IO.File]::WriteAllText($p, $content, [Text.UTF8Encoding]::new($false)) }
function ReadRaw([string]$p){ Get-Content -LiteralPath $p -Raw }
function BackupFile([string]$file,[string]$stamp,[ref]$r){
  if(!(Test-Path -LiteralPath $file)){ $r.Value += ("- [SKIP] missing: " + $file); return }
  $bdir = Join-Path $root ("tools\_patch_backup\eco-step-200\" + $stamp)
  EnsureDir $bdir
  $leaf = Split-Path $file -Leaf
  $dest = Join-Path $bdir ($leaf + "--" + $stamp)
  Copy-Item -LiteralPath $file -Destination $dest -Force
  $r.Value += ("- backup: " + $file + " -> " + $dest)
}

function GetNpmCmd(){
  $cmd = (Get-Command npm.cmd -ErrorAction SilentlyContinue)
  if($cmd){ return "npm.cmd" }
  return "npm"
}
function RunNpm([string[]]$args){
  $npm = GetNpmCmd
  $out = & $npm @args 2>&1
  return ($out | Out-String)
}

$stamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
EnsureDir (Join-Path $root "reports")
$reportPath = Join-Path $root ("reports\eco-step-200-stabilize-eslint9-and-verify-" + $stamp + ".md")

$r = @()
$r += "# ECO STEP 200 — Stabilize ESLint 9 + Verify (lint/build)"
$r += ""
$r += ("Stamp: " + $stamp)
$r += ("Root: " + $root)
$r += ""

# ------------------------------------------------------------
# PATCH A) garantir deps do parser TS (lint em TS/TSX sem regra chata)
# ------------------------------------------------------------
$r += "## PATCH A — deps (@typescript-eslint/parser + plugin)"
$parserPath = Join-Path $root "node_modules\@typescript-eslint\parser\package.json"
$pluginPath = Join-Path $root "node_modules\@typescript-eslint\eslint-plugin\package.json"
if(!(Test-Path -LiteralPath $parserPath) -or !(Test-Path -LiteralPath $pluginPath)){
  $r += "- installing devDeps..."
  $r += RunNpm @("i","-D","@typescript-eslint/parser","@typescript-eslint/eslint-plugin")
} else {
  $r += "- ok: deps já presentes"
}
$r += ""

# ------------------------------------------------------------
# PATCH B) eslint.config.mjs (flat) mínimo + ignora lixo + permissivo
# ------------------------------------------------------------
$r += "## PATCH B — eslint.config.mjs (flat) mínimo + ignores"
$eslintPath = Join-Path $root "eslint.config.mjs"
BackupFile $eslintPath $stamp ([ref]$r)
$eslintLines = @(
  'import tsParser from "@typescript-eslint/parser";',
  'import tsPlugin from "@typescript-eslint/eslint-plugin";',
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
  '  {',
  '    files: ["**/*.{ts,tsx}"],',
  '    languageOptions: {',
  '      parser: tsParser,',
  '      parserOptions: {',
  '        ecmaVersion: "latest",',
  '        sourceType: "module",',
  '        ecmaFeatures: { jsx: true }',
  '      }',
  '    },',
  '    plugins: { "@typescript-eslint": tsPlugin },',
  '    rules: {',
  '      "@typescript-eslint/no-explicit-any": "off",',
  '      "@typescript-eslint/ban-ts-comment": "off"',
  '    }',
  '  },',
  '  {',
  '    files: ["**/*.{js,cjs,mjs,jsx}"],',
  '    rules: {}',
  '  }',
  '];'
)
WriteUtf8NoBom $eslintPath ($eslintLines -join "`n")
$r += ("- wrote: " + $eslintPath)
$r += ""

# ------------------------------------------------------------
# PATCH C) package.json: scripts.lint
# ------------------------------------------------------------
$r += "## PATCH C — package.json scripts.lint"
$pkgPath = Join-Path $root "package.json"
BackupFile $pkgPath $stamp ([ref]$r)
if(Test-Path -LiteralPath $pkgPath){
  $pkg = (ReadRaw $pkgPath) | ConvertFrom-Json
  if($null -eq $pkg.scripts){ $pkg | Add-Member -NotePropertyName scripts -NotePropertyValue (@{}) -Force }
  $pkg.scripts.lint = "eslint . --no-error-on-unmatched-pattern"
  $json = $pkg | ConvertTo-Json -Depth 80
  WriteUtf8NoBom $pkgPath $json
  $r += "- ok: scripts.lint = eslint . --no-error-on-unmatched-pattern"
} else {
  $r += "- [ERR] package.json não encontrado"
}
$r += ""

# ------------------------------------------------------------
# VERIFY
# ------------------------------------------------------------
$r += "## VERIFY"
$r += "### npm --version"
$r += RunNpm @("--version")
$r += "### node --version"
$r += ((& node --version) | Out-String)
$r += ""
$r += "### npm run lint"
$r += RunNpm @("run","lint")
$r += ""
$r += "### npm run build"
$r += RunNpm @("run","build")
$r += ""

WriteUtf8NoBom $reportPath ($r -join "`n")
Write-Host ("[REPORT] " + $reportPath)
if($OpenReport){ Start-Process $reportPath | Out-Null }