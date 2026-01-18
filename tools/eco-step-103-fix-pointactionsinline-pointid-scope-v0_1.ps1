param([string]$Root = (Get-Location).Path)

$ts = Get-Date -Format "yyyyMMdd-HHmmss"
Write-Host ("== eco-step-103-fix-pointactionsinline-pointid-scope-v0_1 == " + $ts)
Write-Host ("[DIAG] Root: " + $Root)

$boot = Join-Path $Root "tools/_bootstrap.ps1"
if (Test-Path -LiteralPath $boot) { . $boot }

if (-not (Get-Command EnsureDir -ErrorAction SilentlyContinue)) {
  function EnsureDir([string]$p) { if (-not (Test-Path -LiteralPath $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null } }
}
if (-not (Get-Command WriteAllLinesUtf8NoBom -ErrorAction SilentlyContinue)) {
  function WriteAllLinesUtf8NoBom([string]$p, [string[]]$lines) {
    EnsureDir (Split-Path -Parent $p)
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllLines($p, $lines, $enc)
  }
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

$backupDir = Join-Path $Root ("tools/_patch_backup/" + $ts + "-eco-step-103-fix-pointactionsinline-pointid-scope-v0_1")
$reportDir = Join-Path $Root "reports"
EnsureDir $backupDir
EnsureDir $reportDir

$target = Join-Path $Root "src/app/eco/_components/PointActionsInline.tsx"
if (-not (Test-Path -LiteralPath $target)) { throw "[STOP] Nao achei: src/app/eco/_components/PointActionsInline.tsx" }

Write-Host ("[DIAG] Target: " + $target)
BackupFile $Root $target $backupDir

$L = @(
'"use client";',
'',
'import { useMemo, useState } from "react";',
'',
'type AnyObj = any;',
'',
'function asStr(v: any): string {',
'  if (typeof v === "string") return v;',
'  if (v === null || v === undefined) return "";',
'  try { return String(v); } catch { return ""; }',
'}',
'',
'function pickId(p: AnyObj): string {',
'  const v = (p as any)?.pointId ?? (p as any)?.id ?? (p as any)?.point?.id ?? (p as any)?.data?.id ?? (p as any)?.item?.id ?? "";',
'  return asStr(v);',
'}',
'',
'function pickCounts(p: AnyObj): AnyObj {',
'  return ((p as any)?.counts ?? (p as any)?.point?.counts ?? (p as any)?.data?.counts ?? (p as any)?.item?.counts ?? {}) as AnyObj;',
'}',
'',
'async function postJson(url: string, body: any) {',
'  const r = await fetch(url, {',
'    method: "POST",',
'    headers: { "content-type": "application/json" },',
'    body: JSON.stringify(body),',
'  });',
'  const j = await r.json().catch(() => ({}));',
'  if (!r.ok || (j as any)?.ok === false) throw new Error((j as any)?.error || "request_failed");',
'  return j;',
'}',
'',
'export default function PointActionsInline(props: {',
'  pointId?: string;',
'  point?: AnyObj;',
'  data?: AnyObj;',
'  item?: AnyObj;',
'  counts?: AnyObj;',
'  onChanged?: (next?: AnyObj) => void;',
'}) {',
'  const pid = useMemo(() => {',
'    return asStr(props.pointId) || pickId(props.point) || pickId(props.data) || pickId(props.item) || pickId(props);',
'  }, [props.pointId, props.point, props.data, props.item]);',
'',
'  const initial = useMemo(() => {',
'    return (props.counts || pickCounts(props) || {}) as AnyObj;',
'  }, [props.counts, props.point, props.data, props.item]);',
'',
'  const [busy, setBusy] = useState<string>("");',
'  const [local, setLocal] = useState<AnyObj>(initial);',
'',
'  const confirmN = Number((local as any)?.confirm ?? (local as any)?.confirmCount ?? (local as any)?.confirmed ?? 0) || 0;',
'  const supportN = Number((local as any)?.support ?? (local as any)?.supportCount ?? 0) || 0;',
'  const replicarN = Number((local as any)?.replicar ?? (local as any)?.replicarCount ?? 0) || 0;',
'',
'  if (!pid) return null;',
'',
'  const btnStyle: any = {',
'    padding: "8px 10px",',
'    borderRadius: 999,',
'    border: "1px solid #111",',
'    background: "#fff",',
'    color: "#111",',
'    fontWeight: 900,',
'    textDecoration: "none",',
'    display: "inline-flex",',
'    alignItems: "center",',
'    gap: 8,',
'    cursor: "pointer",',
'  };',
'',
'  const wrapStyle: any = {',
'    display: "flex",',
'    flexWrap: "wrap",',
'    gap: 8,',
'    alignItems: "center",',
'  };',
'',
'  async function act(kind: "confirm" | "support" | "replicar") {',
'    if (busy) return;',
'    setBusy(kind);',
'    try {',
'      if (kind === "confirm") {',
'        await postJson("/api/eco/points/confirm", { pointId: pid });',
'        const next = { ...local, confirm: confirmN + 1, confirmCount: confirmN + 1 };',
'        setLocal(next);',
'        props.onChanged?.(next);',
'      }',
'      if (kind === "support") {',
'        await postJson("/api/eco/points/support", { pointId: pid });',
'        const next = { ...local, support: supportN + 1, supportCount: supportN + 1 };',
'        setLocal(next);',
'        props.onChanged?.(next);',
'      }',
'      if (kind === "replicar") {',
'        await postJson("/api/eco/points/replicar", { pointId: pid });',
'        const next = { ...local, replicar: replicarN + 1, replicarCount: replicarN + 1 };',
'        setLocal(next);',
'        props.onChanged?.(next);',
'      }',
'    } catch (e: any) {',
'      console.error(e);',
'      alert("Falha: " + (e?.message || "erro"));',
'    } finally {',
'      setBusy("");',
'    }',
'  }',
'',
'  return (',
'    <div style={wrapStyle}>',
'      <button type="button" onClick={() => act("confirm")} disabled={!!busy} style={btnStyle}>',
'        ✅ Confirmar {confirmN > 0 ? "(" + confirmN + ")" : ""}',
'      </button>',
'      <button type="button" onClick={() => act("support")} disabled={!!busy} style={btnStyle}>',
'        🤝 Apoiar {supportN > 0 ? "(" + supportN + ")" : ""}',
'      </button>',
'      <button type="button" onClick={() => act("replicar")} disabled={!!busy} style={btnStyle}>',
'        ♻️ Replicar {replicarN > 0 ? "(" + replicarN + ")" : ""}',
'      </button>',
'    </div>',
'  );',
'}',
'')

WriteAllLinesUtf8NoBom $target $L
Write-Host ("[PATCH] rewrote " + $target)

$rep = Join-Path $reportDir ("eco-step-103-fix-pointactionsinline-pointid-scope-v0_1-" + $ts + ".md")
$repText = @(
"# eco-step-103-fix-pointactionsinline-pointid-scope-v0_1",
"",
"- Time: " + $ts,
"- Backup: " + $backupDir,
"",
"## What",
"- Rewrote src/app/eco/_components/PointActionsInline.tsx to avoid bare `pointId` ReferenceError.",
"- Now derives id from props.pointId OR props.point/data/item/id and calls APIs directly.",
"",
"## Verify",
"1) Ctrl+C -> npm run dev",
"2) Open /eco/mural/confirmados (must not crash with pointId is not defined)",
"3) Click ✅/🤝/♻️ and confirm POSTs to /api/eco/points/(confirm|support|replicar) work",
""
) -join "`n"
WriteUtf8NoBom $rep $repText
Write-Host ("[REPORT] " + $rep)

Write-Host ""
Write-Host "[VERIFY] Ctrl+C -> npm run dev"
Write-Host "[VERIFY] /eco/mural/confirmados"