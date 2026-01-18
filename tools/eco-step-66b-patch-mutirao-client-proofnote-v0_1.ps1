param(
  [string]$Root = (Get-Location).Path
)

$ts = Get-Date -Format 'yyyyMMdd-HHmmss'

# --- bootstrap
$boot = Join-Path $Root "tools/_bootstrap.ps1"
if (Test-Path $boot) { . $boot }

# --- fallbacks
if (-not (Get-Command EnsureDir -ErrorAction SilentlyContinue)) {
  function EnsureDir([string]$p) { if (-not (Test-Path $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null } }
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
    if (Test-Path $p) {
      $rel = $p.Substring($root.Length).TrimStart('\','/')
      $dest = Join-Path $backupDir ($rel -replace '[\\/]', '__')
      Copy-Item -Force -LiteralPath $p -Destination $dest
      Write-Host ('[BK] ' + $rel + ' -> ' + (Split-Path -Leaf $dest))
    }
  }
}
function WriteLinesUtf8NoBom([string]$p, [string[]]$lines) { WriteUtf8NoBom $p ($lines -join "`n") }

$backupDir = Join-Path $Root ('tools/_patch_backup/' + $ts + '-eco-step-66b-patch-mutirao-client-proofnote-v0_1')
$reportDir = Join-Path $Root 'reports'
EnsureDir $backupDir
EnsureDir $reportDir

Write-Host ('== eco-step-66b-patch-mutirao-client-proofnote-v0_1 == ' + $ts)
Write-Host ('[DIAG] Root: ' + $Root)

$src = Join-Path $Root 'src'
if (-not (Test-Path $src)) { throw ('[STOP] Não achei src/: ' + $src) }

# --- find candidates
$cands = Get-ChildItem -LiteralPath $src -Recurse -File -Filter *.tsx |
  Where-Object { $_.FullName -match '\\eco\\' -and $_.Name -match 'Mutirao' -and $_.Name -match 'Client\.tsx$' }

if (-not $cands -or $cands.Count -eq 0) {
  # fallback: any mutirao client anywhere
  $cands = Get-ChildItem -LiteralPath $src -Recurse -File -Filter *.tsx |
    Where-Object { $_.Name -match 'Mutirao' -and $_.Name -match 'Client\.tsx$' }
}

if (-not $cands -or $cands.Count -eq 0) {
  throw "[STOP] Não encontrei nenhum *Mutirao*Client.tsx no repo."
}

function ScoreFile($path) {
  $score = 0
  $p = $path.ToLowerInvariant()
  if ($p -match '\\mutiroe?s\\\[id\]\\') { $score += 7 }
  if ($p -match '\\mutiroe?s\\') { $score += 3 }
  if ($p -match '\\eco\\') { $score += 2 }

  $txt = ""
  try { $txt = Get-Content -Raw -LiteralPath $path } catch { $txt = "" }
  if ($txt -match 'Checklist do mutirão') { $score += 8 }
  if ($txt -match '/api/eco/mutirao') { $score += 4 }
  if ($txt -match 'beforeUrl' -or $txt -match 'afterUrl') { $score += 2 }
  if ($txt -match 'Finalizar' -or $txt -match 'DONE') { $score += 1 }
  return @{ score = $score; text = $txt }
}

$best = $null
foreach ($f in $cands) {
  $r = ScoreFile $f.FullName
  if (-not $best -or $r.score -gt $best.score) {
    $best = @{ path = $f.FullName; score = $r.score; text = $r.text }
  }
}

if (-not $best -or -not (Test-Path $best.path)) { throw "[STOP] Falha ao escolher arquivo do client." }

Write-Host ('[DIAG] Selected: ' + $best.path)
Write-Host ('[DIAG] Score: ' + $best.score)

BackupFile $Root $best.path $backupDir

$raw = $best.text
if (-not $raw) { $raw = Get-Content -Raw -LiteralPath $best.path }
if (-not $raw) { throw ('[STOP] arquivo vazio: ' + $best.path) }

$changed = $false

# 1) garantir proofNote no chkDefault (se existir)
if ($raw -match 'function\s+chkDefault' -and $raw -notmatch 'proofNote') {
  $idxFn = $raw.IndexOf('function chkDefault')
  if ($idxFn -ge 0) {
    $idxRet = $raw.IndexOf('return {', $idxFn)
    if ($idxRet -ge 0) {
      $idxBrace = $raw.IndexOf('{', $idxRet)
      if ($idxBrace -ge 0) {
        $seg = $raw.Substring($idxBrace, [Math]::Min(600, $raw.Length - $idxBrace))
        if ($seg -notmatch 'proofNote') {
          $raw = $raw.Insert($idxBrace + 1, " proofNote: `"`",")
          $changed = $true
          Write-Host "[PATCH] chkDefault: injected proofNote"
        }
      }
    }
  }
}

# 2) inserir textarea após heading do checklist
if ($raw -notmatch 'Justificativa \(se faltar foto\)') {
  $needle = '<div style={{ fontWeight: 900 }}>Checklist do mutirão</div>'
  $pos = $raw.IndexOf($needle)
  if ($pos -ge 0) {
    $insert = $needle + "`n" +
'        <div style={{ opacity: 0.7, fontSize: 12 }}>Regra: pra finalizar (DONE), precisa ANTES+DEPOIS ou uma justificativa.</div>' + "`n" +
'        <label style={{ display: "grid", gap: 6 }}>' + "`n" +
'          <span>Justificativa (se faltar foto)</span>' + "`n" +
'          <textarea value={String((check as any)?.proofNote || "")} onChange={(e) => setCheck((prev: any) => ({ ...prev, proofNote: e.target.value }))} rows={3} placeholder="Explique por que faltou foto (mín 10 caracteres)..." style={{ padding: 10, borderRadius: 10, border: "1px solid #ccc" }} />' + "`n" +
'        </label>'
    $raw = $raw.Replace($needle, $insert)
    $changed = $true
    Write-Host "[PATCH] UI: inserted proofNote textarea"
  } else {
    Write-Host "[WARN] Não achei anchor do checklist. (texto 'Checklist do mutirão') — não inseri textarea."
  }
}

# 3) garantir que o finish envia proofNote (se houver chamada ao finish)
if ($raw -match '/api/eco/mutirao/finish' -and $raw -notmatch 'proofNote:\s*String\(\(check as any\)\?\.' ) {
  $idx = $raw.IndexOf('/api/eco/mutirao/finish')
  if ($idx -ge 0) {
    $jidx = $raw.IndexOf('JSON.stringify(', $idx)
    if ($jidx -ge 0) {
      $bidx = $raw.IndexOf('{', $jidx)
      if ($bidx -ge 0) {
        $look = $raw.Substring($bidx, [Math]::Min(600, $raw.Length - $bidx))
        if ($look -notmatch 'proofNote') {
          $raw = $raw.Insert($bidx + 1, " proofNote: String((check as any)?.proofNote || `"`"),")
          $changed = $true
          Write-Host "[PATCH] Finish: injected proofNote into JSON body"
        }
      }
    }
  }
}

if ($changed) {
  WriteUtf8NoBom $best.path $raw
  Write-Host "[OK] Patched: $($best.path)"
} else {
  Write-Host "[OK] Nada pra patchar (já estava aplicado ou não achei âncoras)."
}

$rep = Join-Path $reportDir ('eco-step-66b-patch-mutirao-client-proofnote-v0_1-' + $ts + '.md')
$repLines = @(
'# eco-step-66b-patch-mutirao-client-proofnote-v0_1',
'',
'- Time: ' + $ts,
'- Backup: ' + $backupDir,
'- Patched: ' + $best.path,
'- Score: ' + $best.score,
'',
'## What it did',
'- Tentou adicionar proofNote no chkDefault() (se existir).',
'- Inseriu textarea "Justificativa (se faltar foto)" no bloco do checklist (se achou anchor).',
'- Se a UI chama /api/eco/mutirao/finish, garante envio de proofNote no body.',
'',
'## Verify',
'1) restart dev',
'2) abrir /eco/mutiroes/[id]',
'3) finalizar sem antes/depois e sem justificativa => deve dar missing_proof',
'4) colocar justificativa (>=10) e finalizar => ok',
''
)
WriteLinesUtf8NoBom $rep $repLines
Write-Host ('[REPORT] ' + $rep)

Write-Host ''
Write-Host '[VERIFY] Ctrl+C -> npm run dev'
Write-Host '[VERIFY] /eco/mutiroes/[id] -> Finalizar: sem prova => missing_proof'
Write-Host '[VERIFY] Com justificativa OU antes+depois => OK'