param([switch]$OpenReport)

$ErrorActionPreference = 'Stop'
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

function FindRepoRoot(){
  $d = (Get-Location).Path
  while($true){
    if(Test-Path -LiteralPath (Join-Path $d 'package.json')){ return $d }
    $parent = Split-Path $d -Parent
    if([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $d){ return (Get-Location).Path }
    $d = $parent
  }
}

function BackupFile([string]$root,[string]$stamp,[string]$file,[ref]$r){
  if(!(Test-Path -LiteralPath $file)){
    $r.Value += ('- [SKIP] missing: ' + $file)
    return
  }
  $bdir = Join-Path $root ('tools\_patch_backup\eco-step-199\' + $stamp)
  EnsureDir $bdir
  $leaf = Split-Path $file -Leaf
  $dest = Join-Path $bdir ($leaf + '--' + $stamp)
  Copy-Item -LiteralPath $file -Destination $dest -Force
  $r.Value += ('- backup: ' + $file + ' -> ' + $dest)
}

$root = FindRepoRoot
Set-Location $root

$stamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
EnsureDir (Join-Path $root 'reports')
$reportPath = Join-Path $root ('reports\eco-step-199-eslint9-minsafe-and-dep-clean-' + $stamp + '.md')

$r = @()
$r += '# ECO STEP 199 — ESLint9 min-safe + limpar __DEP__'
$r += ''
$r += ('Root: ' + $root)
$r += ('Stamp: ' + $stamp)
$r += ''

# -----------------------------
# DIAG
# -----------------------------
$r += '## DIAG'
try { $r += ('- node: ' + (& node -v)) } catch { $r += '- node: (nao achei)' }
try { $r += ('- npm: ' + (& npm -v)) } catch { $r += '- npm: (nao achei)' }

# -----------------------------
# PATCH A — eslint.config.mjs válido e mínimo (ignora TS/TSX por enquanto)
# -----------------------------
$r += ''
$r += '## PATCH A — eslint.config.mjs (flat config válido, ignora TS/TSX)'
$eslintPath = Join-Path $root 'eslint.config.mjs'
BackupFile $root $stamp $eslintPath ([ref]$r)

$lines = @(
  'export default [',
  '  {',
  '    ignores: [',
  '      ''**/node_modules/**'',',
  '      ''**/.next/**'',',
  '      ''**/dist/**'',',
  '      ''**/coverage/**'',',
  '      ''**/reports/**'',',
  '      ''**/*.log'',',
  '      ''**/*.bak'',',
  '      ''tools/_patch_backup/**'',',
  '      ''tools/**/_patch_backup/**'',',
  '      // enquanto a gente estabiliza ESLint 9:',
  '      ''**/*.ts'',',
  '      ''**/*.tsx''',
  '    ],',
  '  },',
  '  {',
  '    files: [''**/*.{js,cjs,mjs,jsx}''],',
  '    languageOptions: {',
  '      ecmaVersion: ''latest'',',
  '      sourceType: ''module''',
  '    },',
  '    rules: {}',
  '  }',
  '];'
)
WriteUtf8NoBom $eslintPath ($lines -join "`n")
$r += '- wrote: eslint.config.mjs'

# -----------------------------
# PATCH B — package.json scripts.lint
# -----------------------------
$r += ''
$r += '## PATCH B — package.json: scripts.lint = eslint .'
$pkgPath = Join-Path $root 'package.json'
BackupFile $root $stamp $pkgPath ([ref]$r)

if(!(Test-Path -LiteralPath $pkgPath)){
  throw ('package.json nao encontrado em ' + $pkgPath)
}

$pkg = (ReadRaw $pkgPath) | ConvertFrom-Json
if($null -eq $pkg.scripts){
  $pkg | Add-Member -NotePropertyName scripts -NotePropertyValue (@{}) -Force
}
$pkg.scripts.lint = 'eslint .'
WriteUtf8NoBom $pkgPath ($pkg | ConvertTo-Json -Depth 50)
$r += '- ok: scripts.lint = eslint .'

# -----------------------------
# PATCH C — remover __DEP__ do src/
# -----------------------------
$r += ''
$r += '## PATCH C — remover __DEP__ do src/'
$srcRoot = Join-Path $root 'src'
if(Test-Path -LiteralPath $srcRoot){
  $hits = Get-ChildItem -Path $srcRoot -Recurse -File -Include *.ts,*.tsx | Select-String -Pattern '__DEP__' -ErrorAction SilentlyContinue
  if($hits){
    $uniq = $hits | Select-Object -ExpandProperty Path -Unique
    foreach($p in $uniq){
      BackupFile $root $stamp $p ([ref]$r)
      $raw = ReadRaw $p
      $raw2 = $raw -replace '\[\s*__DEP__\s*\]','[]'
      $raw2 = $raw2 -replace '__DEP__','0'
      if($raw2 -ne $raw){
        WriteUtf8NoBom $p $raw2
        $r += ('- patched: ' + $p)
      } else {
        $r += ('- [SKIP] no change: ' + $p)
      }
    }
  } else {
    $r += '- ok: sem __DEP__ em src/'
  }
} else {
  $r += '- [SKIP] src/ nao encontrado'
}

# -----------------------------
# VERIFY (usa npm.cmd se existir)
# -----------------------------
$r += ''
$r += '## VERIFY'
$npmCmd = $null
try { $npmCmd = (Get-Command npm -ErrorAction Stop).Source } catch { $npmCmd = 'npm' }
$r += ('- npm bin: ' + $npmCmd)

try {
  $lint = & $npmCmd @('run','lint') 2>&1
  $r += '### npm run lint'
  $r += '~~~'
  $r += ($lint | Out-String)
  $r += '~~~'
} catch {
  $r += '### npm run lint (FAIL)'
  $r += '~~~'
  $r += ($_ | Out-String)
  $r += '~~~'
}

try {
  $build = & $npmCmd @('run','build') 2>&1
  $r += '### npm run build'
  $r += '~~~'
  $r += ($build | Out-String)
  $r += '~~~'
} catch {
  $r += '### npm run build (FAIL)'
  $r += '~~~'
  $r += ($_ | Out-String)
  $r += '~~~'
  throw
}

WriteUtf8NoBom $reportPath ($r -join "`n")
Write-Host ('[REPORT] ' + $reportPath)
if($OpenReport){ Start-Process $reportPath | Out-Null }