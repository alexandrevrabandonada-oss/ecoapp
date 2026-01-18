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
$backupDir = Join-Path $Root ("tools/_patch_backup/" + $ts + "-eco-step-56c-fix-card-og-display-v0_1")
$reportDir = Join-Path $Root "reports"
EnsureDir $backupDir
EnsureDir $reportDir

$rtCard = Join-Path $Root "src/app/api/eco/day-close/card/route.tsx"

Write-Host ("[DIAG] Root: " + $Root)
Write-Host ("[DIAG] Patch: " + $rtCard)

BackupFile $rtCard $backupDir

$enc = New-Object System.Text.UTF8Encoding($false)

$L = @(
'// ECO — day-close/card (PNG) — step 56c: fix next/og display rule',
'',
'import { ImageResponse } from "next/og";',
'',
'export const runtime = "edge";',
'export const dynamic = "force-dynamic";',
'',
'function safeDay(input: string | null): string | null {',
'  const raw = String(input ?? "").trim();',
'  if (!raw) return null;',
'  const norm = raw.replace(/[‐-‒–—―]/g, "-").replace(/\//g, "-");',
'  const m = norm.match(/^(\d{4})-(\d{2})-(\d{2})(?:$|[T\s])/);',
'  if (!m) return null;',
'  const mo = Number(m[2]);',
'  const d = Number(m[3]);',
'  if (mo < 1 || mo > 12) return null;',
'  if (d < 1 || d > 31) return null;',
'  return m[1] + "-" + m[2] + "-" + m[3];',
'}',
'',
'function fmtKg(n: any): string {',
'  const v = Number(n || 0) || 0;',
'  const s = Math.round(v * 10) / 10;',
'  return String(s).replace(".", ",") + " kg";',
'}',
'',
'function pickFormat(input: string | null): { w: number; h: number; label: string } {',
'  const f = String(input ?? "").trim().toLowerCase();',
'  if (f === "1x1" || f === "square") return { w: 1080, h: 1080, label: "1:1" };',
'  return { w: 1080, h: 1350, label: "3:4" };',
'}',
'',
'function topMaterials(by: any): Array<{ k: string; v: number }> {',
'  const out: Array<{ k: string; v: number }> = [];',
'  if (by && typeof by === "object") {',
'    for (const k of Object.keys(by)) out.push({ k, v: Number(by[k] || 0) || 0 });',
'  }',
'  out.sort((a, b) => b.v - a.v);',
'  return out.slice(0, 6);',
'}',
'',
'export async function GET(req: Request) {',
'  const { searchParams } = new URL(req.url);',
'  const day = safeDay(searchParams.get("day") ?? searchParams.get("d") ?? searchParams.get("date"));',
'  const fmt = pickFormat(searchParams.get("format"));',
'  if (!day) return new Response("bad_day", { status: 400 });',
'',
'  const origin = new URL(req.url).origin;',
'  const apiUrl = origin + "/api/eco/day-close?day=" + encodeURIComponent(day);',
'',
'  let totalKg = 0;',
'  let mats: Array<{ k: string; v: number }> = [];',
'  let statusText = "OK";',
'',
'  try {',
'    const res = await fetch(apiUrl, { headers: { Accept: "application/json" }, cache: "no-store" });',
'    const data: any = await res.json().catch(() => ({}));',
'    if (!res.ok || !data?.ok) {',
'      statusText = "ERRO";',
'    } else {',
'      const summary = data?.item?.summary || {};',
'      const totals = summary?.totals || {};',
'      totalKg = Number(totals.totalKg || 0) || 0;',
'      mats = topMaterials(totals.byMaterialKg || {});',
'    }',
'  } catch {',
'    statusText = "ERRO";',
'  }',
'',
'  const bg = "linear-gradient(180deg, #0B0B0B 0%, #0F0F0F 35%, #0B0B0B 100%)";',
'  const yellow = "#F7D500";',
'  const red = "#E53935";',
'  const gray = "#BDBDBD";',
'',
'  return new ImageResponse(',
'    (',
'      <div style={{ width: fmt.w, height: fmt.h, display: "flex", flexDirection: "column", backgroundImage: bg, color: "white", padding: 72, fontFamily: "system-ui, -apple-system, Segoe UI, Roboto, Arial" }}>',
'        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>',
'          <div style={{ display: "flex", flexDirection: "column" }}>',
'            <div style={{ display: "flex", fontSize: 28, letterSpacing: 2, color: yellow, fontWeight: 900 }}>ECO</div>',
'            <div style={{ display: "flex", fontSize: 18, opacity: 0.85 }}>Fechamento do Dia</div>',
'          </div>',
'          <div style={{ display: "flex", gap: 10, alignItems: "center" }}>',
'            <div style={{ display: "flex", fontSize: 16, opacity: 0.8 }}>formato {fmt.label}</div>',
'            <div style={{ display: "flex", width: 14, height: 14, borderRadius: 999, background: statusText === "OK" ? yellow : red }} />',
'          </div>',
'        </div>',
'',
'        <div style={{ display: "flex", height: 28 }} />',
'',
'        <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>',
'          <div style={{ display: "flex", fontSize: 44, fontWeight: 900, letterSpacing: 1 }}>{day}</div>',
'          <div style={{ display: "flex", alignItems: "baseline", gap: 12 }}>',
'            <div style={{ display: "flex", fontSize: 86, fontWeight: 900, color: yellow }}>{fmtKg(totalKg)}</div>',
'            <div style={{ display: "flex", fontSize: 18, opacity: 0.85 }}>total registrado na triagem</div>',
'          </div>',
'        </div>',
'',
'        <div style={{ display: "flex", height: 26 }} />',
'',
'        <div style={{ display: "flex", flexDirection: "column", gap: 12, flex: 1 }}>',
'          <div style={{ display: "flex", fontSize: 20, opacity: 0.9, letterSpacing: 1 }}>POR MATERIAL</div>',
'          <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>',
'            {mats.length ? (',
'              mats.map((m) => (',
'                <div key={m.k} style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "12px 14px", borderRadius: 14, border: "1px solid rgba(255,255,255,0.12)", background: "rgba(255,255,255,0.04)" }}>',
'                  <div style={{ display: "flex", gap: 10, alignItems: "center" }}>',
'                    <div style={{ display: "flex", width: 10, height: 10, borderRadius: 999, background: yellow }} />',
'                    <div style={{ display: "flex", fontSize: 22, fontWeight: 800, textTransform: "uppercase", letterSpacing: 1 }}>{m.k}</div>',
'                  </div>',
'                  <div style={{ display: "flex", fontSize: 24, fontWeight: 900, color: gray }}>{fmtKg(m.v)}</div>',
'                </div>',
'              ))',
'            ) : (',
'              <div style={{ display: "flex", fontSize: 20, opacity: 0.8 }}>Sem dados de materiais (ou triagem vazia).</div>',
'            )}',
'          </div>',
'        </div>',
'',
'        <div style={{ display: "flex", height: 18 }} />',
'',
'        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-end" }}>',
'          <div style={{ display: "flex", flexDirection: "column", gap: 6, maxWidth: 760 }}>',
'            <div style={{ display: "flex", fontSize: 16, opacity: 0.9 }}>Recibo é lei. Cuidado é coletivo. Trabalho digno é o centro.</div>',
'            <div style={{ display: "flex", fontSize: 14, opacity: 0.7 }}>#ECO — Escutar • Cuidar • Organizar</div>',
'          </div>',
'          <div style={{ display: "flex", flexDirection: "column", alignItems: "flex-end", gap: 6 }}>',
'            <div style={{ display: "flex", fontSize: 14, opacity: 0.75 }}>Transparência v0</div>',
'            <div style={{ display: "flex", fontSize: 18, fontWeight: 900, color: yellow }}>VOLTA REDONDA</div>',
'          </div>',
'        </div>',
'      </div>',
'    ),',
'    { width: fmt.w, height: fmt.h }',
'  );',
'}',
''
)

EnsureDir (Split-Path -Parent $rtCard)
[System.IO.File]::WriteAllLines($rtCard, $L, $enc)
Write-Host "[PATCH] rewrote src/app/api/eco/day-close/card/route.tsx"

$rep = Join-Path $reportDir ("eco-step-56c-fix-card-og-display-v0_1-" + $ts + ".md")
$repLines = @(
"# eco-step-56c-fix-card-og-display-v0_1",
"",
"- Time: " + $ts,
"- Backup: " + $backupDir,
"",
"## Fix",
"- next/og: garante display:flex em todos os <div> para evitar erro 'Expected <div> to have explicit display...'",
"",
"## Verify",
"- Reinicie dev server e abra:",
"  - http://localhost:3000/api/eco/day-close/card?day=2025-12-27&format=3x4",
"  - http://localhost:3000/api/eco/day-close/card?day=2025-12-27&format=1x1",
""
)
[System.IO.File]::WriteAllLines($rep, $repLines, $enc)
Write-Host ("[REPORT] " + $rep)

Write-Host ""
Write-Host "[NEXT] Reinicie (Ctrl+C, npm run dev) e teste as URLs do card."