param(
  [string]$Root = (Get-Location).Path
)

$ts = Get-Date -Format 'yyyyMMdd-HHmmss'

# --- bootstrap
$boot = Join-Path $Root "tools/_bootstrap.ps1"
if (Test-Path $boot) { . $boot }

# --- fallbacks
if (-not (Get-Command EnsureDir -ErrorAction SilentlyContinue)) {
  function EnsureDir([string]$p) { if (-not (Test-Path $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null } }
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
    if (Test-Path $p) {
      $rel = $p.Substring($root.Length).TrimStart('\','/')
      $dest = Join-Path $backupDir ($rel -replace '[\\/]', '__')
      Copy-Item -Force -LiteralPath $p -Destination $dest
      Write-Host ('[BK] ' + $rel + ' -> ' + (Split-Path -Leaf $dest))
    }
  }
}
function WriteLinesUtf8NoBom([string]$p, [string[]]$lines) { WriteUtf8NoBom $p ($lines -join "`n") }

$backupDir = Join-Path $Root ('tools/_patch_backup/' + $ts + '-eco-step-66-finish-mutirao-resolve-point-proof-v0_1')
$reportDir = Join-Path $Root 'reports'
EnsureDir $backupDir
EnsureDir $reportDir

Write-Host ('== eco-step-66-finish-mutirao-resolve-point-proof-v0_1 == ' + $ts)
Write-Host ('[DIAG] Root: ' + $Root)

$finishRoute = Join-Path $Root 'src/app/api/eco/mutirao/finish/route.ts'
$updateRoute = Join-Path $Root 'src/app/api/eco/mutirao/update/route.ts'
$clientFile  = Join-Path $Root 'src/app/eco/mutiroes/[id]/MutiraoDetailClient.tsx'

Write-Host ('[DIAG] Will write: ' + $finishRoute)
Write-Host ('[DIAG] Will write: ' + $updateRoute)
Write-Host ('[DIAG] Will patch: ' + $clientFile)

BackupFile $Root $finishRoute $backupDir
BackupFile $Root $updateRoute $backupDir
BackupFile $Root $clientFile  $backupDir

EnsureDir (Split-Path -Parent $finishRoute)
EnsureDir (Split-Path -Parent $updateRoute)

# --- finish route (prova forte + resolve ponto)
$LFinish = @(
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
'function getMutiraoModel() {',
'  const pc: any = prisma as any;',
'  const candidates = ["ecoMutirao", "mutirao", "ecoMutiroes", "mutiroes"];',
'  for (const k of candidates) {',
'    const m = pc?.[k];',
'    if (m && typeof m.update === "function") return { key: k, model: m as any };',
'  }',
'  return null;',
'}',
'function getPointModel() {',
'  const pc: any = prisma as any;',
'  const candidates = ["ecoPoint", "ecoCriticalPoint", "criticalPoint", "ecoPonto", "ponto"];',
'  for (const k of candidates) {',
'    const m = pc?.[k];',
'    if (m && typeof m.update === "function") return { key: k, model: m as any };',
'  }',
'  return null;',
'}',
'function cleanUrl(v: any) {',
'  const s = String(v || "").trim();',
'  if (!s) return null;',
'  return s.slice(0, 500);',
'}',
'function getPointId(row: any) {',
'  return (row?.pointId ?? row?.criticalPointId ?? row?.ecoPointId ?? row?.pontoId ?? row?.point?.id ?? null) as string | null;',
'}',
'',
'export async function POST(req: Request) {',
'  const body = (await req.json().catch(() => null)) as any;',
'  const id = String(body?.id || "").trim();',
'  if (!id) return NextResponse.json({ ok: false, error: "bad_id" }, { status: 400 });',
'',
'  const m = getMutiraoModel();',
'  if (!m?.model) return NextResponse.json({ ok: false, error: "model_not_ready" }, { status: 503 });',
'',
'  const beforeUrl = cleanUrl(body?.beforeUrl);',
'  const afterUrl = cleanUrl(body?.afterUrl);',
'  const checklist = body?.checklist && typeof body.checklist === "object" ? body.checklist : {};',
'  const proofNote = String(checklist?.proofNote || body?.proofNote || "").trim();',
'',
'  const hasProof = !!beforeUrl && !!afterUrl;',
'  if (!hasProof && proofNote.length < 10) {',
'    return NextResponse.json({',
'      ok: false,',
'      error: "missing_proof",',
'      hint: "Envie ANTES e DEPOIS ou escreva justificativa (min 10 chars).",',
'      got: { before: !!beforeUrl, after: !!afterUrl, proofNoteLen: proofNote.length }',
'    }, { status: 400 });',
'  }',
'',
'  const checklist2 = { ...checklist, proofNote: proofNote || checklist?.proofNote || "" };',
'',
'  try {',
'    const data: any = { status: "DONE", checklist: checklist2 };',
'    if (beforeUrl) data.beforeUrl = beforeUrl;',
'    if (afterUrl) data.afterUrl = afterUrl;',
'',
'    const item = await m.model.update({',
'      where: { id },',
'      data,',
'      include: { point: true },',
'    });',
'',
'    const pm = getPointModel();',
'    const pid = getPointId(item);',
'    let pointUpdated = false;',
'    let pointError: string | null = null;',
'',
'    if (pm && pid) {',
'      try {',
'        await pm.model.update({ where: { id: pid }, data: { status: "RESOLVED" } });',
'        pointUpdated = true;',
'      } catch (e) {',
'        pointError = asMsg(e);',
'      }',
'    }',
'',
'    return NextResponse.json({ ok: true, item, meta: { mutiraoModel: m.key, pointModel: pm?.key || "missing", pointUpdated, pointError } });',
'  } catch (e) {',
'    const msg = asMsg(e);',
'    if (looksLikeMissingTable(msg)) {',
'      return NextResponse.json({ ok: false, error: "db_not_ready", detail: msg }, { status: 503 });',
'    }',
'    return NextResponse.json({ ok: false, error: "db_error", detail: msg }, { status: 500 });',
'  }',
'}',
''
)
WriteLinesUtf8NoBom $finishRoute $LFinish
Write-Host '[PATCH] wrote src/app/api/eco/mutirao/finish/route.ts'

# --- update route (rascunho)
$LUpdate = @(
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
'function getMutiraoModel() {',
'  const pc: any = prisma as any;',
'  const candidates = ["ecoMutirao", "mutirao", "ecoMutiroes", "mutiroes"];',
'  for (const k of candidates) {',
'    const m = pc?.[k];',
'    if (m && typeof m.update === "function") return { key: k, model: m as any };',
'  }',
'  return null;',
'}',
'function cleanUrl(v: any) {',
'  const s = String(v || "").trim();',
'  if (!s) return null;',
'  return s.slice(0, 500);',
'}',
'',
'export async function POST(req: Request) {',
'  const body = (await req.json().catch(() => null)) as any;',
'  const id = String(body?.id || "").trim();',
'  if (!id) return NextResponse.json({ ok: false, error: "bad_id" }, { status: 400 });',
'',
'  const m = getMutiraoModel();',
'  if (!m?.model) return NextResponse.json({ ok: false, error: "model_not_ready" }, { status: 503 });',
'',
'  const beforeUrl = cleanUrl(body?.beforeUrl);',
'  const afterUrl = cleanUrl(body?.afterUrl);',
'  const checklist = body?.checklist && typeof body.checklist === "object" ? body.checklist : null;',
'',
'  try {',
'    const data: any = {};',
'    if (beforeUrl) data.beforeUrl = beforeUrl;',
'    if (afterUrl) data.afterUrl = afterUrl;',
'    if (checklist) data.checklist = checklist;',
'',
'    const item = await m.model.update({ where: { id }, data, include: { point: true } });',
'    return NextResponse.json({ ok: true, item, meta: { mutiraoModel: m.key } });',
'  } catch (e) {',
'    const msg = asMsg(e);',
'    if (looksLikeMissingTable(msg)) {',
'      return NextResponse.json({ ok: false, error: "db_not_ready", detail: msg }, { status: 503 });',
'    }',
'    return NextResponse.json({ ok: false, error: "db_error", detail: msg }, { status: 500 });',
'  }',
'}',
''
)
WriteLinesUtf8NoBom $updateRoute $LUpdate
Write-Host '[PATCH] wrote src/app/api/eco/mutirao/update/route.ts'

# --- Patch client UI (regrinha + textarea proofNote)
if (-not (Test-Path $clientFile)) {
  throw ('[STOP] Não achei: ' + $clientFile + ' (confere o caminho da tela do mutirão)')
}

$raw = Get-Content -Raw -LiteralPath $clientFile
if (-not $raw) { throw ('[STOP] arquivo vazio: ' + $clientFile) }

# 1) garantir que chkDefault tem proofNote
if ($raw -notmatch 'proofNote') {
  $raw = $raw -replace 'return \{ luvas: false, sacos: false, agua: false, separacao: false, destino: false, aviso_vizinhos: false \};',
                     'return { luvas: false, sacos: false, agua: false, separacao: false, destino: false, aviso_vizinhos: false, proofNote: "" };'
}

# 2) inserir textarea antes dos botões (ancora: "Checklist do mutirão" bloco)
if ($raw -notmatch 'Justificativa \(se faltar foto\)') {
  $needle = '<div style={{ fontWeight: 900 }}>Checklist do mutirão</div>'
  $insert = $needle + "`n" +
'        <div style={{ opacity: 0.7, fontSize: 12 }}>Regra: pra finalizar (DONE), precisa ANTES+DEPOIS ou uma justificativa.</div>' + "`n" +
'        <label style={{ display: "grid", gap: 6 }}>' + "`n" +
'          <span>Justificativa (se faltar foto)</span>' + "`n" +
'          <textarea value={String((check as any)?.proofNote || "")} onChange={(e) => setCheck((prev: AnyObj) => ({ ...prev, proofNote: e.target.value }))} rows={3} placeholder="Explique por que faltou foto (mín 10 caracteres)..." style={{ padding: 10, borderRadius: 10, border: "1px solid #ccc" }} />' + "`n" +
'        </label>'
  $raw = $raw.Replace($needle, $insert)
}

WriteUtf8NoBom $clientFile $raw
Write-Host '[PATCH] updated MutiraoDetailClient.tsx (proofNote + regra)'

$rep = Join-Path $reportDir ('eco-step-66-finish-mutirao-resolve-point-proof-v0_1-' + $ts + '.md')
$repLines = @(
'# eco-step-66-finish-mutirao-resolve-point-proof-v0_1',
'',
'- Time: ' + $ts,
'- Backup: ' + $backupDir,
'',
'## Changes',
'- POST /api/eco/mutirao/finish: exige prova forte (antes+depois ou justificativa), marca DONE e tenta resolver ponto (OPEN->RESOLVED).',
'- POST /api/eco/mutirao/update: rascunho (before/after/checklist).',
'- UI mutirão: campo justificativa (proofNote) dentro do checklist.',
'',
'## Verify',
'1) restart dev',
'2) /eco/mutiroes/[id] -> tentar finalizar sem fotos e sem justificativa (deve dar erro)',
'3) colocar justificativa e finalizar (deve OK)',
'4) finalizar com antes+depois (OK)',
'5) conferir se o ponto vira RESOLVED (se modelo existir)',
''
)
WriteLinesUtf8NoBom $rep $repLines
Write-Host ('[REPORT] ' + $rep)

Write-Host ''
Write-Host '[VERIFY] Ctrl+C -> npm run dev'
Write-Host '[VERIFY] /eco/mutiroes/[id] -> Finalizar sem prova (deve 400 missing_proof)'
Write-Host '[VERIFY] Com justificativa OU com antes+depois -> OK'