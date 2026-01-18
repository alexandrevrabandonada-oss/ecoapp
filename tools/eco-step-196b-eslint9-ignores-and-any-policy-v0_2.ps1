#requires -Version 7.0
param([switch]$OpenReport)

$ErrorActionPreference = 'Stop'
$root = (Get-Location).Path

function EnsureDir([string]$p){
  if([string]::IsNullOrWhiteSpace($p)){ return }
  if(!(Test-Path $p)){ New-Item -ItemType Directory -Path $p | Out-Null }
}
function WriteUtf8NoBom([string]$path, [string]$text){
  [IO.File]::WriteAllText($path, $text, [Text.UTF8Encoding]::new($false))
}
function BackupFile([string]$src, [string]$backupPath){
  EnsureDir (Split-Path $backupPath -Parent)
  Copy-Item -Force $src $backupPath
}

$stamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
$reportPath = Join-Path $root ('reports\eco-step-196b-eslint9-ignores-anypolicy-' + $stamp + '.md')
EnsureDir (Split-Path $reportPath -Parent)

$r = @()
$r += ('# eco-step-196b — eslint9 ignores + any policy — ' + $stamp)
$r += ''
$r += '## DIAG'
$r += ('- root: ' + $root)

$cfg = Join-Path $root 'eslint.config.mjs'
if(!(Test-Path $cfg)){
  throw ('Nao achei eslint.config.mjs em: ' + $cfg)
}
$r += ('- eslint.config.mjs: ' + $cfg)

$raw = Get-Content -Raw -Encoding UTF8 $cfg
$r += ('- tamanho: ' + $raw.Length + ' chars')

# Mostra as linhas que ajudam a entender o formato (sem quebrar o PS)
$r += ''
$r += '### pistas (export default / const)'
$hits = (Select-String -Path $cfg -Pattern 'export default|const\s+\w+\s*=\s*\[|let\s+\w+\s*=\s*\[|var\s+\w+\s*=\s*\[' -SimpleMatch:$false | Select-Object -First 12)
if($hits){
  foreach($h in $hits){ $r += ('- ' + $h.Line.Trim()) }
}else{
  $r += '- (nenhuma linha encontrada; arquivo pode estar bem diferente)'
}

# --- PATCH ---
$r += ''
$r += '## PATCH'
$backup = Join-Path $root ('tools\_patch_backup\eslint.config.mjs--' + $stamp)
BackupFile $cfg $backup
$r += ('- backup: ' + $backup)

$changed = $false

# Ignorar backups + pastas de build
$ignoreObj = @(
'  // ECO_STEP196B_IGNORES',
'  {',
'    ignores: [',
'      "**/tools/_patch_backup/**",',
'      "**/reports/**",',
'      "**/.next/**",',
'      "**/node_modules/**",',
'      "**/dist/**",',
'      "**/.turbo/**",',
'      "**/.vercel/**",',
'      "**/out/**",',
'      "**/*.bak-*",',
'      "**/*.bak"',
'    ]',
'  },'
) -join "`n"

if($raw -notmatch 'ECO_STEP196B_IGNORES'){
  # Tentativa A: export default [
  if([regex]::IsMatch($raw, 'export\s+default\s*\[')){
    $raw = [regex]::Replace($raw, 'export\s+default\s*\[', ('export default [' + "`n" + $ignoreObj), 1)
    $changed = $true
    $r += '- inseriu ignores apos: export default ['
  }
  else {
    # Tentativa B: export default IDENT
    $m = [regex]::Match($raw, 'export\s+default\s+([A-Za-z0-9_]+)\s*;?')
    if($m.Success){
      $id = $m.Groups[1].Value
      $pat = '(const|let|var)\s+' + [regex]::Escape($id) + '\s*=\s*\['
      if([regex]::IsMatch($raw, $pat)){
        $raw = [regex]::Replace($raw, $pat, ('$1 ' + $id + ' = [' + "`n" + $ignoreObj), 1)
        $changed = $true
        $r += ('- inseriu ignores apos: ' + $id + ' = [')
      } else {
        $r += ('- WARN: achei export default ' + $id + ', mas nao achei declaracao ' + $id + ' = [')
      }
    } else {
      $r += '- WARN: nao achei padrao export default [...] nem export default IDENT'
    }
  }
} else {
  $r += '- ignores: ja existe (marker encontrado)'
}

# Any policy: relaxa any para destravar (e desliga em API)
$anyPolicy = @(
'',
'  // ECO_STEP196B_ANY_POLICY',
'  {',
'    files: ["src/**/*.{ts,tsx}"],',
'    rules: {',
'      "@typescript-eslint/no-explicit-any": "warn"',
'    }',
'  },',
'  {',
'    files: ["src/app/api/**/*.{ts,tsx}"],',
'    rules: {',
'      "@typescript-eslint/no-explicit-any": "off"',
'    }',
'  }'
) -join "`n"

if($raw -notmatch 'ECO_STEP196B_ANY_POLICY'){
  $mEnd = [regex]::Match(
    $raw,
    '\]\s*;?',
    [System.Text.RegularExpressions.RegexOptions]::RightToLeft
  )
  if(!$mEnd.Success){
    throw 'Nao consegui localizar o fechamento do array principal ("];" ou "]").'
  }
  $insertAt = $mEnd.Index
  $raw = $raw.Substring(0,$insertAt) + $anyPolicy + "`n" + $raw.Substring($insertAt)
  $changed = $true
  $r += '- inseriu any policy antes do fechamento do array'
} else {
  $r += '- any policy: ja existe (marker encontrado)'
}

if($changed){
  WriteUtf8NoBom $cfg $raw
  $r += '- escreveu eslint.config.mjs'
} else {
  $r += '- nenhuma mudanca aplicada (talvez ja esteja tudo ok)'
}

# --- VERIFY ---
$r += ''
$r += '## VERIFY'
$r += '- rodando: npm run lint (primeiras 120 linhas)'

try{
  $out = (npm run lint 2>&1 | Select-Object -First 120)
  $exit = $LASTEXITCODE
  $r += ('- exit: ' + $exit)
  $r += ''
  $r += '---'
  foreach($line in $out){ $r += $line }
} catch {
  $r += ('- lint falhou ao executar: ' + $_.Exception.Message)
}

WriteUtf8NoBom $reportPath ($r -join "`n")
Write-Host ('[REPORT] ' + $reportPath)

if($OpenReport){
  Start-Process $reportPath | Out-Null
}