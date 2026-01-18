param([string]$Root = (Get-Location).Path)

$ts = Get-Date -Format "yyyyMMdd-HHmmss"
Write-Host ("== eco-step-99-point-support-action-v0_1 == " + $ts)
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

$backupDir = Join-Path $Root ("tools/_patch_backup/" + $ts + "-eco-step-99-point-support-action-v0_1")
$reportDir = Join-Path $Root "reports"
EnsureDir $backupDir
EnsureDir $reportDir

# --- paths
$schema = Join-Path $Root "prisma/schema.prisma"
if (-not (Test-Path -LiteralPath $schema)) { throw "[STOP] Nao achei prisma/schema.prisma" }

$list2 = Join-Path $Root "src/app/api/eco/points/list2/route.ts"
if (-not (Test-Path -LiteralPath $list2)) { $list2 = FindFileBySuffix $Root "app/api/eco/points/list2/route.ts" }
if (-not $list2) { throw "[STOP] Nao achei list2: src/app/api/eco/points/list2/route.ts" }

$inline = Join-Path $Root "src/app/eco/_components/PointActionsInline.tsx"
if (-not (Test-Path -LiteralPath $inline)) { $inline = FindFileBySuffix $Root "app/eco/_components/PointActionsInline.tsx" }
if (-not $inline) { throw "[STOP] Nao achei: src/app/eco/_components/PointActionsInline.tsx" }

$btnFile = Join-Path $Root "src/app/eco/_components/PointSupportButton.tsx"
$apiFile = Join-Path $Root "src/app/api/eco/points/support/route.ts"

Write-Host ("[DIAG] schema: " + $schema)
Write-Host ("[DIAG] list2:  " + $list2)
Write-Host ("[DIAG] inline: " + $inline)
Write-Host ("[DIAG] will write btn: " + $btnFile)
Write-Host ("[DIAG] will write api: " + $apiFile)

BackupFile $Root $schema $backupDir
BackupFile $Root $list2 $backupDir
BackupFile $Root $inline $backupDir
BackupFile $Root $btnFile $backupDir
BackupFile $Root $apiFile $backupDir

# -----------------------------
# 1) Prisma: add model EcoPointSupport + migrate
# -----------------------------
$sch = Get-Content -LiteralPath $schema -Raw -ErrorAction Stop

# detect point model name (for relation)
$pointModel = $null
foreach ($cand in @("EcoCriticalPoint","CriticalPoint","EcoPoint","Point")) {
  if ($sch -match ("model\s+" + [regex]::Escape($cand) + "\s*\{")) { $pointModel = $cand; break }
}
if (-not $pointModel) {
  # fallback: if schema has an obvious "model" with "lat" and "lng", pick it
  $models = [regex]::Matches($sch, 'model\s+([A-Za-z0-9_]+)\s*\{')
  foreach ($m in $models) {
    $name = $m.Groups[1].Value
    $blockStart = $m.Index
    $block = $sch.Substring($blockStart, [Math]::Min(2000, $sch.Length - $blockStart))
    if ($block -match '\blat\b' -and $block -match '\blng\b') { $pointModel = $name; break }
  }
}
if (-not $pointModel) { throw "[STOP] Nao consegui detectar o model do Ponto Critico no schema. (EcoCriticalPoint/CriticalPoint/EcoPoint/Point)" }

Write-Host ("[DIAG] Point model detected: " + $pointModel)

if ($sch -notmatch 'model\s+EcoPointSupport\s*\{') {
  $modelLines = @(
    '',
    'model EcoPointSupport {',
    '  id        String   @id @default(cuid())',
    '  pointId   String',
    '  note      String?',
    '  createdAt DateTime @default(now())',
    '',
    ('  point     ' + $pointModel + ' @relation(fields: [pointId], references: [id], onDelete: Cascade)'),
    '',
    '  @@index([pointId])',
    '}',
    ''
  )
  $sch2 = $sch + ($modelLines -join "`n")
  WriteUtf8NoBom $schema $sch2
  Write-Host "[PATCH] schema.prisma: appended model EcoPointSupport"
} else {
  Write-Host "[SKIP] schema already has EcoPointSupport"
}

# run prisma migrate dev (best-effort)
$prismaCmd = Join-Path $Root "node_modules/.bin/prisma.cmd"
if (-not (Test-Path -LiteralPath $prismaCmd)) { $prismaCmd = Join-Path $Root "node_modules\.bin\prisma.cmd" }
if (Test-Path -LiteralPath $prismaCmd) {
  Write-Host ("[RUN] " + $prismaCmd + " migrate dev --name eco_point_support")
  try {
    & $prismaCmd migrate dev --name eco_point_support | Out-Host
  } catch {
    Write-Host "[WARN] prisma migrate dev falhou (best-effort). Se precisar, roda manual depois."
  }
  Write-Host ("[RUN] " + $prismaCmd + " generate")
  try { & $prismaCmd generate | Out-Host } catch { Write-Host "[WARN] prisma generate falhou (best-effort)." }
} else {
  Write-Host "[WARN] prisma.cmd nao encontrado. Rode migrate/generate manual depois."
}

# -----------------------------
# 2) API: POST /api/eco/points/support
# -----------------------------
$apiLines = @(
  'import { NextResponse } from "next/server";',
  'import { prisma } from "@/lib/prisma";',
  '',
  'export const runtime = "nodejs";',
  'export const dynamic = "force-dynamic";',
  '',
  'function pickModel(pc: any, primary: string, candidates: string[]) {',
  '  if (pc?.[primary]) return pc[primary];',
  '  for (const k of candidates) {',
  '    if (pc?.[k]) return pc[k];',
  '  }',
  '  return null;',
  '}',
  '',
  'export async function POST(req: Request) {',
  '  try {',
  '    const body = await req.json().catch(() => ({} as any));',
  '    const pointId = String((body as any)?.pointId || "");',
  '    const noteRaw = (body as any)?.note;',
  '    const note = (typeof noteRaw === "string" && noteRaw.trim().length > 0) ? noteRaw.trim().slice(0, 300) : null;',
  '',
  '    if (!pointId) return NextResponse.json({ ok: false, error: "missing_pointId" }, { status: 400 });',
  '',
  '    const pc: any = prisma as any;',
  '    const support = pickModel(pc, "ecoPointSupport", ["ecoPointSupport", "pointSupport", "ecoCriticalPointSupport", "support"]);',
  '    if (!support?.create) return NextResponse.json({ ok: false, error: "model_missing", hint: "EcoPointSupport" }, { status: 500 });',
  '',
  '    const row = await support.create({ data: { pointId, note } });',
  '    return NextResponse.json({ ok: true, id: String(row?.id || "") });',
  '  } catch (e: any) {',
  '    return NextResponse.json({ ok: false, error: "exception", message: String(e?.message || e) }, { status: 500 });',
  '  }',
  '}'
)
WriteUtf8NoBom $apiFile ($apiLines -join "`n")
Write-Host "[PATCH] wrote /api/eco/points/support"

# -----------------------------
# 3) list2: add counts.support via groupBy(pointId) + include in counts
# -----------------------------
$r2 = Get-Content -LiteralPath $list2 -Raw -ErrorAction Stop
$changedList2 = $false

if ($r2 -notmatch 'counts\.support') {
  # insert support block after confirm block marker if exists
  $marker = '// counts.confirm via groupBy(pointId)'
  if ($r2 -match [regex]::Escape($marker)) {
    # find end of confirm map section: we look for "const map" or "const confirmMap"
    # we'll insert support block after first occurrence of "const map" for confirm, or after comment block area.
    $lines = $r2 -split "`n"
    $insertAt = -1
    for ($i=0; $i -lt $lines.Count; $i++) {
      if ($lines[$i] -match [regex]::Escape($marker)) {
        # scan forward to first empty line after confirm section start, but cap
        for ($j=$i+1; $j -lt [Math]::Min($lines.Count, $i+80); $j++) {
          if ($lines[$j] -match 'const\s+map\s*:\s*Record<\s*string\s*,\s*number\s*>' -or $lines[$j] -match 'const\s+confirmMap\s*:\s*Record<') {
            # insert after the confirm map is filled; find next blank line after this block
            for ($k=$j; $k -lt [Math]::Min($lines.Count, $i+140); $k++) {
              if ($lines[$k].Trim() -eq '') { $insertAt = $k+1; break }
            }
            if ($insertAt -gt 0) { break }
          }
        }
        if ($insertAt -gt 0) { break }
      }
    }
    if ($insertAt -lt 0) { $insertAt = 0 }

    $supportBlock = @(
      '',
      '  // counts.support via groupBy(pointId)',
      '  const support = pc?.["ecoPointSupport"];',
      '  const supportMap: Record<string, number> = {};',
      '  if (support?.groupBy) {',
      '    const rows = await support.groupBy({ by: ["pointId"], _count: { _all: true } });',
      '    for (const r of rows) {',
      '      const pid = String((r as any)?.pointId || "");',
      '      if (!pid) continue;',
      '      const n = Number((r as any)?._count?._all ?? 0);',
      '      supportMap[pid] = Number.isFinite(n) ? n : 0;',
      '    }',
      '  }',
      ''
    )

    $out = New-Object System.Collections.Generic.List[string]
    for ($i=0; $i -lt $lines.Count; $i++) {
      $out.Add($lines[$i])
      if ($i -eq ($insertAt-1)) {
        $out.AddRange($supportBlock)
      }
    }
    $r2 = ($out -join "`n")
    $changedList2 = $true
  }

  # add support into counts object (cheap patch)
  if ($r2 -match 'counts\s*:\s*\{\s*confirm\s*:') {
    # ensure support is added after confirm
    $r2b = [regex]::Replace(
      $r2,
      'counts\s*:\s*\{\s*confirm\s*:\s*([^,}]+)',
      { param($m) ("counts: { confirm: " + $m.Groups[1].Value + ", support: (supportMap?.[String((p as any)?.id || (p as any)?.pointId || '')] ?? 0)") },
      1
    )
    if ($r2b -ne $r2) { $r2 = $r2b; $changedList2 = $true }
  }
}

if ($changedList2) {
  WriteUtf8NoBom $list2 $r2
  Write-Host "[PATCH] list2: added supportMap + counts.support (best-effort)"
} else {
  Write-Host "[SKIP] list2 ja tinha counts.support (ou nao encontrei ponto seguro p/ inserir)"
}

# -----------------------------
# 4) UI: PointSupportButton + inject into PointActionsInline
# -----------------------------
$btnLines = @(
  '"use client";',
  '',
  'import { useRouter } from "next/navigation";',
  'import { useState } from "react";',
  '',
  'export default function PointSupportButton({ pointId, count }: { pointId: string; count?: number }) {',
  '  const router = useRouter();',
  '  const [busy, setBusy] = useState(false);',
  '  const n = Number(count ?? 0);',
  '  const showN = Number.isFinite(n) && n > 0;',
  '',
  '  async function onClick() {',
  '    if (!pointId) return;',
  '    const note = window.prompt("🤝 Apoiar: quer deixar uma observação curta? (opcional)","") ?? "";',
  '    setBusy(true);',
  '    try {',
  '      await fetch("/api/eco/points/support", {',
  '        method: "POST",',
  '        headers: { "Content-Type": "application/json" },',
  '        body: JSON.stringify({ pointId, note }),',
  '      });',
  '      router.refresh();',
  '    } finally {',
  '      setBusy(false);',
  '    }',
  '  }',
  '',
  '  return (',
  '    <button',
  '      type="button"',
  '      onClick={onClick}',
  '      disabled={busy}',
  '      style={{',
  '        padding: "8px 10px",',
  '        borderRadius: 12,',
  '        border: "1px solid #111",',
  '        background: "#fff",',
  '        fontWeight: 900,',
  '        cursor: busy ? "progress" : "pointer",',
  '        display: "inline-flex",',
  '        alignItems: "center",',
  '        gap: 8,',
  '        whiteSpace: "nowrap",',
  '      }}',
  '      title="Apoiar (trazer item/ajuda para resolver)"',
  '    >',
  '      🤝 Apoiar',
  '      {showN ? (',
  '        <span style={{',
  '          display: "inline-flex",',
  '          alignItems: "center",',
  '          justifyContent: "center",',
  '          minWidth: 18,',
  '          padding: "2px 8px",',
  '          borderRadius: 999,',
  '          background: "#111",',
  '          color: "#fff",',
  '          fontSize: 12,',
  '          lineHeight: "12px",',
  '        }}>{n}</span>',
  '      ) : null}',
  '    </button>',
  '  );',
  '}'
)
WriteUtf8NoBom $btnFile ($btnLines -join "`n")
Write-Host "[PATCH] wrote PointSupportButton.tsx"

$inl = Get-Content -LiteralPath $inline -Raw -ErrorAction Stop
$didInline = $false

if ($inl -notmatch 'PointSupportButton') {
  # add import after last import
  $linesI = $inl -split "`n"
  $lastImport = -1
  for ($i=0; $i -lt $linesI.Count; $i++) { if ($linesI[$i] -match '^\s*import\s+') { $lastImport = $i } }

  $importLine = 'import PointSupportButton from "./PointSupportButton";'
  $outI = New-Object System.Collections.Generic.List[string]
  for ($i=0; $i -lt $linesI.Count; $i++) {
    $outI.Add($linesI[$i])
    if ($i -eq $lastImport) { $outI.Add($importLine) }
  }
  $inl2 = ($outI -join "`n")

  # insert button near Confirm (or first actions block)
  $linesJ = $inl2 -split "`n"
  $insAt = -1
  for ($i=0; $i -lt $linesJ.Count; $i++) {
    if ($linesJ[$i] -match '/api/eco/points/confirm' -or $linesJ[$i] -match 'Confirmar' -or $linesJ[$i] -match 'CONFIRM') {
      # insert after the closing </button> of confirm
      for ($j=$i; $j -lt [Math]::Min($linesJ.Count, $i+30); $j++) {
        if ($linesJ[$j] -match '</button>') { $insAt = $j+1; break }
      }
      if ($insAt -gt 0) { break }
    }
  }
  if ($insAt -lt 0) {
    # fallback: insert after first <button
    for ($i=0; $i -lt $linesJ.Count; $i++) {
      if ($linesJ[$i] -match '<button') { $insAt = $i; break }
    }
  }
  if ($insAt -lt 0) { throw "[STOP] Nao achei lugar seguro pra inserir o PointSupportButton no PointActionsInline." }

  $indent = ""
  $mInd = [regex]::Match($linesJ[[Math]::Max(0,$insAt-1)], '^\s*')
  if ($mInd.Success) { $indent = $mInd.Value }

  $btnJsx = $indent + '<PointSupportButton pointId={String((point as any)?.id || "")} count={Number((point as any)?.counts?.support ?? 0)} />'

  $outJ = New-Object System.Collections.Generic.List[string]
  for ($i=0; $i -lt $linesJ.Count; $i++) {
    if ($i -eq $insAt) { $outJ.Add($btnJsx) }
    $outJ.Add($linesJ[$i])
  }

  $finalInline = ($outJ -join "`n")
  WriteUtf8NoBom $inline $finalInline
  $didInline = $true
  Write-Host "[PATCH] PointActionsInline: imported + inserted PointSupportButton"
} else {
  Write-Host "[SKIP] PointActionsInline ja tem PointSupportButton"
}

# report
$rep = Join-Path $reportDir ("eco-step-99-point-support-action-v0_1-" + $ts + ".md")
$repText = @(
"# eco-step-99-point-support-action-v0_1",
"",
"- Time: " + $ts,
"- Backup: " + $backupDir,
"",
"## Changes",
"- Prisma: model EcoPointSupport (pointId, note, createdAt) + migrate dev (best-effort) + generate",
"- API: POST /api/eco/points/support",
"- UI: PointSupportButton + inject in PointActionsInline",
"- list2: counts.support via groupBy(pointId) (best-effort) + inclui em counts",
"",
"## Verify",
"1) Ctrl+C -> npm run dev",
"2) /eco/mural: clique 🤝 Apoiar em um ponto",
"3) Recarregue: deve aparecer (N) no botão",
"4) Network: POST /api/eco/points/support -> { ok: true }"
) -join "`n"
WriteUtf8NoBom $rep $repText
Write-Host ("[REPORT] " + $rep)

Write-Host ""
Write-Host "[VERIFY] Ctrl+C -> npm run dev"
Write-Host "[VERIFY] /eco/mural -> clicar 🤝 Apoiar"
Write-Host "[VERIFY] ver count no botao (N) e POST /api/eco/points/support ok"