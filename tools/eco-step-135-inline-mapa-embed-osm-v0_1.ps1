#requires -Version 7.0
$ErrorActionPreference = "Stop"

$me = "eco-step-135-inline-mapa-embed-osm-v0_1"
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$Root = (Resolve-Path ".").Path

$bootstrap = Join-Path $Root "tools\_bootstrap.ps1"
if (Test-Path $bootstrap) { . $bootstrap }

if (-not (Get-Command EnsureDir -ErrorAction SilentlyContinue)) {
  function EnsureDir($p) { if ([string]::IsNullOrWhiteSpace($p)) { return }; if (-not (Test-Path $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null } }
}
if (-not (Get-Command WriteUtf8NoBom -ErrorAction SilentlyContinue)) {
  function WriteUtf8NoBom($path, $content) {
    $dir = Split-Path -Parent $path
    if (-not [string]::IsNullOrWhiteSpace($dir)) { EnsureDir $dir }
    [IO.File]::WriteAllText($path, $content, [System.Text.UTF8Encoding]::new($false))
  }
}
if (-not (Get-Command BackupFile -ErrorAction SilentlyContinue)) {
  function BackupFile($path, $backupDir) {
    if (-not (Test-Path -LiteralPath $path)) { return }
    EnsureDir $backupDir
    $leaf = Split-Path -Leaf $path
    Copy-Item -LiteralPath $path -Destination (Join-Path $backupDir ($leaf + ".bak")) -Force
  }
}

$backupDir = Join-Path $Root ("tools\_patch_backup\" + $me + "-" + $stamp)
EnsureDir $backupDir

$report = @()
$report += "# $me  - stamp: $stamp"
$report += ""
$report += "## DIAG"
$report += ("Root: " + $Root)
$report += ("Bootstrap: " + (Test-Path $bootstrap))
$report += ""

# ===== Patch: MuralInlineMapa.tsx =====
$inlinePath = Join-Path $Root "src\app\eco\mural\_components\MuralInlineMapa.tsx"
BackupFile $inlinePath $backupDir

$tsx = @(
'"use client";',
'',
'import { useEffect, useMemo, useState } from "react";',
'import { usePathname, useRouter, useSearchParams } from "next/navigation";',
'',
'type Pt = {',
'  id: string;',
'  lat?: number | null;',
'  lng?: number | null;',
'  latitude?: number | null;',
'  longitude?: number | null;',
'  kind?: string | null;',
'  bairro?: string | null;',
'};',
'',
'type ApiResp = { items?: Pt[] };',
'',
'function num(v: any): number {',
'  const n = Number(v);',
'  return Number.isFinite(n) ? n : 0;',
'}',
'',
'function latOf(p: Pt): number {',
'  return num((p as any).lat ?? (p as any).latitude);',
'}',
'function lngOf(p: Pt): number {',
'  return num((p as any).lng ?? (p as any).longitude);',
'}',
'',
'function buildOsmSrc(lat: number, lng: number): string {',
'  const dLat = 0.01;',
'  const dLng = 0.01;',
'  const left = (lng - dLng).toFixed(6);',
'  const bottom = (lat - dLat).toFixed(6);',
'  const right = (lng + dLng).toFixed(6);',
'  const top = (lat + dLat).toFixed(6);',
'  const bbox = [left, bottom, right, top].join("%2C");',
'  const marker = encodeURIComponent(lat.toFixed(6) + "," + lng.toFixed(6));',
'  return "https://www.openstreetmap.org/export/embed.html?bbox=" + bbox + "&layer=mapnik&marker=" + marker;',
'}',
'',
'function buildOsmLink(lat: number, lng: number): string {',
'  const a = lat.toFixed(6);',
'  const o = lng.toFixed(6);',
'  return "https://www.openstreetmap.org/?mlat=" + a + "&mlon=" + o + "#map=17/" + a + "/" + o;',
'}',
'',
'export default function MuralInlineMapa() {',
'  const sp = useSearchParams();',
'  const router = useRouter();',
'  const pathname = usePathname();',
'',
'  const focus = sp.get("focus") || "";',
'  const wantOpen = sp.get("map") === "1";',
'',
'  const [open, setOpen] = useState<boolean>(wantOpen);',
'  const [items, setItems] = useState<Pt[]>([]);',
'  const [loading, setLoading] = useState<boolean>(false);',
'',
'  useEffect(() => {',
'    setOpen(wantOpen);',
'  }, [wantOpen]);',
'',
'  useEffect(() => {',
'    if (!open) return;',
'    let alive = true;',
'    setLoading(true);',
'    fetch("/api/eco/points?limit=200", { cache: "no-store" })',
'      .then((r) => r.json())',
'      .then((j: ApiResp) => {',
'        if (!alive) return;',
'        setItems(Array.isArray(j?.items) ? j.items : []);',
'      })',
'      .catch(() => {',
'        if (!alive) return;',
'        setItems([]);',
'      })',
'      .finally(() => {',
'        if (!alive) return;',
'        setLoading(false);',
'      });',
'    return () => {',
'      alive = false;',
'    };',
'  }, [open]);',
'',
'  const focused = useMemo(() => {',
'    const arr = items || [];',
'    const byId = focus ? arr.find((p) => String((p as any).id) === String(focus)) : undefined;',
'    if (byId && latOf(byId) && lngOf(byId)) return byId;',
'    const anyPt = arr.find((p) => latOf(p) && lngOf(p));',
'    return anyPt || null;',
'  }, [items, focus]);',
'',
'  const center = useMemo(() => {',
'    if (focused) return { lat: latOf(focused), lng: lngOf(focused) };',
'    return { lat: -22.520, lng: -44.100 };',
'  }, [focused]);',
'',
'  const src = useMemo(() => buildOsmSrc(center.lat, center.lng), [center.lat, center.lng]);',
'  const osmLink = useMemo(() => buildOsmLink(center.lat, center.lng), [center.lat, center.lng]);',
'',
'  function toggle() {',
'    const next = !open;',
'    setOpen(next);',
'    const usp = new URLSearchParams(sp.toString());',
'    if (next) usp.set("map", "1"); else usp.delete("map");',
'    router.replace(pathname + (usp.toString() ? ("?" + usp.toString()) : ""), { scroll: false });',
'  }',
'',
'  return (',
'    <section style={{ marginTop: 12, marginBottom: 12 }}>',
'      <div style={{ display: "flex", gap: 8, alignItems: "center", flexWrap: "wrap" }}>',
'        <button',
'          onClick={toggle}',
'          style={{',
'            padding: "10px 12px",',
'            borderRadius: 12,',
'            border: "1px solid #111",',
'            background: open ? "#111" : "#fff",',
'            color: open ? "#fff" : "#111",',
'            fontWeight: 900,',
'          }}',
'        >',
'          {open ? "Fechar mapa" : "🗺️ Ver mapa aqui"}',
'        </button>',
'        <a href={osmLink} target="_blank" rel="noreferrer" style={{ fontWeight: 800, textDecoration: "underline" }}>',
'          Abrir no OpenStreetMap',
'        </a>',
'        {focused ? (',
'          <span style={{ opacity: 0.85, fontSize: 12 }}>',
'            foco: {(focused as any).kind || "ponto"} {(focused as any).bairro ? ("• " + String((focused as any).bairro)) : ""}',
'          </span>',
'        ) : null}',
'      </div>',
'',
'      {open ? (',
'        <div style={{ marginTop: 10, borderRadius: 16, overflow: "hidden", border: "1px solid #111" }}>',
'          <iframe',
'            title="Mapa do Cuidado"',
'            src={src}',
'            style={{ width: "100%", height: 520, border: 0, display: "block" }}',
'            loading="lazy"',
'          />',
'          <div style={{ padding: 10, background: "#fff", borderTop: "1px solid #111", fontSize: 12 }}>',
'            {loading ? "Carregando pontos..." : (items.length ? ("Pontos carregados: " + items.length) : "Sem pontos com coordenadas ainda.")}{" "}',
'            Dica: abrir já focando: <code>?map=1&amp;focus=&lt;id&gt;</code>.',
'          </div>',
'        </div>',
'      ) : null}',
'    </section>',
'  );',
'}',
''
)

EnsureDir (Split-Path -Parent $inlinePath)
WriteUtf8NoBom $inlinePath ($tsx -join "`n")
$report += "## PATCH"
$report += ("- updated: " + $inlinePath)

# ===== Patch: /eco/mural/page.tsx (import + render) =====
$pagePath = Join-Path $Root "src\app\eco\mural\page.tsx"
if (Test-Path -LiteralPath $pagePath) {
  BackupFile $pagePath $backupDir
  $lines = Get-Content -LiteralPath $pagePath

  if (-not ($lines -join "`n").Contains("MuralInlineMapa")) {
    # insert import after last import line
    $importLine = 'import MuralInlineMapa from "./_components/MuralInlineMapa";'
    $lastImport = -1
    for ($i=0; $i -lt $lines.Count; $i++) {
      if ($lines[$i].TrimStart().StartsWith("import ")) { $lastImport = $i }
    }
    if ($lastImport -ge 0) {
      $new = New-Object System.Collections.Generic.List[string]
      for ($i=0; $i -lt $lines.Count; $i++) {
        $new.Add($lines[$i])
        if ($i -eq $lastImport) { $new.Add($importLine) }
      }
      $lines = $new.ToArray()
    }

    # render after MuralNewPointClient line
    $new2 = New-Object System.Collections.Generic.List[string]
    $inserted = $false
    for ($i=0; $i -lt $lines.Count; $i++) {
      $new2.Add($lines[$i])
      if (-not $inserted -and $lines[$i].Contains("MuralNewPointClient") -and $lines[$i].Contains("/>")) {
        $new2.Add("      <MuralInlineMapa />")
        $inserted = $true
      }
    }
    $lines = $new2.ToArray()

    WriteUtf8NoBom $pagePath ($lines -join "`n")
    $report += ("- updated: " + $pagePath + " (import + render)")
  } else {
    $report += ("- skip: " + $pagePath + " (já tem MuralInlineMapa)")
  }
} else {
  $report += ("- WARN: não achei " + $pagePath)
}

$report += ""
$report += "## VERIFY"
$report += "- Ctrl+C -> npm run dev"
$report += "- abrir /eco/mural"
$report += "- clicar **🗺️ Ver mapa aqui** (e conferir iframe)"
$report += "- teste foco: /eco/mural?map=1&focus=<id>"

$reportPath = Join-Path $Root ("reports\" + $me + "-" + $stamp + ".md")
WriteUtf8NoBom $reportPath ($report -join "`n")
Write-Host ("[REPORT] " + $reportPath)
Write-Host ""
Write-Host "[VERIFY] rode:"
Write-Host "  Ctrl+C -> npm run dev"
Write-Host "  abrir /eco/mural"
Write-Host "  clicar 🗺️ Ver mapa aqui"
Write-Host "  (opcional) abrir /eco/mural?map=1&focus=<id>"