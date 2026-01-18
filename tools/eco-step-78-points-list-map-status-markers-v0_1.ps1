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

function AddImportIfMissing([string]$raw, [string]$nl, [string]$importLine) {
  if ($raw.Contains($importLine)) { return $raw }
  $imports = [regex]::Matches($raw, "(?m)^\s*import .+;\s*$")
  if ($imports.Count -gt 0) {
    $m = $imports[$imports.Count - 1]
    $pos = $m.Index + $m.Length
    return $raw.Insert($pos, $nl + $importLine)
  }
  return $importLine + $nl + $raw
}

function InsertBadgeInFirstMap([string]$raw, [string]$nl) {
  # procura padrões: points.map((p) => (  ... <div ...> ... ))
  $rx = [regex]::new("(?s)(\b(points|items|rows)\s*\.map\(\(\s*([A-Za-z_]\w*)\s*\)\s*=>\s*\()", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
  $m = $rx.Match($raw)
  if (-not $m.Success) { return @{ ok=$false; raw=$raw; why="no_map_pattern" } }

  $var = $m.Groups[3].Value
  $start = $m.Index + $m.Length

  # acha primeiro "<" depois do "=> ("
  $lt = $raw.IndexOf("<", $start)
  if ($lt -lt 0) { return @{ ok=$false; raw=$raw; why="no_jsx_after_map" } }

  # acha o ">" do primeiro tag
  $gt = $raw.IndexOf(">", $lt)
  if ($gt -lt 0) { return @{ ok=$false; raw=$raw; why="no_tag_close" } }

  # já tem PointBadge nessa região? (evita duplicar)
  $windowEnd = [Math]::Min($raw.Length, $gt + 300)
  $window = $raw.Substring($lt, $windowEnd - $lt)
  if ($window -match "PointBadge") { return @{ ok=$false; raw=$raw; why="already_has_badge_nearby" } }

  $insert = $nl + '        <PointBadge p={' + $var + '} />' + $nl
  $raw2 = $raw.Insert($gt + 1, $insert)
  return @{ ok=$true; raw=$raw2; var=$var }
}

function PatchMapLibreMarkers([string]$raw, [string]$nl) {
  if (-not ($raw -match "maplibregl\.Marker")) { return @{ ok=$false; raw=$raw; why="no_maplibre_marker" } }
  if (-not ($raw -match "document\.createElement\((`"|' )div(`"|')\)")) { return @{ ok=$false; raw=$raw; why="no_div_marker_el" } }

  # tenta achar loop var perto de new maplibregl.Marker
  $idx = $raw.IndexOf("new maplibregl.Marker")
  if ($idx -lt 0) { return @{ ok=$false; raw=$raw; why="no_marker_ctor" } }

  $from = [Math]::Max(0, $idx - 450)
  $ctx = $raw.Substring($from, $idx - $from)

  $loopVar = $null
  $m1 = [regex]::Match($ctx, "forEach\(\(\s*([A-Za-z_]\w*)")
  if ($m1.Success) { $loopVar = $m1.Groups[1].Value }
  if (-not $loopVar) {
    $m2 = [regex]::Match($ctx, "for\s*\(\s*const\s+([A-Za-z_]\w*)\s+of")
    if ($m2.Success) { $loopVar = $m2.Groups[1].Value }
  }
  if (-not $loopVar) { return @{ ok=$false; raw=$raw; why="cannot_detect_loop_var" } }

  # injeta style após criação do el
  $rxEl = [regex]::new("document\.createElement\((`"|' )div(`"|')\)\s*;")
  $mEl = $rxEl.Match($raw)
  if (-not $mEl.Success) { return @{ ok=$false; raw=$raw; why="no_el_create_stmt" } }

  $after = $mEl.Index + $mEl.Length
  $snippet = @(
$nl + '      // status marker (OPEN/RESOLVED)' ,
$nl + '      try {' ,
$nl + '        const __fill = markerFill(' + $loopVar + ');' ,
$nl + '        const __brd = markerBorder(' + $loopVar + ');' ,
$nl + '        // @ts-ignore' ,
$nl + '        el.style.background = __fill;' ,
$nl + '        // @ts-ignore' ,
$nl + '        el.style.borderColor = __brd;' ,
$nl + '      } catch {}' + $nl
) -join ""

  # evita duplicar
  if ($raw.Substring([Math]::Max(0, $after), [Math]::Min(400, $raw.Length - $after)) -match "markerFill\(") {
    return @{ ok=$false; raw=$raw; why="already_patched_near_el" }
  }

  $raw2 = $raw.Insert($after, $snippet)
  return @{ ok=$true; raw=$raw2; var=$loopVar }
}

$backupDir = Join-Path $Root ('tools/_patch_backup/' + $ts + '-eco-step-78-points-list-map-status-markers-v0_1')
$reportDir = Join-Path $Root 'reports'
EnsureDir $backupDir
EnsureDir $reportDir

Write-Host ('== eco-step-78-points-list-map-status-markers-v0_1 == ' + $ts)
Write-Host ('[DIAG] Root: ' + $Root)

# 1) helper shared file
$helper = Join-Path $Root 'src/app/eco/_ui/PointStatus.tsx'
Write-Host ('[DIAG] Will write: ' + $helper)
BackupFile $Root $helper $backupDir

$LHelper = @(
'"use client";',
'',
'import React from "react";',
'',
'export function normStatus(v: any) {',
'  return String(v || "").trim().toUpperCase();',
'}',
'export function isResolvedStatus(s: string) {',
'  const t = normStatus(s);',
'  return t === "RESOLVED" || t === "RESOLVIDO" || t === "DONE" || t === "CLOSED" || t === "FINALIZADO";',
'}',
'export function getPointStatus(p: any) {',
'  const m = (p && p.meta && typeof p.meta === "object") ? p.meta : null;',
'  return normStatus(p?.status || p?.state || m?.status || m?.state || "");',
'}',
'export function markerFill(p: any) {',
'  const s = getPointStatus(p);',
'  return isResolvedStatus(s) ? "#2EEB2E" : "#FFDD00";',
'}',
'export function markerBorder(p: any) {',
'  const s = getPointStatus(p);',
'  return isResolvedStatus(s) ? "#0A7A0A" : "#111111";',
'}',
'export function badgeLabel(p: any) {',
'  const s = getPointStatus(p);',
'  return isResolvedStatus(s) ? "RESOLVIDO" : (s || "ABERTO");',
'}',
'export function PointBadge(props: { p: any }) {',
'  const s = getPointStatus(props.p);',
'  const ok = isResolvedStatus(s);',
'  const label = badgeLabel(props.p);',
'  return (',
'    <span',
'      style={{',
'        display: "inline-block",',
'        padding: "6px 10px",',
'        borderRadius: 999,',
'        border: "1px solid #111",',
'        fontWeight: 900,',
'        background: ok ? "#B7FFB7" : "#FFDD00",',
'        color: "#111",',
'        textTransform: "uppercase",',
'        letterSpacing: 0.4,',
'        fontSize: 12,',
'        lineHeight: "12px",',
'        marginBottom: 8,',
'      }}',
'    >',
'      {label}',
'    </span>',
'  );',
'}',
''
)

EnsureDir (Split-Path -Parent $helper)
WriteUtf8NoBom $helper ($LHelper -join "`n")
Write-Host "[PATCH] wrote PointStatus helper"

# 2) scan for candidate TSX files referencing /api/eco/points
$srcApp = Join-Path $Root 'src/app'
if (-not (Test-Path -LiteralPath $srcApp)) { throw "[STOP] Não achei src/app" }

$tsx = Get-ChildItem -Path $srcApp -Recurse -File -Filter '*.tsx' -ErrorAction SilentlyContinue `
  | Where-Object { $_.FullName -notmatch "\\eco\\share\\" }

$hits = @()
foreach ($f in $tsx) {
  $raw = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction SilentlyContinue
  if (-not $raw) { continue }
  if ($raw -notmatch "/api/eco/points") { continue }

  $score = 0
  $lp = $f.FullName.ToLowerInvariant()
  $lc = $raw.ToLowerInvariant()

  if ($lp -match "\\eco\\") { $score += 5 }
  if ($lp -match "\\mapa\\") { $score += 25 }
  if ($lp -match "\\pontos\\") { $score += 35 }
  if ($lp -match "\\points\\") { $score += 35 }
  if ($lc.Contains("maplibre") -or $lc.Contains("mapbox") -or $lc.Contains("leaflet") -or $lc.Contains("marker")) { $score += 20 }
  if ($lc.Contains("points.map") -or $lc.Contains("items.map") -or $lc.Contains("rows.map")) { $score += 20 }

  $hits += [PSCustomObject]@{ path=$f.FullName; score=$score }
}

if ($hits.Count -eq 0) {
  Write-Host "[WARN] Não achei TSX com /api/eco/points para patch de lista/map. (helper foi criado mesmo assim)"
}

$hits = $hits | Sort-Object score -Descending

# pick up to 3 targets: top list-like + top map-like
$targets = @()

# map-like: prefer contains "\mapa\"
$mapT = $hits | Where-Object { $_.path -match "\\mapa\\" } | Select-Object -First 1
if ($mapT) { $targets += $mapT }

# list-like: prefer contains "\pontos\" or "\points\"
$listT = $hits | Where-Object { $_.path -match "\\pontos\\|\\points\\" } | Select-Object -First 1
if ($listT) { $targets += $listT }

# fallback: next best
$targets += ($hits | Select-Object -First 2)

# unique
$targets = $targets | Sort-Object path -Unique

$patched = @()
foreach ($t in $targets) {
  $p = $t.path
  if (-not (Test-Path -LiteralPath $p)) { continue }
  $raw = Get-Content -LiteralPath $p -Raw
  if (-not $raw) { continue }
  $nl = DetectNewline $raw

  Write-Host ('[DIAG] Candidate: ' + $p + ' (score ' + $t.score + ')')

  $changed = $false
  $raw2 = $raw

  # add import
  $imp = 'import { PointBadge, markerFill, markerBorder } from "@/app/eco/_ui/PointStatus";'
  $raw2 = AddImportIfMissing $raw2 $nl $imp
  if ($raw2 -ne $raw) { $changed = $true }

  # inject badge into first map render
  $rBadge = InsertBadgeInFirstMap $raw2 $nl
  if ($rBadge.ok) { $raw2 = $rBadge.raw; $changed = $true; Write-Host ('[PATCH] badge injected using var ' + $rBadge.var) }
  else { Write-Host ('[INFO] badge not injected: ' + $rBadge.why) }

  # maplibre marker patch best-effort
  $rMap = PatchMapLibreMarkers $raw2 $nl
  if ($rMap.ok) { $raw2 = $rMap.raw; $changed = $true; Write-Host ('[PATCH] maplibre marker color injected using var ' + $rMap.var) }
  else { Write-Host ('[INFO] marker patch skipped: ' + $rMap.why) }

  if ($changed) {
    BackupFile $Root $p $backupDir
    WriteUtf8NoBom $p $raw2
    $patched += $p
  }
}

# REPORT
$rep = Join-Path $reportDir ('eco-step-78-points-list-map-status-markers-v0_1-' + $ts + '.md')
$repLines = @(
'# eco-step-78-points-list-map-status-markers-v0_1',
'',
'- Time: ' + $ts,
'- Backup: ' + $backupDir,
'',
'## Added',
'- src/app/eco/_ui/PointStatus.tsx (PointBadge + markerFill/markerBorder)',
'',
'## Patched (best-effort)',
(($patched | ForEach-Object { '- ' + $_.Substring($Root.Length).TrimStart('\','/') }) -join "`n"),
'',
'## Verify',
'1) Ctrl+C -> npm run dev',
'2) Abra a LISTA de pontos (onde aparece cards) e confira o carimbo ABERTO/RESOLVIDO',
'3) Abra o MAPA (se usa MapLibre markers) e confira: pinos verdes para RESOLVIDO, amarelos para ABERTO'
)
WriteUtf8NoBom $rep ($repLines -join "`n")
Write-Host ('[REPORT] ' + $rep)

Write-Host ""
Write-Host "[VERIFY] Ctrl+C -> npm run dev"
Write-Host "[VERIFY] conferir LISTA e MAPA de pontos: badge + cor do marcador"