param([string]$Root = (Get-Location).Path)

$ts = Get-Date -Format "yyyyMMdd-HHmmss"
Write-Host ("== eco-step-98-confirm-badge-and-points-alias-v0_1 == " + $ts)
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
      EnsureDir (Split-Path -Parent $dest)
      Copy-Item -Force -LiteralPath $p -Destination $dest
      Write-Host ('[BK] ' + $rel + ' -> ' + (Split-Path -Leaf $dest))
    }
  }
}

function FindFileBySuffix([string]$root, [string]$suffix) {
  $src = Join-Path $root "src"
  if (-not (Test-Path -LiteralPath $src)) { return $null }
  $hits = Get-ChildItem -LiteralPath $src -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
    ($_.FullName -replace '\\','/') -like ('*/' + $suffix)
  }
  if ($hits -and $hits.Count -ge 1) { return $hits[0].FullName }
  return $null
}

$backupDir = Join-Path $Root ("tools/_patch_backup/" + $ts + "-eco-step-98-confirm-badge-and-points-alias-v0_1")
$reportDir = Join-Path $Root "reports"
EnsureDir $backupDir
EnsureDir $reportDir

# Targets
$pointsAlias = Join-Path $Root "src/app/api/eco/points/route.ts"
$list2 = Join-Path $Root "src/app/api/eco/points/list2/route.ts"
if (-not (Test-Path -LiteralPath $list2)) { $list2 = FindFileBySuffix $Root "app/api/eco/points/list2/route.ts" }
if (-not $list2) { throw "[STOP] Nao achei list2: src/app/api/eco/points/list2/route.ts" }

$inline = Join-Path $Root "src/app/eco/_components/PointActionsInline.tsx"
if (-not (Test-Path -LiteralPath $inline)) { $inline = FindFileBySuffix $Root "app/eco/_components/PointActionsInline.tsx" }
if (-not $inline) { throw "[STOP] Nao achei: src/app/eco/_components/PointActionsInline.tsx" }

Write-Host ("[DIAG] list2:       " + $list2)
Write-Host ("[DIAG] pointsAlias:" + $pointsAlias)
Write-Host ("[DIAG] inline:     " + $inline)

BackupFile $Root $pointsAlias $backupDir
BackupFile $Root $inline $backupDir

# -----------------------------
# 1) Create /api/eco/points alias -> list2 (prevents 404)
# -----------------------------
$aliasLines = @(
  'export { runtime, dynamic, GET } from "./list2/route";'
)
WriteUtf8NoBom $pointsAlias ($aliasLines -join "`n")
Write-Host "[PATCH] wrote /api/eco/points alias -> list2"

# -----------------------------
# 2) Patch PointActionsInline: show ✅ Confirmado (N) using counts.confirm
# -----------------------------
$raw = Get-Content -LiteralPath $inline -Raw -ErrorAction Stop

if ($raw -match 'counts\?\.\s*confirm' -or $raw -match 'confirmN' -or $raw -match 'CONFIRMADO') {
  Write-Host "[SKIP] Parece que o badge de confirmacao ja existe no PointActionsInline."
} else {
  $lines = $raw -split "`n"

  # find "return (" index
  $ret = -1
  for ($i=0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^\s*return\s*\(') { $ret = $i; break }
  }
  if ($ret -lt 0) { throw "[STOP] Nao achei 'return (' no PointActionsInline.tsx" }

  # insert const confirmN before return
  $indent = ""
  $mIndent = [regex]::Match($lines[$ret], '^\s*')
  if ($mIndent.Success) { $indent = $mIndent.Value }

  $insConst = @(
    ($indent + 'const confirmN = Number((point as any)?.counts?.confirm ?? (point as any)?.confirmCount ?? 0);'),
    ($indent + 'const showConfirmN = Number.isFinite(confirmN) && confirmN > 0;')
  )

  $out = New-Object System.Collections.Generic.List[string]
  for ($i=0; $i -lt $lines.Count; $i++) {
    if ($i -eq $ret) {
      $out.AddRange($insConst)
      $out.Add('')
    }
    $out.Add($lines[$i])
  }
  $raw2 = ($out -join "`n")

  # Now inject UI inside first wrapper after return(
  $lines2 = $raw2 -split "`n"
  $wrapper = -1
  for ($i=$ret; $i -lt [Math]::Min($lines2.Count, $ret+40); $i++) {
    if ($lines2[$i] -match '<(div|section|header)\b') { $wrapper = $i; break }
  }
  if ($wrapper -lt 0) { throw "[STOP] Nao achei wrapper <div|section|header> logo apos o return(" }

  $ind2 = ""
  $m2 = [regex]::Match($lines2[$wrapper], '^\s*')
  if ($m2.Success) { $ind2 = $m2.Value }

  $badge = @(
    ($ind2 + '{showConfirmN ? ('),
    ($ind2 + '  <span'),
    ($ind2 + '    title={"Confirmado por " + confirmN}'),
    ($ind2 + '    style={{'),
    ($ind2 + '      display: "inline-flex",'),
    ($ind2 + '      alignItems: "center",'),
    ($ind2 + '      gap: 8,'),
    ($ind2 + '      padding: "5px 10px",'),
    ($ind2 + '      borderRadius: 999,'),
    ($ind2 + '      border: "1px solid #111",'),
    ($ind2 + '      background: "#fff",'),
    ($ind2 + '      fontWeight: 900,'),
    ($ind2 + '      fontSize: 12,'),
    ($ind2 + '      lineHeight: "12px",'),
    ($ind2 + '      whiteSpace: "nowrap",'),
    ($ind2 + '    }}'),
    ($ind2 + '  >'),
    ($ind2 + '    ✅ CONFIRMADO'),
    ($ind2 + '    <span'),
    ($ind2 + '      style={{'),
    ($ind2 + '        display: "inline-flex",'),
    ($ind2 + '        alignItems: "center",'),
    ($ind2 + '        justifyContent: "center",'),
    ($ind2 + '        minWidth: 20,'),
    ($ind2 + '        padding: "2px 8px",'),
    ($ind2 + '        borderRadius: 999,'),
    ($ind2 + '        background: "#111",'),
    ($ind2 + '        color: "#fff",'),
    ($ind2 + '        fontWeight: 900,'),
    ($ind2 + '        fontSize: 12,'),
    ($ind2 + '        lineHeight: "12px",'),
    ($ind2 + '      }}'),
    ($ind2 + '    >'),
    ($ind2 + '      {confirmN}'),
    ($ind2 + '    </span>'),
    ($ind2 + '  </span>'),
    ($ind2 + ') : null}'),
    ($ind2 + '')
  )

  # Avoid double insert: if near wrapper already has CONFIRMADO, skip (shouldn't happen)
  $already = $false
  for ($j = [Math]::Max(0, $wrapper-10); $j -le [Math]::Min($lines2.Count-1, $wrapper+10); $j++) {
    if ($lines2[$j] -match 'CONFIRMADO') { $already = $true; break }
  }

  if (-not $already) {
    $out2 = New-Object System.Collections.Generic.List[string]
    for ($i=0; $i -lt $lines2.Count; $i++) {
      $out2.Add($lines2[$i])
      if ($i -eq $wrapper) {
        $out2.AddRange($badge)
      }
    }
    $final = ($out2 -join "`n")
    WriteUtf8NoBom $inline $final
    Write-Host "[PATCH] injected confirm badge into PointActionsInline"
  } else {
    Write-Host "[SKIP] Badge ja estava perto do wrapper."
  }
}

# Report
$rep = Join-Path $reportDir ("eco-step-98-confirm-badge-and-points-alias-v0_1-" + $ts + ".md")
$repText = @(
"# eco-step-98-confirm-badge-and-points-alias-v0_1",
"",
"- Time: " + $ts,
"- Backup: " + $backupDir,
"",
"## Changes",
"- Added/ensured: src/app/api/eco/points/route.ts (alias -> list2) para evitar 404 legado",
"- Patched: src/app/eco/_components/PointActionsInline.tsx (badge ✅ CONFIRMADO + numero via counts.confirm)",
"",
"## Verify",
"1) Ctrl+C -> npm run dev",
"2) http://localhost:3000/api/eco/points?limit=10  (200; alias)",
"3) Abra /eco/mural e /eco/mural/confirmados: cards com confirmacao devem mostrar ✅ CONFIRMADO (N)",
"4) DevTools/Network: confirme que /api/eco/points ou /api/eco/points/list2 responde 200"
) -join "`n"
WriteUtf8NoBom $rep $repText
Write-Host ("[REPORT] " + $rep)

Write-Host ""
Write-Host "[VERIFY] Ctrl+C -> npm run dev"
Write-Host "[VERIFY] http://localhost:3000/api/eco/points?limit=10"
Write-Host "[VERIFY] /eco/mural e /eco/mural/confirmados (badge ✅ CONFIRMADO)"