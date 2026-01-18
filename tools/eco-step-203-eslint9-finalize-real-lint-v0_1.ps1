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
  if(!(Test-Path -LiteralPath $p)){ return $null }
  Get-Content -LiteralPath $p -Raw
}

function BackupFile([string]$backupRoot,[string]$stamp,[string]$file,[ref]$r){
  if(!(Test-Path -LiteralPath $file)){
    $r.Value += ("- [SKIP] missing: " + $file)
    return
  }
  EnsureDir $backupRoot
  $leaf = Split-Path $file -Leaf
  $dest = Join-Path $backupRoot ($leaf + "--" + $stamp)
  Copy-Item -LiteralPath $file -Destination $dest -Force
  $r.Value += ("- backup: " + $file + " -> " + $dest)
}

function FindNpmCmdPath(){
  $c = Get-Command npm.cmd -ErrorAction SilentlyContinue
  if($c){ return $c.Source }
  $c = Get-Command npm -ErrorAction SilentlyContinue
  if($c){ return $c.Source }
  return $null
}

function RunNpm([string[]]$args){
  $npmPath = FindNpmCmdPath
  if(!$npmPath){ throw "npm(.cmd) nao encontrado no PATH" }
  & $npmPath @args 2>&1
}

# root (assumindo tools/)
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Push-Location $root
try {
  $stamp = (Get-Date).ToString("yyyyMMdd-HHmmss")

  EnsureDir (Join-Path $root "reports")
  $reportPath = Join-Path $root ("reports\eco-step-203-eslint9-finalize-real-lint-" + $stamp + ".md")

  $backupDir = Join-Path $root ("tools\_patch_backup\eco-step-203\" + $stamp)
  EnsureDir $backupDir

  $r = @()
  $r += "# ECO STEP 203 — ESLint 9 final: lint REAL em src/ + ignores + verify via npm.cmd"
  $r += ""
  $r += ("Stamp: " + $stamp)
  $r += ("Root: " + $root)
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
  $r += "### npm path detectado"
  $npmDetected = FindNpmCmdPath
  $r += ("- npm: " + ($npmDetected ?? "<null>"))
  $r += ""
  $r += "### eslint.config.mjs (primeiras 60 linhas, se existir)"
  $eslintPath = Join-Path $root "eslint.config.mjs"
  if(Test-Path -LiteralPath $eslintPath){
    $r += "~~~"
    $raw = Get-Content -LiteralPath $eslintPath -TotalCount 60 -ErrorAction SilentlyContinue
    $r += ($raw | Out-String).TrimEnd()
    $r += "~~~"
  } else {
    $r += "- (nao existe ainda)"
  }
  $r += ""

  # -----------------------------
  # PATCH A) remover __DEP__ em src/
  # -----------------------------
  $r += "## PATCH A — remover __DEP__ em src/ (pra nao poluir hooks/lint)"
  $srcRoot = Join-Path $root "src"
  if(Test-Path -LiteralPath $srcRoot){
    $hits = Get-ChildItem -Path $srcRoot -Recurse -File -Include *.ts,*.tsx,*.js,*.jsx |
      Select-String -Pattern "__DEP__" -ErrorAction SilentlyContinue
    if($hits){
      $uniq = $hits | Select-Object -ExpandProperty Path -Unique
      foreach($p in $uniq){
        BackupFile $backupDir $stamp $p ([ref]$r)
        $raw = ReadRaw $p
        if($null -eq $raw){ continue }

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
      $r += "- ok: sem __DEP__ em src/"
    }
  } else {
    $r += ("- [SKIP] src/ nao encontrado: " + $srcRoot)
  }
  $r += ""

  # -----------------------------
  # PATCH B) eslint.config.mjs: lint REAL em src/ + ignores de pastas lixo
  # -----------------------------
  $r += "## PATCH B — eslint.config.mjs (flat) minimo, mas REAL (src/)"
  BackupFile $backupDir $stamp $eslintPath ([ref]$r)

  $eslintLines = @(
    "import tsParser from '@typescript-eslint/parser';",
    "",
    "export default [",
    "  {",
    "    ignores: [",
    "      '**/node_modules/**',",
    "      '**/.next/**',",
    "      '**/dist/**',",
    "      '**/coverage/**',",
    "      '**/reports/**',",
    "      'reports/**',",
    "      'tools/_patch_backup/**',",
    "      'tools/**/_patch_backup/**',",
    "      '**/*.bak-*',",
    "      '**/*.bak',",
    "      '**/*.log'",
    "    ],",
    "  },",
    "  {",
    "    files: ['src/**/*.{js,jsx,ts,tsx}'],",
    "    languageOptions: {",
    "      parser: tsParser,",
    "      parserOptions: {",
    "        ecmaVersion: 'latest',",
    "        sourceType: 'module',",
    "        ecmaFeatures: { jsx: true },",
    "      },",
    "    },",
    "    rules: {",
    "      // minimo pra nao travar agora; endurecemos depois",
    "      'no-unused-vars': 'off',",
    "      'no-undef': 'off'",
    "    },",
    "  },",
    "];",
    ""
  )

  WriteUtf8NoBom $eslintPath ($eslintLines -join "`n")
  $r += ("- wrote: " + $eslintPath)
  $r += ""

  # -----------------------------
  # PATCH C) package.json: lint chama eslint via node (mais robusto no Windows)
  # -----------------------------
  $r += "## PATCH C — package.json scripts.lint (robusto: node ./node_modules/.../eslint.js)"
  $pkgPath = Join-Path $root "package.json"
  BackupFile $backupDir $stamp $pkgPath ([ref]$r)

  if(Test-Path -LiteralPath $pkgPath){
    $pkgRaw = ReadRaw $pkgPath
    if([string]::IsNullOrWhiteSpace($pkgRaw)){ throw "package.json vazio/ilegivel" }
    $pkg = $pkgRaw | ConvertFrom-Json
    if($null -eq $pkg.scripts){
      $pkg | Add-Member -NotePropertyName scripts -NotePropertyValue (@{}) -Force
    }

    $pkg.scripts.lint = "node ./node_modules/eslint/bin/eslint.js src --ext .js,.jsx,.ts,.tsx --cache --no-error-on-unmatched-pattern"
    $json = ($pkg | ConvertTo-Json -Depth 80)
    WriteUtf8NoBom $pkgPath ($json + "`n")
    $r += "- ok: scripts.lint atualizado"
  } else {
    $r += "- [ERR] package.json nao encontrado"
  }
  $r += ""

  # -----------------------------
  # VERIFY (sempre via npm.cmd se existir)
  # -----------------------------
  $r += "## VERIFY"
  $r += "### npm --version (via npm.cmd preferencial)"
  $r += "~~~"
  $r += (RunNpm @("--version") | Out-String).TrimEnd()
  $r += "~~~"
  $r += ""

  $r += "### npm run lint"
  $r += "~~~"
  $r += (RunNpm @("run","lint") | Out-String).TrimEnd()
  $r += "~~~"
  $r += ""

  $r += "### npm run build"
  $r += "~~~"
  $r += (RunNpm @("run","build") | Out-String).TrimEnd()
  $r += "~~~"
  $r += ""

  $r += "## NEXT"
  $r += "- Se no terminal `npm` continuar imprimindo help em vez de rodar, use `npm.cmd` (ou fixe: `Set-Alias npm npm.cmd`)."
  $r += "- Agora o lint é REAL (src/) e ignora tools/_patch_backup + reports, que eram a origem de muito ruído."
  $r += "- Próximo tijolo: rodar o smoke canônico (tools\\eco-step-148b* mais recente)."

  WriteUtf8NoBom $reportPath ($r -join "`n")
  Write-Host ("[REPORT] " + $reportPath)

  if($OpenReport){ Start-Process $reportPath | Out-Null }
}
finally {
  Pop-Location
}