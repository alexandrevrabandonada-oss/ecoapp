param([string]$Root = (Get-Location).Path)

$ts = Get-Date -Format "yyyyMMdd-HHmmss"
Write-Host ("== eco-step-100-fix-list2-confirm-groupby-field-v0_1 == " + $ts)
Write-Host ("[DIAG] Root: " + $Root)

$target = Join-Path $Root "src/app/api/eco/points/list2/route.ts"
if (-not (Test-Path -LiteralPath $target)) { throw "[STOP] Nao achei: src/app/api/eco/points/list2/route.ts" }
Write-Host ("[DIAG] Target: " + $target)

# helpers (self-contained)
function EnsureDir([string]$p) { if (-not (Test-Path -LiteralPath $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function WriteUtf8NoBom([string]$p, [string]$content) {
  EnsureDir (Split-Path -Parent $p)
  $enc = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($p, $content, $enc)
}
function BackupFile([string]$root, [string]$p, [string]$backupDir) {
  if (Test-Path -LiteralPath $p) {
    $rel = $p.Substring($root.Length).TrimStart('\','/')
    $dest = Join-Path $backupDir ($rel -replace '[\\/]', '__')
    Copy-Item -Force -LiteralPath $p -Destination $dest
    Write-Host ('[BK] ' + $rel + ' -> ' + (Split-Path -Leaf $dest))
  }
}

$backupDir = Join-Path $Root ("tools/_patch_backup/" + $ts + "-eco-step-100-fix-list2-confirm-groupby-field-v0_1")
$reportDir = Join-Path $Root "reports"
EnsureDir $backupDir
EnsureDir $reportDir
BackupFile $Root $target $backupDir

$raw = Get-Content -LiteralPath $target -Raw -ErrorAction Stop

# 1) Fix broken multiline string patterns that keep popping up:
#    pc?.["\n ecoPointConfirm \n"]  -> pc?.["ecoPointConfirm"]
#    pickModel(pc, "\n ecoPoint \n", ...) -> pickModel(pc, "ecoPoint", ...)
$before = $raw

$raw = [regex]::Replace(
  $raw,
  '\[\s*"\s*\r?\n\s*([A-Za-z0-9_]+)\s*\r?\n\s*"\s*\]',
  { param($m) '["' + $m.Groups[1].Value + '"]' }
)

$raw = [regex]::Replace(
  $raw,
  'pickModel\(\s*pc\s*,\s*"\s*\r?\n\s*([A-Za-z0-9_]+)\s*\r?\n\s*"\s*,',
  { param($m) 'pickModel(pc, "' + $m.Groups[1].Value + '",' }
)

$fixedStrings = ($raw -ne $before)

# 2) Patch the confirm counts block to try multiple field names for groupBy.by
$lines = $raw -split "`n"
$idxConfirmComment = -1
for ($i=0; $i -lt $lines.Count; $i++) {
  if ($lines[$i] -match 'counts\.confirm') { $idxConfirmComment = $i; break }
}

$start = -1
$end   = -1

if ($idxConfirmComment -ge 0) {
  $start = $idxConfirmComment
  for ($j = $idxConfirmComment; $j -lt $lines.Count; $j++) {
    if ($lines[$j] -match 'return\s+map\s*;') { $end = $j; break }
  }
}

# fallback: find confirmModel.groupBy
if ($start -lt 0 -or $end -lt 0) {
  $idxGB = -1
  for ($i=0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match 'confirmModel\.groupBy') { $idxGB = $i; break }
  }
  if ($idxGB -ge 0) {
    $start = $idxGB
    for ($b = [Math]::Max(0, $idxGB-12); $b -le $idxGB; $b++) {
      if ($lines[$b] -match 'const\s+map\b') { $start = $b; break }
    }
    for ($j = $idxGB; $j -lt [Math]::Min($lines.Count, $idxGB+80); $j++) {
      if ($lines[$j] -match 'return\s+map\s*;') { $end = $j; break }
    }
  }
}

if ($start -lt 0 -or $end -lt 0) {
  throw "[STOP] Nao consegui localizar o bloco de counts.confirm (nem confirmModel.groupBy). Cola aqui o src/app/api/eco/points/list2/route.ts que eu ajusto no fio."
}

# detect indentation from the start line
$indent = ""
$mmIndent = [regex]::Match($lines[$start], '^\s*')
if ($mmIndent.Success) { $indent = $mmIndent.Value }

# replacement block (no dependency on ids variable; groups ALL)
$ins = @(
  ($indent + "// counts.confirm via groupBy (field name varies by schema)"),
  ($indent + "const map: Record<string, number> = {};"),
  ($indent + "if (!confirmModel || typeof confirmModel.groupBy !== ""function"") return map;"),
  ($indent + "const candidates = [""pointId"", ""criticalPointId"", ""ecoCriticalPointId"", ""ecoPointId""];"),
  ($indent + "for (const field of candidates) {"),
  ($indent + "  try {"),
  ($indent + "    const rows = await confirmModel.groupBy({"),
  ($indent + "      by: [field] as any,"),
  ($indent + "      _count: { _all: true } as any,"),
  ($indent + "    } as any);"),
  ($indent + "    for (const r of (rows as any[])) {"),
  ($indent + "      const k = String((r as any)[field] ?? """");"),
  ($indent + "      const n = Number((r as any)?._count?._all ?? 0);"),
  ($indent + "      if (k) map[k] = n;"),
  ($indent + "    }"),
  ($indent + "    return map;"),
  ($indent + "  } catch (e) {"),
  ($indent + "    // try next candidate"),
  ($indent + "  }"),
  ($indent + "}"),
  ($indent + "return map;")
)

$new = New-Object System.Collections.Generic.List[string]
for ($i=0; $i -lt $lines.Count; $i++) {
  if ($i -eq $start) {
    $new.AddRange($ins)
    $i = $end
    continue
  }
  $new.Add($lines[$i])
}

$raw2 = ($new -join "`n")
WriteUtf8NoBom $target $raw2

$rep = Join-Path $reportDir ("eco-step-100-fix-list2-confirm-groupby-field-v0_1-" + $ts + ".md")
$repText = @(
  "# eco-step-100-fix-list2-confirm-groupby-field-v0_1",
  "",
  "- Time: " + $ts,
  "- Backup: " + $backupDir,
  "",
  "## What was happening",
  "- Prisma error: Invalid value for argument `by` in confirmModel.groupBy (field `criticalPointId` nao existe no model real).",
  "- E em alguns momentos o arquivo ficava com strings quebradas em multiplas linhas (""Unterminated string constant"").",
  "",
  "## Changes",
  "- list2 route: normaliza strings quebradas para `pc?.[\"ecoPointConfirm\"]` e `pickModel(pc, \"ecoPoint\", ...)` quando aparecer.",
  "- list2 route: bloco `counts.confirm` agora tenta `pointId / criticalPointId / ecoCriticalPointId / ecoPointId` e usa o primeiro que funcionar.",
  "",
  "## Verify",
  "1) Ctrl+C -> npm run dev",
  "2) http://localhost:3000/api/eco/points/list2?limit=10 (nao pode dar erro do Prisma)",
  "3) http://localhost:3000/eco/mural/confirmados (deve abrir sem 500)",
  "",
  "## Notes",
  "- Esse patch agrupa contagens no dataset todo (sem `where in ids`) pra ficar independente do nome da variavel de ids no arquivo. Se precisar otimizar depois, eu faço a versao com filtro."
) -join "`n"
WriteUtf8NoBom $rep $repText

Write-Host ("[OK] Patched: " + $target)
Write-Host ("[REPORT] " + $rep)
Write-Host ""
Write-Host "[VERIFY] Ctrl+C -> npm run dev"
Write-Host "[VERIFY] GET /api/eco/points/list2?limit=10 (sem erro do Prisma)"
Write-Host "[VERIFY] /eco/mural/confirmados"