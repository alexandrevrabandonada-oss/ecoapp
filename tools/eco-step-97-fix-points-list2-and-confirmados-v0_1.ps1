param([string]$Root = (Get-Location).Path)

$ts = Get-Date -Format "yyyyMMdd-HHmmss"
Write-Host ("== eco-step-97-fix-points-list2-and-confirmados-v0_1 == " + $ts)
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

$backupDir = Join-Path $Root ("tools/_patch_backup/" + $ts + "-eco-step-97-fix-points-list2-and-confirmados-v0_1")
$reportDir = Join-Path $Root "reports"
EnsureDir $backupDir
EnsureDir $reportDir

# Targets
$list2 = Join-Path $Root "src/app/api/eco/points/list2/route.ts"
if (-not (Test-Path -LiteralPath $list2)) { $list2 = FindFileBySuffix $Root "app/api/eco/points/list2/route.ts" }
if (-not $list2) { throw "[STOP] Nao achei: src/app/api/eco/points/list2/route.ts" }

$muralClient = Join-Path $Root "src/app/eco/mural/MuralClient.tsx"
if (-not (Test-Path -LiteralPath $muralClient)) { $muralClient = FindFileBySuffix $Root "app/eco/mural/MuralClient.tsx" }

$muralPage = Join-Path $Root "src/app/eco/mural/page.tsx"
if (-not (Test-Path -LiteralPath $muralPage)) { $muralPage = FindFileBySuffix $Root "app/eco/mural/page.tsx" }

$confirmPage = Join-Path $Root "src/app/eco/mural/confirmados/page.tsx"

Write-Host ("[DIAG] list2:      " + $list2)
if ($muralClient) { Write-Host ("[DIAG] MuralClient: " + $muralClient) } else { Write-Host "[WARN] Nao achei MuralClient.tsx (vou seguir mesmo)"; }
if ($muralPage) { Write-Host ("[DIAG] Mural page:  " + $muralPage) } else { Write-Host "[WARN] Nao achei mural/page.tsx (vou criar confirmados mesmo)"; }
Write-Host ("[DIAG] Will write: " + $confirmPage)

BackupFile $Root $list2 $backupDir
if ($muralClient) { BackupFile $Root $muralClient $backupDir }
if ($muralPage) { BackupFile $Root $muralPage $backupDir }
BackupFile $Root $confirmPage $backupDir

# -----------------------------
# 1) REWRITE list2 route (clean, no multiline strings)
# -----------------------------
$L = New-Object System.Collections.Generic.List[string]
$L.Add('import { NextResponse } from "next/server";')
$L.Add('import { prisma } from "@/lib/prisma";')
$L.Add('')
$L.Add('export const runtime = "nodejs";')
$L.Add('export const dynamic = "force-dynamic";')
$L.Add('')
$L.Add('function asMsg(e: unknown) {')
$L.Add('  if (e instanceof Error) return e.message;')
$L.Add('  try { return String(e); } catch { return "unknown"; }')
$L.Add('}')
$L.Add('')
$L.Add('function asInt(v: any, def: number) {')
$L.Add('  const n = Number(v);')
$L.Add('  return Number.isFinite(n) && n > 0 ? Math.floor(n) : def;')
$L.Add('}')
$L.Add('')
$L.Add('function pickModel(pc: any, candidates: string[]) {')
$L.Add('  for (const k of candidates) {')
$L.Add('    const m = pc?.[k];')
$L.Add('    if (m && typeof m.findMany === "function") return { key: k, model: m as any };')
$L.Add('  }')
$L.Add('  return null;')
$L.Add('}')
$L.Add('')
$L.Add('function looksLikeUnknownArg(msg: string) {')
$L.Add('  const m = msg.toLowerCase();')
$L.Add('  return m.includes("unknown argument") || m.includes("unknown arg");')
$L.Add('}')
$L.Add('')
$L.Add('async function tryFindMany(model: any, tries: any[]) {')
$L.Add('  let last: any = null;')
$L.Add('  for (const args of tries) {')
$L.Add('    try {')
$L.Add('      return await model.findMany(args);')
$L.Add('    } catch (e) {')
$L.Add('      last = e;')
$L.Add('      const msg = asMsg(e);')
$L.Add('      if (!looksLikeUnknownArg(msg)) break;')
$L.Add('    }')
$L.Add('  }')
$L.Add('  if (last) throw last;')
$L.Add('  return [];')
$L.Add('}')
$L.Add('')
$L.Add('async function groupCountBy(confirmModel: any, fieldName: string) {')
$L.Add('  const map: Record<string, number> = {};')
$L.Add('  if (!confirmModel || typeof confirmModel.groupBy !== "function") return map;')
$L.Add('  try {')
$L.Add('    const rows = await confirmModel.groupBy({ by: [fieldName], _count: { _all: true } } as any);')
$L.Add('    for (const r of rows as any[]) {')
$L.Add('      const id = String((r as any)?.[fieldName] ?? "");')
$L.Add('      const n = Number((r as any)?._count?._all ?? 0) || 0;')
$L.Add('      if (id) map[id] = n;')
$L.Add('    }')
$L.Add('    return map;')
$L.Add('  } catch {')
$L.Add('    return map;')
$L.Add('  }')
$L.Add('}')
$L.Add('')
$L.Add('export async function GET(req: Request) {')
$L.Add('  const url = new URL(req.url);')
$L.Add('  const limit = Math.min(500, asInt(url.searchParams.get("limit"), 160));')
$L.Add('  const base = String(url.searchParams.get("base") || "pontos").trim();')
$L.Add('')
$L.Add('  const pc: any = prisma as any;')
$L.Add('  const pointPick = pickModel(pc, ["ecoCriticalPoint","criticalPoint","ecoPoint","point"]);')
$L.Add('  if (!pointPick) return NextResponse.json({ ok: false, error: "model_not_ready", detail: "point model" }, { status: 503 });')
$L.Add('')
$L.Add('  const confirmPick = pickModel(pc, ["ecoPointConfirm","pointConfirm","ecoCriticalPointConfirm","criticalPointConfirm","ecoConfirm","confirm"]);')
$L.Add('')
$L.Add('  try {')
$L.Add('    const tries: any[] = [];')
$L.Add('    // try createdAt desc, then id desc, then no order')
$L.Add('    tries.push({ take: limit, orderBy: { createdAt: "desc" } as any });')
$L.Add('    tries.push({ take: limit, orderBy: { id: "desc" } as any });')
$L.Add('    tries.push({ take: limit });')
$L.Add('    let items: any[] = await tryFindMany(pointPick.model, tries);')
$L.Add('')
$L.Add('    // counts.confirm best-effort')
$L.Add('    let countsById: Record<string, number> = {};')
$L.Add('    let confirmField = "";')
$L.Add('    if (confirmPick) {')
$L.Add('      const a = await groupCountBy(confirmPick.model, "pointId");')
$L.Add('      if (Object.keys(a).length > 0) { countsById = a; confirmField = "pointId"; }')
$L.Add('      if (!confirmField) {')
$L.Add('        const b = await groupCountBy(confirmPick.model, "criticalPointId");')
$L.Add('        if (Object.keys(b).length > 0) { countsById = b; confirmField = "criticalPointId"; }')
$L.Add('      }')
$L.Add('    }')
$L.Add('')
$L.Add('    // attach counts + filter base')
$L.Add('    items = items.map((p) => {')
$L.Add('      const id = String((p as any)?.id ?? "");')
$L.Add('      const n = id ? (countsById[id] ?? 0) : 0;')
$L.Add('      return { ...p, counts: { ...(p as any)?.counts, confirm: n } };')
$L.Add('    });')
$L.Add('')
$L.Add('    if (base === "confirmados") {')
$L.Add('      items = items.filter((p) => Number((p as any)?.counts?.confirm ?? 0) > 0);')
$L.Add('      items.sort((a, b) => Number((b as any)?.counts?.confirm ?? 0) - Number((a as any)?.counts?.confirm ?? 0));')
$L.Add('    }')
$L.Add('    if (base === "chamados") {')
$L.Add('      // best-effort: prioriza OPEN se existir')
$L.Add('      items.sort((a, b) => {')
$L.Add('        const sa = String((a as any)?.status ?? "");')
$L.Add('        const sb = String((b as any)?.status ?? "");')
$L.Add('        const oa = sa === "OPEN" ? 0 : 1;')
$L.Add('        const ob = sb === "OPEN" ? 0 : 1;')
$L.Add('        if (oa !== ob) return oa - ob;')
$L.Add('        return 0;')
$L.Add('      });')
$L.Add('    }')
$L.Add('')
$L.Add('    return NextResponse.json({')
$L.Add('      ok: true,')
$L.Add('      items,')
$L.Add('      meta: {')
$L.Add('        base,')
$L.Add('        pointModel: pointPick.key,')
$L.Add('        confirmModel: confirmPick ? confirmPick.key : null,')
$L.Add('        confirmBy: confirmField || null,')
$L.Add('      },')
$L.Add('    });')
$L.Add('  } catch (e) {')
$L.Add('    const msg = asMsg(e);')
$L.Add('    return NextResponse.json({ ok: false, error: "db_error", detail: msg }, { status: 500 });')
$L.Add('  }')
$L.Add('}')
$codeList2 = ($L -join "`n")
WriteUtf8NoBom $list2 $codeList2
Write-Host "[PATCH] rewrote /api/eco/points/list2 (clean, no multiline strings)"

# -----------------------------
# 2) Create /eco/mural/confirmados page
# -----------------------------
$importLine = 'import MuralClient from "../MuralClient";'
if ($muralClient -and (Test-Path -LiteralPath $muralClient)) {
  $mr = Get-Content -LiteralPath $muralClient -Raw -ErrorAction Stop
  if ($mr -notmatch 'export\s+default') {
    $importLine = 'import { MuralClient } from "../MuralClient";'
  }
}
$P = New-Object System.Collections.Generic.List[string]
$P.Add($importLine)
$P.Add('')
$P.Add('export const dynamic = "force-dynamic";')
$P.Add('')
$P.Add('export default function Page() {')
$P.Add('  return (')
$P.Add('    <main style={{ padding: 16, maxWidth: 1100, margin: "0 auto" }}>')
$P.Add('      <h1 style={{ margin: "0 0 8px 0" }}>Mural — Confirmados</h1>')
$P.Add('      <p style={{ margin: "0 0 14px 0", opacity: 0.85 }}>Pontos que ja tiveram ✅ confirmações (ordenado por mais confirmados).</p>')
if ($importLine -like 'import { MuralClient*') {
  $P.Add('      <MuralClient base="confirmados" />')
} else {
  $P.Add('      <MuralClient base="confirmados" />')
}
$P.Add('    </main>')
$P.Add('  );')
$P.Add('}')
WriteUtf8NoBom $confirmPage (($P -join "`n"))
Write-Host "[PATCH] wrote /eco/mural/confirmados/page.tsx"

# -----------------------------
# 3) Patch mural page: add link button (best-effort, no invalid nesting)
# -----------------------------
if ($muralPage -and (Test-Path -LiteralPath $muralPage)) {
  $raw = Get-Content -LiteralPath $muralPage -Raw -ErrorAction Stop
  if ($raw -notmatch '\/eco\/mural\/confirmados') {
    $lines = $raw -split "`n"
    $idxCham = -1
    for ($i=0; $i -lt $lines.Count; $i++) {
      if ($lines[$i] -match '\/eco\/mural\/chamados') { $idxCham = $i; break }
    }

    if ($idxCham -ge 0) {
      # find close </a> after cham line
      $close = -1
      for ($j=$idxCham; $j -lt [Math]::Min($lines.Count, $idxCham+25); $j++) {
        if ($lines[$j] -match '^\s*<\/a>\s*$') { $close = $j; break }
      }
      if ($close -lt 0) { $close = $idxCham }

      $indent = ""
      $mIndent = [regex]::Match($lines[$idxCham], '^\s*')
      if ($mIndent.Success) { $indent = $mIndent.Value }

      $btnLines = @(
        ($indent + '<a href="/eco/mural/confirmados" style={{ padding: "9px 10px", borderRadius: 12, border: "1px solid #111", textDecoration: "none", color: "#111", fontWeight: 900, background: "#fff" }}>'),
        ($indent + '  ✅ Confirmados'),
        ($indent + '</a>')
      )

      $new = New-Object System.Collections.Generic.List[string]
      for ($i=0; $i -lt $lines.Count; $i++) {
        $new.Add($lines[$i])
        if ($i -eq $close) {
          $new.AddRange($btnLines)
        }
      }
      $raw2 = ($new -join "`n")
      WriteUtf8NoBom $muralPage $raw2
      Write-Host "[PATCH] mural/page.tsx: added link /eco/mural/confirmados"
    } else {
      Write-Host "[WARN] Nao achei link /eco/mural/chamados no mural page; nao inseri botao confirmados."
    }
  } else {
    Write-Host "[SKIP] mural page ja tem link confirmados."
  }
}

# -----------------------------
# 4) Patch MuralClient fetch to send base= (best-effort)
# -----------------------------
if ($muralClient -and (Test-Path -LiteralPath $muralClient)) {
  $raw = Get-Content -LiteralPath $muralClient -Raw -ErrorAction Stop
  $changed = $false

  # Replace fetch("/api/eco/points/list2?....") -> fetch("/api/eco/points/list2?....&base=" + encodeURIComponent(base))
  $rx = [regex]'fetch\(\s*["''](/api/eco/points/list2\?[^"'']*)["'']\s*\)'
  $m = $rx.Match($raw)
  if ($m.Success) {
    $url0 = $m.Groups[1].Value
    if ($url0 -notmatch '(^|[&?])base=') {
      $sep = "&"
      if ($url0 -notmatch '\?') { $sep = "?" }
      $url1 = $url0 + $sep + 'base='
      $replacement = 'fetch("' + $url1 + '" + encodeURIComponent(base))'
      $raw = $rx.Replace($raw, $replacement, 1)
      $changed = $true
      Write-Host "[PATCH] MuralClient: fetch list2 now includes base="
    }
  }

  # If it fetches /api/eco/points?..., do same (alias route)
  $rx2 = [regex]'fetch\(\s*["''](/api/eco/points\?[^"'']*)["'']\s*\)'
  $m2 = $rx2.Match($raw)
  if ($m2.Success) {
    $url0 = $m2.Groups[1].Value
    if ($url0 -notmatch '(^|[&?])base=') {
      $sep = "&"
      if ($url0 -notmatch '\?') { $sep = "?" }
      $url1 = $url0 + $sep + 'base='
      $replacement = 'fetch("' + $url1 + '" + encodeURIComponent(base))'
      $raw = $rx2.Replace($raw, $replacement, 1)
      $changed = $true
      Write-Host "[PATCH] MuralClient: fetch points now includes base="
    }
  }

  if ($changed) {
    WriteUtf8NoBom $muralClient $raw
  } else {
    Write-Host "[SKIP] Nao achei fetch simples para list2/points no MuralClient (ou ja tinha base=)."
  }
}

# Report
$rep = Join-Path $reportDir ("eco-step-97-fix-points-list2-and-confirmados-v0_1-" + $ts + ".md")
$repText = @(
"# eco-step-97-fix-points-list2-and-confirmados-v0_1",
"",
"- Time: " + $ts,
"- Backup: " + $backupDir,
"",
"## Changes",
"- Rewrote: src/app/api/eco/points/list2/route.ts (remove multiline strings; add counts.confirm; support base=confirmados/chamados)",
"- Added:  src/app/eco/mural/confirmados/page.tsx",
"- Patched (best-effort): src/app/eco/mural/page.tsx (button Confirmados)",
"- Patched (best-effort): src/app/eco/mural/MuralClient.tsx (send base= in fetch)",
"",
"## Verify",
"1) Ctrl+C -> npm run dev",
"2) http://localhost:3000/api/eco/points/list2?limit=10  (200)",
"3) http://localhost:3000/api/eco/points/list2?limit=50&base=confirmados (200, items com counts.confirm > 0)",
"4) http://localhost:3000/eco/mural (botao Confirmados)",
"5) http://localhost:3000/eco/mural/confirmados",
"6) Network: veja /api/eco/points/list2 ... base=..."
) -join "`n"
WriteUtf8NoBom $rep $repText
Write-Host ("[REPORT] " + $rep)

Write-Host ""
Write-Host "[VERIFY] Ctrl+C -> npm run dev"
Write-Host "[VERIFY] http://localhost:3000/api/eco/points/list2?limit=10"
Write-Host "[VERIFY] http://localhost:3000/api/eco/points/list2?limit=50&base=confirmados"
Write-Host "[VERIFY] /eco/mural e /eco/mural/confirmados"