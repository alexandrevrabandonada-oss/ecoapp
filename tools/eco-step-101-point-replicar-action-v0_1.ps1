param(
  [string]$Root = (Get-Location).Path
)

$ts = Get-Date -Format "yyyyMMdd-HHmmss"
Write-Host ("== eco-step-101-point-replicar-action-v0_1 == " + $ts)
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
if (-not (Get-Command NewReport -ErrorAction SilentlyContinue)) {
  function NewReport([string]$root, [string]$name, [string[]]$lines) {
    $dir = Join-Path $root "reports"
    EnsureDir $dir
    $p = Join-Path $dir ($name + "-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".md")
    WriteUtf8NoBom $p (($lines -join "`n") + "`n")
    return $p
  }
}

function FindModelBlock([string]$text, [string]$modelName) {
  $m = [regex]::Match($text, "(?ms)^\s*model\s+" + [regex]::Escape($modelName) + "\s*\{")
  if (-not $m.Success) { return $null }
  $openIdx = $text.IndexOf("{", $m.Index)
  if ($openIdx -lt 0) { return $null }
  $i = $openIdx
  $depth = 0
  while ($i -lt $text.Length) {
    $ch = $text[$i]
    if ($ch -eq "{") { $depth++ }
    elseif ($ch -eq "}") {
      $depth--
      if ($depth -eq 0) {
        return @{ start = $m.Index; open = $openIdx; close = $i; end = $i + 1 }
      }
    }
    $i++
  }
  return $null
}

$backupDir = Join-Path $Root ("tools/_patch_backup/" + $ts + "-eco-step-101")
EnsureDir $backupDir

$schema = Join-Path $Root "prisma/schema.prisma"
$list2  = Join-Path $Root "src/app/api/eco/points/list2/route.ts"
$inline = Join-Path $Root "src/app/eco/_components/PointActionsInline.tsx"
$btn    = Join-Path $Root "src/app/eco/_components/PointReplicarButton.tsx"
$api    = Join-Path $Root "src/app/api/eco/points/replicar/route.ts"

Write-Host ("[DIAG] schema: " + $schema)
Write-Host ("[DIAG] list2:  " + $list2)
Write-Host ("[DIAG] inline: " + $inline)
Write-Host ("[DIAG] will write btn: " + $btn)
Write-Host ("[DIAG] will write api: " + $api)

if (-not (Test-Path -LiteralPath $schema)) { throw "[STOP] Nao achei prisma/schema.prisma" }
if (-not (Test-Path -LiteralPath $list2))  { throw "[STOP] Nao achei src/app/api/eco/points/list2/route.ts" }
if (-not (Test-Path -LiteralPath $inline)) { throw "[STOP] Nao achei src/app/eco/_components/PointActionsInline.tsx" }

BackupFile $Root $schema $backupDir
BackupFile $Root $list2  $backupDir
BackupFile $Root $inline $backupDir
BackupFile $Root $btn    $backupDir
BackupFile $Root $api    $backupDir

# -------------------------
# PATCH 1) Prisma schema: add model EcoPointReplicate + opposite field in EcoCriticalPoint
# -------------------------
$raw = Get-Content -LiteralPath $schema -Raw -ErrorAction Stop

if ($raw -match "(?ms)^\s*model\s+EcoPointReplicate\s*\{") {
  Write-Host "[SKIP] schema.prisma ja tem model EcoPointReplicate"
} else {
  $append = @(
    "",
    "model EcoPointReplicate {",
    "  id          String    @id @default(cuid())",
    "  createdAt   DateTime  @default(now())",
    "  pointId     String",
    "  fingerprint String",
    "",
    "  point       EcoCriticalPoint @relation(fields: [pointId], references: [id], onDelete: Cascade)",
    "",
    "  @@unique([pointId, fingerprint])",
    "  @@index([pointId])",
    "}",
    ""
  ) -join "`r`n"

  WriteUtf8NoBom $schema ($raw + $append)
  $raw = Get-Content -LiteralPath $schema -Raw -ErrorAction Stop
  Write-Host "[PATCH] schema.prisma: appended model EcoPointReplicate"
}

$blk = FindModelBlock $raw "EcoCriticalPoint"
if ($null -eq $blk) {
  Write-Host "[WARN] Nao achei model EcoCriticalPoint (vou pular campo oposto replicates)."
} else {
  $inside = $raw.Substring($blk.open + 1, $blk.close - $blk.open - 1)
  if ($inside -match "(?m)^\s*replicates\s+EcoPointReplicate\[\]") {
    Write-Host "[SKIP] EcoCriticalPoint ja tem replicates EcoPointReplicate[]"
  } else {
    $insertLine = "  replicates EcoPointReplicate[]"
    $before = $raw.Substring(0, $blk.close)
    $after  = $raw.Substring($blk.close)
    if ($before -notmatch "(\r?\n)\s*$") { $before = $before + "`r`n" }
    $before = $before + $insertLine + "`r`n"
    $raw2 = $before + $after
    WriteUtf8NoBom $schema $raw2
    Write-Host "[PATCH] schema.prisma: added EcoCriticalPoint.replicates EcoPointReplicate[]"
  }
}

# -------------------------
# Prisma migrate + generate
# -------------------------
$prismaCmd = Join-Path $Root "node_modules/.bin/prisma.cmd"
if (-not (Test-Path -LiteralPath $prismaCmd)) {
  Write-Host "[WARN] prisma.cmd nao encontrado em node_modules/.bin (pulando migrate/generate)."
} else {
  Write-Host ("[RUN] " + $prismaCmd + " validate")
  & $prismaCmd validate

  Write-Host ("[RUN] " + $prismaCmd + " migrate dev --name eco_point_replicate")
  & $prismaCmd migrate dev --name eco_point_replicate

  Write-Host ("[RUN] " + $prismaCmd + " generate")
  & $prismaCmd generate
}

# -------------------------
# PATCH 2) API route /api/eco/points/replicar
# -------------------------
$A = New-Object System.Collections.Generic.List[string]
$A.Add('import { NextResponse } from "next/server";')
$A.Add('import { prisma } from "@/lib/prisma";')
$A.Add('')
$A.Add('export const runtime = "nodejs";')
$A.Add('export const dynamic = "force-dynamic";')
$A.Add('')
$A.Add('function pickModel(pc: any, primary: string, fallbacks: string[]) {')
$A.Add('  if (!pc) return null;')
$A.Add('  if (pc[primary]) return pc[primary];')
$A.Add('  for (const k of fallbacks) {')
$A.Add('    if (pc[k]) return pc[k];')
$A.Add('    const kk = k.charAt(0).toLowerCase() + k.slice(1);')
$A.Add('    if (pc[kk]) return pc[kk];')
$A.Add('  }')
$A.Add('  return null;')
$A.Add('}')
$A.Add('')
$A.Add('function djb2(s: string) {')
$A.Add('  let h = 5381;')
$A.Add('  for (let i = 0; i < s.length; i++) {')
$A.Add('    h = ((h << 5) + h) ^ s.charCodeAt(i);')
$A.Add('  }')
$A.Add('  return (h >>> 0).toString(36);')
$A.Add('}')
$A.Add('')
$A.Add('function fingerprintFrom(req: Request) {')
$A.Add('  const h = req.headers;')
$A.Add('  const ip = (h.get("x-forwarded-for") || h.get("x-real-ip") || "local").split(",")[0].trim();')
$A.Add('  const ua = h.get("user-agent") || "ua";')
$A.Add('  return djb2(ip + "|" + ua);')
$A.Add('}')
$A.Add('')
$A.Add('export async function POST(req: Request) {')
$A.Add('  try {')
$A.Add('    const body = await req.json().catch(() => ({} as any));')
$A.Add('    const pointId = String((body as any)?.pointId || "");')
$A.Add('    if (!pointId) return NextResponse.json({ ok: false, error: "bad_pointId" }, { status: 400 });')
$A.Add('')
$A.Add('    const fp = fingerprintFrom(req);')
$A.Add('    const pc: any = prisma as any;')
$A.Add('    const model = pickModel(pc, "ecoPointReplicate", ["EcoPointReplicate", "pointReplicate", "ecoCriticalPointReplicate", "criticalPointReplicate"]);')
$A.Add('    if (!model) return NextResponse.json({ ok: false, error: "no_model" }, { status: 500 });')
$A.Add('')
$A.Add('    // toggle (idempotent por fingerprint)')
$A.Add('    let existed = null as any;')
$A.Add('    try {')
$A.Add('      existed = await model.findUnique({ where: { pointId_fingerprint: { pointId, fingerprint: fp } } } as any);')
$A.Add('    } catch (e) {')
$A.Add('      existed = await model.findFirst({ where: { pointId, fingerprint: fp } } as any);')
$A.Add('    }')
$A.Add('')
$A.Add('    if (existed?.id) {')
$A.Add('      try { await model.delete({ where: { id: existed.id } } as any); } catch (e) {}')
$A.Add('    } else {')
$A.Add('      try { await model.create({ data: { pointId, fingerprint: fp } } as any); } catch (e) {}')
$A.Add('    }')
$A.Add('')
$A.Add('    const count = await model.count({ where: { pointId } } as any).catch(() => 0);')
$A.Add('    return NextResponse.json({ ok: true, pointId, replicated: existed ? false : true, count });')
$A.Add('  } catch (e: any) {')
$A.Add('    return NextResponse.json({ ok: false, error: "exception", detail: String(e?.message || e) }, { status: 500 });')
$A.Add('  }')
$A.Add('}')
WriteUtf8NoBom $api ($A -join "`n")
Write-Host "[PATCH] wrote /api/eco/points/replicar"

# -------------------------
# PATCH 3) UI button component
# -------------------------
$B = New-Object System.Collections.Generic.List[string]
$B.Add('"use client";')
$B.Add('')
$B.Add('import { useMemo, useState } from "react";')
$B.Add('')
$B.Add('export default function PointReplicarButton({')
$B.Add('  pointId,')
$B.Add('  counts,')
$B.Add('}: {')
$B.Add('  pointId: string;')
$B.Add('  counts?: any;')
$B.Add('}) {')
$B.Add('  const initial = useMemo(() => {')
$B.Add('    const c = counts || {};')
$B.Add('    const n = Number(c.replicate ?? c.replicar ?? c.replica ?? 0);')
$B.Add('    return Number.isFinite(n) ? n : 0;')
$B.Add('  }, [counts]);')
$B.Add('')
$B.Add('  const [n, setN] = useState<number>(initial);')
$B.Add('  const [busy, setBusy] = useState(false);')
$B.Add('')
$B.Add('  async function onClick() {')
$B.Add('    if (busy) return;')
$B.Add('    setBusy(true);')
$B.Add('    try {')
$B.Add('      const res = await fetch("/api/eco/points/replicar", {')
$B.Add('        method: "POST",')
$B.Add('        headers: { "Content-Type": "application/json" },')
$B.Add('        body: JSON.stringify({ pointId }),')
$B.Add('      });')
$B.Add('      const j = await res.json().catch(() => null);')
$B.Add('      if (j && j.ok) setN(Number(j.count || 0));')
$B.Add('    } finally {')
$B.Add('      setBusy(false);')
$B.Add('    }')
$B.Add('  }')
$B.Add('')
$B.Add('  return (')
$B.Add('    <button')
$B.Add('      type="button"')
$B.Add('      onClick={onClick}')
$B.Add('      disabled={busy}')
$B.Add('      title="Replicar (boa prática)"')
$B.Add('      style={{')
$B.Add('        padding: "8px 10px",')
$B.Add('        borderRadius: 12,')
$B.Add('        border: "1px solid #111",')
$B.Add('        background: "#fff",')
$B.Add('        fontWeight: 900,')
$B.Add('        cursor: busy ? "not-allowed" : "pointer",')
$B.Add('        display: "inline-flex",')
$B.Add('        alignItems: "center",')
$B.Add('        gap: 8,')
$B.Add('      }}')
$B.Add('    >')
$B.Add('      ♻️ Replicar')
$B.Add('      <span')
$B.Add('        style={{')
$B.Add('          display: "inline-flex",')
$B.Add('          alignItems: "center",')
$B.Add('          justifyContent: "center",')
$B.Add('          minWidth: 18,')
$B.Add('          padding: "2px 8px",')
$B.Add('          borderRadius: 999,')
$B.Add('          background: "#111",')
$B.Add('          color: "#fff",')
$B.Add('          fontSize: 12,')
$B.Add('          lineHeight: "12px",')
$B.Add('        }}')
$B.Add('      >')
$B.Add('        {n}')
$B.Add('      </span>')
$B.Add('    </button>')
$B.Add('  );')
$B.Add('}')
WriteUtf8NoBom $btn ($B -join "`n")
Write-Host "[PATCH] wrote PointReplicarButton.tsx"

# -------------------------
# PATCH 4) Patch PointActionsInline to include Replicar button
# -------------------------
$rawI = Get-Content -LiteralPath $inline -Raw -ErrorAction Stop
if ($rawI -notmatch "PointReplicarButton") {
  # add import near other imports
  $lines = $rawI -split "`n"
  $lastImport = -1
  for ($i=0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match '^\s*import\s+') { $lastImport = $i } }
  $ins = 'import PointReplicarButton from "./PointReplicarButton";'
  $out = New-Object System.Collections.Generic.List[string]
  for ($i=0; $i -lt $lines.Count; $i++) {
    $out.Add($lines[$i])
    if ($i -eq $lastImport) { $out.Add($ins) }
  }
  $rawI = ($out -join "`n")
  Write-Host "[PATCH] PointActionsInline: added import PointReplicarButton"
}

# insert component near support (preferred) or at end of actions row
$lines2 = $rawI -split "`n"
$inserted = $false

for ($i=0; $i -lt $lines2.Count; $i++) {
  if ($lines2[$i] -match "PointSupportButton") {
    # insert after this line (or after the block line)
    $indent = ([regex]::Match($lines2[$i], '^\s*')).Value
    $insLine = $indent + '<PointReplicarButton pointId={pointId} counts={counts} />'
    $out2 = New-Object System.Collections.Generic.List[string]
    for ($j=0; $j -lt $lines2.Count; $j++) {
      $out2.Add($lines2[$j])
      if ($j -eq $i) { $out2.Add($insLine); $inserted = $true }
    }
    $rawI = ($out2 -join "`n")
    break
  }
}

if (-not $inserted) {
  # try to insert before closing of main wrapper: look for "</div>" near end
  $lines2 = $rawI -split "`n"
  for ($i=$lines2.Count-1; $i -ge 0; $i--) {
    if ($lines2[$i] -match '^\s*</div>\s*$') {
      $indent = ([regex]::Match($lines2[$i], '^\s*')).Value
      $insLine = $indent + '<PointReplicarButton pointId={pointId} counts={counts} />'
      $out2 = New-Object System.Collections.Generic.List[string]
      for ($j=0; $j -lt $lines2.Count; $j++) {
        if ($j -eq $i) { $out2.Add($insLine); $inserted = $true }
        $out2.Add($lines2[$j])
      }
      $rawI = ($out2 -join "`n")
      break
    }
  }
}

if ($inserted) {
  WriteUtf8NoBom $inline $rawI
  Write-Host "[PATCH] PointActionsInline: inserted <PointReplicarButton />"
} else {
  Write-Host "[WARN] Nao consegui inserir o botao automaticamente. (Me cola PointActionsInline.tsx que eu encaixo.)"
}

# -------------------------
# PATCH 5) Patch list2 to include replicate counts
# -------------------------
$rawL = Get-Content -LiteralPath $list2 -Raw -ErrorAction Stop

if ($rawL -match "replicateBy" -or $rawL -match "replicateModel") {
  Write-Host "[SKIP] list2 ja parece ter replicate"
} else {
  # 5a) add replicateModel line after supportModel
  $rawL = $rawL -replace '(const\s+supportModel\s*=\s*pickModel\([^\r\n]+\)\s*;)', ('$1' + "`n" + '    const replicateModel = pickModel(pc, "ecoPointReplicate", ["EcoPointReplicate", "pointReplicate", "ecoCriticalPointReplicate", "criticalPointReplicate"]);')

  # 5b) add replicate groupBy after support groupBy
  $rawL = $rawL -replace '(const\s+support\s*=\s*await\s+groupCountByAnyFk\([^\r\n]+\)\s*;)', ('$1' + "`n" + '    const replicate = await groupCountByAnyFk(replicateModel, fkCandidates);')

  # 5c) add rr + counts.replicate
  $rawL = $rawL -replace 'const\s+ss\s*=\s*support\.map\[id\]\s*\|\|\s*0\s*;',
                        ('const ss = support.map[id] || 0;' + "`n" + '      const rr = replicate.map[id] || 0;')

  $rawL = $rawL -replace 'support:\s*ss\s*,', ('support: ss,' + "`n" + '          replicate: rr,')

  # 5d) meta replicateBy
  $rawL = $rawL -replace 'supportBy:\s*support\.field,', ('supportBy: support.field,' + "`n" + '        replicateBy: replicate.field,')

  WriteUtf8NoBom $list2 $rawL
  Write-Host "[PATCH] list2: added replicate counts + meta.replicateBy"
}

# -------------------------
# REPORT
# -------------------------
$rep = NewReport $Root "eco-step-101-point-replicar-action-v0_1" @(
  "# eco-step-101-point-replicar-action-v0_1",
  "",
  "- Time: " + $ts,
  "- Backup: " + $backupDir,
  "",
  "## Changes",
  "- prisma/schema.prisma: added model EcoPointReplicate + EcoCriticalPoint.replicates",
  "- API: POST /api/eco/points/replicar (toggle by fingerprint)",
  "- UI: PointReplicarButton + integrado em PointActionsInline",
  "- list2: counts.replicate + meta.replicateBy",
  "",
  "## Verify",
  "1) Ctrl+C",
  "2) npm run dev",
  "3) GET http://localhost:3000/api/eco/points/list2?limit=10 (ver counts.replicate e meta.replicateBy)",
  "4) /eco/mural -> clicar ♻️ Replicar e ver contador subir/baixar",
  ""
)
Write-Host ("[REPORT] " + $rep)

Write-Host ""
Write-Host "[VERIFY] Ctrl+C -> npm run dev"
Write-Host "[VERIFY] /eco/mural -> ♻️ Replicar (N)"
Write-Host "[VERIFY] /api/eco/points/list2?limit=10 -> counts.replicate"