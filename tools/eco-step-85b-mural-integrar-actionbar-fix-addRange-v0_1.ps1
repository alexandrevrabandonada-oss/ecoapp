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

Write-Host ('== eco-step-85b-mural-integrar-actionbar-fix-addRange-v0_1 == ' + $ts)
Write-Host ('[DIAG] Root: ' + $Root)

$srcApp = Join-Path $Root 'src/app'
if (-not (Test-Path -LiteralPath $srcApp)) { throw "[STOP] Nao achei src/app" }

$backupDir = Join-Path $Root ('tools/_patch_backup/' + $ts + '-eco-step-85b-mural-integrar-actionbar-fix-addRange-v0_1')
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

function FindBestMuralClient([string]$muralDir) {
  if (-not (Test-Path -LiteralPath $muralDir)) { return $null }
  $files = Get-ChildItem -LiteralPath $muralDir -File -Filter *.tsx -ErrorAction SilentlyContinue
  if (-not $files) { return $null }

  $best = $null
  $bestScore = -1
  foreach ($f in $files) {
    $raw = ReadText $f.FullName
    if (-not $raw) { continue }
    $score = 0
    if ($raw.Contains("/api/eco/points")) { $score += 10 }
    if ($raw.Contains("/api/eco/critical")) { $score += 8 }
    if ($raw.Contains("/eco/share/ponto")) { $score += 8 }
    if ($raw.Contains("items.map") -or $raw.Contains(".map((")) { $score += 6 }
    if ($raw.Contains("Mural")) { $score += 4 }
    if ($raw.Contains("use client")) { $score += 2 }
    if ($score -gt $bestScore) { $bestScore = $score; $best = $f.FullName }
  }

  if ($bestScore -lt 10) { return $null }
  return $best
}

function ExtractMapVarName([string[]]$lines) {
  foreach ($ln in $lines) {
    if ($ln.Contains(".map((") -and $ln.Contains("=>")) {
      $i = $ln.IndexOf(".map((")
      if ($i -ge 0) {
        $rest = $ln.Substring($i + 6)
        $j = $rest.IndexOf(")")
        if ($j -gt 0) {
          $inside = $rest.Substring(0, $j).Trim()
          $tok = $inside.Split(",")[0].Trim()
          $tok = $tok.Split(" ")[0].Trim()
          if ($tok) { return $tok }
        }
      }
    }
  }
  return "p"
}

# ---- 1) Patch mural client ----
$muralDir = Join-Path $srcApp "eco/mural"
$clientPath = FindBestMuralClient $muralDir
if (-not $clientPath) {
  throw "[STOP] Nao consegui detectar o Client do /eco/mural. Confere se existe src/app/eco/mural/*.tsx"
}

BackupFile $Root $clientPath $backupDir
$raw = ReadText $clientPath
if (-not $raw) { throw "[STOP] Falha ao ler: $clientPath" }

$didClient = $false

if ($raw.Contains("PointActionBar") -or $raw.Contains("/eco/_components/PointActionBar")) {
  Write-Host "[OK] Mural client ja tem PointActionBar (ou foi integrado antes)."
} else {
  $lines = $raw -split "`n"
  $varName = ExtractMapVarName $lines

  # inserir import depois do ultimo import
  $lastImport = -1
  for ($i=0; $i -lt $lines.Length; $i++) {
    $t = $lines[$i].TrimStart()
    if ($t.StartsWith("import ")) { $lastImport = $i }
  }

  $ins = [string[]]@('import { PointActionBar } from "../_components/PointActionBar";')

  if ($lastImport -ge 0) {
    $new = New-Object System.Collections.Generic.List[string]
    for ($i=0; $i -lt $lines.Length; $i++) {
      $new.Add($lines[$i])
      if ($i -eq $lastImport) {
        foreach ($s in $ins) { $new.Add($s) }
      }
    }
    $lines = $new.ToArray()
  } else {
    $new = New-Object System.Collections.Generic.List[string]
    foreach ($s in $ins) { $new.Add($s) }
    foreach ($ln in $lines) { $new.Add($ln) }
    $lines = $new.ToArray()
  }

  # inserir barra de acoes perto do link share/ponto
  $needleIndex = -1
  for ($i=0; $i -lt $lines.Length; $i++) {
    $ln = $lines[$i]
    if ($ln.Contains("share/ponto") -or $ln.Contains("Abrir compartilhar") -or $ln.Contains("Compartilhar")) {
      $needleIndex = $i
      break
    }
  }
  if ($needleIndex -lt 0) {
    for ($i=0; $i -lt $lines.Length; $i++) {
      if ($lines[$i].Contains("key=") -and $lines[$i].Contains("border") -and $lines[$i].Contains("style={{")) {
        $needleIndex = $i + 1
        break
      }
    }
  }
  if ($needleIndex -lt 0) { throw "[STOP] Nao achei ponto seguro para inserir ActionBar no mural client." }

  $block = [string[]]@(
'              <div style={{ display: "grid", gap: 8, marginTop: 10 }}>',
'                <div style={{ fontWeight: 950, fontSize: 12, opacity: 0.85 }}>Acoes (reacoes viram acoes)</div>',
('                <PointActionBar pointId={' + $varName + '.id} compact />'),
'              </div>'
  )

  $new2 = New-Object System.Collections.Generic.List[string]
  for ($i=0; $i -lt $lines.Length; $i++) {
    if ($i -eq $needleIndex) {
      foreach ($s in $block) { $new2.Add($s) }
    }
    $new2.Add($lines[$i])
  }

  WriteLines $clientPath $new2.ToArray()
  Write-Host ("[PATCH] updated mural client: " + $clientPath)
  $didClient = $true
}

# ---- 2) Patch /eco/mural/page.tsx (fallback link) ----
$pagePath = Join-Path $muralDir "page.tsx"
$didPage = $false

if (Test-Path -LiteralPath $pagePath) {
  BackupFile $Root $pagePath $backupDir
  $praw = ReadText $pagePath
  if ($praw -and (-not $praw.Contains("/eco/mural-acoes"))) {
    $plines = $praw -split "`n"
    $inserted = $false
    $out = New-Object System.Collections.Generic.List[string]
    foreach ($ln in $plines) {
      $out.Add($ln)
      if (-not $inserted -and $ln.Contains("<p") -and $ln.Contains("opacity")) {
        $out.Add('      <div style={{ margin: "10px 0 14px 0" }}>')
        $out.Add('        <a href="/eco/mural-acoes" style={{ padding: "9px 10px", borderRadius: 12, border: "1px solid #111", textDecoration: "none", color: "#111", fontWeight: 900, background: "#fff" }}>')
        $out.Add('          Ver versao com acoes (fallback)')
        $out.Add('        </a>')
        $out.Add('      </div>')
        $inserted = $true
      }
    }
    if ($inserted) {
      WriteLines $pagePath $out.ToArray()
      Write-Host "[PATCH] added fallback link in /eco/mural/page.tsx"
      $didPage = $true
    } else {
      Write-Host "[WARN] nao inseri link no page.tsx (nao achei <p> alvo)."
    }
  } else {
    Write-Host "[OK] /eco/mural/page.tsx ja tem link (ou nao leu)."
  }
} else {
  Write-Host "[WARN] nao achei /eco/mural/page.tsx (ok se mural for outro layout)."
}

# ---- REPORT ----
$rep = Join-Path $reportDir ('eco-step-85b-mural-integrar-actionbar-fix-addRange-v0_1-' + $ts + '.md')
$repLines = @(
'# eco-step-85b-mural-integrar-actionbar-fix-addRange-v0_1',
'',
'- Time: ' + $ts,
'- Backup: ' + $backupDir,
'',
'## Target',
'- Mural client: ' + $clientPath,
'- page.tsx: ' + $pagePath,
'',
'## Did',
'- Patched client: ' + $didClient,
'- Patched page: ' + $didPage,
'',
'## Verify',
'1) Ctrl+C -> npm run dev',
'2) Abra /eco/mural',
'3) Veja os botoes de acoes no card (Confirmar/Apoiar/Chamado/Gratidao/Replicar)',
'4) Clique e recarregue (F5) para ver contadores persistirem',
'5) Fallback: /eco/mural-acoes'
)
WriteUtf8NoBom $rep ($repLines -join "`n")
Write-Host ('[REPORT] ' + $rep)

Write-Host ""
Write-Host "[VERIFY] Ctrl+C -> npm run dev"
Write-Host "[VERIFY] Abra /eco/mural e teste as acoes no card"