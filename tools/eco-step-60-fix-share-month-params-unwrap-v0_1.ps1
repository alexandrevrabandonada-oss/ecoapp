param(
  [string]$Root = (Get-Location).Path
)

function EnsureDir([string]$p) { if (-not (Test-Path $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function WriteAllLinesUtf8NoBom([string]$p, [string[]]$lines) {
  EnsureDir (Split-Path -Parent $p)
  $enc = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllLines($p, $lines, $enc)
}
function BackupFile([string]$p, [string]$backupDir) {
  if (Test-Path $p) {
    $rel = $p.Substring($Root.Length).TrimStart('\','/')
    $dest = Join-Path $backupDir ($rel -replace '[\\/]', '__')
    Copy-Item -Force -LiteralPath $p -Destination $dest
    Write-Host ("[BK] " + $rel + " -> " + (Split-Path -Leaf $dest))
  }
}

$ts = Get-Date -Format "yyyyMMdd-HHmmss"
$backupDir = Join-Path $Root ("tools/_patch_backup/" + $ts + "-eco-step-60-fix-share-month-params-unwrap-v0_1")
$reportDir = Join-Path $Root "reports"
EnsureDir $backupDir
EnsureDir $reportDir

Write-Host ("== eco-step-60-fix-share-month-params-unwrap-v0_1 == " + $ts)
Write-Host ("[DIAG] Root: " + $Root)

$page = Join-Path $Root "src/app/eco/share/mes/[month]/page.tsx"
$client = Join-Path $Root "src/app/eco/share/mes/[month]/ShareMonthClient.tsx"

Write-Host ("[DIAG] Will patch: " + $page)
Write-Host ("[DIAG] Will ensure: " + $client)

BackupFile $page $backupDir
BackupFile $client $backupDir

# Patch page.tsx: unwrap params safely
$LPage = @(
'import ShareMonthClient from "./ShareMonthClient";',
'',
'export const dynamic = "force-dynamic";',
'',
'export default async function Page(props: any) {',
'  const p0 = props?.params;',
'  const resolved = p0 && typeof p0.then === "function" ? await p0 : p0;',
'  const month = String(resolved?.month || "");',
'',
'  return (',
'    <main style={{ padding: 16, maxWidth: 1100, margin: "0 auto" }}>',
'      <h1 style={{ margin: "0 0 8px 0" }}>Compartilhar mês: {month || "—"}</h1>',
'      <p style={{ margin: "0 0 14px 0", opacity: 0.85 }}>Card + legenda prontos para postar.</p>',
'      <ShareMonthClient month={month} />',
'    </main>',
'  );',
'}',
''
)
WriteAllLinesUtf8NoBom $page $LPage
Write-Host "[PATCH] wrote src/app/eco/share/mes/[month]/page.tsx"

# Ensure ShareMonthClient exists (minimal + sem hydration treta)
if (-not (Test-Path $client)) {
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
'function fmtKg(n: any): string {',
'  const v = Number(n || 0) || 0;',
'  const s = Math.round(v * 10) / 10;',
'  return String(s).replace(".", ",") + " kg";',
'}',
'',
'function topLines(by: any): string[] {',
'  const arr: Array<{ k: string; v: number }> = [];',
'  if (by && typeof by === "object") {',
'    for (const k of Object.keys(by)) arr.push({ k, v: Number(by[k] || 0) || 0 });',
'  }',
'  arr.sort((a, b) => b.v - a.v);',
'  return arr.slice(0, 5).map((x) => String(x.k) + ": " + fmtKg(x.v));',
'}',
'',
'export default function ShareMonthClient({ month }: { month: string }) {',
'  const [item, setItem] = useState<AnyObj | null>(null);',
'  const [status, setStatus] = useState<string>("ok");',
'',
'  const safeMonth = useMemo(() => String(month || "").trim(), [month]);',
'  const apiUrl = useMemo(() => "/api/eco/month-close?month=" + encodeURIComponent(safeMonth) + "&fresh=0", [safeMonth]);',
'',
'  useEffect(() => {',
'    let alive = true;',
'    (async () => {',
'      if (!safeMonth) { setItem(null); setStatus("mes_invalido"); return; }',
'      setStatus("carregando");',
'      const d = await jget(apiUrl);',
'      if (!alive) return;',
'      if (d && d.ok && d.item) { setItem(d.item); setStatus("ok"); }',
'      else { setItem(null); setStatus("erro"); }',
'    })();',
'    return () => { alive = false; };',
'  }, [apiUrl, safeMonth]);',
'',
'  const summary = (item && (item.summary as any)) || {};',
'  const totals = (summary && (summary.totals as any)) || {};',
'  const totalKg = fmtKg(totals.totalKg || 0);',
'  const days = Number(totals.days || 0) || 0;',
'  const lines = topLines(totals.byMaterialKg || {});',
'',
'  const legend = useMemo(() => {',
'    if (!safeMonth) return "ECO — Transparência do mês (mês inválido)";',
'    const head = "ECO — Transparência do mês " + safeMonth;',
'    const body = "Total do mês: " + totalKg + "\\nDias fechados: " + String(days);',
'    const mats = lines.length ? ("\\nTop materiais:\\n" + lines.join("\\n")) : "\\nTop materiais: sem dados ainda";',
'    const footer = "\\n\\n#ECO — Escutar • Cuidar • Organizar\\nLink: /eco/share/mes/" + safeMonth;',
'    return head + "\\n" + body + mats + footer;',
'  }, [safeMonth, totalKg, days, lines]);',
'',
'  const waHref = useMemo(() => "https://wa.me/?text=" + encodeURIComponent(legend), [legend]);',
'  const card34 = useMemo(() => "/api/eco/month-close/card?format=3x4&month=" + encodeURIComponent(safeMonth), [safeMonth]);',
'  const card11 = useMemo(() => "/api/eco/month-close/card?format=1x1&month=" + encodeURIComponent(safeMonth), [safeMonth]);',
'',
'  async function copyLegend() {',
'    try {',
'      await navigator.clipboard.writeText(legend);',
'      alert("Legenda copiada!");',
'    } catch {',
'      try {',
'        const ta = document.createElement("textarea");',
'        ta.value = legend;',
'        document.body.appendChild(ta);',
'        ta.select();',
'        document.execCommand("copy");',
'        document.body.removeChild(ta);',
'        alert("Legenda copiada!");',
'      } catch {',
'        alert("Não consegui copiar automaticamente. Selecione e copie manualmente.");',
'      }',
'    }',
'  }',
'',
'  return (',
'    <section style={{ display: "grid", gap: 12 }}>',
'      <div style={{ display: "grid", gap: 6, padding: 12, border: "1px solid #ddd", borderRadius: 12 }}>',
'        <div style={{ fontWeight: 900 }}>Status: {status}</div>',
'        <div style={{ opacity: 0.85 }}>Mês: {safeMonth || "—"} • Total: {totalKg} • Dias: {String(days)}</div>',
'      </div>',
'',
'      <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>',
'        <a href={card34} target="_blank" rel="noreferrer" style={{ textDecoration: "none", padding: "8px 10px", borderRadius: 10, border: "1px solid #111", background: "#F7D500", color: "#111", fontWeight: 800 }}>',
'          Abrir Card 3:4',
'        </a>',
'        <a href={card11} target="_blank" rel="noreferrer" style={{ textDecoration: "none", padding: "8px 10px", borderRadius: 10, border: "1px solid #111" }}>',
'          Abrir Card 1:1',
'        </a>',
'        <button onClick={copyLegend} style={{ padding: "8px 10px", borderRadius: 10, border: "1px solid #111", background: "#fff", cursor: "pointer" }}>',
'          Copiar legenda',
'        </button>',
'        <a href={waHref} target="_blank" rel="noreferrer" style={{ textDecoration: "none", padding: "8px 10px", borderRadius: 10, border: "1px solid #111" }}>',
'          WhatsApp',
'        </a>',
'      </div>',
'',
'      <div style={{ display: "grid", gap: 8, padding: 12, border: "1px solid #ddd", borderRadius: 12 }}>',
'        <div style={{ fontWeight: 900 }}>Legenda (preview)</div>',
'        <pre style={{ margin: 0, whiteSpace: "pre-wrap", fontFamily: "ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace", fontSize: 13, opacity: 0.9 }}>{legend}</pre>',
'      </div>',
'    </section>',
'  );',
'}',
''
  )
  WriteAllLinesUtf8NoBom $client $LClient
  Write-Host "[PATCH] created src/app/eco/share/mes/[month]/ShareMonthClient.tsx"
} else {
  Write-Host "[DIAG] ShareMonthClient.tsx already exists (kept). Only page.tsx was fixed."
}

# Report
$rep = Join-Path $reportDir ("eco-step-60-fix-share-month-params-unwrap-v0_1-" + $ts + ".md")
$repLines = @(
"# eco-step-60-fix-share-month-params-unwrap-v0_1",
"",
"- Time: " + $ts,
"- Backup: " + $backupDir,
"",
"## Fix",
"- Avoid crash at params.month by unwrapping params if it is a Promise (Next 16/Turbopack case).",
"- Ensures ShareMonthClient exists (minimal, hydration-safe).",
"",
"## Verify",
"1) Restart dev server",
"2) Open /eco/share/mes/2025-12",
"3) Open card links and WhatsApp link",
""
)
WriteAllLinesUtf8NoBom $rep $repLines
Write-Host ("[REPORT] " + $rep)

Write-Host ""
Write-Host "[VERIFY] Ctrl+C -> npm run dev"
Write-Host "[VERIFY] Abra: /eco/share/mes/2025-12"