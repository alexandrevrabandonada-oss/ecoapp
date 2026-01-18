param([string]$Root = (Get-Location).Path)

$ErrorActionPreference = "Stop"
$me = "eco-step-122-add-eco-mapa-mvp-v0_1"
$stamp = (Get-Date -Format "yyyyMMdd-HHmmss")
Write-Host ("== " + $me + " == " + $stamp)
Write-Host ("[DIAG] Root: " + $Root)

# bootstrap
$boot = Join-Path $Root "tools\_bootstrap.ps1"
if (!(Test-Path -LiteralPath $boot)) { throw "[STOP] tools/_bootstrap.ps1 não encontrado" }
. $boot

if (-not (Get-Command EnsureDir -ErrorAction SilentlyContinue)) { throw "[STOP] bootstrap não carregou EnsureDir" }

$backupDir = Join-Path $Root ("tools\_patch_backup\" + $stamp + "-" + $me)
EnsureDir $backupDir

# ===== PATCH: criar /eco/mapa =====
$dir = Join-Path $Root "src\app\eco\mapa"
EnsureDir $dir

$page = Join-Path $dir "page.tsx"
$client = Join-Path $dir "MapaClient.tsx"

if (Test-Path -LiteralPath $page) { BackupFile $page $backupDir }
if (Test-Path -LiteralPath $client) { BackupFile $client $backupDir }

$pageLines = @(
'import MapaClient from "./MapaClient";',
'',
'export const dynamic = "force-dynamic";',
'',
'export default function Page() {',
'  return (',
'    <main style={{ padding: 16 }}>',
'      <h1 style={{ fontSize: 28, fontWeight: 900, marginBottom: 6 }}>Mapa ECO</h1>',
'      <p style={{ marginTop: 0, marginBottom: 12, opacity: 0.85 }}>',
'        MVP: lista de pontos críticos + link para abrir no OpenStreetMap.',
'      </p>',
'      <MapaClient />',
'    </main>',
'  );',
'}',
''
)
WriteUtf8NoBom $page ($pageLines -join "`n")
Write-Host ("[PATCH] wrote -> " + $page)

$clientLines = @(
'"use client";',
'',
'import React from "react";',
'',
'type Point = {',
'  id: string;',
'  kind: string;',
'  lat: number;',
'  lng: number;',
'  status?: string | null;',
'  note?: string | null;',
'  createdAt?: string | null;',
'  counts?: { confirm?: number; support?: number; replicar?: number } | null;',
'};',
'',
'function num(v: any) {',
'  const n = Number(v);',
'  return Number.isFinite(n) ? n : 0;',
'}',
'',
'function fmtDay(iso?: string | null) {',
'  if (!iso) return "";',
'  try { return new Date(iso).toLocaleString(); } catch { return String(iso); }',
'}',
'',
'function osmLink(lat: number, lng: number) {',
'  const a = String(lat);',
'  const b = String(lng);',
'  return "https://www.openstreetmap.org/?mlat=" + a + "&mlon=" + b + "#map=19/" + a + "/" + b;',
'}',
'',
'function shortId(id: string) {',
'  const s = String(id || "");',
'  return s.length > 12 ? (s.slice(0, 12) + "…") : s;',
'}',
'',
'export default function MapaClient() {',
'  const [loading, setLoading] = React.useState(true);',
'  const [err, setErr] = React.useState<string | null>(null);',
'  const [items, setItems] = React.useState<Point[]>([]);',
'',
'  React.useEffect(() => {',
'    let alive = true;',
'    (async () => {',
'      try {',
'        setLoading(true);',
'        setErr(null);',
'        const r = await fetch("/api/eco/points?limit=200", { cache: "no-store" as any });',
'        const j = await r.json();',
'        if (!alive) return;',
'        const arr = Array.isArray(j?.items) ? j.items : [];',
'        setItems(arr);',
'      } catch (e: any) {',
'        if (!alive) return;',
'        setErr(e?.message ? String(e.message) : String(e));',
'      } finally {',
'        if (alive) setLoading(false);',
'      }',
'    })();',
'    return () => { alive = false; };',
'  }, []);',
'',
'  const stats = React.useMemo(() => {',
'    const byKind: Record<string, number> = {};',
'    for (const p of items) {',
'      const k = String(p?.kind || "UNKNOWN");',
'      byKind[k] = (byKind[k] || 0) + 1;',
'    }',
'    const topKinds = Object.entries(byKind).sort((a, b) => b[1] - a[1]).slice(0, 5);',
'    return { total: items.length, topKinds };',
'  }, [items]);',
'',
'  if (loading) {',
'    return (',
'      <div style={{ padding: 12, border: "1px solid #111", borderRadius: 12, background: "#fff" }}>',
'        Carregando pontos…',
'      </div>',
'    );',
'  }',
'',
'  if (err) {',
'    return (',
'      <div style={{ padding: 12, border: "2px solid #b00", borderRadius: 12, background: "#fff" }}>',
'        Erro: {err}',
'      </div>',
'    );',
'  }',
'',
'  return (',
'    <div style={{ display: "grid", gap: 12 }}>',
'      <div style={{ padding: 12, border: "1px solid #111", borderRadius: 12, background: "#fff" }}>',
'        <div style={{ fontWeight: 900 }}>Total: {stats.total}</div>',
'        {stats.topKinds.length ? (',
'          <div style={{ marginTop: 6, display: "flex", flexWrap: "wrap", gap: 8 }}>',
'            {stats.topKinds.map(([k, n]) => (',
'              <span',
'                key={k}',
'                style={{ padding: "6px 10px", border: "1px solid #111", borderRadius: 999, background: "#f6f6f6", fontWeight: 800 }}',
'              >',
'                {k} ({n})',
'              </span>',
'            ))}',
'          </div>',
'        ) : null}',
'      </div>',
'',
'      <div style={{ overflowX: "auto", border: "1px solid #111", borderRadius: 12, background: "#fff" }}>',
'        <table style={{ width: "100%", borderCollapse: "collapse", fontSize: 14 }}>',
'          <thead>',
'            <tr>',
'              <th style={{ textAlign: "left", padding: 10, borderBottom: "1px solid #111" }}>Ponto</th>',
'              <th style={{ textAlign: "left", padding: 10, borderBottom: "1px solid #111" }}>Tipo</th>',
'              <th style={{ textAlign: "left", padding: 10, borderBottom: "1px solid #111" }}>Status</th>',
'              <th style={{ textAlign: "right", padding: 10, borderBottom: "1px solid #111" }}>✅</th>',
'              <th style={{ textAlign: "right", padding: 10, borderBottom: "1px solid #111" }}>🤝</th>',
'              <th style={{ textAlign: "right", padding: 10, borderBottom: "1px solid #111" }}>♻️</th>',
'              <th style={{ textAlign: "left", padding: 10, borderBottom: "1px solid #111" }}>Quando</th>',
'              <th style={{ textAlign: "left", padding: 10, borderBottom: "1px solid #111" }}>Mapa</th>',
'            </tr>',
'          </thead>',
'          <tbody>',
'            {items.map((p) => (',
'              <tr key={p.id}>',
'                <td style={{ padding: 10, borderBottom: "1px solid #ddd", fontWeight: 900 }}>{shortId(String(p.id))}</td>',
'                <td style={{ padding: 10, borderBottom: "1px solid #ddd" }}>{String(p.kind || "")}</td>',
'                <td style={{ padding: 10, borderBottom: "1px solid #ddd" }}>{String(p.status || "")}</td>',
'                <td style={{ padding: 10, borderBottom: "1px solid #ddd", textAlign: "right" }}>{num(p?.counts?.confirm)}</td>',
'                <td style={{ padding: 10, borderBottom: "1px solid #ddd", textAlign: "right" }}>{num(p?.counts?.support)}</td>',
'                <td style={{ padding: 10, borderBottom: "1px solid #ddd", textAlign: "right" }}>{num(p?.counts?.replicar)}</td>',
'                <td style={{ padding: 10, borderBottom: "1px solid #ddd" }}>{fmtDay(p.createdAt)}</td>',
'                <td style={{ padding: 10, borderBottom: "1px solid #ddd" }}>',
'                  <a href={osmLink(Number(p.lat), Number(p.lng))} target="_blank" rel="noreferrer" style={{ fontWeight: 900 }}>',
'                    Abrir',
'                  </a>',
'                </td>',
'              </tr>',
'            ))}',
'            {!items.length ? (',
'              <tr>',
'                <td colSpan={8} style={{ padding: 12 }}>Nenhum ponto ainda.</td>',
'              </tr>',
'            ) : null}',
'          </tbody>',
'        </table>',
'      </div>',
'    </div>',
'  );',
'}',
''
)
WriteUtf8NoBom $client ($clientLines -join "`n")
Write-Host ("[PATCH] wrote -> " + $client)

# REPORT
$r = @()
$r += "# $me"
$r += ""
$r += "- Time: $stamp"
$r += "- Backup: $backupDir"
$r += ""
$r += "## Patched"
$r += "- src/app/eco/mapa/page.tsx"
$r += "- src/app/eco/mapa/MapaClient.tsx"
$r += ""
$r += "## Verify"
$r += "1) Ctrl+C -> npm run dev"
$r += "2) abrir /eco/mapa"
$reportPath = NewReport $Root $me $stamp $r
Write-Host ("[REPORT] " + $reportPath)

Write-Host ""
Write-Host "[VERIFY] rode:"
Write-Host "  Ctrl+C -> npm run dev"
Write-Host "  abrir /eco/mapa"