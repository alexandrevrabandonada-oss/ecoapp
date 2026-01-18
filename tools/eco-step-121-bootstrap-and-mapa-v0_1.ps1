param([string]$Root = (Get-Location).Path)
$ErrorActionPreference = "Stop"
$me = "eco-step-121-bootstrap-and-mapa-v0_1"
$stamp = (Get-Date -Format "yyyyMMdd-HHmmss")
Write-Host ("== " + $me + " == " + $stamp)
Write-Host ("[DIAG] Root: " + $Root)
# --- local minimal helpers (don't depend on bootstrap)
function EnsureDirLocal([string]$p) { if ([string]::IsNullOrWhiteSpace($p)) { return }; if (!(Test-Path -LiteralPath $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function WriteUtf8NoBomLocal([string]$p, [string]$content) { $enc = New-Object System.Text.UTF8Encoding($false); EnsureDirLocal (Split-Path -Parent $p); [IO.File]::WriteAllText($p, $content, $enc) }
function BackupFileLocal([string]$p, [string]$dir) { if (!(Test-Path -LiteralPath $p)) { return }; EnsureDirLocal $dir; $leaf = [IO.Path]::GetFileName($p); $dst = Join-Path $dir ($leaf + ".bak"); Copy-Item -LiteralPath $p -Destination $dst -Force }
$backupDir = Join-Path $Root ("tools\_patch_backup\" + $stamp + "-" + $me)
EnsureDirLocal $backupDir
# --- (1) Ensure tools/_bootstrap.ps1 exists and exports EnsureDir/WriteUtf8NoBom/BackupFile/NewReport
$bootPath = Join-Path $Root "tools\_bootstrap.ps1"
if (Test-Path -LiteralPath $bootPath) { BackupFileLocal $bootPath $backupDir }
$bootLines = @(
  "# tools/_bootstrap.ps1 (auto-fixed)",
  "Set-StrictMode -Version Latest",
  "$ErrorActionPreference = 'Stop'",
  "",
  "function EnsureDir([string]`$p) {",
  "  if ([string]::IsNullOrWhiteSpace(`$p)) { return }",
  "  if (!(Test-Path -LiteralPath `$p)) { New-Item -ItemType Directory -Force -Path `$p | Out-Null }",
  "}",
  "",
  "function WriteUtf8NoBom([string]`$path, [string]`$content) {",
  "  `$enc = New-Object System.Text.UTF8Encoding(`$false)",
  "  EnsureDir (Split-Path -Parent `$path)",
  "  [IO.File]::WriteAllText(`$path, `$content, `$enc)",
  "}",
  "",
  "function BackupFile([string]`$path, [string]`$backupDir) {",
  "  if (!(Test-Path -LiteralPath `$path)) { return }",
  "  EnsureDir `$backupDir",
  "  `$name = [IO.Path]::GetFileName(`$path)",
  "  `$dst = Join-Path `$backupDir (`$name + '.bak')",
  "  Copy-Item -LiteralPath `$path -Destination `$dst -Force",
  "}",
  "",
  "function NewReport([string]`$Root, [string]`$me, [string]`$stamp, [string[]]`$lines) {",
  "  `$reports = Join-Path `$Root 'reports'",
  "  EnsureDir `$reports",
  "  `$path = Join-Path `$reports (`$me + '-' + `$stamp + '.md')",
  "  WriteUtf8NoBom `$path (`$lines -join ""`n"")",
  "  return `$path",
  "}"
)
WriteUtf8NoBomLocal $bootPath ($bootLines -join "`n")
Write-Host ("[PATCH] ensured -> " + $bootPath)
. $bootPath
Write-Host ("[DIAG] bootstrap ok: " + ((Get-Command EnsureDir -ErrorAction SilentlyContinue) -ne $null) + ", " + ((Get-Command WriteUtf8NoBom -ErrorAction SilentlyContinue) -ne $null))
# --- (2) Add /eco/mapa (Mapa v0)
$mapDir = Join-Path $Root "src\app\eco\mapa"
EnsureDir $mapDir
$mapClientPath = Join-Path $mapDir "EcoMapaClient.tsx"
BackupFile $mapClientPath $backupDir
$mapClient = @(
  "'use client';",
  "",
  "import { useEffect, useMemo, useState } from 'react';",
  "",
  "type Point = {",
  "  id: string;",
  "  kind?: string | null;",
  "  status?: string | null;",
  "  note?: string | null;",
  "  lat?: number | null;",
  "  lng?: number | null;",
  "  createdAt?: string | null;",
  "  counts?: { confirm?: number; support?: number; replicar?: number; call?: number } | null;",
  "};",
  "",
  "function num(v: any): number {",
  "  if (typeof v === 'number') return v;",
  "  const n = parseInt(String(v || '0'), 10);",
  "  return Number.isFinite(n) ? n : 0;",
  "}",
  "",
  "function score(p: Point): number {",
  "  const c = p.counts || {};",
  "  return num(c.confirm) + num(c.support) + num(c.replicar) + num((c as any).call);",
  "}",
  "",
  "export default function EcoMapaClient() {",
  "  const [items, setItems] = useState<Point[]>([]);",
  "  const [loading, setLoading] = useState(true);",
  "  const [err, setErr] = useState<string | null>(null);",
  "  const [q, setQ] = useState('');",
  "  const [kind, setKind] = useState('ALL');",
  "",
  "  async function load() {",
  "    setLoading(true);",
  "    setErr(null);",
  "    try {",
  "      const res = await fetch('/api/eco/points?limit=200', { cache: 'no-store' });",
  "      const j = await res.json();",
  "      const arr = Array.isArray(j?.items) ? j.items : [];",
  "      setItems(arr);",
  "    } catch (e: any) {",
  "      setErr(e?.message ? String(e.message) : String(e));",
  "    } finally {",
  "      setLoading(false);",
  "    }",
  "  }",
  "",
  "  useEffect(() => { void load(); }, []);",
  "",
  "  const kinds = useMemo(() => {",
  "    const s = new Set<string>();",
  "    for (const it of items) {",
  "      const k = String(it?.kind || '').trim();",
  "      if (k) s.add(k);",
  "    }",
  "    return ['ALL', ...Array.from(s).sort()];",
  "  }, [items]);",
  "",
  "  const filtered = useMemo(() => {",
  "    const qq = q.trim().toLowerCase();",
  "    return items",
  "      .filter((p) => {",
  "        if (kind !== 'ALL' && String(p?.kind || '') !== kind) return false;",
  "        if (!qq) return true;",
  "        const hay = (String(p?.kind || '') + ' ' + String(p?.note || '') + ' ' + String(p?.status || '')).toLowerCase();",
  "        return hay.includes(qq);",
  "      })",
  "      .slice()",
  "      .sort((a, b) => {",
  "        const sc = score(b) - score(a);",
  "        if (sc) return sc;",
  "        const ta = Date.parse(String(a?.createdAt || ''));",
  "        const tb = Date.parse(String(b?.createdAt || ''));",
  "        return (Number.isFinite(tb) ? tb : 0) - (Number.isFinite(ta) ? ta : 0);",
  "      });",
  "  }, [items, q, kind]);",
  "",
  "  return (",
  "    <div style={{ maxWidth: 980, margin: '0 auto' }}>",
  "      <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center', margin: '12px 0' }}>",
  "        <input",
  "          value={q}",
  "          onChange={(e) => setQ(e.target.value)}",
  "          placeholder='buscar por tipo/nota/status…'",
  "          style={{ padding: 10, borderRadius: 12, border: '2px solid #111', minWidth: 240 }}",
  "        />",
  "        <select value={kind} onChange={(e) => setKind(e.target.value)} style={{ padding: 10, borderRadius: 12, border: '2px solid #111' }}>",
  "          {kinds.map((k) => (",
  "            <option key={k} value={k}>{k}</option>",
  "          ))}",
  "        </select>",
  "        <button onClick={() => void load()} style={{ padding: '10px 12px', borderRadius: 12, border: '2px solid #111', fontWeight: 900, background: '#fff' }}>",
  "          ↻ Atualizar",
  "        </button>",
  "        <a href='/eco/mural' style={{ padding: '10px 12px', borderRadius: 12, border: '2px solid #111', fontWeight: 900, background: '#fff', textDecoration: 'none', color: '#111' }}>",
  "          ← Voltar pro Mural",
  "        </a>",
  "      </div>",
  "",
  "      {loading ? <p>Carregando…</p> : null}",
  "      {err ? <p style={{ color: '#b00', fontWeight: 900 }}>Erro: {err}</p> : null}",
  "",
  "      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))', gap: 12 }}>",
  "        {filtered.map((p) => {",
  "          const lat = typeof p.lat === 'number' ? p.lat : null;",
  "          const lng = typeof p.lng === 'number' ? p.lng : null;",
  "          const g = (lat !== null && lng !== null) ? ('https://www.google.com/maps?q=' + lat + ',' + lng) : null;",
  "          const c = p.counts || {};",
  "          return (",
  "            <div key={p.id} style={{ background: '#fff', border: '2px solid #111', borderRadius: 16, padding: 12 }}>",
  "              <div style={{ display: 'flex', justifyContent: 'space-between', gap: 8 }}>",
  "                <div style={{ fontWeight: 900 }}>{String(p.kind || 'PONTO')}</div>",
  "                <div style={{ fontSize: 12, fontWeight: 900, opacity: 0.8 }}>{String(p.status || '')}</div>",
  "              </div>",
  "              <div style={{ marginTop: 6, fontSize: 13, opacity: 0.9 }}>{p.note ? String(p.note) : '(sem nota)'}</div>",
  "              <div style={{ marginTop: 10, display: 'flex', gap: 8, flexWrap: 'wrap' }}>",
  "                <span style={{ fontSize: 12, border: '1px solid #111', borderRadius: 999, padding: '4px 8px', fontWeight: 900 }}>✅ {num(c.confirm)}</span>",
  "                <span style={{ fontSize: 12, border: '1px solid #111', borderRadius: 999, padding: '4px 8px', fontWeight: 900 }}>🤝 {num(c.support)}</span>",
  "                <span style={{ fontSize: 12, border: '1px solid #111', borderRadius: 999, padding: '4px 8px', fontWeight: 900 }}>♻️ {num(c.replicar)}</span>",
  "              </div>",
  "              <div style={{ marginTop: 10, display: 'flex', gap: 8, flexWrap: 'wrap' }}>",
  "                {g ? (",
  "                  <a href={g} target='_blank' rel='noreferrer' style={{ padding: '9px 10px', borderRadius: 12, border: '2px solid #111', fontWeight: 900, background: '#fff', textDecoration: 'none', color: '#111' }}>",
  "                    🗺️ Abrir no Maps",
  "                  </a>",
  "                ) : (",
  "                  <span style={{ fontSize: 12, opacity: 0.8 }}>sem coordenadas</span>",
  "                )}",
  "                <span style={{ fontSize: 12, opacity: 0.8 }}>id: {p.id}</span>",
  "              </div>",
  "            </div>",
  "          );",
  "        })}",
  "      </div>",
  "    </div>",
  "  );",
  "}"
)
WriteUtf8NoBom $mapClientPath ($mapClient -join "`n")
Write-Host ("[PATCH] wrote -> " + $mapClientPath)
$mapPagePath = Join-Path $mapDir "page.tsx"
BackupFile $mapPagePath $backupDir
$mapPage = @(
  "import EcoMapaClient from ""./EcoMapaClient"";",
  "",
  "export const dynamic = ""force-dynamic"";",
  "",
  "export default function Page() {",
  "  return (",
  "    <main style={{ padding: 16, background: ""#f6f6f6"", minHeight: ""100vh"", color: ""#111"" }}>",
  "      <h1 style={{ margin: ""0 0 6px 0"" }}>Mapa ECO (v0)</h1>",
  "      <p style={{ margin: ""0 0 12px 0"", opacity: 0.85 }}>",
  "        Lista de pontos com link direto pro Google Maps. (Sem mapa pesado ainda.)",
  "      </p>",
  "      <EcoMapaClient />",
  "    </main>",
  "  );",
  "}"
)
WriteUtf8NoBom $mapPagePath ($mapPage -join "`n")
Write-Host ("[PATCH] wrote -> " + $mapPagePath)
# --- try to add a simple link inside /eco/mural (best-effort)
$muralPage = Join-Path $Root "src\app\eco\mural\page.tsx"
if (Test-Path -LiteralPath $muralPage) {
  $raw = Get-Content -LiteralPath $muralPage -Raw
  if ($raw -and ($raw -notmatch "/eco/mapa")) {
    BackupFile $muralPage $backupDir
    $needle = "<MuralNavPillsClient />"
    if ($raw.Contains($needle)) {
      $ins = $needle + "`n" + "      <div style={{ margin: ""10px 0 14px 0"", display: ""flex"", gap: 8, flexWrap: ""wrap"" }}>" + "`n" +
             "        <a href=""/eco/mapa"" style={{ padding: ""9px 10px"", borderRadius: 12, border: ""2px solid #111"", textDecoration: ""none"", color: ""#111"", fontWeight: 900, background: ""#fff"" }}>🗺️ Mapa</a>" + "`n" +
             "      </div>"
      $raw2 = $raw.Replace($needle, $ins)
      if ($raw2 -ne $raw) {
        WriteUtf8NoBom $muralPage $raw2
        Write-Host ("[PATCH] added link -> " + $muralPage)
      } else {
        Write-Host "[WARN] could not patch mural link (no replace)"
      }
    } else {
      Write-Host "[WARN] MuralNavPillsClient not found, skipped link patch"
    }
  } else {
    Write-Host "[DIAG] mural already has /eco/mapa link (or empty file)"
  }
} else {
  Write-Host "[WARN] mural page not found, skipped link patch"
}
# --- REPORT
$r = @()
$r += "# $me"
$r += ""
$r += "- Time: $stamp"
$r += "- Backup: $backupDir"
$r += ""
$r += "## What changed"
$r += "- ensured tools/_bootstrap.ps1 exports EnsureDir/WriteUtf8NoBom/BackupFile/NewReport"
$r += "- added /eco/mapa (Mapa v0) with Google Maps links"
$r += "- best-effort: added 🗺️ link in /eco/mural"
$r += ""
$r += "## Verify"
$r += "1) Ctrl+C -> npm run dev"
$r += "2) abrir /eco/mapa (deve listar e abrir no Google Maps)"
$r += "3) abrir /eco/mural e achar o link 🗺️ Mapa (se não aparecer, tudo bem — use /eco/mapa direto)"
$r += ""
$reportPath = NewReport $Root $me $stamp $r
Write-Host ("[REPORT] " + $reportPath)
Write-Host ""
Write-Host "[VERIFY] rode:"
Write-Host "  Ctrl+C -> npm run dev"
Write-Host "  abrir /eco/mapa"