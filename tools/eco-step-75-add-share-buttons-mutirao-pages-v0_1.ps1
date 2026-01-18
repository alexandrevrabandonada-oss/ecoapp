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

function DetectNewline([string]$s) {
  if ($s -match "`r`n") { return "`r`n" }
  return "`n"
}

function InsertAfter([string]$raw, [string]$needle, [string]$insert, [string]$nl) {
  $pos = $raw.IndexOf($needle)
  if ($pos -lt 0) { return $raw }
  $after = $raw.IndexOf($nl, $pos)
  if ($after -lt 0) { $after = $pos + $needle.Length }
  else { $after = $after + $nl.Length }
  return $raw.Insert($after, $insert)
}

function InsertAfterMainOpen([string]$raw, [string]$insert, [string]$nl) {
  $pos = $raw.IndexOf("<main")
  if ($pos -lt 0) { return $raw }
  $after = $raw.IndexOf(">", $pos)
  if ($after -lt 0) { return $raw }
  $after = $after + 1
  return $raw.Insert($after, $nl + $insert)
}

function EnsureAsyncAndId([string]$raw, [string]$nl) {
  # 1) Make Page async if needed
  if ($raw -match "export\s+default\s+function\s+Page") {
    if (-not ($raw -match "export\s+default\s+async\s+function\s+Page")) {
      $raw = $raw -replace "export\s+default\s+function\s+Page", "export default async function Page"
    }
  }

  # 2) Insert id snippet if not present
  if (-not ($raw -match "const\s+id\s*=\s*String\(")) {
    $idx = $raw.IndexOf("function Page")
    if ($idx -ge 0) {
      $brace = $raw.IndexOf("{", $idx)
      if ($brace -ge 0) {
        $snippet = $nl + '  const p: any = await (params as any);' + $nl + '  const id = String(p?.id || "");' + $nl
        $raw = $raw.Insert($brace + 1, $snippet)
      }
    }
  }

  # 3) Replace params.id -> id (best-effort)
  $raw = $raw.Replace("params?.id", "id")
  $raw = $raw.Replace("params.id", "id")

  return $raw
}

$backupDir = Join-Path $Root ('tools/_patch_backup/' + $ts + '-eco-step-75-add-share-buttons-mutirao-pages-v0_1')
$reportDir = Join-Path $Root 'reports'
EnsureDir $backupDir
EnsureDir $reportDir

Write-Host ('== eco-step-75-add-share-buttons-mutirao-pages-v0_1 == ' + $ts)
Write-Host ('[DIAG] Root: ' + $Root)

# Locate detail page
$detailPage = Join-Path $Root 'src/app/eco/mutiroes/[id]/page.tsx'
if (-not (Test-Path -LiteralPath $detailPage)) {
  $cand = Get-ChildItem -Path (Join-Path $Root 'src/app/eco/mutiroes') -Recurse -File -Filter 'page.tsx' `
    | Where-Object { $_.FullName -match "\\mutiroes\\\[id\]\\page\.tsx$" -and $_.FullName -notmatch "\\finalizar\\" -and $_.FullName -notmatch "\\share\\" } `
    | Select-Object -First 1
  if ($cand) { $detailPage = $cand.FullName }
}

# Locate finalizar page
$finishPage = Join-Path $Root 'src/app/eco/mutiroes/[id]/finalizar/page.tsx'
if (-not (Test-Path -LiteralPath $finishPage)) {
  $cand2 = Get-ChildItem -Path (Join-Path $Root 'src/app/eco/mutiroes') -Recurse -File -Filter 'page.tsx' `
    | Where-Object { $_.FullName -match "\\mutiroes\\\[id\]\\finalizar\\page\.tsx$" } `
    | Select-Object -First 1
  if ($cand2) { $finishPage = $cand2.FullName }
}

if (-not (Test-Path -LiteralPath $detailPage)) { throw ('[STOP] Não achei a page do mutirão [id]: ' + $detailPage) }
if (-not (Test-Path -LiteralPath $finishPage)) { throw ('[STOP] Não achei a page do finalizar: ' + $finishPage) }

Write-Host ('[DIAG] detailPage: ' + $detailPage)
Write-Host ('[DIAG] finishPage: ' + $finishPage)

BackupFile $Root $detailPage $backupDir
BackupFile $Root $finishPage $backupDir

$shareBlockLines = @(
'      <div style={{ display: "flex", gap: 10, flexWrap: "wrap", margin: "10px 0 14px 0" }}>',
'        <a',
'          href={"/eco/share/mutirao/" + encodeURIComponent(id)}',
'          target="_blank"',
'          rel="noreferrer"',
'          style={{',
'            padding: "10px 12px",',
'            borderRadius: 12,',
'            border: "1px solid #111",',
'            textDecoration: "none",',
'            color: "#111",',
'            background: "#FFDD00",',
'            fontWeight: 900,',
'          }}',
'        >',
'          Compartilhar (card)',
'        </a>',
'      </div>'
)

# --- Patch detail page ---
$raw1 = Get-Content -LiteralPath $detailPage -Raw
if (-not $raw1) { throw "[STOP] raw vazio no detailPage" }
$nl1 = DetectNewline $raw1

if ($raw1 -notmatch "/eco/share/mutirao/") {
  $raw1 = EnsureAsyncAndId $raw1 $nl1
  $shareBlock = ($shareBlockLines -join $nl1) + $nl1

  if ($raw1 -match "</h1>") {
    $raw1 = InsertAfter $raw1 "</h1>" $shareBlock $nl1
  } else {
    $raw1 = InsertAfterMainOpen $raw1 $shareBlock $nl1
  }

  WriteUtf8NoBom $detailPage $raw1
  Write-Host "[PATCH] detail page: adicionou botão Compartilhar + await params + id"
} else {
  Write-Host "[SKIP] detail page já tem /eco/share/mutirao/"
}

# --- Patch finalizar page ---
$raw2 = Get-Content -LiteralPath $finishPage -Raw
if (-not $raw2) { throw "[STOP] raw vazio no finishPage" }
$nl2 = DetectNewline $raw2

if ($raw2 -notmatch "/eco/share/mutirao/") {
  # finalize page já costuma ter id; mas garantimos também
  $raw2 = EnsureAsyncAndId $raw2 $nl2
  $shareBlock2 = ($shareBlockLines -join $nl2) + $nl2

  if ($raw2 -match "</h1>") {
    $raw2 = InsertAfter $raw2 "</h1>" $shareBlock2 $nl2
  } else {
    $raw2 = InsertAfterMainOpen $raw2 $shareBlock2 $nl2
  }

  WriteUtf8NoBom $finishPage $raw2
  Write-Host "[PATCH] finalizar page: adicionou botão Compartilhar + await params + id"
} else {
  Write-Host "[SKIP] finalizar page já tem /eco/share/mutirao/"
}

# REPORT
$rep = Join-Path $reportDir ('eco-step-75-add-share-buttons-mutirao-pages-v0_1-' + $ts + '.md')
$repLines = @(
'# eco-step-75-add-share-buttons-mutirao-pages-v0_1',
'',
'- Time: ' + $ts,
'- Backup: ' + $backupDir,
'',
'## Patched',
'- ' + ($detailPage.Substring($Root.Length).TrimStart('\','/')),
'- ' + ($finishPage.Substring($Root.Length).TrimStart('\','/')),
'',
'## O que mudou',
'- Adiciona botão "Compartilhar (card)" apontando para /eco/share/mutirao/{id}',
'- Garante compat Next 16: Page async + await(params) + id seguro (best-effort)',
'',
'## Verify',
'1) Ctrl+C -> npm run dev',
'2) Abrir /eco/mutiroes/<id> e clicar "Compartilhar (card)"',
'3) Abrir /eco/mutiroes/<id>/finalizar e clicar "Compartilhar (card)"'
)
WriteUtf8NoBom $rep ($repLines -join "`n")
Write-Host ('[REPORT] ' + $rep)

Write-Host ""
Write-Host "[VERIFY] Ctrl+C -> npm run dev"
Write-Host "[VERIFY] /eco/mutiroes/<id> e /eco/mutiroes/<id>/finalizar"