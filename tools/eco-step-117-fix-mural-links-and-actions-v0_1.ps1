param(
  [string]$Root = (Get-Location).Path
)

$ErrorActionPreference = "Stop"

function TryDotSourceBootstrap($rootPath) {
  $b1 = Join-Path $rootPath "tools\_bootstrap.ps1"
  if (Test-Path $b1) { . $b1; return $true }
  return $false
}

# best-effort bootstrap
[void](TryDotSourceBootstrap $Root)

# ---- fallbacks (se _bootstrap não tiver carregado)
if (-not (Get-Command EnsureDir -ErrorAction SilentlyContinue)) {
  function EnsureDir([string]$p) {
    if (-not $p) { return }
    New-Item -ItemType Directory -Force -Path $p | Out-Null
  }
}

if (-not (Get-Command WriteUtf8NoBom -ErrorAction SilentlyContinue)) {
  function WriteUtf8NoBom([string]$path, [string]$content) {
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($path, $content, $enc)
  }
}

if (-not (Get-Command BackupFile -ErrorAction SilentlyContinue)) {
  function BackupFile([string]$src, [string]$backupDir) {
    if (-not (Test-Path $src)) { return }
    EnsureDir $backupDir
    $safe = ($src -replace "[:\\\/]", "_")
    $dst = Join-Path $backupDir $safe
    Copy-Item -Force $src $dst
  }
}

function ReadRaw([string]$p) {
  if (-not (Test-Path $p)) { return $null }
  return Get-Content -Raw -ErrorAction SilentlyContinue $p
}

function IndentAt([string]$raw, [int]$idx) {
  if ($idx -le 0) { return "" }
  $ln = $raw.LastIndexOf("`n", $idx)
  if ($ln -lt 0) { $ln = 0 } else { $ln = $ln + 1 }
  $i = $ln
  $sb = New-Object System.Text.StringBuilder
  while ($i -lt $raw.Length) {
    $ch = $raw[$i]
    if ($ch -eq " " -or $ch -eq "`t") { [void]$sb.Append($ch); $i++ } else { break }
  }
  return $sb.ToString()
}

function FindMatchingCloseTag([string]$raw, [string]$tag, [int]$startIdx) {
  $open = "<" + $tag
  $close = "</" + $tag + ">"
  $i = $startIdx
  $depth = 0

  # assume que startIdx aponta para o primeiro "<tag"
  $depth = 1
  $i = $startIdx + $open.Length

  while ($true) {
    $nextOpen = $raw.IndexOf($open, $i)
    $nextClose = $raw.IndexOf($close, $i)
    if ($nextClose -lt 0) { return -1 }

    if ($nextOpen -ge 0 -and $nextOpen -lt $nextClose) {
      $depth++
      $i = $nextOpen + $open.Length
      continue
    }

    $depth--
    if ($depth -eq 0) {
      return $nextClose
    }
    $i = $nextClose + $close.Length
  }
}

function EnsureImportLine([string]$raw, [string]$importLine) {
  if ($raw.Contains($importLine)) { return $raw }
  $lines = $raw -split "`n", 0, "SimpleMatch"
  $out = New-Object System.Collections.Generic.List[string]
  $inserted = $false
  $i = 0

  # mantém 'use client' no topo se existir
  if ($lines.Count -gt 0 -and $lines[0].Trim() -eq "'use client';") {
    $out.Add($lines[0])
    $i = 1
  }

  # copia imports existentes e insere no final do bloco de imports
  for (; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    if (-not $inserted -and -not $line.Trim().StartsWith("import ")) {
      $out.Add($importLine)
      $inserted = $true
    }
    $out.Add($line)
  }

  if (-not $inserted) {
    $out.Add($importLine)
  }

  return ($out -join "`n")
}

function FixNestedAnchorsInMuralPage([string]$raw) {
  $idxStart = $raw.IndexOf('<a href="/eco/mural/chamados"')
  if ($idxStart -lt 0) { return $null }
  $idxConfirm = $raw.IndexOf('href="/eco/mural/confirmados"', $idxStart)
  if ($idxConfirm -lt 0) { return $null }

  $c1 = $raw.IndexOf("</a>", $idxStart)
  if ($c1 -lt 0) { return $null }
  $c2 = $raw.IndexOf("</a>", $c1 + 4)
  if ($c2 -lt 0) { return $null }

  $indent = IndentAt $raw $idxStart

  $snippet = @()
  $snippet += $indent + '<a href="/eco/mural/chamados" style={{ padding: "9px 10px", borderRadius: 12, border: "1px solid #111", textDecoration: "none", color: "#111", fontWeight: 900, background: "#fff" }}>📣 Chamados ativos (OPEN)</a>'
  $snippet += $indent + '<a href="/eco/mural/confirmados" style={{ padding: "9px 10px", borderRadius: 12, border: "1px solid #111", textDecoration: "none", color: "#111", fontWeight: 900, background: "#fff" }}>✅ Confirmados</a>'
  $rep = ($snippet -join "`n")

  $len = ($c2 + 4) - $idxStart
  return $raw.Remove($idxStart, $len).Insert($idxStart, $rep)
}

function InjectActionsIntoFile([string]$raw, [string]$importLine, [string]$varFallback) {
  $m = [regex]::Match($raw, '\.map\(\(\s*([A-Za-z_]\w*)')
  $var = $varFallback
  if ($m.Success) { $var = $m.Groups[1].Value }

  $needle = "key={" + $var + ".id"
  $idxKey = $raw.IndexOf($needle)
  if ($idxKey -lt 0) { return @{ ok=$false; raw=$raw; why="não achei key={VAR.id} (var=" + $var + ")" } }

  $startDiv = $raw.LastIndexOf("<div", $idxKey)
  $tag = "div"
  $startIdx = $startDiv
  if ($startIdx -lt 0) {
    $startArt = $raw.LastIndexOf("<article", $idxKey)
    if ($startArt -ge 0) { $tag = "article"; $startIdx = $startArt }
  }
  if ($startIdx -lt 0) { return @{ ok=$false; raw=$raw; why="não achei <div>/<article> do card" } }

  $closeIdx = FindMatchingCloseTag $raw $tag $startIdx
  if ($closeIdx -lt 0) { return @{ ok=$false; raw=$raw; why="não achei fechamento do card (<" + $tag + ">)" } }

  $indent = IndentAt $raw $closeIdx
  $insIndent = $indent + "  "
  $snippet = $insIndent + "<MuralPointActionsClient pointId={" + $var + ".id} counts={" + $var + ".counts} />"

  if ($raw.Contains("MuralPointActionsClient")) {
    $raw2 = $raw
  } else {
    $raw2 = EnsureImportLine $raw $importLine
  }

  # precisa recalcular closeIdx se inseriu import acima (mudou offsets). Rebusca por key.
  $idxKey2 = $raw2.IndexOf($needle)
  if ($idxKey2 -ge 0) {
    $startDiv2 = $raw2.LastIndexOf("<div", $idxKey2)
    $tag2 = "div"
    $startIdx2 = $startDiv2
    if ($startIdx2 -lt 0) {
      $startArt2 = $raw2.LastIndexOf("<article", $idxKey2)
      if ($startArt2 -ge 0) { $tag2 = "article"; $startIdx2 = $startArt2 }
    }
    if ($startIdx2 -ge 0) {
      $closeIdx2 = FindMatchingCloseTag $raw2 $tag2 $startIdx2
      if ($closeIdx2 -ge 0) {
        if ($raw2.IndexOf("<MuralPointActionsClient", $startIdx2) -ge 0 -and $raw2.IndexOf("<MuralPointActionsClient", $startIdx2) -lt $closeIdx2) {
          return @{ ok=$true; raw=$raw2; why="já tinha actions no card" }
        }
        $raw2 = $raw2.Insert($closeIdx2, "`n" + $snippet + "`n" + $indent)
        return @{ ok=$true; raw=$raw2; why="inject ok (var=" + $var + ", tag=" + $tag2 + ")" }
      }
    }
  }

  return @{ ok=$false; raw=$raw2; why="falhou no reinject pós-import" }
}

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$me = "eco-step-117-fix-mural-links-and-actions-v0_1"
Write-Host ("== " + $me + " == " + $stamp)
Write-Host ("[DIAG] Root: " + $Root)

$backupDir = Join-Path $Root ("tools\_patch_backup\" + $stamp + "-" + $me)
EnsureDir $backupDir

$patched = @()

# --- 1) Fix nested anchors in /eco/mural page.tsx
$page = Join-Path $Root "src\app\eco\mural\page.tsx"
if (Test-Path $page) {
  $raw = ReadRaw $page
  if ($raw) {
    $new = FixNestedAnchorsInMuralPage $raw
    if ($new -and $new -ne $raw) {
      BackupFile $page $backupDir
      WriteUtf8NoBom $page $new
      $patched += "src/app/eco/mural/page.tsx (fix nested <a>)"
      Write-Host ("[PATCH] fixed nested <a> -> " + $page)
    } else {
      Write-Host "[DIAG] page.tsx: nada pra corrigir (ou padrão diferente)."
    }
  }
} else {
  Write-Host "[WARN] não achei src/app/eco/mural/page.tsx"
}

# --- 2) Rewrite action route robustly (DMMF-safe)
$actionRoute = Join-Path $Root "src\app\api\eco\points\action\route.ts"
EnsureDir (Split-Path -Parent $actionRoute)
if (Test-Path $actionRoute) { BackupFile $actionRoute $backupDir }

$ts = @(
'// AUTO-GENERATED by tools/eco-step-117-fix-mural-links-and-actions-v0_1.ps1',
'// POST /api/eco/points/action  { pointId, action: "confirm"|"support"|"replicar", actor?, note? }',
'// Goal: never fail due to missing required fields (uses Prisma.dmmf to fill required scalar/enum fields).',
'',
'import { NextResponse } from "next/server";',
'import { prisma } from "@/lib/prisma";',
'import { Prisma } from "@prisma/client";',
'',
'export const runtime = "nodejs";',
'export const dynamic = "force-dynamic";',
'',
'type AnyRec = Record<string, any>;',
'',
'function toDelegate(name: string) {',
'  return name && name.length ? name.slice(0, 1).toLowerCase() + name.slice(1) : name;',
'}',
'function getDmmf(): any {',
'  return (Prisma as any).dmmf as any;',
'}',
'function getModels(): any[] {',
'  const d = getDmmf();',
'  return d && d.datamodel && Array.isArray(d.datamodel.models) ? d.datamodel.models : [];',
'}',
'function getEnums(): any[] {',
'  const d = getDmmf();',
'  return d && d.datamodel && Array.isArray(d.datamodel.enums) ? d.datamodel.enums : [];',
'}',
'function enumFirst(enumName: string): string | null {',
'  const e = getEnums().find((x: any) => x && x.name === enumName);',
'  const v = e && Array.isArray(e.values) && e.values.length ? e.values[0].name : null;',
'  return v || null;',
'}',
'function findModelByDelegate(delegateKey: string): any | null {',
'  return getModels().find((m: any) => m && toDelegate(m.name) === delegateKey) || null;',
'}',
'function findModelByName(modelName: string): any | null {',
'  return getModels().find((m: any) => m && m.name === modelName) || null;',
'}',
'function hasField(modelName: string, fieldName: string): boolean {',
'  const m = findModelByName(modelName);',
'  return !!(m && Array.isArray(m.fields) && m.fields.some((f: any) => f && f.name === fieldName));',
'}',
'function pickDelegate(pc: any, candidates: string[]): string | null {',
'  for (const c of candidates) {',
'    if (pc && pc[c]) return c;',
'  }',
'  return null;',
'}',
'function randId(prefix: string) {',
'  return prefix + "-" + Math.random().toString(36).slice(2, 8) + "-" + Date.now().toString(36);',
'}',
'function findFkField(modelName: string, targetModelName: string): string | null {',
'  const m = findModelByName(modelName);',
'  if (!m || !Array.isArray(m.fields)) return null;',
'  for (const f of m.fields) {',
'    if (f && f.kind === "object" && f.type === targetModelName) {',
'      const rff = (f as any).relationFromFields;',
'      if (Array.isArray(rff) && rff.length) return rff[0];',
'    }',
'  }',
'  const scalar = m.fields.find((f: any) => f && (f.kind === "scalar" || f.kind === "enum") && /pointId/i.test(f.name));',
'  return scalar ? scalar.name : null;',
'}',
'function buildRequiredData(modelName: string, base: AnyRec, ctx: AnyRec): AnyRec {',
'  const m = findModelByName(modelName);',
'  const out: AnyRec = {};',
'  const now = new Date();',
'  const fields = m && Array.isArray(m.fields) ? m.fields : [];',
'  for (const f of fields) {',
'    if (!f) continue;',
'    if (f.isList) continue;',
'    if (f.kind !== "scalar" && f.kind !== "enum") continue;',
'    if (!f.isRequired) continue;',
'    if (f.hasDefaultValue) continue;',
'    if (base && base[f.name] !== undefined) continue;',
'    if (f.name === "id") { out[f.name] = randId("id"); continue; }',
'    if (f.name === "createdAt" || f.name === "updatedAt") { out[f.name] = now; continue; }',
'    if (f.name === "actor") { out[f.name] = ctx.actor; continue; }',
'    if (f.name === "note") { out[f.name] = ctx.note; continue; }',
'    if (f.name === "fingerprint") { out[f.name] = "act-" + Date.now().toString(36) + "-" + Math.random().toString(36).slice(2, 8); continue; }',
'    if (f.kind === "enum") { out[f.name] = enumFirst(f.type) || "OPEN"; continue; }',
'    if (f.type === "String") { out[f.name] = ctx.actor; continue; }',
'    if (f.type === "Int" || f.type === "Float") { out[f.name] = 0; continue; }',
'    if (f.type === "Boolean") { out[f.name] = false; continue; }',
'    if (f.type === "DateTime") { out[f.name] = now; continue; }',
'    out[f.name] = ctx.actor;',
'  }',
'  for (const k of Object.keys(base || {})) out[k] = base[k];',
'  if (hasField(modelName, "actor") && out["actor"] === undefined) out["actor"] = ctx.actor;',
'  if (hasField(modelName, "note") && out["note"] === undefined) out["note"] = ctx.note;',
'  return out;',
'}',
'async function safeJson(req: Request): Promise<AnyRec> {',
'  try {',
'    const t = await req.text();',
'    return t ? JSON.parse(t) : {};',
'  } catch {',
'    return {};',
'  }',
'}',
'function isKnownReqError(e: any): boolean {',
'  return !!(e && typeof e === "object" && e.code && typeof e.code === "string");',
'}',
'export async function POST(req: Request) {',
'  try {',
'    const body = await safeJson(req);',
'    const pointId = String(body.pointId || "").trim();',
'    const action = String(body.action || "").toLowerCase().trim();',
'    const actor = String(body.actor || "anon").trim() || "anon";',
'    const note = String(body.note || "");',
'    if (!pointId) return NextResponse.json({ ok: false, error: "missing_pointId" }, { status: 400 });',
'    if (!action || !["confirm","support","replicar"].includes(action)) {',
'      return NextResponse.json({ ok: false, error: "bad_action" }, { status: 400 });',
'    }',
'    const pc: any = prisma as any;',
'    const keys = Object.keys(pc);',
'    const pointKey = pickDelegate(pc, ["ecoCriticalPoint", "ecoPoint", "ecoCriticalPointV2"])',
'      || (keys.find((k) => /point/i.test(k) && /eco/i.test(k)) || null);',
'    if (!pointKey) return NextResponse.json({ ok: false, error: "point_model_not_found" }, { status: 500 });',
'    const pointModel = findModelByDelegate(pointKey);',
'    if (!pointModel) return NextResponse.json({ ok: false, error: "dmmf_point_model_not_found", pointKey }, { status: 500 });',
'    const p = await pc[pointKey].findUnique({ where: { id: pointId } });',
'    if (!p) return NextResponse.json({ ok: false, error: "point_not_found" }, { status: 404 });',
'    const confirmKey = pickDelegate(pc, ["ecoCriticalPointConfirm", "ecoPointConfirm", "ecoCriticalConfirm"])',
'      || (keys.find((k) => /confirm/i.test(k) && /eco/i.test(k)) || null);',
'    const supportKey = pickDelegate(pc, ["ecoPointSupport", "ecoCriticalPointSupport"])',
'      || (keys.find((k) => /support/i.test(k) && /eco/i.test(k)) || null);',
'    const replicarKey = pickDelegate(pc, ["ecoPointReplicate", "ecoPointReplicar", "ecoCriticalPointReplicate"])',
'      || (keys.find((k) => (/replic/i.test(k) || /replicar/i.test(k)) && /eco/i.test(k)) || null);',
'    const ctx = { actor, note };',
'    let created = false;',
'    let targetKey: string | null = null;',
'    if (action === "confirm") targetKey = confirmKey;',
'    if (action === "support") targetKey = supportKey;',
'    if (action === "replicar") targetKey = replicarKey;',
'    if (targetKey) {',
'      const tm = findModelByDelegate(targetKey);',
'      if (tm) {',
'        const fk = findFkField(tm.name, pointModel.name) || "pointId";',
'        const base: AnyRec = {};',
'        if (hasField(tm.name, "id")) base.id = randId(action.slice(0, 1));',
'        base[fk] = pointId;',
'        if (hasField(tm.name, "actor")) base.actor = actor;',
'        if (hasField(tm.name, "note") && note) base.note = note;',
'        if (hasField(tm.name, "createdAt")) base.createdAt = new Date();',
'        if (hasField(tm.name, "updatedAt")) base.updatedAt = new Date();',
'        if (hasField(tm.name, "fingerprint")) base.fingerprint = "act-" + action + "-" + Date.now().toString(36) + "-" + Math.random().toString(36).slice(2, 8);',
'        const data = buildRequiredData(tm.name, base, ctx);',
'        try {',
'          await pc[targetKey].create({ data });',
'          created = true;',
'        } catch (e: any) {',
'          if (isKnownReqError(e) && e.code === "P2002") {',
'            created = false;',
'          } else {',
'            throw e;',
'          }',
'        }',
'      }',
'    }',
'    const counts: AnyRec = { confirm: 0, support: 0, replicar: 0 };',
'    if (confirmKey) {',
'      const cm = findModelByDelegate(confirmKey);',
'      const ck = cm ? (findFkField(cm.name, pointModel.name) || "pointId") : "pointId";',
'      try { counts.confirm = await pc[confirmKey].count({ where: { [ck]: pointId } }); } catch {}',
'    }',
'    if (supportKey) {',
'      const sm = findModelByDelegate(supportKey);',
'      const sk = sm ? (findFkField(sm.name, pointModel.name) || "pointId") : "pointId";',
'      try { counts.support = await pc[supportKey].count({ where: { [sk]: pointId } }); } catch {}',
'    }',
'    if (replicarKey) {',
'      const rm = findModelByDelegate(replicarKey);',
'      const rk = rm ? (findFkField(rm.name, pointModel.name) || "pointId") : "pointId";',
'      try { counts.replicar = await pc[replicarKey].count({ where: { [rk]: pointId } }); } catch {}',
'    }',
'    return NextResponse.json({',
'      ok: true,',
'      error: null,',
'      pointId,',
'      action,',
'      created,',
'      counts,',
'      models: { pointKey, confirmKey, supportKey, replicarKey },',
'    });',
'  } catch (e: any) {',
'    const msg = e && e.message ? String(e.message) : String(e);',
'    return NextResponse.json({ ok: false, error: "action_failed", message: msg }, { status: 500 });',
'  }',
'}',
''
)

WriteUtf8NoBom $actionRoute ($ts -join "`n")
$patched += "src/app/api/eco/points/action/route.ts (rewrite DMMF-safe)"
Write-Host ("[PATCH] rewrote -> " + $actionRoute)

# --- 3) Inject actions component in MuralClient + MuralAcoesClient (best-effort)
$muralClient = Join-Path $Root "src\app\eco\mural\MuralClient.tsx"
if (Test-Path $muralClient) {
  $raw = ReadRaw $muralClient
  if ($raw) {
    $res = InjectActionsIntoFile $raw 'import MuralPointActionsClient from "./_components/MuralPointActionsClient";' "p"
    if ($res.ok -and $res.raw -ne $raw) {
      BackupFile $muralClient $backupDir
      WriteUtf8NoBom $muralClient $res.raw
      $patched += "src/app/eco/mural/MuralClient.tsx (inject actions)"
      Write-Host ("[PATCH] injected actions -> " + $muralClient + " :: " + $res.why)
    } else {
      Write-Host ("[WARN] MuralClient: não injetei :: " + $res.why)
    }
  }
} else {
  Write-Host "[WARN] não achei src/app/eco/mural/MuralClient.tsx"
}

$muralAcoes = Join-Path $Root "src\app\eco\mural-acoes\MuralAcoesClient.tsx"
if (Test-Path $muralAcoes) {
  $raw = ReadRaw $muralAcoes
  if ($raw) {
    $res = InjectActionsIntoFile $raw 'import MuralPointActionsClient from "../mural/_components/MuralPointActionsClient";' "p"
    if ($res.ok -and $res.raw -ne $raw) {
      BackupFile $muralAcoes $backupDir
      WriteUtf8NoBom $muralAcoes $res.raw
      $patched += "src/app/eco/mural-acoes/MuralAcoesClient.tsx (inject actions)"
      Write-Host ("[PATCH] injected actions -> " + $muralAcoes + " :: " + $res.why)
    } else {
      Write-Host ("[WARN] MuralAcoesClient: não injetei :: " + $res.why)
    }
  }
} else {
  Write-Host "[WARN] não achei src/app/eco/mural-acoes/MuralAcoesClient.tsx"
}

# --- REPORT
$report = @()
$report += "# $me"
$report += ""
$report += "- Time: $stamp"
$report += "- Backup: $backupDir"
$report += ""
$report += "## Patched"
if ($patched.Count -eq 0) { $report += "- (none)" } else { foreach ($p in $patched) { $report += "- $p" } }
$report += ""
$report += "## Verify"
$report += "1) Ctrl+C -> npm run dev"
$report += "2) abrir /eco/mural (não pode aparecer hydration error de <a> dentro de <a>)"
$report += "3) `$pid = (irm 'http://localhost:3000/api/eco/points?limit=1').items[0].id"
$report += "4) `$b = @{ pointId = `$pid; action = 'confirm'; actor = 'dev' } | ConvertTo-Json -Compress"
$report += "5) irm 'http://localhost:3000/api/eco/points/action' -Method Post -ContentType 'application/json' -Body `$b | ConvertTo-Json -Depth 60"
$report += "6) abrir /eco/mural e clicar ✅ 🤝 ♻️ (contadores sobem)"
$report += ""

$reportPath = Join-Path $Root ("reports\" + $me + "-" + $stamp + ".md")
EnsureDir (Split-Path -Parent $reportPath)
WriteUtf8NoBom $reportPath ($report -join "`n")
Write-Host ("[REPORT] " + $reportPath)

Write-Host ""
Write-Host "[VERIFY] rode:"
Write-Host "  Ctrl+C -> npm run dev"
Write-Host "  abrir /eco/mural"
Write-Host "  `$pid = (irm 'http://localhost:3000/api/eco/points?limit=1').items[0].id"
Write-Host "  `$b = @{ pointId = `$pid; action = 'confirm'; actor = 'dev' } | ConvertTo-Json -Compress"
Write-Host "  irm 'http://localhost:3000/api/eco/points/action' -Method Post -ContentType 'application/json' -Body `$b | ConvertTo-Json -Depth 60"