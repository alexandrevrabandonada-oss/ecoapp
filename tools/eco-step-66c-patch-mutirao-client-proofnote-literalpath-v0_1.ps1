param(
  [string]$Root = (Get-Location).Path
)

$ts = Get-Date -Format 'yyyyMMdd-HHmmss'

# --- bootstrap
$boot = Join-Path $Root "tools/_bootstrap.ps1"
if (Test-Path -LiteralPath $boot) { . $boot }

# --- fallbacks
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

$backupDir = Join-Path $Root ('tools/_patch_backup/' + $ts + '-eco-step-66c-patch-mutirao-client-proofnote-literalpath-v0_1')
$reportDir = Join-Path $Root 'reports'
EnsureDir $backupDir
EnsureDir $reportDir

Write-Host ('== eco-step-66c-patch-mutirao-client-proofnote-literalpath-v0_1 == ' + $ts)
Write-Host ('[DIAG] Root: ' + $Root)

$src = Join-Path $Root 'src'
if (-not (Test-Path -LiteralPath $src)) { throw ('[STOP] Não achei src/: ' + $src) }

# --- gather candidates (nome)
$cands = @(Get-ChildItem -LiteralPath $src -Recurse -File -Include *.tsx,*.ts |
  Where-Object {
    $_.Name -match 'Client\.(tsx|ts)$' -and (
      $_.Name -match 'Mutir' -or $_.FullName -match '\\mutir' -or $_.FullName -match '\\mutiro'
    )
  })

# fallback: por conteúdo (mais caro, mas garante)
if (-not $cands -or $cands.Count -eq 0) {
  Write-Host "[DIAG] Nenhum candidato por nome. Buscando por conteúdo (mutirao + use client)..."
  $all = Get-ChildItem -LiteralPath $src -Recurse -File -Include *.tsx,*.ts |
    Where-Object { $_.Name -match 'Client\.(tsx|ts)$' }
  $tmp = @()
  foreach ($f in $all) {
    $hit1 = $false
    $hit2 = $false
    try {
      $hit1 = Select-String -LiteralPath $f.FullName -Pattern 'mutirao' -Quiet
      $hit2 = Select-String -LiteralPath $f.FullName -Pattern '"use client"' -Quiet
    } catch {}
    if ($hit1 -and $hit2) { $tmp += $f }
  }
  $cands = @($tmp)
}

if (-not $cands -or $cands.Count -eq 0) {
  throw "[STOP] Não encontrei Client Component de mutirão. (nenhum *Client.tsx/ts* com 'mutirao')"
}

function ScoreFile([string]$path) {
  $score = 0
  $p = $path.ToLowerInvariant()

  if ($p -match '\\eco\\') { $score += 2 }
  if ($p -match '\\mutiroe?s\\') { $score += 3 }
  if ($p -match '\\mutiroe?s\\\[id\]\\') { $score += 8 }

  $txt = ""
  try { $txt = Get-Content -Raw -LiteralPath $path } catch { $txt = "" }

  if ($txt -match 'Checklist do mutirão') { $score += 8 }
  if ($txt -match '/api/eco/mutirao') { $score += 6 }
  if ($txt -match 'beforeUrl' -and $txt -match 'afterUrl') { $score += 5 }
  if ($txt -match 'status' -and $txt -match 'DONE') { $score += 2 }
  if ($txt -match 'Finalizar' -or $txt -match 'Concluir') { $score += 1 }

  return @{ score = $score; text = $txt }
}

# rank + pick best
$ranked = @()
foreach ($f in $cands) {
  $r = ScoreFile $f.FullName
  $ranked += [PSCustomObject]@{ Path = $f.FullName; Score = $r.score; }
}
$ranked = $ranked | Sort-Object -Property Score -Descending

Write-Host "[DIAG] Candidates (top 10):"
$ranked | Select-Object -First 10 | ForEach-Object { Write-Host ("  - (" + $_.Score + ") " + $_.Path) }

$bestPath = $ranked[0].Path
if (-not (Test-Path -LiteralPath $bestPath)) { throw "[STOP] bestPath não existe (literal): $bestPath" }

$best = ScoreFile $bestPath
Write-Host ('[DIAG] Selected: ' + $bestPath)
Write-Host ('[DIAG] Score: ' + $best.score)

BackupFile $Root $bestPath $backupDir

$raw = $best.text
if (-not $raw) { $raw = Get-Content -Raw -LiteralPath $bestPath }
if (-not $raw) { throw ('[STOP] arquivo vazio: ' + $bestPath) }

$changed = $false

# 1) proofNote no chkDefault (se existir)
if ($raw -match 'function\s+chkDefault' -and $raw -notmatch 'proofNote') {
  $idxFn = $raw.IndexOf('function chkDefault')
  if ($idxFn -ge 0) {
    $idxRet = $raw.IndexOf('return {', $idxFn)
    if ($idxRet -ge 0) {
      $idxBrace = $raw.IndexOf('{', $idxRet)
      if ($idxBrace -ge 0) {
        $seg = $raw.Substring($idxBrace, [Math]::Min(800, $raw.Length - $idxBrace))
        if ($seg -notmatch 'proofNote') {
          $raw = $raw.Insert($idxBrace + 1, ' proofNote: "",')
          $changed = $true
          Write-Host "[PATCH] chkDefault: injected proofNote"
        }
      }
    }
  }
}

# 2) textarea no bloco do checklist (tenta várias âncoras)
if ($raw -notmatch 'Justificativa \(se faltar foto\)') {
  $anchors = @(
    '<div style={{ fontWeight: 900 }}>Checklist do mutirão</div>',
    'Checklist do mutirão',
    'Checklist'
  )

  $insertBlock =
'        <div style={{ opacity: 0.7, fontSize: 12 }}>Regra: pra finalizar (DONE), precisa ANTES+DEPOIS ou uma justificativa.</div>' + "`n" +
'        <label style={{ display: "grid", gap: 6 }}>' + "`n" +
'          <span>Justificativa (se faltar foto)</span>' + "`n" +
'          <textarea value={String((check as any)?.proofNote || "")} onChange={(e) => setCheck((prev: any) => ({ ...prev, proofNote: e.target.value }))} rows={3} placeholder="Explique por que faltou foto (mín 10 caracteres)..." style={{ padding: 10, borderRadius: 10, border: "1px solid #ccc" }} />' + "`n" +
'        </label>'

  $done = $false
  foreach ($needle in $anchors) {
    $pos = $raw.IndexOf($needle)
    if ($pos -ge 0) {
      # se a âncora for o div completo, substitui; se for texto solto, injeta após a primeira ocorrência
      if ($needle.StartsWith('<div')) {
        $raw = $raw.Replace($needle, $needle + "`n" + $insertBlock)
      } else {
        $raw = $raw.Replace($needle, $needle + "`n" + $insertBlock)
      }
      $changed = $true
      $done = $true
      Write-Host "[PATCH] UI: inserted proofNote textarea (anchor=$needle)"
      break
    }
  }
  if (-not $done) {
    Write-Host "[WARN] Não achei âncora do checklist. (não inseri textarea)"
  }
}

# 3) se já chama /api/eco/mutirao/finish, garante proofNote no body
if ($raw -match '/api/eco/mutirao/finish' -and $raw -notmatch 'proofNote\s*:') {
  $idx = $raw.IndexOf('/api/eco/mutirao/finish')
  if ($idx -ge 0) {
    $jidx = $raw.IndexOf('JSON.stringify(', $idx)
    if ($jidx -ge 0) {
      $bidx = $raw.IndexOf('{', $jidx)
      if ($bidx -ge 0) {
        $look = $raw.Substring($bidx, [Math]::Min(800, $raw.Length - $bidx))
        if ($look -notmatch 'proofNote') {
          $raw = $raw.Insert($bidx + 1, ' proofNote: String((check as any)?.proofNote || ""),')
          $changed = $true
          Write-Host "[PATCH] Finish: injected proofNote into JSON body"
        }
      }
    }
  }
}

if ($changed) {
  WriteUtf8NoBom $bestPath $raw
  Write-Host "[OK] Patched: $bestPath"
} else {
  Write-Host "[OK] Nada pra patchar (já aplicado ou não achei âncoras)."
}

$rep = Join-Path $reportDir ('eco-step-66c-patch-mutirao-client-proofnote-literalpath-v0_1-' + $ts + '.md')
$repLines = @(
'# eco-step-66c-patch-mutirao-client-proofnote-literalpath-v0_1',
'',
'- Time: ' + $ts,
'- Backup: ' + $backupDir,
'- Patched: ' + $bestPath,
'- Score: ' + $best.score,
'',
'## Verify',
'1) restart dev',
'2) abrir /eco/mutiroes/[id]',
'3) procurar textarea "Justificativa (se faltar foto)" no checklist',
'4) finalizar sem antes/depois e sem justificativa => deve dar missing_proof (se UI chama finish)',
''
)
WriteUtf8NoBom $rep ($repLines -join "`n")
Write-Host ('[REPORT] ' + $rep)

Write-Host ''
Write-Host '[VERIFY] Ctrl+C -> npm run dev'
Write-Host '[VERIFY] Abra /eco/mutiroes/[id] e veja o campo "Justificativa".'