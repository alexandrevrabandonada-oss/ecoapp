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

function WriteLinesUtf8NoBom([string]$p, [string[]]$lines) {
  $text = ($lines -join "`n")
  WriteUtf8NoBom $p $text
}

$backupDir = Join-Path $Root ('tools/_patch_backup/' + $ts + '-eco-step-65-recibos-hub-v0_1')
$reportDir = Join-Path $Root 'reports'
EnsureDir $backupDir
EnsureDir $reportDir

Write-Host ('== eco-step-65-recibos-hub-v0_1 == ' + $ts)
Write-Host ('[DIAG] Root: ' + $Root)

$apiList  = Join-Path $Root 'src/app/api/eco/recibo/list/route.ts'
$page     = Join-Path $Root 'src/app/eco/recibos/page.tsx'
$client   = Join-Path $Root 'src/app/eco/recibos/RecibosClient.tsx'

Write-Host ('[DIAG] Will write: ' + $apiList)
Write-Host ('[DIAG] Will write: ' + $page)
Write-Host ('[DIAG] Will write: ' + $client)

BackupFile $Root $apiList $backupDir
BackupFile $Root $page $backupDir
BackupFile $Root $client $backupDir

# --- API: /api/eco/recibo/list
$LApi = @(
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
'',
'function getModel(candidates: string[]) {',
'  const pc: any = prisma as any;',
'  for (const k of candidates) {',
'    const m = pc?.[k];',
'    if (m && typeof m.findMany === "function") return { key: k, model: m as any };',
'  }',
'  return null;',
'}',
'',
'function clampLimit(v: any) {',
'  const n = Number(v || 30);',
'  if (!Number.isFinite(n)) return 30;',
'  return Math.max(1, Math.min(200, Math.floor(n)));',
'}',
'',
'export async function GET(req: Request) {',
'  const { searchParams } = new URL(req.url);',
'  const limit = clampLimit(searchParams.get("limit"));',
'',
'  const dayClose = getModel(["ecoDayClose", "dayClose", "ecoDayclose"]);',
'  const mutirao  = getModel(["ecoMutirao", "mutirao", "ecoMutiroes", "ecoMutirões"]);',
'',
'  const out: any = { ok: true, limit, sources: {}, dayCloses: [], mutiroes: [] };',
'',
'  try {',
'    if (dayClose) {',
'      out.sources.dayClose = dayClose.key;',
'      const rows = await dayClose.model.findMany({',
'        orderBy: { day: "desc" },',
'        take: limit,',
'      });',
'      out.dayCloses = rows || [];',
'    } else {',
'      out.sources.dayClose = "missing";',
'    }',
'',
'    if (mutirao) {',
'      out.sources.mutirao = mutirao.key;',
'      const rows = await mutirao.model.findMany({',
'        where: { status: "DONE" },',
'        orderBy: { startAt: "desc" },',
'        take: limit,',
'        include: { point: true },',
'      });',
'      out.mutiroes = rows || [];',
'    } else {',
'      out.sources.mutirao = "missing";',
'    }',
'',
'    return NextResponse.json(out);',
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
WriteLinesUtf8NoBom $apiList $LApi
Write-Host '[PATCH] wrote src/app/api/eco/recibo/list/route.ts'

# --- Page: /eco/recibos
$LPage = @(
'import RecibosClient from "./RecibosClient";',
'',
'export default function Page() {',
'  return (',
'    <main style={{ padding: 16, maxWidth: 1100, margin: "0 auto" }}>',
'      <h1 style={{ margin: "0 0 8px 0" }}>Recibos ECO</h1>',
'      <p style={{ margin: "0 0 14px 0", opacity: 0.85 }}>',
'        Provas fortes: fechamento do dia e mutirões concluídos (antes/depois).',
'      </p>',
'      <RecibosClient />',
'    </main>',
'  );',
'}',
''
)
WriteLinesUtf8NoBom $page $LPage
Write-Host '[PATCH] wrote src/app/eco/recibos/page.tsx'

# --- Client UI
$LClient = @(
'"use client";',
'',
'import { useEffect, useMemo, useState } from "react";',
'',
'type AnyObj = Record<string, any>;',
'',
'async function jget(url: string): Promise<AnyObj> {',
'  const res = await fetch(url, { headers: { Accept: "application/json" }, cache: "no-store" });',
'  const data = await res.json().catch(() => ({}));',
'  if (!res.ok) return { ok: false, status: res.status, ...data };',
'  return data;',
'}',
'',
'function fmtDate(day: string) {',
'  const s = String(day || "");',
'  if (/^\\d{4}-\\d{2}-\\d{2}$/.test(s)) {',
'    const y = s.slice(0, 4);',
'    const m = s.slice(5, 7);',
'    const d = s.slice(8, 10);',
'    return d + "/" + m + "/" + y;',
'  }',
'  return s;',
'}',
'',
'function clip(text: string) {',
'  try {',
'    if (navigator && navigator.clipboard && navigator.clipboard.writeText) {',
'      navigator.clipboard.writeText(text);',
'    }',
'  } catch {}',
'}',
'',
'export default function RecibosClient() {',
'  const [data, setData] = useState<AnyObj | null>(null);',
'  const [status, setStatus] = useState<string>("carregando");',
'  const [msg, setMsg] = useState<string>("");',
'  const [limit, setLimit] = useState<number>(30);',
'',
'  const url = useMemo(() => "/api/eco/recibo/list?limit=" + encodeURIComponent(String(limit)), [limit]);',
'',
'  async function refresh() {',
'    setStatus("carregando");',
'    setMsg("");',
'    const d = await jget(url);',
'    if (d && d.ok) {',
'      setData(d);',
'      setStatus("ok");',
'    } else {',
'      setData(null);',
'      setStatus("erro");',
'      setMsg("Erro: " + String(d?.error || d?.detail || "unknown"));',
'    }',
'  }',
'',
'  useEffect(() => { refresh(); }, [url]);',
'',
'  const dayCloses = Array.isArray(data?.dayCloses) ? data!.dayCloses : [];',
'  const mutiroes = Array.isArray(data?.mutiroes) ? data!.mutiroes : [];',
'',
'  return (',
'    <section style={{ display: "grid", gap: 14 }}>',
'      <div style={{ display: "flex", gap: 10, flexWrap: "wrap", alignItems: "center" }}>',
'        <a href="/eco" style={{ textDecoration: "none", padding: "8px 10px", borderRadius: 10, border: "1px solid #111" }}>Voltar</a>',
'        <button onClick={refresh} style={{ padding: "8px 10px", borderRadius: 10, border: "1px solid #111", background: "#fff", cursor: "pointer" }}>Atualizar</button>',
'        <label style={{ display: "flex", gap: 8, alignItems: "center" }}>',
'          <span style={{ opacity: 0.75 }}>limite</span>',
'          <input value={String(limit)} onChange={(e) => setLimit(Number(e.target.value || 30))} style={{ width: 90, padding: "8px 10px", borderRadius: 10, border: "1px solid #ccc" }} />',
'        </label>',
'        <div style={{ opacity: 0.7 }}>status: {status}</div>',
'      </div>',
'',
'      {msg ? <div style={{ padding: 10, borderRadius: 10, background: "#fff7cc", border: "1px solid #f0d000" }}>{msg}</div> : null}',
'',
'      <div style={{ display: "grid", gap: 10, padding: 12, border: "1px solid #ddd", borderRadius: 12 }}>',
'        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline" }}>',
'          <div style={{ fontWeight: 900 }}>Fechamentos do dia</div>',
'          <div style={{ opacity: 0.7, fontSize: 12 }}>fonte: {String(data?.sources?.dayClose || "—")}</div>',
'        </div>',
'',
'        {dayCloses.length === 0 ? <div style={{ opacity: 0.7 }}>Nenhum fechamento encontrado.</div> : null}',
'',
'        <div style={{ display: "grid", gap: 10 }}>',
'          {dayCloses.map((it: AnyObj) => {',
'            const day = String(it.day || "");',
'            const share = "/eco/share/dia/" + encodeURIComponent(day);',
'            const card = "/api/eco/day-close/card?format=3x4&day=" + encodeURIComponent(day);',
'            const totalKg = it?.summary?.totals?.totalKg;',
'            const count = it?.summary?.totals?.count;',
'            const legend = "ECO — Fechamento do dia " + day + "\\n" +',
'              "Total: " + String(totalKg ?? "—") + " kg • Itens: " + String(count ?? "—") + "\\n" +',
'              "#ECO — Escutar • Cuidar • Organizar";',
'',
'            return (',
'              <div key={day} style={{ display: "grid", gap: 8, padding: 12, borderRadius: 12, border: "1px solid #eee" }}>',
'                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline" }}>',
'                  <div style={{ fontWeight: 900 }}>{fmtDate(day)}</div>',
'                  <div style={{ opacity: 0.8, fontSize: 12 }}>kg: {String(totalKg ?? "—")} • itens: {String(count ?? "—")}</div>',
'                </div>',
'                <div style={{ display: "flex", gap: 10, flexWrap: "wrap", alignItems: "center" }}>',
'                  <a href={share} style={{ textDecoration: "none", padding: "8px 10px", borderRadius: 10, border: "1px solid #111" }}>Abrir share</a>',
'                  <a href={card} target="_blank" rel="noreferrer" style={{ textDecoration: "none", padding: "8px 10px", borderRadius: 10, border: "1px solid #111" }}>Abrir card 3:4</a>',
'                  <button onClick={() => clip(legend)} style={{ padding: "8px 10px", borderRadius: 10, border: "1px solid #111", background: "#fff", cursor: "pointer" }}>Copiar legenda</button>',
'                </div>',
'              </div>',
'            );',
'          })}',
'        </div>',
'      </div>',
'',
'      <div style={{ display: "grid", gap: 10, padding: 12, border: "1px solid #ddd", borderRadius: 12 }}>',
'        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline" }}>',
'          <div style={{ fontWeight: 900 }}>Mutirões concluídos</div>',
'          <div style={{ opacity: 0.7, fontSize: 12 }}>fonte: {String(data?.sources?.mutirao || "—")}</div>',
'        </div>',
'',
'        {mutiroes.length === 0 ? <div style={{ opacity: 0.7 }}>Nenhum mutirão concluído encontrado.</div> : null}',
'',
'        <div style={{ display: "grid", gap: 10 }}>',
'          {mutiroes.map((it: AnyObj) => {',
'            const id = String(it.id || "");',
'            const startAt = String(it.startAt || "");',
'            const day = startAt ? startAt.slice(0, 10) : "";',
'            const share = "/eco/share/mutirao/" + encodeURIComponent(id);',
'            const card = "/api/eco/mutirao/card?format=3x4&id=" + encodeURIComponent(id);',
'            const kind = String(it?.point?.kind || "PONTO");',
'            const note = String(it?.point?.note || "");',
'            const confirm = String(it?.point?.confirmCount || 0);',
'',
'            const legend = "ECO — Mutirão concluído\\n" +',
'              (day ? ("Data: " + day + "\\n") : "") +',
'              "Ponto: " + kind + "\\n" +',
'              (note ? ("Obs: " + note + "\\n") : "") +',
'              "Confirmações: " + confirm + "\\n" +',
'              "#ECO — Escutar • Cuidar • Organizar";',
'',
'            return (',
'              <div key={id} style={{ display: "grid", gap: 8, padding: 12, borderRadius: 12, border: "1px solid #eee" }}>',
'                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline", gap: 10 }}>',
'                  <div style={{ fontWeight: 900 }}>{kind}</div>',
'                  <div style={{ opacity: 0.75, fontSize: 12 }}>conf.: {confirm}</div>',
'                </div>',
'                {note ? <div style={{ opacity: 0.85 }}>{note}</div> : null}',
'                <div style={{ display: "flex", gap: 10, flexWrap: "wrap", alignItems: "center" }}>',
'                  <a href={share} style={{ textDecoration: "none", padding: "8px 10px", borderRadius: 10, border: "1px solid #111" }}>Abrir share</a>',
'                  <a href={card} target="_blank" rel="noreferrer" style={{ textDecoration: "none", padding: "8px 10px", borderRadius: 10, border: "1px solid #111" }}>Abrir card 3:4</a>',
'                  <button onClick={() => clip(legend)} style={{ padding: "8px 10px", borderRadius: 10, border: "1px solid #111", background: "#fff", cursor: "pointer" }}>Copiar legenda</button>',
'                </div>',
'              </div>',
'            );',
'          })}',
'        </div>',
'      </div>',
'',
'      <div style={{ opacity: 0.7, fontSize: 12 }}>',
'        Dica: esse hub é pra operar “prova forte”: fechamento do dia e mutirão com antes/depois.',
'      </div>',
'    </section>',
'  );',
'}',
''
)
WriteLinesUtf8NoBom $client $LClient
Write-Host '[PATCH] wrote src/app/eco/recibos/RecibosClient.tsx'

$rep = Join-Path $reportDir ('eco-step-65-recibos-hub-v0_1-' + $ts + '.md')
$repLines = @(
'# eco-step-65-recibos-hub-v0_1',
'',
'- Time: ' + $ts,
'- Backup: ' + $backupDir,
'',
'## Added',
'- GET /api/eco/recibo/list',
'- Page /eco/recibos',
'',
'## Verify',
'1) restart dev',
'2) abrir /eco/recibos',
'3) testar botões share/card/copy',
''
)
WriteLinesUtf8NoBom $rep $repLines
Write-Host ('[REPORT] ' + $rep)

Write-Host ''
Write-Host '[VERIFY] Ctrl+C -> npm run dev'
Write-Host '[VERIFY] Abra /eco/recibos'