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

Write-Host ('== eco-step-86-confirmado-badge-ui-v0_1 == ' + $ts)
Write-Host ('[DIAG] Root: ' + $Root)

$src = Join-Path $Root 'src'
if (-not (Test-Path -LiteralPath $src)) { throw "[STOP] Nao achei src/" }

$backupDir = Join-Path $Root ('tools/_patch_backup/' + $ts + '-eco-step-86-confirmado-badge-ui-v0_1')
$reportDir = Join-Path $Root 'reports'
EnsureDir $backupDir
EnsureDir $reportDir

function ReadText([string]$p) {
  if (-not (Test-Path -LiteralPath $p)) { return $null }
  return [System.IO.File]::ReadAllText($p)
}

function WriteLines([string]$p, [string[]]$lines) {
  WriteUtf8NoBom $p ($lines -join "`n")
}

function PickPointActionBarFile([string]$root) {
  $cands = @()

  $files = Get-ChildItem -LiteralPath (Join-Path $root 'src') -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Extension -in @('.ts','.tsx') }

  foreach ($f in $files) {
    $name = $f.Name.ToLowerInvariant()
    if ($name -like '*pointactionbar*') {
      $cands += $f.FullName
      continue
    }
    $raw = ReadText $f.FullName
    if (-not $raw) { continue }
    if ($raw -match 'PointActionBar' -and ($raw -match 'export\s+function\s+PointActionBar' -or $raw -match 'function\s+PointActionBar' -or $raw -match 'const\s+PointActionBar')) {
      $cands += $f.FullName
    }
  }

  if (-not $cands -or $cands.Count -eq 0) { return $null }

  # rank: prefer tsx with pointId + compact
  $best = $null
  $bestScore = -1
  foreach ($p in $cands) {
    $raw = ReadText $p
    if (-not $raw) { continue }
    $score = 0
    if ($p.ToLowerInvariant().EndsWith('.tsx')) { $score += 2 }
    if ($raw.Contains('pointId')) { $score += 8 }
    if ($raw.Contains('compact')) { $score += 4 }
    if ($raw.Contains('/api/eco/points')) { $score += 6 }
    if ($raw.Contains('/api/eco/actions')) { $score += 6 }
    if ($raw -match 'use client') { $score += 3 }
    if ($score -gt $bestScore) { $bestScore = $score; $best = $p }
  }

  return $best
}

$barFile = PickPointActionBarFile $Root
if (-not $barFile) { throw "[STOP] Nao achei PointActionBar no repo." }

Write-Host ('[DIAG] PointActionBar: ' + $barFile)

BackupFile $Root $barFile $backupDir
$raw = ReadText $barFile
if (-not $raw) { throw "[STOP] Falha ao ler: $barFile" }

if ($raw.Contains('Confirmado por') -or $raw.Contains('confirmado por')) {
  Write-Host "[OK] Ja tem badge 'Confirmado por' no PointActionBar. Nada a fazer."
} else {
  $lines = $raw -split "`n"

  # 1) detectar como pegar "counts" sem referenciar variavel inexistente
  $hasCountsVar = $false
  if ($raw -match 'const\s+\[\s*counts\b' -or $raw -match 'const\s+counts\b') { $hasCountsVar = $true }

  $hasDataVar = $false
  if ($raw -match 'const\s+\[\s*data\b' -or $raw -match 'const\s+data\b') { $hasDataVar = $true }

  $countsExpr = $null
  if ($hasCountsVar) { $countsExpr = 'counts' }
  elseif ($hasDataVar -and $raw.Contains('.counts')) { $countsExpr = 'data?.counts' }
  else { $countsExpr = $null }

  if (-not $countsExpr) {
    Write-Host "[DIAG] Nao detectei var counts/data. Vou tentar inferir via 'state?.counts' se existir."
    if ($raw -match 'const\s+\[\s*state\b' -or $raw -match 'const\s+state\b') {
      if ($raw.Contains('.counts')) { $countsExpr = 'state?.counts' }
    }
  }

  if (-not $countsExpr) {
    throw "[STOP] Nao consegui detectar onde ficam os contadores no PointActionBar (counts/data/state). Cola aqui o arquivo pra eu ajustar."
  }

  Write-Host ('[DIAG] countsExpr: ' + $countsExpr)

  # 2) inserir bloco de cálculo ANTES do return(
  $idxReturn = -1
  for ($i=0; $i -lt $lines.Length; $i++) {
    if ($lines[$i] -match '^\s*return\s*\(') { $idxReturn = $i; break }
  }
  if ($idxReturn -lt 0) { throw "[STOP] Nao achei 'return (' no PointActionBar." }

  # evita duplicar caso ja exista __counts/confirmN
  $already = $raw.Contains('const __counts') -or $raw.Contains('const confirmN')
  if (-not $already) {
    $calc = @(
'  const __counts: any = ' + $countsExpr + ' as any;',
'  const confirmN = Number(',
'    __counts?.confirmCount ??',
'    __counts?.confirm ??',
'    __counts?.CONFIRM ??',
'    __counts?.confirmar ??',
'    __counts?.CONFIRMAR ??',
'    __counts?.seen ??',
'    __counts?.ok ??',
'    __counts?.OK ??',
'    0',
'  ) || 0;'
    )

    $new = New-Object System.Collections.Generic.List[string]
    for ($i=0; $i -lt $lines.Length; $i++) {
      if ($i -eq $idxReturn) {
        foreach ($s in $calc) { $new.Add($s) }
        $new.Add('') | Out-Null
      }
      $new.Add($lines[$i])
    }
    $lines = $new.ToArray()
    $raw2 = $lines -join "`n"
  } else {
    $raw2 = $raw
  }

  # 3) inserir badge JSX logo após o container raiz do return
  $lines2 = $raw2 -split "`n"
  $idxReturn2 = -1
  for ($i=0; $i -lt $lines2.Length; $i++) {
    if ($lines2[$i] -match '^\s*return\s*\(') { $idxReturn2 = $i; break }
  }
  if ($idxReturn2 -lt 0) { throw "[STOP] Nao achei return apos patch." }

  $idxWrap = -1
  $maxLook = [Math]::Min($lines2.Length - 1, $idxReturn2 + 60)
  for ($i=($idxReturn2+1); $i -le $maxLook; $i++) {
    $ln = $lines2[$i].TrimStart()
    if ($ln.StartsWith('<div') -and ($lines2[$i] -notmatch '</div>')) { $idxWrap = $i; break }
    if ($ln.StartsWith('<section') -and ($lines2[$i] -notmatch '</section>')) { $idxWrap = $i; break }
  }
  if ($idxWrap -lt 0) { throw "[STOP] Nao achei container raiz (<div>/<section>) no retorno." }

  $indent = ($lines2[$idxWrap] -replace '(^\s*).*','$1')
  $indent2 = $indent + '  '

  $badge = @(
$indent2 + '{confirmN > 0 ? (',
$indent2 + '  <div style={{ fontSize: 12, fontWeight: 950, opacity: 0.9 }}>',
$indent2 + '    ✅ Confirmado por {confirmN} pessoas',
$indent2 + '  </div>',
$indent2 + ') : null}'
  )

  $new3 = New-Object System.Collections.Generic.List[string]
  for ($i=0; $i -lt $lines2.Length; $i++) {
    $new3.Add($lines2[$i])
    if ($i -eq $idxWrap) {
      foreach ($s in $badge) { $new3.Add($s) }
    }
  }

  WriteLines $barFile $new3.ToArray()
  Write-Host "[PATCH] PointActionBar agora exibe badge '✅ Confirmado por X pessoas' quando confirmN > 0"
}

# ---- REPORT ----
$rep = Join-Path $reportDir ('eco-step-86-confirmado-badge-ui-v0_1-' + $ts + '.md')
$repLines = @(
'# eco-step-86-confirmado-badge-ui-v0_1',
'',
'- Time: ' + $ts,
'- Backup: ' + $backupDir,
'- File: ' + $barFile,
'',
'## What',
'- UI-only: mostra "✅ Confirmado por X pessoas" no PointActionBar quando contador de Confirmar > 0',
'- Sem schema/migration',
'',
'## Verify',
'1) Ctrl+C -> npm run dev',
'2) Abra /eco/mural',
'3) Clique em ✅ Confirmar num ponto',
'4) Veja aparecer "✅ Confirmado por 1 pessoas" (ou mais)',
'5) F5: deve persistir (contagem vem do backend)',
'',
'## Fallback',
'- /eco/mural-acoes continua valido'
)
WriteUtf8NoBom $rep ($repLines -join "`n")
Write-Host ('[REPORT] ' + $rep)

Write-Host ""
Write-Host "[VERIFY] Ctrl+C -> npm run dev"
Write-Host "[VERIFY] /eco/mural -> clique ✅ Confirmar -> veja o badge no card"