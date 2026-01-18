param(
  [string]$Root = (Get-Location).Path
)

$ts = Get-Date -Format "yyyyMMdd-HHmmss"

$boot = Join-Path $Root "tools/_bootstrap.ps1"
if (Test-Path -LiteralPath $boot) { . $boot }

if (-not (Get-Command EnsureDir -ErrorAction SilentlyContinue)) {
  function EnsureDir([string]$p) { if (-not (Test-Path -LiteralPath $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null } }
}
if (-not (Get-Command WriteUtf8NoBom -ErrorAction SilentlyContinue)) {
  function WriteUtf8NoBom([string]$p, [string]$content) {
    EnsureDir (Split-Path -Parent $p)
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($p, $content, $enc)
  }
}
if (-not (Get-Command BackupFile -ErrorAction SilentlyContinue)) {
  function BackupFile([string]$root, [string]$p, [string]$backupDir) {
    if (Test-Path -LiteralPath $p) {
      $rel = $p.Substring($root.Length).TrimStart('\','/')
      $dest = Join-Path $backupDir ($rel -replace '[\\/]', '__')
      Copy-Item -Force -LiteralPath $p -Destination $dest
      Write-Host ('[BK] ' + $rel + ' -> ' + (Split-Path -Leaf $dest))
    }
  }
}

Write-Host ('== eco-step-86b-confirmado-badge-ui-smart-v0_1 == ' + $ts)
Write-Host ('[DIAG] Root: ' + $Root)

$barFile = Join-Path $Root 'src/app/eco/_components/PointActionBar.tsx'
if (-not (Test-Path -LiteralPath $barFile)) {
  throw "[STOP] Nao achei: src/app/eco/_components/PointActionBar.tsx"
}

$backupDir = Join-Path $Root ('tools/_patch_backup/' + $ts + '-eco-step-86b-confirmado-badge-ui-smart-v0_1')
$reportDir = Join-Path $Root 'reports'
EnsureDir $backupDir
EnsureDir $reportDir

BackupFile $Root $barFile $backupDir

$raw = [System.IO.File]::ReadAllText($barFile)
if (-not $raw) { throw "[STOP] Falha ao ler PointActionBar.tsx" }

if ($raw -match 'Confirmado por' -or $raw -match '✅\s*Confirmado') {
  Write-Host "[OK] Ja tem badge de confirmado no arquivo. Nada a fazer."
  exit 0
}

$lines = $raw -split "`n"

# localizar inicio da funcao/componente
$start = -1
for ($i=0; $i -lt $lines.Length; $i++) {
  $ln = $lines[$i]
  if ($ln -match 'export\s+function\s+PointActionBar\b' -or
      $ln -match 'function\s+PointActionBar\b' -or
      $ln -match 'export\s+const\s+PointActionBar\b' -or
      $ln -match 'const\s+PointActionBar\b') {
    $start = $i
    break
  }
}
if ($start -lt 0) { throw "[STOP] Nao achei definicao de PointActionBar no arquivo." }

# achar primeiro "return (" depois do start
$idxReturn = -1
for ($i=($start+1); $i -lt $lines.Length; $i++) {
  if ($lines[$i] -match '^\s*return\s*\(') { $idxReturn = $i; break }
}
if ($idxReturn -lt 0) { throw "[STOP] Nao achei 'return (' dentro do PointActionBar." }

# segment para procurar origem do contador
$seg = ($lines[$start..($idxReturn-1)] -join "`n")

# 1) procurar algo do tipo getCount("confirm") ou count("confirm")
$confirmExpr = $null

$m = [regex]::Match($seg, 'getCount\s*\(\s*["'']confirm[^"'']*["'']\s*\)', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
if ($m.Success) { $confirmExpr = $m.Value }

if (-not $confirmExpr) {
  $m2 = [regex]::Match($seg, '\bcount\s*\(\s*["'']confirm[^"'']*["'']\s*\)', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
  if ($m2.Success) { $confirmExpr = $m2.Value }
}

# 2) procurar padroes de objeto: X?.counts?.confirm / X.counts.confirm / X?.confirm / X.confirm
$countsExpr = $null

if (-not $confirmExpr) {
  $m3 = [regex]::Match($seg, '([A-Za-z_][A-Za-z0-9_]*)\s*\?\.\s*counts\s*\?\.\s*(confirmCount|confirm|confirmar|seen|ok)\b', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
  if ($m3.Success) { $countsExpr = ($m3.Groups[1].Value + '?.counts') }

  if (-not $countsExpr) {
    $m4 = [regex]::Match($seg, '([A-Za-z_][A-Za-z0-9_]*)\s*\.\s*counts\s*\.\s*(confirmCount|confirm|confirmar|seen|ok)\b', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if ($m4.Success) { $countsExpr = ($m4.Groups[1].Value + '.counts') }
  }

  if (-not $countsExpr) {
    $m5 = [regex]::Match($seg, '([A-Za-z_][A-Za-z0-9_]*)\s*\?\.\s*(confirmCount|confirm|confirmar|seen|ok)\b', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if ($m5.Success) { $countsExpr = $m5.Groups[1].Value }
  }

  if (-not $countsExpr) {
    $m6 = [regex]::Match($seg, '([A-Za-z_][A-Za-z0-9_]*)\s*\.\s*(confirmCount|confirm|confirmar|seen|ok)\b', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if ($m6.Success) { $countsExpr = $m6.Groups[1].Value }
  }
}

if ($confirmExpr) {
  Write-Host ('[DIAG] Found confirmExpr: ' + $confirmExpr)
} elseif ($countsExpr) {
  Write-Host ('[DIAG] Found countsExpr: ' + $countsExpr)
} else {
  throw "[STOP] Nao consegui inferir origem do contador de Confirmar no PointActionBar. Cole o conteudo do arquivo aqui que eu ajusto manualmente."
}

# inserir calculo antes do return
$calc = New-Object System.Collections.Generic.List[string]
if ($confirmExpr) {
  $calc.Add('  const confirmN = Number(' + $confirmExpr + ') || 0;')
} else {
  $calc.Add('  const __counts: any = (' + $countsExpr + ' as any);')
  $calc.Add('  const confirmN = Number(')
  $calc.Add('    __counts?.confirmCount ??')
  $calc.Add('    __counts?.confirm ??')
  $calc.Add('    __counts?.CONFIRM ??')
  $calc.Add('    __counts?.confirmar ??')
  $calc.Add('    __counts?.CONFIRMAR ??')
  $calc.Add('    __counts?.seen ??')
  $calc.Add('    __counts?.ok ??')
  $calc.Add('    __counts?.OK ??')
  $calc.Add('    0')
  $calc.Add('  ) || 0;')
}

# evitar duplicar se rodar 2x
$seg2 = ($lines[$start..($idxReturn-1)] -join "`n")
if ($seg2 -match 'const\s+confirmN\b') {
  Write-Host "[OK] confirmN ja existe. Pulando insercao de calculo."
} else {
  $newA = New-Object System.Collections.Generic.List[string]
  for ($i=0; $i -lt $lines.Length; $i++) {
    if ($i -eq $idxReturn) {
      foreach ($s in $calc) { $newA.Add($s) }
      $newA.Add('') | Out-Null
    }
    $newA.Add($lines[$i])
  }
  $lines = $newA.ToArray()
}

# re-acha return e container raiz para inserir o badge
$raw2 = ($lines -join "`n")
$lines2 = $raw2 -split "`n"

$idxReturn2 = -1
for ($i=($start+1); $i -lt $lines2.Length; $i++) {
  if ($lines2[$i] -match '^\s*return\s*\(') { $idxReturn2 = $i; break }
}
if ($idxReturn2 -lt 0) { throw "[STOP] Nao achei return apos inserir calc." }

$idxWrap = -1
$maxLook = [Math]::Min($lines2.Length - 1, $idxReturn2 + 80)
for ($i=($idxReturn2+1); $i -le $maxLook; $i++) {
  $t = $lines2[$i].TrimStart()
  if ($t.StartsWith('<div') -and ($lines2[$i] -notmatch '</div>')) { $idxWrap = $i; break }
  if ($t.StartsWith('<section') -and ($lines2[$i] -notmatch '</section>')) { $idxWrap = $i; break }
}
if ($idxWrap -lt 0) { throw "[STOP] Nao achei container raiz (<div>/<section>) no return." }

$indent = ($lines2[$idxWrap] -replace '(^\s*).*','$1')
$indent2 = $indent + '  '

$badge = @(
  $indent2 + '{confirmN > 0 ? (',
  $indent2 + '  <div style={{ fontSize: 12, fontWeight: 950, opacity: 0.9 }}>',
  $indent2 + '    ✅ Confirmado por {confirmN} pessoas',
  $indent2 + '  </div>',
  $indent2 + ') : null}'
)

# nao duplicar badge
if ($raw2 -match '✅\s*Confirmado\s+por') {
  Write-Host "[OK] Badge ja existe. Nada a fazer."
} else {
  $newB = New-Object System.Collections.Generic.List[string]
  for ($i=0; $i -lt $lines2.Length; $i++) {
    $newB.Add($lines2[$i])
    if ($i -eq $idxWrap) {
      foreach ($s in $badge) { $newB.Add($s) }
    }
  }
  $lines2 = $newB.ToArray()
}

WriteUtf8NoBom $barFile ($lines2 -join "`n")
Write-Host "[PATCH] Badge de confirmado inserido no PointActionBar.tsx"

# REPORT
$rep = Join-Path $reportDir ('eco-step-86b-confirmado-badge-ui-smart-v0_1-' + $ts + '.md')
$r = @(
'# eco-step-86b-confirmado-badge-ui-smart-v0_1',
'',
'- Time: ' + $ts,
'- Backup: ' + $backupDir,
'- File: ' + $barFile,
'',
'## What',
'- UI-only: exibe "✅ Confirmado por X pessoas" no card quando Confirmar > 0',
'- Detecao automatica da origem do contador dentro do PointActionBar',
'',
'## Verify',
'1) Ctrl+C -> npm run dev',
'2) /eco/mural',
'3) Clique ✅ Confirmar em um ponto',
'4) Deve aparecer o badge no card; F5 deve manter'
)
WriteUtf8NoBom $rep ($r -join "`n")
Write-Host ('[REPORT] ' + $rep)

Write-Host ""
Write-Host "[VERIFY] Ctrl+C -> npm run dev"
Write-Host "[VERIFY] /eco/mural -> clique ✅ Confirmar -> veja o badge no card"