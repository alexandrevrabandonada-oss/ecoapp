param([string]$Root = (Get-Location).Path)

$ts = Get-Date -Format "yyyyMMdd-HHmmss"
Write-Host ("== eco-step-102-fix-pointid-bareidentifiers-v0_1 == " + $ts)
Write-Host ("[DIAG] Root: " + $Root)

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

function FixByArray([string]$raw, [string]$field) {
  $esc = [regex]::Escape($field)
  $pat = '(?ms)(\bby\s*:\s*\[\s*)' + $esc + '(\s*\])'
  return [regex]::Replace($raw, $pat, { param($m) $m.Groups[1].Value + '"' + $field + '"' + $m.Groups[2].Value })
}

function FixOptBracket([string]$raw, [string]$field) {
  $esc = [regex]::Escape($field)
  # ?. [ field ]  -> ?.["field"]
  $pat = '(?m)\?\.\s*\[\s*' + $esc + '\s*\]'
  return [regex]::Replace($raw, $pat, { param($m) '?.["' + $field + '"]' })
}

function FixBracketPlain([string]$raw, [string]$field) {
  $esc = [regex]::Escape($field)
  # [ field ]  -> ["field"]  (SO quando parece "by: [field]" já cobre; aqui cobre acessos tipo pc[pointId])
  $pat = '(?m)(\[\s*)' + $esc + '(\s*\])'
  return [regex]::Replace($raw, $pat, { param($m) $m.Groups[1].Value + '"' + $field + '"' + $m.Groups[2].Value })
}

$backupDir = Join-Path $Root ("tools/_patch_backup/" + $ts + "-eco-step-102-fix-pointid-bareidentifiers-v0_1")
$reportDir = Join-Path $Root "reports"
EnsureDir $backupDir
EnsureDir $reportDir

# 0) (Opcional) conserta Prisma relation do EcoPointSupport (não muda DB; só schema)
$schema = Join-Path $Root "prisma/schema.prisma"
$schemaTouched = $false
if (Test-Path -LiteralPath $schema) {
  $sraw = Get-Content -LiteralPath $schema -Raw
  if ($sraw -match 'model\s+EcoPointSupport\s*\{') {
    # tenta descobrir o nome do model referenciado em "point <ModelName> @relation"
    $refModel = $null
    $mm = [regex]::Match($sraw, 'model\s+EcoPointSupport\s*\{(?s).*?\bpoint\s+([A-Za-z_][A-Za-z0-9_]*)\s+@relation', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    if ($mm.Success) { $refModel = $mm.Groups[1].Value }

    if ($refModel) {
      $modelPat = 'model\s+' + [regex]::Escape($refModel) + '\s*\{'
      if ($sraw -match $modelPat) {
        # se o model alvo não tem nenhum campo EcoPointSupport[] ainda, injeta "supports EcoPointSupport[]"
        if ($sraw -notmatch ('model\s+' + [regex]::Escape($refModel) + '\s*\{(?s).*?\bEcoPointSupport\[\]')) {
          BackupFile $Root $schema $backupDir
          $lines = $sraw -split "`n"
          $out = New-Object System.Collections.Generic.List[string]

          $inTarget = $false
          $inserted = $false

          for ($i=0; $i -lt $lines.Count; $i++) {
            $ln = $lines[$i]
            if ($ln -match ('^\s*model\s+' + [regex]::Escape($refModel) + '\s*\{')) { $inTarget = $true }

            if ($inTarget -and (-not $inserted) -and ($ln -match '^\s*\}')) {
              # antes do } do model alvo
              $out.Add('  supports  EcoPointSupport[]')
              $inserted = $true
              $schemaTouched = $true
            }

            $out.Add($ln)

            if ($inTarget -and ($ln -match '^\s*\}')) { $inTarget = $false }
          }

          if ($schemaTouched) {
            WriteUtf8NoBom $schema ($out -join "`n")
            Write-Host ('[PATCH] schema.prisma: added opposite relation in ' + $refModel + ' (supports EcoPointSupport[])')
          }
        } else {
          Write-Host ('[SKIP] schema.prisma: ' + $refModel + ' already has EcoPointSupport[] relation')
        }
      }
    }
  }
}

# 1) varre e corrige usos perigosos (by: [pointId], pc?.[pointId], etc)
$files = Get-ChildItem -Path (Join-Path $Root "src") -Recurse -File -Include *.ts,*.tsx | Where-Object {
  $_.FullName -match '\\src\\app\\eco\\' -or $_.FullName -match '\\src\\app\\api\\eco\\'
}

Write-Host ('[DIAG] Files scanned: ' + $files.Count)

$changed = New-Object System.Collections.Generic.List[string]
$susp = New-Object System.Collections.Generic.List[string]

$fields = @('pointId','criticalPointId','ecoPointId','ecoCriticalPointId')

foreach ($f in $files) {
  $p = $f.FullName
  $raw = Get-Content -LiteralPath $p -Raw

  $before = $raw

  foreach ($fld in $fields) {
    $raw = FixByArray $raw $fld
    $raw = FixOptBracket $raw $fld
    # só aplica o "bracket plain" se o arquivo parece lidar com prisma-as-any (pc/prisma) — pra não estragar código que usa map[pointId] de verdade
    if ($raw -match '\b(prisma|pc)\b' -and $raw -match '\[\s*' + [regex]::Escape($fld) + '\s*\]') {
      $raw = FixBracketPlain $raw $fld
    }
  }

  if ($raw -ne $before) {
    BackupFile $Root $p $backupDir
    WriteUtf8NoBom $p $raw
    $rel = $p.Substring($Root.Length).TrimStart('\','/')
    $changed.Add($rel)
    Write-Host ('[PATCH] fixed: ' + $rel)
  }
}

# 2) coletar linhas ainda suspeitas (onde aparece pointId "nu" sem ser foo.pointId)
foreach ($f in $files) {
  $p = $f.FullName
  $matches = Select-String -LiteralPath $p -Pattern '\b(pointId|criticalPointId)\b' -AllMatches -ErrorAction SilentlyContinue
  foreach ($m in $matches) {
    $line = $m.Line
    if (-not $line) { continue }

    $hasDot = ($line -match '\.\s*(pointId|criticalPointId)\b')
    $looksBad =
      ($line -match 'by\s*:\s*\[') -or
      ($line -match '\?\.\s*\[') -or
      ($line -match '\[\s*(pointId|criticalPointId)\s*\]') -or
      ($line -match '\{\s*(pointId|criticalPointId)\s*\}') -or
      (($line -match '\b(pointId|criticalPointId)\b') -and (-not $hasDot) -and ($line -match 'groupBy|orderBy|where|select|include|data\s*:'))

    if ($looksBad) {
      $rel = $p.Substring($Root.Length).TrimStart('\','/')
      $susp.Add(($rel + ':' + $m.LineNumber + ' | ' + $line.Trim()))
    }
  }
}

$rep = Join-Path $reportDir ("eco-step-102-fix-pointid-bareidentifiers-v0_1-" + $ts + ".md")
$repLines = New-Object System.Collections.Generic.List[string]
$repLines.Add('# eco-step-102-fix-pointid-bareidentifiers-v0_1')
$repLines.Add('')
$repLines.Add('- Time: ' + $ts)
$repLines.Add('- Backup: ' + $backupDir)
$repLines.Add('')

$repLines.Add('## Patched files')
if ($changed.Count -eq 0) {
  $repLines.Add('- (none)')
} else {
  foreach ($c in $changed) { $repLines.Add('- ' + $c) }
}
$repLines.Add('')

$repLines.Add('## Suspicious remaining lines (review if crash persists)')
if ($susp.Count -eq 0) {
  $repLines.Add('- (none)')
} else {
  foreach ($s in $susp) { $repLines.Add('- ' + $s) }
}
$repLines.Add('')

$repLines.Add('## Verify')
$repLines.Add('1) Ctrl+C -> npm run dev')
$repLines.Add('2) GET http://localhost:3000/api/eco/points/list2?limit=10')
$repLines.Add('3) Abrir /eco/mural/confirmados (sem ReferenceError)')
$repLines.Add('')

WriteUtf8NoBom $rep ($repLines -join "`n")
Write-Host ('[REPORT] ' + $rep)

Write-Host ''
Write-Host '[VERIFY] Ctrl+C -> npm run dev'
Write-Host '[VERIFY] /api/eco/points/list2?limit=10'
Write-Host '[VERIFY] /eco/mural/confirmados'