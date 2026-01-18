param(
  [string]$Root = (Get-Location).Path
)

$ts = Get-Date -Format 'yyyyMMdd-HHmmss'

# --- bootstrap
$boot = Join-Path $Root "tools/_bootstrap.ps1"
if (Test-Path -LiteralPath $boot) { . $boot }

# --- fallbacks
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
function WriteLines([string]$p, [string[]]$lines) { WriteUtf8NoBom $p ($lines -join "`n") }

$backupDir = Join-Path $Root ('tools/_patch_backup/' + $ts + '-eco-step-67-point-resolution-reopen-v0_1')
$reportDir = Join-Path $Root 'reports'
EnsureDir $backupDir
EnsureDir $reportDir

Write-Host ('== eco-step-67-point-resolution-reopen-v0_1 == ' + $ts)
Write-Host ('[DIAG] Root: ' + $Root)

$src = Join-Path $Root 'src'
if (-not (Test-Path -LiteralPath $src)) { throw ('[STOP] Não achei src/: ' + $src) }

# --- paths to write
$comp = Join-Path $Root 'src/app/eco/_components/EcoPointResolutionPanel.tsx'
$apiDetail = Join-Path $Root 'src/app/api/eco/point/detail/route.ts'
$apiReopen = Join-Path $Root 'src/app/api/eco/point/reopen/route.ts'

Write-Host ('[DIAG] Will write: ' + $comp)
Write-Host ('[DIAG] Will write: ' + $apiDetail)
Write-Host ('[DIAG] Will write: ' + $apiReopen)

BackupFile $Root $comp $backupDir
BackupFile $Root $apiDetail $backupDir
BackupFile $Root $apiReopen $backupDir

EnsureDir (Split-Path -Parent $comp)
EnsureDir (Split-Path -Parent $apiDetail)
EnsureDir (Split-Path -Parent $apiReopen)

# --- component: EcoPointResolutionPanel (self-contained)
$LComp = @(
'"use client";',
'',
'import { useEffect, useState } from "react";',
'',
'export default function EcoPointResolutionPanel() {',
'  const [pointId, setPointId] = useState<string>("");',
'  const [loading, setLoading] = useState<boolean>(false);',
'  const [uploading, setUploading] = useState<boolean>(false);',
'  const [err, setErr] = useState<string | null>(null);',
'  const [data, setData] = useState<any>(null);',
'  const [note, setNote] = useState<string>("");',
'  const [evidenceUrl, setEvidenceUrl] = useState<string>("");',
'',
'  useEffect(() => {',
'    try {',
'      const parts = String(window.location.pathname || "").split("/").filter(Boolean);',
'      const id = parts.length ? parts[parts.length - 1] : "";',
'      setPointId(id);',
'    } catch {',
'      // ignore',
'    }',
'  }, []);',
'',
'  async function load() {',
'    if (!pointId) return;',
'    setLoading(true);',
'    setErr(null);',
'    try {',
'      const res = await fetch("/api/eco/point/detail?id=" + encodeURIComponent(pointId), { cache: "no-store" } as any);',
'      const j = await res.json().catch(() => null);',
'      if (!res.ok || !j?.ok) throw new Error(j?.detail || j?.error || ("HTTP " + res.status));',
'      setData(j);',
'    } catch (e: any) {',
'      setErr(e?.message || String(e));',
'    } finally {',
'      setLoading(false);',
'    }',
'  }',
'',
'  useEffect(() => {',
'    void load();',
'  }, [pointId]);',
'',
'  async function doUpload(file: File) {',
'    setUploading(true);',
'    setErr(null);',
'    try {',
'      const fd = new FormData();',
'      fd.append("file", file);',
'      fd.append("kind", "point_reopen");',
'      const res = await fetch("/api/eco/upload", { method: "POST", body: fd });',
'      const j = await res.json().catch(() => null);',
'      if (!res.ok || !j?.ok) throw new Error(j?.detail || j?.error || ("HTTP " + res.status));',
'      const url = String(j?.url || j?.fileUrl || j?.item?.url || "");',
'      if (!url) throw new Error("upload_ok_but_no_url");',
'      setEvidenceUrl(url);',
'    } catch (e: any) {',
'      setErr(e?.message || String(e));',
'    } finally {',
'      setUploading(false);',
'    }',
'  }',
'',
'  async function doReopen() {',
'    if (!pointId) return;',
'    const n = String(note || "").trim();',
'    const ev = String(evidenceUrl || "").trim();',
'    // anti-reincidência: exige nova evidência OU relato bem completo',
'    if (ev.length < 6 && n.length < 20) {',
'      setErr("Para reabrir: envie uma evidência (foto/url) OU escreva um relato bem completo (>= 20 caracteres).");',
'      return;',
'    }',
'    setLoading(true);',
'    setErr(null);',
'    try {',
'      const res = await fetch("/api/eco/point/reopen", {',
'        method: "POST",',
'        headers: { "Content-Type": "application/json" },',
'        body: JSON.stringify({ id: pointId, note: n, evidenceUrl: ev }),',
'      });',
'      const j = await res.json().catch(() => null);',
'      if (!res.ok || !j?.ok) throw new Error(j?.detail || j?.error || ("HTTP " + res.status));',
'      setNote("");',
'      await load();',
'    } catch (e: any) {',
'      setErr(e?.message || String(e));',
'    } finally {',
'      setLoading(false);',
'    }',
'  }',
'',
'  const point = data?.point;',
'  const mut = data?.resolvedByMutirao;',
'  const status = String(point?.status || "").toUpperCase();',
'  const isResolved = status === "RESOLVED" || status === "DONE";',
'',
'  return (',
'    <section style={{ margin: "14px 0", padding: 12, border: "1px solid #e5e5e5", borderRadius: 12, background: "#fff" }}>',
'      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", gap: 10 }}>',
'        <div style={{ fontWeight: 900 }}>Resolução & reincidência</div>',
'        <button onClick={() => void load()} disabled={loading || !pointId} style={{ padding: "6px 10px", borderRadius: 10, border: "1px solid #ccc", background: "#fff" }}>',
'          Atualizar',
'        </button>',
'      </div>',
'',
'      {!pointId ? <div style={{ opacity: 0.75, marginTop: 8 }}>Carregando id…</div> : null}',
'      {err ? <div style={{ marginTop: 10, color: "#b00020" }}>{err}</div> : null}',
'',
'      {isResolved && mut ? (',
'        <div style={{ marginTop: 10, display: "grid", gap: 6 }}>',
'          <div style={{ opacity: 0.8 }}>Este ponto foi resolvido por um mutirão.</div>',
'          <div style={{ display: "flex", gap: 10, flexWrap: "wrap" }}>',
'            <a href={"/eco/mutiroes/" + String(mut.id)} style={{ textDecoration: "none", padding: "8px 10px", borderRadius: 10, border: "1px solid #111", color: "#111" }}>',
'              Ver mutirão: {String(mut.id).slice(0, 8)}…',
'            </a>',
'          </div>',
'        </div>',
'      ) : null}',
'',
'      {isResolved ? (',
'        <div style={{ marginTop: 12, display: "grid", gap: 10 }}>',
'          <div style={{ fontWeight: 800 }}>Reabrir (anti-reincidência)</div>',
'          <div style={{ opacity: 0.8, fontSize: 12 }}>',
'            Regra: para reabrir, precisamos de <b>nova evidência</b> (foto/url) ou um relato bem completo. Isso mantém o “recibo” como prova.',
'          </div>',
'',
'          <label style={{ display: "grid", gap: 6 }}>',
'            <span>Nova evidência (URL da foto) — opcional</span>',
'            <input value={evidenceUrl} onChange={(e) => setEvidenceUrl(e.target.value)} placeholder="https://..." style={{ padding: 10, borderRadius: 10, border: "1px solid #ccc" }} />',
'          </label>',
'',
'          <label style={{ display: "grid", gap: 6 }}>',
'            <span>Ou envie uma foto (upload)</span>',
'            <input type="file" accept="image/*" disabled={uploading} onChange={(e) => { const f = e.target.files && e.target.files[0]; if (f) void doUpload(f); }} />',
'            {uploading ? <span style={{ opacity: 0.7, fontSize: 12 }}>Enviando…</span> : null}',
'          </label>',
'',
'          <label style={{ display: "grid", gap: 6 }}>',
'            <span>Justificativa / o que voltou a acontecer</span>',
'            <textarea value={note} onChange={(e) => setNote(e.target.value)} rows={3} placeholder="Descreva a reincidência (mín 20 caracteres se não tiver foto)..." style={{ padding: 10, borderRadius: 10, border: "1px solid #ccc" }} />',
'          </label>',
'',
'          <div style={{ display: "flex", gap: 10, flexWrap: "wrap" }}>',
'            <button onClick={() => void doReopen()} disabled={loading || !pointId} style={{ padding: "10px 12px", borderRadius: 12, border: "1px solid #111", background: "#111", color: "#fff" }}>',
'              Reabrir ponto',
'            </button>',
'          </div>',
'        </div>',
'      ) : (',
'        <div style={{ marginTop: 10, opacity: 0.75, fontSize: 12 }}>(Este painel aparece quando o ponto está RESOLVIDO.)</div>',
'      )}',
'    </section>',
'  );',
'}',
''
)
WriteLines $comp $LComp
Write-Host '[PATCH] wrote EcoPointResolutionPanel.tsx'

# --- API: /api/eco/point/detail
$LApiDetail = @(
'import { NextResponse } from "next/server";',
'import { prisma } from "@/lib/prisma";',
'',
'export const runtime = "nodejs";',
'export const dynamic = "force-dynamic";',
'',
'function asMsg(e: unknown) {',
'  if (e instanceof Error) return e.message;',
'  try { return String(e); } catch { return "unknown"; }',
'}',
'function looksLikeMissingTable(msg: string) {',
'  const m = msg.toLowerCase();',
'  return m.includes("does not exist") || m.includes("no such table") || m.includes("p2021");',
'}',
'function getPointModel() {',
'  const pc: any = prisma as any;',
'  const candidates = ["ecoPoint", "ecoCriticalPoint", "criticalPoint", "ecoPonto", "ponto", "ecoPontoCritico"];',
'  for (const k of candidates) {',
'    const m = pc?.[k];',
'    if (m && typeof m.findUnique === "function") return { key: k, model: m as any };',
'  }',
'  return null;',
'}',
'function getMutiraoModel() {',
'  const pc: any = prisma as any;',
'  const candidates = ["ecoMutirao", "mutirao", "ecoMutiroes", "mutiroes"];',
'  for (const k of candidates) {',
'    const m = pc?.[k];',
'    if (m && typeof m.findFirst === "function") return { key: k, model: m as any };',
'  }',
'  return null;',
'}',
'',
'export async function GET(req: Request) {',
'  const { searchParams } = new URL(req.url);',
'  const id = String(searchParams.get("id") || searchParams.get("pointId") || "").trim();',
'  if (!id) return NextResponse.json({ ok: false, error: "bad_id" }, { status: 400 });',
'',
'  const pm = getPointModel();',
'  if (!pm?.model) return NextResponse.json({ ok: false, error: "model_not_ready" }, { status: 503 });',
'',
'  try {',
'    const point = await pm.model.findUnique({ where: { id } });',
'    if (!point) return NextResponse.json({ ok: false, error: "not_found" }, { status: 404 });',
'',
'    const mm = getMutiraoModel();',
'    let resolvedByMutirao: any = null;',
'',
'    const st = String(point?.status || "").toUpperCase();',
'    const isResolved = st === "RESOLVED" || st === "DONE";',
'',
'    if (isResolved && mm?.model) {',
'      resolvedByMutirao = await mm.model.findFirst({',
'        where: {',
'          OR: [',
'            { pointId: id },',
'            { criticalPointId: id },',
'            { ecoPointId: id },',
'            { pontoId: id },',
'          ],',
'          status: "DONE",',
'        },',
'        orderBy: { updatedAt: "desc" },',
'      }).catch(() => null);',
'    }',
'',
'    return NextResponse.json({ ok: true, point, resolvedByMutirao, meta: { pointModel: pm.key, mutiraoModel: mm?.key || "missing" } });',
'  } catch (e) {',
'    const msg = asMsg(e);',
'    if (looksLikeMissingTable(msg)) return NextResponse.json({ ok: false, error: "db_not_ready", detail: msg }, { status: 503 });',
'    return NextResponse.json({ ok: false, error: "db_error", detail: msg }, { status: 500 });',
'  }',
'}',
''
)
WriteLines $apiDetail $LApiDetail
Write-Host '[PATCH] wrote /api/eco/point/detail'

# --- API: /api/eco/point/reopen (best-effort update; tenta salvar meta, depois fallback)
$LApiReopen = @(
'import { NextResponse } from "next/server";',
'import { prisma } from "@/lib/prisma";',
'',
'export const runtime = "nodejs";',
'export const dynamic = "force-dynamic";',
'',
'function asMsg(e: unknown) {',
'  if (e instanceof Error) return e.message;',
'  try { return String(e); } catch { return "unknown"; }',
'}',
'function looksLikeMissingTable(msg: string) {',
'  const m = msg.toLowerCase();',
'  return m.includes("does not exist") || m.includes("no such table") || m.includes("p2021");',
'}',
'function getPointModel() {',
'  const pc: any = prisma as any;',
'  const candidates = ["ecoPoint", "ecoCriticalPoint", "criticalPoint", "ecoPonto", "ponto", "ecoPontoCritico"];',
'  for (const k of candidates) {',
'    const m = pc?.[k];',
'    if (m && typeof m.update === "function") return { key: k, model: m as any };',
'  }',
'  return null;',
'}',
'',
'export async function POST(req: Request) {',
'  const body = (await req.json().catch(() => null)) as any;',
'  const id = String(body?.id || body?.pointId || "").trim();',
'  const note = String(body?.note || "").trim();',
'  const evidenceUrl = String(body?.evidenceUrl || "").trim();',
'',
'  if (!id) return NextResponse.json({ ok: false, error: "bad_id" }, { status: 400 });',
'',
'  // anti-reincidência: evidência OU relato bem completo',
'  if (evidenceUrl.length < 6 && note.length < 20) {',
'    return NextResponse.json({ ok: false, error: "missing_new_evidence", hint: "Envie evidência (foto/url) OU relato >= 20 chars.", got: { evidenceUrlLen: evidenceUrl.length, noteLen: note.length } }, { status: 400 });',
'  }',
'',
'  const pm = getPointModel();',
'  if (!pm?.model) return NextResponse.json({ ok: false, error: "model_not_ready" }, { status: 503 });',
'',
'  const stamp = new Date().toISOString();',
'  const metaObj = { reopenedAt: stamp, reopenNote: note, reopenEvidenceUrl: evidenceUrl };',
'',
'  try {',
'    // tentativa 1: gravar em meta (se existir)',
'    try {',
'      const item = await pm.model.update({ where: { id }, data: { status: "OPEN", meta: metaObj } });',
'      return NextResponse.json({ ok: true, item, meta: { pointModel: pm.key, mode: "status+meta" } });',
'    } catch {',
'      // ignore -> fallback',
'    }',
'',
'    // tentativa 2: status + notes/evidence (se existir)',
'    try {',
'      const item = await pm.model.update({ where: { id }, data: { status: "OPEN", reopenNote: note, reopenEvidenceUrl: evidenceUrl, reopenedAt: new Date(stamp) } });',
'      return NextResponse.json({ ok: true, item, meta: { pointModel: pm.key, mode: "status+fields" } });',
'    } catch {',
'      // ignore -> fallback',
'    }',
'',
'    // fallback final: só status',
'    const item = await pm.model.update({ where: { id }, data: { status: "OPEN" } });',
'    return NextResponse.json({ ok: true, item, meta: { pointModel: pm.key, mode: "status_only" } });',
'  } catch (e) {',
'    const msg = asMsg(e);',
'    if (looksLikeMissingTable(msg)) return NextResponse.json({ ok: false, error: "db_not_ready", detail: msg }, { status: 503 });',
'    return NextResponse.json({ ok: false, error: "db_error", detail: msg }, { status: 500 });',
'  }',
'}',
''
)
WriteLines $apiReopen $LApiReopen
Write-Host '[PATCH] wrote /api/eco/point/reopen'

# --- Try patch point detail page to render panel
function ScorePage([string]$path) {
  $score = 0
  $p = $path.ToLowerInvariant()
  if ($p -match '\\eco\\') { $score += 2 }
  if ($p -match '\\(ponto|pontos|point|points|critical)') { $score += 3 }
  if ($p -match '\\\[[^\]]+\]\\') { $score += 6 } # [id] folder
  if ($p -match 'page\.tsx$') { $score += 4 }

  $txt = ""
  try { $txt = Get-Content -Raw -LiteralPath $path } catch { $txt = "" }
  if ($txt -match 'params\.' -and $txt -match '\[id\]' ) { $score += 5 }
  if ($txt -match 'Ponto' -or $txt -match 'point') { $score += 2 }
  if ($txt -match 'EcoPointResolutionPanel') { $score -= 100 } # already patched
  return @{ score = $score; text = $txt }
}

$pages = @(Get-ChildItem -LiteralPath (Join-Path $Root 'src/app/eco') -Recurse -File -Filter page.tsx)
$ranked = @()

foreach ($f in $pages) {
  $r = ScorePage $f.FullName
  if ($r.score -gt 5) {
    $ranked += [PSCustomObject]@{ Path = $f.FullName; Score = $r.score }
  }
}

$ranked = $ranked | Sort-Object -Property Score -Descending

$patchedPage = $null
if ($ranked -and $ranked.Count -gt 0) {
  Write-Host "[DIAG] Candidate point detail pages (top 10):"
  $ranked | Select-Object -First 10 | ForEach-Object { Write-Host ("  - (" + $_.Score + ") " + $_.Path) }

  $target = $ranked[0].Path
  if (Test-Path -LiteralPath $target) {
    $r = ScorePage $target
    $raw = $r.text
    if (-not $raw) { $raw = Get-Content -Raw -LiteralPath $target }

    if ($raw -and ($raw -notmatch 'EcoPointResolutionPanel')) {
      BackupFile $Root $target $backupDir

      # add import after last import (best-effort)
      if ($raw -notmatch 'EcoPointResolutionPanel') {
        if ($raw -notmatch 'from "@\/app\/eco\/_components\/EcoPointResolutionPanel"') {
          $importLine = 'import EcoPointResolutionPanel from "@/app/eco/_components/EcoPointResolutionPanel";'
          $m = [regex]::Matches($raw, '^\s*import[^\n]*\n', [System.Text.RegularExpressions.RegexOptions]::Multiline)
          if ($m.Count -gt 0) {
            $last = $m[$m.Count - 1]
            $pos = $last.Index + $last.Length
            $raw = $raw.Insert($pos, $importLine + "`n")
          } else {
            # no imports -> add at top
            $raw = $importLine + "`n" + $raw
          }
        }
      }

      # insert panel inside first <main ...> or <section ...> or after 'return ('
      if ($raw -notmatch '<EcoPointResolutionPanel\s*/>') {
        $ins = "`n      <EcoPointResolutionPanel />`n"
        $idxMain = $raw.IndexOf("<main")
        if ($idxMain -ge 0) {
          $gt = $raw.IndexOf(">", $idxMain)
          if ($gt -ge 0) { $raw = $raw.Insert($gt + 1, $ins) }
        } else {
          $idxSec = $raw.IndexOf("<section")
          if ($idxSec -ge 0) {
            $gt = $raw.IndexOf(">", $idxSec)
            if ($gt -ge 0) { $raw = $raw.Insert($gt + 1, $ins) }
          } else {
            $idxRet = $raw.IndexOf("return (")
            if ($idxRet -ge 0) {
              $pos = $idxRet + 8
              $raw = $raw.Insert($pos, $ins)
            }
          }
        }
      }

      WriteUtf8NoBom $target $raw
      $patchedPage = $target
      Write-Host ('[PATCH] patched point detail page: ' + $target)
    } else {
      Write-Host "[OK] Page já parece patchada ou vazia."
    }
  }
} else {
  Write-Host "[WARN] Não achei page.tsx de detalhe de ponto (vou deixar só APIs + componente)."
}

$rep = Join-Path $reportDir ('eco-step-67-point-resolution-reopen-v0_1-' + $ts + '.md')
$repLines = @(
'# eco-step-67-point-resolution-reopen-v0_1',
'',
'- Time: ' + $ts,
'- Backup: ' + $backupDir,
'- Component: src/app/eco/_components/EcoPointResolutionPanel.tsx',
'- API: /api/eco/point/detail',
'- API: /api/eco/point/reopen',
'- Patched page: ' + ($(if ($patchedPage) { $patchedPage } else { '(none)' })),
'',
'## Verify',
'1) Ctrl+C -> npm run dev',
'2) Abra o detalhe de um ponto RESOLVIDO',
'3) Deve aparecer painel "Resolução & reincidência"',
'4) Se tiver mutirão ligado ao ponto, deve mostrar link /eco/mutiroes/[id]',
'5) Clique Reabrir: (exige evidência URL ou relato >= 20 chars)',
''
)
WriteUtf8NoBom $rep ($repLines -join "`n")
Write-Host ('[REPORT] ' + $rep)

Write-Host ''
Write-Host '[VERIFY] Ctrl+C -> npm run dev'
Write-Host '[VERIFY] Abra o detalhe de um ponto RESOLVIDO e procure o painel "Resolução & reincidência".'
Write-Host '[VERIFY] Teste Reabrir com evidência (URL) ou relato >= 20 caracteres.'