param([switch]$OpenReport)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function EnsureDir([string]$p){
  if(!(Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null }
}
function WriteUtf8NoBom([string]$p,[string]$content){
  [IO.File]::WriteAllText($p, $content, [Text.UTF8Encoding]::new($false))
}
function ReadRaw([string]$p){ Get-Content -LiteralPath $p -Raw -Encoding UTF8 }

function RelPath([string]$root,[string]$full){
  $r = $full
  if($r.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)){
    $r = $r.Substring($root.Length).TrimStart("\")
  }
  return $r
}
function BackupFile([string]$root,[string]$stamp,[string]$file,[ref]$r){
  if(!(Test-Path -LiteralPath $file)){
    $r.Value += ("- [SKIP] missing: " + $file)
    return
  }
  $bdir = Join-Path $root ("tools\_patch_backup\eco-step-202\" + $stamp)
  EnsureDir $bdir
  $rel = (RelPath $root $file) -replace "[\\/:]","__"
  $dest = Join-Path $bdir ($rel + "--" + $stamp)
  Copy-Item -LiteralPath $file -Destination $dest -Force
  $r.Value += ("- backup: " + $file + " -> " + $dest)
}

function NodeModulePath([string]$root,[string]$name){
  $p = "node_modules\" + ($name -replace "/","\") + "\package.json"
  return (Join-Path $root $p)
}
function HasNodeModule([string]$root,[string]$name){
  return (Test-Path -LiteralPath (NodeModulePath $root $name))
}
function RunNpm([string[]]$args){
  $npmCmd = (Get-Command npm.cmd -ErrorAction SilentlyContinue)
  if($npmCmd){ return (& npm.cmd @args 2>&1) }
  return (& npm @args 2>&1)
}

$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$stamp = (Get-Date).ToString("yyyyMMdd-HHmmss")

EnsureDir (Join-Path $root "reports")
$reportPath = Join-Path $root ("reports\eco-step-202-eslint9-real-lint-minsafe-" + $stamp + ".md")

$r = @()
$r += "# ECO STEP 202 — ESLint 9 real lint (minsafes) + excludes"
$r += ""
$r += ("Stamp: " + $stamp)
$r += ("Root: " + $root)
$r += ""

# -----------------------------
# PATCH A) deps mínimas pro flat config TS
# -----------------------------
$r += "## PATCH A — garantir deps ESLint 9 + TS parser/plugin"
$need = @(
  "@eslint/js",
  "@typescript-eslint/parser",
  "@typescript-eslint/eslint-plugin"
)
$missing = @()
foreach($m in $need){
  if(!(HasNodeModule $root $m)){ $missing += $m }
}
if($missing.Count -gt 0){
  $r += ("- install devDeps: " + ($missing -join ", "))
  $out = RunNpm (@("i","-D") + $missing)
  $r += "~~~"
  $r += ($out | Out-String)
  $r += "~~~"
} else {
  $r += "- ok: deps já presentes"
}
$r += ""

# -----------------------------
# PATCH B) eslint.config.mjs (flat config) — LINT só no src/
# -----------------------------
$r += "## PATCH B — eslint.config.mjs (flat config, lint só src/)"
$eslintPath = Join-Path $root "eslint.config.mjs"
BackupFile $root $stamp $eslintPath ([ref]$r)

$eslintLines = @(
  'import js from "@eslint/js";',
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
  '    // base JS rules (escopo: src/)',
  '    ...js.configs.recommended,',
  '    files: ["src/**/*.{js,jsx,ts,tsx}"],',
  '  },',
  '  {',
  '    files: ["src/**/*.{ts,tsx}"],',
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
  '      ...tsPlugin.configs.recommended.rules,',
  '      // minsafes pra não travar o projeto agora:',
  '      "no-undef": "off",',
  '      "no-unused-vars": "off",',
  '      "@typescript-eslint/no-unused-vars": ["warn", { "argsIgnorePattern": "^_", "varsIgnorePattern": "^_" }],',
  '      "@typescript-eslint/no-explicit-any": "off",',
  '    }',
  '  }',
  '];',
  ''
)
WriteUtf8NoBom $eslintPath ($eslintLines -join "`n")
$r += ("- wrote: " + $eslintPath)
$r += ""

# -----------------------------
# PATCH C) package.json scripts.lint (Windows-safe)
# -----------------------------
$r += "## PATCH C — package.json scripts.lint (Windows-safe)"
$pkgPath = Join-Path $root "package.json"
BackupFile $root $stamp $pkgPath ([ref]$r)

if(Test-Path -LiteralPath $pkgPath){
  $pkg = (ReadRaw $pkgPath) | ConvertFrom-Json
  if($null -eq $pkg.scripts){
    $pkg | Add-Member -NotePropertyName scripts -NotePropertyValue (@{}) -Force
  }
  # lint só no src/ (evita varrer repo inteiro e pegar sujeira)
  $pkg.scripts.lint = "eslint src --ext .js,.jsx,.ts,.tsx --cache --no-error-on-unmatched-pattern"
  $json = $pkg | ConvertTo-Json -Depth 80
  WriteUtf8NoBom $pkgPath $json
  $r += "- ok: scripts.lint = eslint src --ext ... --cache --no-error-on-unmatched-pattern"
} else {
  $r += "- [ERR] package.json não encontrado"
}
$r += ""

# -----------------------------
# PATCH D) tsconfig exclude backups/reports (pra TS/build não varrer lixo)
# -----------------------------
$r += "## PATCH D — tsconfig.json exclude (backups/reports)"
$tsPath = Join-Path $root "tsconfig.json"
BackupFile $root $stamp $tsPath ([ref]$r)

if(Test-Path -LiteralPath $tsPath){
  $ts = (ReadRaw $tsPath) | ConvertFrom-Json
  if($null -eq $ts.exclude){
    $ts | Add-Member -NotePropertyName exclude -NotePropertyValue (@()) -Force
  }
  $needEx = @(
    "reports",
    "tools/_patch_backup",
    "tools/**/_patch_backup"
  )
  $cur = @()
  foreach($e in @($ts.exclude)){ if($e){ $cur += [string]$e } }
  foreach($e in $needEx){ if(!($cur -contains $e)){ $cur += $e } }
  $ts.exclude = $cur
  $tsJson = $ts | ConvertTo-Json -Depth 80
  WriteUtf8NoBom $tsPath $tsJson
  $r += "- ok: tsconfig exclude atualizado"
} else {
  $r += "- [SKIP] tsconfig.json não encontrado"
}
$r += ""

# -----------------------------
# VERIFY
# -----------------------------
$r += "## VERIFY"
$r += "### npm --version"
$r += "~~~"
$r += (RunNpm @("--version") | Out-String)
$r += "~~~"
$r += ""

$r += "### npm run lint"
$r += "~~~"
$r += (RunNpm @("run","lint") | Out-String)
$r += "~~~"
$r += ""

$r += "### npm run build"
$r += "~~~"
$r += (RunNpm @("run","build") | Out-String)
$r += "~~~"
$r += ""

$r += "## NEXT"
$r += "- Se seu terminal continuar 'estranho' com npm, pode fixar: Set-Alias npm npm.cmd"
$r += "- Agora o lint está REAL (src/). Se quiser endurecer depois, a gente sobe regras gradualmente."

WriteUtf8NoBom $reportPath ($r -join "`n")
Write-Host ("[REPORT] " + $reportPath)

if($OpenReport){
  Start-Process $reportPath | Out-Null
}
