param([string]$Root = (Get-Location).Path)

$ts = Get-Date -Format "yyyyMMdd-HHmmss"
Write-Host ("== eco-step-99c-fix-support-relation-and-list2-strings-v0_1 == " + $ts)
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

function FindModelBlock([string]$raw, [string]$modelName) {
  $m = [regex]::Match($raw, "(?s)model\s+" + [regex]::Escape($modelName) + "\s*\{")
  if (-not $m.Success) { return $null }

  $braceStart = $raw.IndexOf("{", $m.Index)
  if ($braceStart -lt 0) { return $null }

  $depth = 0
  $endBrace = -1
  for ($i = $braceStart; $i -lt $raw.Length; $i++) {
    $ch = $raw[$i]
    if ($ch -eq "{") { $depth++ }
    elseif ($ch -eq "}") {
      $depth--
      if ($depth -eq 0) { $endBrace = $i; break }
    }
  }
  if ($endBrace -lt 0) { return $null }

  return @{
    model = $modelName
    start = $m.Index
    braceStart = $braceStart
    endBrace = $endBrace
    body = $raw.Substring($braceStart + 1, $endBrace - $braceStart - 1)
  }
}

function EnsureInverseRelationSupport([string]$raw) {
  # Prefer EcoCriticalPoint; fallback to other common names if needed
  $candidates = @("EcoCriticalPoint","CriticalPoint","EcoPoint","Point")
  $block = $null
  foreach ($name in $candidates) {
    $b = FindModelBlock $raw $name
    if ($b) { $block = $b; break }
  }
  if (-not $block) {
    throw "[STOP] Nao achei o model do ponto no schema (EcoCriticalPoint/CriticalPoint/EcoPoint/Point)."
  }

  if ($block.body -match "EcoPointSupport\[\]") {
    Write-Host ("[SKIP] schema.prisma: inverse field ja existe em model " + $block.model)
    return @{ raw = $raw; changed = $false; model = $block.model }
  }

  $insertLine = "  supports EcoPointSupport[]`n"
  $newRaw = $raw.Substring(0, $block.endBrace) + $insertLine + $raw.Substring($block.endBrace)
  Write-Host ("[PATCH] schema.prisma: added 'supports EcoPointSupport[]' to model " + $block.model)
  return @{ raw = $newRaw; changed = $true; model = $block.model }
}

function FixList2BrokenStrings([string]$raw2) {
  $script:changed = $false

  # 1) pickModel(pc, "<name>", ...) with newlines/spaces inside quotes
  $raw2 = [regex]::Replace(
    $raw2,
    'pickModel\(\s*pc\s*,\s*"\s*([A-Za-z0-9_]+)\s*"\s*,',
    { param($m) $script:changed = $true; return 'pickModel(pc, "' + $m.Groups[1].Value + '",'; }
  )

  # 2) pc?.[" <name> "] or pc?.[' <name> '] with whitespace/newlines
  $raw2 = [regex]::Replace(
    $raw2,
    'pc\?\.\[\s*"\s*([A-Za-z0-9_]+)\s*"\s*\]',
    { param($m) $script:changed = $true; return 'pc?.["' + $m.Groups[1].Value + '"]'; }
  )
  $raw2 = [regex]::Replace(
    $raw2,
    "pc\?\.\[\s*'\s*([A-Za-z0-9_]+)\s*'\s*\]",
    { param($m) $script:changed = $true; return "pc?.['" + $m.Groups[1].Value + "']"; }
  )

  return @{ raw = $raw2; changed = $script:changed }
}

$backupDir = Join-Path $Root ("tools/_patch_backup/" + $ts + "-eco-step-99c-fix-support-relation-and-list2-strings-v0_1")
$reportDir = Join-Path $Root "reports"
EnsureDir $backupDir
EnsureDir $reportDir

$schema = Join-Path $Root "prisma/schema.prisma"
$list2  = Join-Path $Root "src/app/api/eco/points/list2/route.ts"
$prisma = Join-Path $Root "node_modules/.bin/prisma.cmd"

Write-Host ("[DIAG] schema: " + $schema)
Write-Host ("[DIAG] list2:   " + $list2)
Write-Host ("[DIAG] prisma: " + $prisma)

if (-not (Test-Path -LiteralPath $schema)) { throw "[STOP] Nao achei prisma/schema.prisma" }
if (-not (Test-Path -LiteralPath $list2))  { throw "[STOP] Nao achei src/app/api/eco/points/list2/route.ts" }

BackupFile $Root $schema $backupDir
BackupFile $Root $list2  $backupDir

# --- PATCH schema.prisma
$rawSchema = Get-Content -LiteralPath $schema -Raw -ErrorAction Stop
$r = EnsureInverseRelationSupport $rawSchema
if ($r.changed) { WriteUtf8NoBom $schema $r.raw }

# --- PATCH list2 route.ts
$rawList2 = Get-Content -LiteralPath $list2 -Raw -ErrorAction Stop
$fx = FixList2BrokenStrings $rawList2
if ($fx.changed) {
  WriteUtf8NoBom $list2 $fx.raw
  Write-Host "[PATCH] list2 route.ts: fixed broken multiline strings"
} else {
  Write-Host "[SKIP] list2 route.ts: no broken patterns found"
}

# --- RUN prisma (best-effort)
if (-not (Test-Path -LiteralPath $prisma)) {
  Write-Host "[WARN] prisma.cmd nao encontrado em node_modules/.bin. Instale prisma/@prisma-client e rode migrate/generate manualmente."
} else {
  Write-Host "[RUN] prisma validate"
  & $prisma validate
  $ec = $LASTEXITCODE
  if ($ec -ne 0) { throw ("[STOP] prisma validate falhou (exit " + $ec + ")") }

  Write-Host "[RUN] prisma migrate dev (best-effort)"
  try {
    & $prisma migrate dev --name eco_point_support_rel
    Write-Host ("[OK] migrate dev exit " + $LASTEXITCODE)
  } catch {
    Write-Host ("[WARN] migrate dev falhou: " + $_.Exception.Message)
    Write-Host "[HINT] Se acusar Drift no SQLite, faça backup de prisma/dev.db e rode: prisma migrate reset --force; depois migrate dev + generate."
  }

  Write-Host "[RUN] prisma generate"
  & $prisma generate
  Write-Host ("[OK] generate exit " + $LASTEXITCODE)
}

# --- REPORT
$rep = Join-Path $reportDir ("eco-step-99c-fix-support-relation-and-list2-strings-v0_1-" + $ts + ".md")
$repText = @(
"# eco-step-99c-fix-support-relation-and-list2-strings-v0_1",
"",
"- Time: " + $ts,
"- Backup: " + $backupDir,
"",
"## Changes",
"- schema.prisma: added inverse field supports EcoPointSupport[] on point model (fix P1012 missing opposite relation).",
"- list2 route.ts: fixed broken multiline strings in pickModel(...) and pc?.[\"...\"] accesses.",
"",
"## Verify",
"1) Ctrl+C -> npm run dev",
"2) GET http://localhost:3000/api/eco/points/list2?limit=10 (nao pode dar parse error)",
"3) /eco/mural e /eco/mural/confirmados carregam sem 500",
"4) Clique 🤝 Apoiar e veja se POST /api/eco/points/support responde ok",
""
) -join "`n"
WriteUtf8NoBom $rep $repText
Write-Host ("[REPORT] " + $rep)

Write-Host "[VERIFY] Ctrl+C -> npm run dev"
Write-Host "[VERIFY] irm http://localhost:3000/api/eco/points/list2?limit=10 -Headers @{Accept='application/json'} | ConvertTo-Json -Depth 50"
Write-Host "[VERIFY] abra /eco/mural e /eco/mural/confirmados"