param(
  [string]$Root = (Get-Location).Path
)

function EnsureDir([string]$p) { if (-not (Test-Path $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function BackupFile([string]$p, [string]$backupDir) {
  if (Test-Path $p) {
    $rel = $p.Substring($Root.Length).TrimStart('\','/')
    $dest = Join-Path $backupDir ($rel -replace '[\\/]', '__')
    Copy-Item -Force -LiteralPath $p -Destination $dest
    Write-Host ("[BK] " + $rel + " -> " + (Split-Path -Leaf $dest))
  }
}

$ts = Get-Date -Format "yyyyMMdd-HHmmss"
$backupDir = Join-Path $Root ("tools/_patch_backup/" + $ts + "-eco-step-55-day-close-ui-v0_1")
$reportDir = Join-Path $Root "reports"
EnsureDir $backupDir
EnsureDir $reportDir

$rtList = Join-Path $Root "src/app/api/eco/day-close/list/route.ts"
$pg = Join-Path $Root "src/app/eco/fechamento/page.tsx"
$client = Join-Path $Root "src/app/eco/fechamento/FechamentoClient.tsx"

Write-Host ("[DIAG] Root: " + $Root)
Write-Host ("[DIAG] Will write: " + $rtList)
Write-Host ("[DIAG] Will write: " + $pg)
Write-Host ("[DIAG] Will write: " + $client)

BackupFile $rtList $backupDir
BackupFile $pg $backupDir
BackupFile $client $backupDir

$enc = New-Object System.Text.UTF8Encoding($false)

# ---------------- API list route ----------------
$linesApi = @(
'// ECO — day-close/list (history) — step 55',
'',
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
'',
'function looksLikeMissingTable(msg: string) {',
'  const m = msg.toLowerCase();',
'  return m.includes("does not exist") || m.includes("no such table") || m.includes("p2021");',
'}',
'',
'function getDayCloseModel() {',
'  const pc: any = prisma as any;',
'  return pc?.ecoDayClose;',
'}',
'',
'function clamp(n: number, a: number, b: number) {',
'  return Math.max(a, Math.min(b, n));',
'}',
'',
'export async function GET(req: Request) {',
'  const { searchParams } = new URL(req.url);',
'  const raw = String(searchParams.get("limit") ?? "30").trim();',
'  const limit = clamp(Number(raw) || 30, 1, 200);',
'',
'  const model = getDayCloseModel();',
'  if (!model?.findMany) {',
'    return NextResponse.json({ ok: false, error: "model_not_ready" }, { status: 503 });',
'  }',
'',
'  try {',
'    const items = await model.findMany({',
'      orderBy: { day: "desc" },',
'      take: limit,',
'    });',
'    return NextResponse.json({ ok: true, items, limit });',
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

EnsureDir (Split-Path -Parent $rtList)
[System.IO.File]::WriteAllLines($rtList, $linesApi, $enc)
Write-Host "[PATCH] wrote src/app/api/eco/day-close/list/route.ts"

# ---------------- UI page ----------------
$linesPage = @(
'// ECO — Fechamento do Dia (UI) — step 55',
'',
'import FechamentoClient from "./FechamentoClient";',
'',
'export const dynamic = "force-dynamic";',
'',
'export default function Page() {',
'  return (',
'    <main style={{ padding: 16, fontFamily: "system-ui, -apple-system, Segoe UI, Roboto, Arial" }}>',
'      <h1 style={{ margin: "0 0 8px 0" }}>ECO — Fechamento do Dia</h1>',
'      <p style={{ margin: "0 0 16px 0", opacity: 0.85 }}>',
'        Fecha o dia (upsert) e mostra o resumo + histórico. (Brasil -03:00)',
'      </p>',
'      <FechamentoClient />',
'    </main>',
'  );',
'}',
''
)

EnsureDir (Split-Path -Parent $pg)
[System.IO.File]::WriteAllLines($pg, $linesPage, $enc)
Write-Host "[PATCH] wrote src/app/eco/fechamento/page.tsx"

# ---------------- client component ----------------
$linesClient = @(
'"use client";',
'',
'import { useEffect, useMemo, useState } from "react";',
'',
'type AnyObj = Record<string, any>;',
'',
'function brDayToday(): string {',
'  // pega YYYY-MM-DD em America/Sao_Paulo, sem depender de toISOString (UTC)',
'  try {',
'    const parts = new Intl.DateTimeFormat("en-CA", { timeZone: "America/Sao_Paulo", year: "numeric", month: "2-digit", day: "2-digit" }).formatToParts(new Date());',
'    const y = parts.find(p => p.type === "year")?.value || "";',
'    const m = parts.find(p => p.type === "month")?.value || "";',
'    const d = parts.find(p => p.type === "day")?.value || "";',
'    if (y && m && d) return y + "-" + m + "-" + d;',
'  } catch {}',
'  // fallback: local date',
'  const dt = new Date();',
'  const y = String(dt.getFullYear());',
'  const m = String(dt.getMonth() + 1).padStart(2, "0");',
'  const d = String(dt.getDate()).padStart(2, "0");',
'  return y + "-" + m + "-" + d;',
'}',
'',
'async function jget(url: string): Promise<AnyObj> {',
'  const res = await fetch(url, { headers: { Accept: "application/json" }, cache: "no-store" });',
'  const data = await res.json().catch(() => ({}));',
'  if (!res.ok) return { ok: false, status: res.status, ...data };',
'  return data;',
'}',
'',
'export default function FechamentoClient() {',
'  const [day, setDay] = useState<string>(brDayToday());',
'  const [busy, setBusy] = useState(false);',
'  const [result, setResult] = useState<AnyObj | null>(null);',
'  const [history, setHistory] = useState<AnyObj | null>(null);',
'',
'  const dayCloseUrl = useMemo(() => {',
'    return "/api/eco/day-close?day=" + encodeURIComponent(day);',
'  }, [day]);',
'',
'  async function loadHistory() {',
'    const data = await jget("/api/eco/day-close/list?limit=30");',
'    setHistory(data);',
'  }',
'',
'  async function doClose(fresh: boolean) {',
'    setBusy(true);',
'    try {',
'      const url = dayCloseUrl + (fresh ? "&fresh=1" : "");',
'      const data = await jget(url);',
'      setResult(data);',
'      await loadHistory();',
'    } finally {',
'      setBusy(false);',
'    }',
'  }',
'',
'  useEffect(() => {',
'    loadHistory();',
'    // eslint-disable-next-line react-hooks/exhaustive-deps',
'  }, []);',
'',
'  return (',
'    <section style={{ display: "grid", gap: 12, maxWidth: 980 }}>',
'      <div style={{ display: "flex", gap: 8, alignItems: "center", flexWrap: "wrap" }}>',
'        <label style={{ display: "flex", gap: 8, alignItems: "center" }}>',
'          <span>Dia:</span>',
'          <input',
'            value={day}',
'            onChange={(e) => setDay(e.target.value)}',
'            placeholder="YYYY-MM-DD"',
'            style={{ padding: "6px 8px", border: "1px solid #ccc", borderRadius: 6, minWidth: 150 }}',
'          />',
'        </label>',
'',
'        <button',
'          onClick={() => doClose(false)}',
'          disabled={busy}',
'          style={{ padding: "8px 10px", borderRadius: 8, border: "1px solid #111", cursor: busy ? "not-allowed" : "pointer" }}',
'        >',
'          Fechar / Buscar cache',
'        </button>',
'',
'        <button',
'          onClick={() => doClose(true)}',
'          disabled={busy}',
'          style={{ padding: "8px 10px", borderRadius: 8, border: "1px solid #111", cursor: busy ? "not-allowed" : "pointer" }}',
'        >',
'          Recalcular (fresh=1)',
'        </button>',
'',
'        <button',
'          onClick={() => loadHistory()}',
'          disabled={busy}',
'          style={{ padding: "8px 10px", borderRadius: 8, border: "1px solid #111", cursor: busy ? "not-allowed" : "pointer" }}',
'        >',
'          Atualizar histórico',
'        </button>',
'      </div>',
'',
'      <div style={{ display: "grid", gap: 12, gridTemplateColumns: "1fr 1fr" }}>',
'        <div>',
'          <h2 style={{ margin: "0 0 8px 0" }}>Resultado</h2>',
'          <pre style={{ whiteSpace: "pre-wrap", wordBreak: "break-word", padding: 12, border: "1px solid #ddd", borderRadius: 10, minHeight: 160 }}>',
'            {result ? JSON.stringify(result, null, 2) : "—"}',
'          </pre>',
'        </div>',
'        <div>',
'          <h2 style={{ margin: "0 0 8px 0" }}>Histórico (últimos 30)</h2>',
'          <pre style={{ whiteSpace: "pre-wrap", wordBreak: "break-word", padding: 12, border: "1px solid #ddd", borderRadius: 10, minHeight: 160 }}>',
'            {history ? JSON.stringify(history, null, 2) : "—"}',
'          </pre>',
'        </div>',
'      </div>',
'    </section>',
'  );',
'}',
''
)

EnsureDir (Split-Path -Parent $client)
[System.IO.File]::WriteAllLines($client, $linesClient, $enc)
Write-Host "[PATCH] wrote src/app/eco/fechamento/FechamentoClient.tsx"

# ---------------- report ----------------
$rep = Join-Path $reportDir ("eco-step-55-day-close-ui-v0_1-" + $ts + ".md")
$repLines = @(
"# eco-step-55-day-close-ui-v0_1",
"",
"- Time: " + $ts,
"- Backup: " + $backupDir,
"",
"## Added",
"- API: /api/eco/day-close/list (GET?limit=30)",
"- UI: /eco/fechamento (page + client component)",
"",
"## Next verify",
"- Restart dev server",
"- Open http://localhost:3000/eco/fechamento",
"- Test list: irm 'http://localhost:3000/api/eco/day-close/list?limit=5' | ConvertTo-Json -Depth 20",
""
)
[System.IO.File]::WriteAllLines($rep, $repLines, $enc)
Write-Host ("[REPORT] " + $rep)

Write-Host ""
Write-Host "[VERIFY] rode:"
Write-Host "  1) npm run dev (reinicia)"
Write-Host "  2) abra: http://localhost:3000/eco/fechamento"
Write-Host "  3) irm 'http://localhost:3000/api/eco/day-close/list?limit=5' | ConvertTo-Json -Depth 20"