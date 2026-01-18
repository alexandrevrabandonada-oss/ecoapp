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

Write-Host ('== eco-step-90-mural-strong-light-actions-v0_1 == ' + $ts)
Write-Host ('[DIAG] Root: ' + $Root)

# 1) localizar o MuralClient
$all = Get-ChildItem -LiteralPath (Join-Path $Root "src") -Recurse -File -Filter "MuralClient.tsx" -ErrorAction SilentlyContinue
$best = $null
if ($all) {
  $best = $all | Where-Object { $_.FullName -match "\\eco\\mural\\" } | Select-Object -First 1
  if (-not $best) { $best = $all | Select-Object -First 1 }
}
if (-not $best) { throw "[STOP] Nao achei nenhum MuralClient.tsx em src/. Procure por um arquivo do mural e renomeie para MuralClient.tsx ou me diga o caminho." }

$muralClient = $best.FullName
Write-Host ('[DIAG] MuralClient: ' + $muralClient)

$actionsComp = Join-Path $Root "src/app/eco/_components/PointActionsInline.tsx"
Write-Host ('[DIAG] Will write: ' + $actionsComp)

$backupDir = Join-Path $Root ('tools/_patch_backup/' + $ts + '-eco-step-90-mural-strong-light-actions-v0_1')
$reportDir = Join-Path $Root 'reports'
EnsureDir $backupDir
EnsureDir $reportDir

BackupFile $Root $muralClient $backupDir

# 2) escrever PointActionsInline.tsx
$A = New-Object System.Collections.Generic.List[string]
$A.Add('"use client";')
$A.Add('')
$A.Add('import { useMemo, useState } from "react";')
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
$A.Add('function openWa(text: string) {')
$A.Add('  const url = "https://wa.me/?text=" + enc(text);')
$A.Add('  try { window.open(url, "_blank", "noopener,noreferrer"); } catch { window.location.href = url; }')
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
$A.Add('    { url: "/api/eco/points/confirm?id=" + enc(id), body: null },')
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
$A.Add('export default function PointActionsInline(props: { point: AnyObj; compact?: boolean }) {')
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
$A.Add('  const msgBase = useMemo(() => {')
$A.Add('    const head = "ECO — " + title + (bairro ? (" (" + bairro + ")") : "");')
$A.Add('    const link = window?.location?.origin ? (window.location.origin + "/eco/pontos/" + id) : ("/eco/pontos/" + id);')
$A.Add('    return { head, link };')
$A.Add('  }, [id, title, bairro]);')
$A.Add('')
$A.Add('  const wrap: any = { display: "flex", gap: 8, flexWrap: "wrap", marginTop: 10 };')
$A.Add('  const btn: any = { padding: "7px 10px", borderRadius: 12, border: "1px solid rgba(0,0,0,0.35)", background: "rgba(255,255,255,0.75)", color: "#111", fontWeight: 950, fontSize: 12, cursor: "pointer" };')
$A.Add('  const btnStrong: any = { padding: "7px 10px", borderRadius: 12, border: "1px solid #111", background: "#fff", color: "#111", fontWeight: 950, fontSize: 12, cursor: "pointer" };')
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
$A.Add('        ✅ Confirmar' + ' ' + '{confirmCount ? ("(" + String(confirmCount) + ")") : ""}')
$A.Add('      </button>')
$A.Add('')
$A.Add('      <button')
$A.Add('        type="button"')
$A.Add('        style={btn}')
$A.Add('        onClick={() => openWa(msgBase.head + "\\nPosso apoiar com item/ajuda nesse ponto?\\n" + msgBase.link)}')
$A.Add('      >')
$A.Add('        🤝 Apoiar')
$A.Add('      </button>')
$A.Add('')
$A.Add('      <button')
$A.Add('        type="button"')
$A.Add('        style={btn}')
$A.Add('        onClick={() => openWa("ECO — Repasse (boa prática)\\n" + msgBase.head + "\\n" + msgBase.link)}')
$A.Add('      >')
$A.Add('        ♻️ Replicar')
$A.Add('      </button>')
$A.Add('')
$A.Add('      <button')
$A.Add('        type="button"')
$A.Add('        style={btn}')
$A.Add('        onClick={() => openWa("ECO — Chamado\\n" + msgBase.head + "\\nBora organizar?\\n" + msgBase.link)}')
$A.Add('      >')
$A.Add('        📣 Chamado' + ' ' + '{call0 ? ("(" + String(call0) + ")") : ""}')
$A.Add('      </button>')
$A.Add('')
$A.Add('      <button')
$A.Add('        type="button"')
$A.Add('        style={btn}')
$A.Add('        onClick={() => openWa("ECO — Gratidão\\n" + msgBase.head + "\\nObrigado a quem colou e ajudou. Cuidado é coletivo.\\n" + msgBase.link)}')
$A.Add('      >')
$A.Add('        🌱 Gratidão')
$A.Add('      </button>')
$A.Add('    </div>')
$A.Add('  );')
$A.Add('}')
$A.Add('')

WriteUtf8NoBom $actionsComp ($A -join "`n")
Write-Host ('[PATCH] wrote ' + $actionsComp)

# 3) reescrever MuralClient com selo forte/leve + ações
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
$M.Add('export default function MuralClient(props: { base?: string }) {')
$M.Add('  const base = String(props?.base || "pontos");')
$M.Add('  const [state, setState] = useState<{ loading: boolean; err: string; src: string; items: AnyRow[] }>({ loading: true, err: "", src: "", items: [] });')
$M.Add('')
$M.Add('  useEffect(() => {')
$M.Add('    let alive = true;')
$M.Add('    ;(async () => {')
$M.Add('      const tries = base.includes("ponto") ? [')
$M.Add('        "/api/eco/points/list?limit=120",')
$M.Add('        "/api/eco/points?limit=120",')
$M.Add('        "/api/eco/critical/list?limit=120",')
$M.Add('        "/api/eco/critical?limit=120",')
$M.Add('      ] : [')
$M.Add('        "/api/eco/points/list?limit=120",')
$M.Add('        "/api/eco/points?limit=120",')
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
$M.Add('    const arr = (state.items || []).slice();')
$M.Add('    arr.sort((a: any, b: any) => {')
$M.Add('      const ac = num(b?.counts?.call ?? b?.callCount ?? b?.chamadoCount ?? 0) - num(a?.counts?.call ?? a?.callCount ?? a?.chamadoCount ?? 0);')
$M.Add('      if (ac) return ac;')
$M.Add('      const ax = num(b?.counts?.confirm ?? b?.confirmCount ?? 0) - num(a?.counts?.confirm ?? a?.confirmCount ?? 0);')
$M.Add('      if (ax) return ax;')
$M.Add('      const da = String(b?.createdAt || b?.created_at || b?.date || "");')
$M.Add('      const db = String(a?.createdAt || a?.created_at || a?.date || "");')
$M.Add('      return da.localeCompare(db);')
$M.Add('    });')
$M.Add('    return arr;')
$M.Add('  }, [state.items]);')
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
$M.Add('  return (')
$M.Add('    <section>')
$M.Add('      <div style={{ display: "flex", justifyContent: "space-between", gap: 10, marginBottom: 10, flexWrap: "wrap" }}>')
$M.Add('        <div style={{ fontSize: 12, opacity: 0.75 }}>Ordenado por chamado/confirmacao (MVP)</div>')
$M.Add('        <div style={{ fontSize: 11, opacity: 0.55 }}>src: {state.src}</div>')
$M.Add('      </div>')
$M.Add('      <div style={grid}>')
$M.Add('        {items.length === 0 ? (')
$M.Add('          <div style={{ opacity: 0.75 }}>Sem itens.</div>')
$M.Add('        ) : (')
$M.Add('          items.map((p: any, idx: number) => {')
$M.Add('            const id = String(p?.id || p?.pointId || p?.pid || "");')
$M.Add('            const t = String(p?.title || p?.name || p?.kind || "Ponto crítico");')
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
$M.Add('                <div style={meta}>')
$M.Add('                  <span style={{ fontWeight: 900 }}>Bairro:</span> {bairro || "—"}')
$M.Add('                </div>')
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

# 4) report
$rep = Join-Path $reportDir ('eco-step-90-mural-strong-light-actions-v0_1-' + $ts + '.md')
$repLines = @(
'# eco-step-90-mural-strong-light-actions-v0_1',
'',
'- Time: ' + $ts,
'- Backup: ' + $backupDir,
'',
'## What',
'- Criou PointActionsInline (5 acoes: Confirmar + WhatsApp templates).',
'- Reescreveu MuralClient para: selo forte/leve (RECIBO ECO vs REGISTRO) + Acoes inline.',
'',
'## Verify',
'1) Ctrl+C -> npm run dev',
'2) Abrir /eco/mural',
'3) Cada card mostra selo (RECIBO ECO ou REGISTRO) + 5 botoes',
'4) Clicar "Confirmar" incrementa e tenta /api/eco/points/confirm',
'5) Botoes WhatsApp abrem com texto pronto'
)
WriteUtf8NoBom $rep ($repLines -join "`n")
Write-Host ('[REPORT] ' + $rep)

Write-Host ""
Write-Host "[VERIFY] Ctrl+C -> npm run dev"
Write-Host "[VERIFY] /eco/mural -> conferir selo forte/leve + 5 acoes"