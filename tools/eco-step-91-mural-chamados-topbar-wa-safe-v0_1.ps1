param(
  [string]$Root = (Get-Location).Path
)

$ts = Get-Date -Format "yyyyMMdd-HHmmss"

$boot = Join-Path $Root "tools/_bootstrap.ps1"
if (Test-Path -LiteralPath $boot) { . $boot }

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

Write-Host ('== eco-step-91-mural-chamados-topbar-wa-safe-v0_1 == ' + $ts)
Write-Host ('[DIAG] Root: ' + $Root)

$backupDir = Join-Path $Root ('tools/_patch_backup/' + $ts + '-eco-step-91-mural-chamados-topbar-wa-safe-v0_1')
$reportDir = Join-Path $Root 'reports'
EnsureDir $backupDir
EnsureDir $reportDir

# localizar arquivos
$mc = Get-ChildItem -LiteralPath (Join-Path $Root "src") -Recurse -File -Filter "MuralClient.tsx" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $mc) { throw "[STOP] Nao achei MuralClient.tsx em src/." }
$muralClient = $mc.FullName

$pa = Get-ChildItem -LiteralPath (Join-Path $Root "src") -Recurse -File -Filter "PointActionsInline.tsx" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $pa) { throw "[STOP] Nao achei PointActionsInline.tsx em src/." }
$pointActions = $pa.FullName

$muralPage = Join-Path $Root "src/app/eco/mural/page.tsx"
if (-not (Test-Path -LiteralPath $muralPage)) {
  $alt = Get-ChildItem -LiteralPath (Join-Path $Root "src/app/eco") -Recurse -File -Filter "page.tsx" -ErrorAction SilentlyContinue | Where-Object { $_.FullName -match "\\eco\\mural\\page\.tsx$" } | Select-Object -First 1
  if ($alt) { $muralPage = $alt.FullName }
}
if (-not (Test-Path -LiteralPath $muralPage)) { throw "[STOP] Nao achei src/app/eco/mural/page.tsx" }

$chamadosPage = Join-Path $Root "src/app/eco/mural/chamados/page.tsx"

Write-Host ('[DIAG] MuralClient: ' + $muralClient)
Write-Host ('[DIAG] PointActionsInline: ' + $pointActions)
Write-Host ('[DIAG] Mural page: ' + $muralPage)
Write-Host ('[DIAG] Will write: ' + $chamadosPage)

BackupFile $Root $muralClient $backupDir
BackupFile $Root $pointActions $backupDir
BackupFile $Root $muralPage $backupDir

# 1) rewrite PointActionsInline (WA safe, sem window no render)
$A = New-Object System.Collections.Generic.List[string]
$A.Add('"use client";')
$A.Add('')
$A.Add('import { useState } from "react";')
$A.Add('')
$A.Add('type AnyObj = any;')
$A.Add('')
$A.Add('function num(v: any) {')
$A.Add('  const n = Number(v);')
$A.Add('  return Number.isFinite(n) ? n : 0;')
$A.Add('}')
$A.Add('')
$A.Add('function pickCount(p: AnyObj, keys: string[]) {')
$A.Add('  for (const k of keys) {')
$A.Add('    const v = p?.[k] ?? p?.counts?.[k] ?? p?.actions?.[k] ?? p?.stats?.[k];')
$A.Add('    const n = num(v);')
$A.Add('    if (n) return n;')
$A.Add('  }')
$A.Add('  return 0;')
$A.Add('}')
$A.Add('')
$A.Add('function enc(s: string) { return encodeURIComponent(s); }')
$A.Add('')
$A.Add('function getOriginSafe() {')
$A.Add('  try {')
$A.Add('    if (typeof window !== "undefined" && window.location && window.location.origin) return window.location.origin;')
$A.Add('  } catch {}')
$A.Add('  return "";')
$A.Add('}')
$A.Add('')
$A.Add('function openWa(text: string) {')
$A.Add('  const url = "https://wa.me/?text=" + enc(text);')
$A.Add('  try { window.open(url, "_blank", "noopener,noreferrer"); } catch { try { window.location.href = url; } catch {} }')
$A.Add('}')
$A.Add('')
$A.Add('async function postJson(url: string, body: any) {')
$A.Add('  const res = await fetch(url, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(body) });')
$A.Add('  const j = await res.json().catch(() => ({}));')
$A.Add('  return { ok: res.ok, status: res.status, json: j };')
$A.Add('}')
$A.Add('')
$A.Add('async function confirmPoint(id: string) {')
$A.Add('  const tries = [')
$A.Add('    { url: "/api/eco/points/confirm", body: { id } },')
$A.Add('    { url: "/api/eco/points/confirm", body: { pointId: id } },')
$A.Add('    { url: "/api/eco/points/confirm?id=" + enc(id), body: null as any },')
$A.Add('  ];')
$A.Add('  for (const t of tries) {')
$A.Add('    try {')
$A.Add('      if (t.body === null) {')
$A.Add('        const r = await fetch(t.url, { method: "POST" });')
$A.Add('        const j = await r.json().catch(() => ({}));')
$A.Add('        if (r.ok) return { ok: true, json: j };')
$A.Add('      } else {')
$A.Add('        const r = await postJson(t.url, t.body);')
$A.Add('        if (r.ok) return { ok: true, json: r.json };')
$A.Add('      }')
$A.Add('    } catch {}')
$A.Add('  }')
$A.Add('  return { ok: false, json: {} };')
$A.Add('}')
$A.Add('')
$A.Add('export default function PointActionsInline(props: { point: AnyObj }) {')
$A.Add('  const p = props.point || {};')
$A.Add('  const id = String(p?.id || p?.pointId || p?.pid || "");')
$A.Add('  const title = String(p?.title || p?.name || "Ponto");')
$A.Add('  const bairro = String(p?.bairro || p?.neighborhood || p?.area || "");')
$A.Add('  const confirm0 = pickCount(p, ["confirm", "confirmCount", "confirmar", "seen", "ok", "OK"]);')
$A.Add('  const call0 = pickCount(p, ["call", "callCount", "chamado", "chamados", "CALL", "CALLED"]);')
$A.Add('')
$A.Add('  const [confirmCount, setConfirmCount] = useState<number>(confirm0);')
$A.Add('  const [busy, setBusy] = useState<string>("");')
$A.Add('')
$A.Add('  const wrap: any = { display: "flex", gap: 8, flexWrap: "wrap", marginTop: 10 };')
$A.Add('  const btn: any = { padding: "7px 10px", borderRadius: 12, border: "1px solid rgba(0,0,0,0.35)", background: "rgba(255,255,255,0.75)", color: "#111", fontWeight: 950, fontSize: 12, cursor: "pointer" };')
$A.Add('  const btnStrong: any = { padding: "7px 10px", borderRadius: 12, border: "1px solid #111", background: "#fff", color: "#111", fontWeight: 950, fontSize: 12, cursor: "pointer" };')
$A.Add('')
$A.Add('  function linkForMsg() {')
$A.Add('    const rel = "/eco/pontos/" + id;')
$A.Add('    const origin = getOriginSafe();')
$A.Add('    return origin ? (origin + rel) : rel;')
$A.Add('  }')
$A.Add('')
$A.Add('  function head() {')
$A.Add('    return "ECO — " + title + (bairro ? (" (" + bairro + ")") : "");')
$A.Add('  }')
$A.Add('')
$A.Add('  return (')
$A.Add('    <div style={wrap}>')
$A.Add('      <button')
$A.Add('        type="button"')
$A.Add('        style={btnStrong}')
$A.Add('        disabled={!id || busy === "confirm"}')
$A.Add('        onClick={async () => {')
$A.Add('          if (!id) return;')
$A.Add('          setBusy("confirm");')
$A.Add('          const r = await confirmPoint(id);')
$A.Add('          if (r.ok) {')
$A.Add('            const next = Number(r.json?.counts?.confirm ?? r.json?.confirm ?? r.json?.confirmCount ?? (confirmCount + 1));')
$A.Add('            if (Number.isFinite(next)) setConfirmCount(next); else setConfirmCount(confirmCount + 1);')
$A.Add('          } else {')
$A.Add('            setConfirmCount(confirmCount + 1);')
$A.Add('          }')
$A.Add('          setBusy("");')
$A.Add('        }}')
$A.Add('      >')
$A.Add('        ✅ Confirmar {confirmCount ? ("(" + String(confirmCount) + ")") : ""}')
$A.Add('      </button>')
$A.Add('')
$A.Add('      <button type="button" style={btn} onClick={() => openWa(head() + "\\nPosso apoiar com item/ajuda nesse ponto?\\n" + linkForMsg())}>')
$A.Add('        🤝 Apoiar')
$A.Add('      </button>')
$A.Add('')
$A.Add('      <button type="button" style={btn} onClick={() => openWa("ECO — Repasse (boa pratica)\\n" + head() + "\\n" + linkForMsg())}>')
$A.Add('        ♻️ Replicar')
$A.Add('      </button>')
$A.Add('')
$A.Add('      <button type="button" style={btn} onClick={() => openWa("ECO — Chamado\\n" + head() + "\\nBora organizar?\\n" + linkForMsg())}>')
$A.Add('        📣 Chamado {call0 ? ("(" + String(call0) + ")") : ""}')
$A.Add('      </button>')
$A.Add('')
$A.Add('      <button type="button" style={btn} onClick={() => openWa("ECO — Gratidao\\n" + head() + "\\nObrigado a quem colou e ajudou. Cuidado e coletivo.\\n" + linkForMsg())}>')
$A.Add('        🌱 Gratidao')
$A.Add('      </button>')
$A.Add('    </div>')
$A.Add('  );')
$A.Add('}')
$A.Add('')

WriteUtf8NoBom $pointActions ($A -join "`n")
Write-Host ('[PATCH] rewrote ' + $pointActions)

# 2) rewrite MuralClient (mode="chamados" filtra OPEN e ordena por call)
$M = New-Object System.Collections.Generic.List[string]
$M.Add('"use client";')
$M.Add('')
$M.Add('import { useEffect, useMemo, useState } from "react";')
$M.Add('import Link from "next/link";')
$M.Add('import PointActionsInline from "@/app/eco/_components/PointActionsInline";')
$M.Add('')
$M.Add('type AnyRow = any;')
$M.Add('')
$M.Add('function num(v: any) {')
$M.Add('  const n = Number(v);')
$M.Add('  return Number.isFinite(n) ? n : 0;')
$M.Add('}')
$M.Add('')
$M.Add('async function tryJson(url: string) {')
$M.Add('  const res = await fetch(url, { cache: "no-store" });')
$M.Add('  if (!res.ok) throw new Error("fetch_failed:" + res.status);')
$M.Add('  return await res.json();')
$M.Add('}')
$M.Add('')
$M.Add('async function loadList(tries: string[]) {')
$M.Add('  for (const t of tries) {')
$M.Add('    try {')
$M.Add('      const j = await tryJson(t);')
$M.Add('      const items = j?.items ?? j?.data ?? j?.list ?? j?.rows ?? j?.points ?? j?.criticalPoints;')
$M.Add('      if (Array.isArray(items)) return { ok: true as const, items, src: t };')
$M.Add('    } catch {}')
$M.Add('  }')
$M.Add('  return { ok: false as const, items: [] as AnyRow[], src: "none" };')
$M.Add('}')
$M.Add('')
$M.Add('function isStrong(p: AnyRow) {')
$M.Add('  const st = String(p?.status || p?.state || "").toUpperCase();')
$M.Add('  if (st === "RESOLVED") return true;')
$M.Add('  const keys = ["proofUrl","proofURL","proof","afterUrl","afterURL","photoAfterUrl","mutiraoId","mutiraoID","receiptUrl","reciboUrl"];')
$M.Add('  for (const k of keys) {')
$M.Add('    const v = p?.[k] ?? p?.meta?.[k] ?? p?.proof?.[k];')
$M.Add('    if (v) return true;')
$M.Add('  }')
$M.Add('  return false;')
$M.Add('}')
$M.Add('')
$M.Add('function strengthBadge(p: AnyRow) {')
$M.Add('  if (isStrong(p)) return { txt: "🧾 RECIBO ECO", border: "1px solid #111", bg: "#fff" };')
$M.Add('  return { txt: "📝 REGISTRO", border: "1px solid rgba(0,0,0,0.25)", bg: "rgba(255,255,255,0.65)" };')
$M.Add('}')
$M.Add('')
$M.Add('export default function MuralClient(props: { base?: string; mode?: "all" | "chamados" }) {')
$M.Add('  const base = String(props?.base || "pontos");')
$M.Add('  const mode = (props?.mode || "all") as any;')
$M.Add('  const [state, setState] = useState<{ loading: boolean; err: string; src: string; items: AnyRow[] }>({ loading: true, err: "", src: "", items: [] });')
$M.Add('')
$M.Add('  useEffect(() => {')
$M.Add('    let alive = true;')
$M.Add('    ;(async () => {')
$M.Add('      const tries = base.includes("ponto") ? [')
$M.Add('        "/api/eco/points/list?limit=160",')
$M.Add('        "/api/eco/points?limit=160",')
$M.Add('        "/api/eco/critical/list?limit=160",')
$M.Add('        "/api/eco/critical?limit=160",')
$M.Add('      ] : [')
$M.Add('        "/api/eco/points/list?limit=160",')
$M.Add('        "/api/eco/points?limit=160",')
$M.Add('      ];')
$M.Add('')
$M.Add('      const r = await loadList(tries);')
$M.Add('      if (!alive) return;')
$M.Add('      if (!r.ok) {')
$M.Add('        setState({ loading: false, err: "Sem dados (API nao respondeu).", src: r.src, items: [] });')
$M.Add('        return;')
$M.Add('      }')
$M.Add('      setState({ loading: false, err: "", src: r.src, items: r.items || [] });')
$M.Add('    })();')
$M.Add('    return () => { alive = false; };')
$M.Add('  }, [base]);')
$M.Add('')
$M.Add('  const items = useMemo(() => {')
$M.Add('    let arr = (state.items || []).slice();')
$M.Add('    if (mode === "chamados") {')
$M.Add('      arr = arr.filter((p: any) => {')
$M.Add('        const st = String(p?.status || p?.state || "OPEN").toUpperCase();')
$M.Add('        return st === "OPEN";')
$M.Add('      });')
$M.Add('    }')
$M.Add('    arr.sort((a: any, b: any) => {')
$M.Add('      const ac = num(b?.counts?.call ?? b?.callCount ?? b?.chamadoCount ?? 0) - num(a?.counts?.call ?? a?.callCount ?? a?.chamadoCount ?? 0);')
$M.Add('      if (ac) return ac;')
$M.Add('      const ax = num(b?.counts?.confirm ?? b?.confirmCount ?? 0) - num(a?.counts?.confirm ?? a?.confirmCount ?? 0);')
$M.Add('      if (ax) return ax;')
$M.Add('      const da = String(b?.createdAt || b?.created_at || b?.date || "");')
$M.Add('      const db = String(a?.createdAt || a?.created_at || a?.date || "");')
$M.Add('      return da.localeCompare(db);')
$M.Add('    });')
$M.Add('    if (mode === "chamados") return arr.slice(0, 60);')
$M.Add('    return arr;')
$M.Add('  }, [state.items, mode]);')
$M.Add('')
$M.Add('  const grid: any = { display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(320px, 1fr))", gap: 12 };')
$M.Add('  const cardBase: any = { borderRadius: 16, padding: 12, background: "rgba(255,255,255,0.75)", border: "1px solid rgba(0,0,0,0.20)" };')
$M.Add('  const title: any = { margin: 0, fontSize: 15, fontWeight: 950, letterSpacing: 0.2, color: "#111" };')
$M.Add('  const meta: any = { margin: "6px 0 0 0", fontSize: 12, opacity: 0.82 };')
$M.Add('  const rowTop: any = { display: "flex", justifyContent: "space-between", alignItems: "center", gap: 10, marginBottom: 8 };')
$M.Add('  const pill: any = { fontSize: 11, fontWeight: 950, padding: "3px 10px", borderRadius: 999, display: "inline-block" };')
$M.Add('')
$M.Add('  if (state.loading) return <div style={{ opacity: 0.7 }}>Carregando mural...</div>;')
$M.Add('  if (state.err) return <div style={{ opacity: 0.8 }}>{state.err} <span style={{ opacity: 0.6 }}>src: {state.src}</span></div>;')
$M.Add('')
$M.Add('  const head = mode === "chamados" ? "Chamados ativos" : "Mural";')
$M.Add('')
$M.Add('  return (')
$M.Add('    <section>')
$M.Add('      <div style={{ display: "flex", justifyContent: "space-between", gap: 10, marginBottom: 10, flexWrap: "wrap" }}>')
$M.Add('        <div style={{ fontSize: 12, opacity: 0.75 }}>{head} — ordenado por chamado/confirmacao (MVP)</div>')
$M.Add('        <div style={{ fontSize: 11, opacity: 0.55 }}>src: {state.src}</div>')
$M.Add('      </div>')
$M.Add('      <div style={grid}>')
$M.Add('        {items.length === 0 ? (')
$M.Add('          <div style={{ opacity: 0.75 }}>Sem itens.</div>')
$M.Add('        ) : (')
$M.Add('          items.map((p: any, idx: number) => {')
$M.Add('            const id = String(p?.id || p?.pointId || p?.pid || "");')
$M.Add('            const t = String(p?.title || p?.name || p?.kind || "Ponto critico");')
$M.Add('            const bairro = String(p?.bairro || p?.neighborhood || p?.area || "");')
$M.Add('            const st = String(p?.status || p?.state || "").toUpperCase();')
$M.Add('            const b = strengthBadge(p);')
$M.Add('            const strong = isStrong(p);')
$M.Add('            const card = { ...cardBase, border: strong ? "2px solid rgba(0,0,0,0.65)" : cardBase.border, background: strong ? "#fff" : cardBase.background };')
$M.Add('            return (')
$M.Add('              <article key={id || idx} style={card}>')
$M.Add('                <div style={rowTop}>')
$M.Add('                  <span style={{ ...pill, border: "1px solid rgba(0,0,0,0.25)", background: "rgba(0,0,0,0.04)" }}>{st || "OPEN"}</span>')
$M.Add('                  <span style={{ ...pill, border: b.border, background: b.bg }}>{b.txt}</span>')
$M.Add('                </div>')
$M.Add('                <h3 style={title}>')
$M.Add('                  <Link href={id ? ("/eco/pontos/" + id) : "/eco/mural"} style={{ color: "#111", textDecoration: "none" }}>{t}</Link>')
$M.Add('                </h3>')
$M.Add('                <div style={meta}><span style={{ fontWeight: 900 }}>Bairro:</span> {bairro || "—"}</div>')
$M.Add('                <PointActionsInline point={p} />')
$M.Add('              </article>')
$M.Add('            );')
$M.Add('          })')
$M.Add('        )}')
$M.Add('      </div>')
$M.Add('    </section>')
$M.Add('  );')
$M.Add('}')
$M.Add('')

WriteUtf8NoBom $muralClient ($M -join "`n")
Write-Host ('[PATCH] rewrote ' + $muralClient)

# 3) write /eco/mural/chamados
$P = New-Object System.Collections.Generic.List[string]
$P.Add('import MuralClient from "../MuralClient";')
$P.Add('')
$P.Add('export default function Page() {')
$P.Add('  return (')
$P.Add('    <main style={{ padding: 16, maxWidth: 1100, margin: "0 auto" }}>')
$P.Add('      <h1 style={{ margin: "0 0 8px 0" }}>Chamados ativos</h1>')
$P.Add('      <p style={{ margin: "0 0 14px 0", opacity: 0.85 }}>Somente pontos OPEN, ordenados por chamado (📣).</p>')
$P.Add('      <div style={{ margin: "0 0 14px 0", display: "flex", gap: 8, flexWrap: "wrap" }}>')
$P.Add('        <a href="/eco/mural" style={{ padding: "9px 10px", borderRadius: 12, border: "1px solid #111", textDecoration: "none", color: "#111", fontWeight: 900, background: "#fff" }}>Voltar ao mural</a>')
$P.Add('      </div>')
$P.Add('      <MuralClient base="pontos" mode="chamados" />')
$P.Add('    </main>')
$P.Add('  );')
$P.Add('}')
$P.Add('')

WriteUtf8NoBom $chamadosPage ($P -join "`n")
Write-Host ('[PATCH] wrote ' + $chamadosPage)

# 4) patch /eco/mural/page.tsx: add botão "Chamados ativos" (fora de <p>)
$raw = Get-Content -LiteralPath $muralPage -Raw -ErrorAction Stop
if ($raw -notmatch "/eco/mural/chamados") {
  $insert = @"
      <div style={{ margin: "10px 0 14px 0", display: "flex", gap: 8, flexWrap: "wrap" }}>
        <a href="/eco/mural/chamados" style={{ padding: "9px 10px", borderRadius: 12, border: "1px solid #111", textDecoration: "none", color: "#111", fontWeight: 900, background: "#fff" }}>
          Ver chamados ativos (OPEN)
        </a>
      </div>

"@
  # tenta inserir antes do primeiro <MuralClient .../>
  $idx = $raw.IndexOf("<MuralClient")
  if ($idx -gt 0) {
    $raw2 = $raw.Insert($idx, $insert)
  } else {
    # fallback: antes do </main>
    $idx2 = $raw.LastIndexOf("</main>")
    if ($idx2 -gt 0) { $raw2 = $raw.Insert($idx2, $insert) } else { $raw2 = $raw + "`n" + $insert }
  }
  WriteUtf8NoBom $muralPage $raw2
  Write-Host ('[PATCH] updated ' + $muralPage + ' (added /eco/mural/chamados link)')
} else {
  Write-Host ('[SKIP] mural page already links to /eco/mural/chamados')
}

# 5) report
$rep = Join-Path $reportDir ('eco-step-91-mural-chamados-topbar-wa-safe-v0_1-' + $ts + '.md')
$repLines = @(
'# eco-step-91-mural-chamados-topbar-wa-safe-v0_1',
'',
'- Time: ' + $ts,
'- Backup: ' + $backupDir,
'',
'## What',
'- PointActionsInline: WhatsApp safe (sem window no render), mensagens com link relativo/absoluto safe.',
'- MuralClient: novo prop mode="chamados" (filtra OPEN, ordena por 📣).',
'- Nova pagina: /eco/mural/chamados.',
'- Botao no /eco/mural apontando para /eco/mural/chamados.',
'',
'## Verify',
'1) Ctrl+C -> npm run dev',
'2) Abrir /eco/mural e clicar "Ver chamados ativos (OPEN)".',
'3) /eco/mural/chamados deve listar apenas OPEN e ordenar por 📣.',
'4) WhatsApp abre ao clicar (Apoiar/Replicar/Chamado/Gratidao).',
'5) Confirmar aumenta contador (e tenta POST /api/eco/points/confirm).'
)
WriteUtf8NoBom $rep ($repLines -join "`n")
Write-Host ('[REPORT] ' + $rep)

Write-Host ""
Write-Host "[VERIFY] Ctrl+C -> npm run dev"
Write-Host "[VERIFY] /eco/mural -> botao Chamados"
Write-Host "[VERIFY] /eco/mural/chamados -> apenas OPEN, ordenado por 📣"