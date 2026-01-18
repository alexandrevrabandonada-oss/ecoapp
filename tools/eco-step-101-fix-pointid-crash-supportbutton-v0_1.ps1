param([string]$Root = (Get-Location).Path)

$ts = Get-Date -Format "yyyyMMdd-HHmmss"
Write-Host ("== eco-step-101-fix-pointid-crash-supportbutton-v0_1 == " + $ts)
Write-Host ("[DIAG] Root: " + $Root)

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

$backupDir = Join-Path $Root ("tools/_patch_backup/" + $ts + "-eco-step-101-fix-pointid-crash-supportbutton-v0_1")
$reportDir = Join-Path $Root "reports"
EnsureDir $backupDir
EnsureDir $reportDir

$btn = Join-Path $Root "src/app/eco/_components/PointSupportButton.tsx"
EnsureDir (Split-Path -Parent $btn)

BackupFile $Root $btn $backupDir

$L = New-Object System.Collections.Generic.List[string]
$L.Add('"use client";') | Out-Null
$L.Add('') | Out-Null
$L.Add('import React from "react";') | Out-Null
$L.Add('') | Out-Null
$L.Add('type AnyObj = any;') | Out-Null
$L.Add('') | Out-Null
$L.Add('function n(v: any): number {') | Out-Null
$L.Add('  const x = Number(v);') | Out-Null
$L.Add('  return Number.isFinite(x) ? x : 0;') | Out-Null
$L.Add('}') | Out-Null
$L.Add('') | Out-Null
$L.Add('function pickId(pointId?: any, point?: AnyObj): string {') | Out-Null
$L.Add('  const pid = pointId ?? point?.id ?? point?.pointId ?? point?.criticalPointId ?? point?.ecoCriticalPointId ?? "";') | Out-Null
$L.Add('  return String(pid || "");') | Out-Null
$L.Add('}') | Out-Null
$L.Add('') | Out-Null
$L.Add('function pickCount(initialCount?: any, point?: AnyObj): number {') | Out-Null
$L.Add('  if (initialCount != null) return n(initialCount);') | Out-Null
$L.Add('  const c = point?.counts?.support ?? point?.supportCount ?? point?.counts?.apoio ?? point?.apoioCount ?? 0;') | Out-Null
$L.Add('  return n(c);') | Out-Null
$L.Add('}') | Out-Null
$L.Add('') | Out-Null
$L.Add('export default function PointSupportButton(props: { pointId?: string; point?: AnyObj; initialCount?: number; className?: string; style?: React.CSSProperties }) {') | Out-Null
$L.Add('  const pid = pickId(props.pointId, props.point);') | Out-Null
$L.Add('  const [count, setCount] = React.useState<number>(() => pickCount(props.initialCount, props.point));') | Out-Null
$L.Add('  const [busy, setBusy] = React.useState(false);') | Out-Null
$L.Add('') | Out-Null
$L.Add('  async function onClick() {') | Out-Null
$L.Add('    if (!pid || busy) return;') | Out-Null
$L.Add('    setBusy(true);') | Out-Null
$L.Add('    try {') | Out-Null
$L.Add('      const r = await fetch("/api/eco/points/support", {') | Out-Null
$L.Add('        method: "POST",') | Out-Null
$L.Add('        headers: { "Content-Type": "application/json" },') | Out-Null
$L.Add('        body: JSON.stringify({ pointId: pid }),') | Out-Null
$L.Add('      });') | Out-Null
$L.Add('      const j = await r.json().catch(() => ({} as any));') | Out-Null
$L.Add('      if (r.ok && j && typeof j.count === "number") {') | Out-Null
$L.Add('        setCount(j.count);') | Out-Null
$L.Add('      } else if (r.ok) {') | Out-Null
$L.Add('        setCount((c) => c + 1);') | Out-Null
$L.Add('      }') | Out-Null
$L.Add('    } finally {') | Out-Null
$L.Add('      setBusy(false);') | Out-Null
$L.Add('    }') | Out-Null
$L.Add('  }') | Out-Null
$L.Add('') | Out-Null
$L.Add('  const disabled = !pid || busy;') | Out-Null
$L.Add('') | Out-Null
$L.Add('  return (') | Out-Null
$L.Add('    <button') | Out-Null
$L.Add('      type="button"') | Out-Null
$L.Add('      onClick={onClick}') | Out-Null
$L.Add('      disabled={disabled}') | Out-Null
$L.Add('      className={props.className}') | Out-Null
$L.Add('      style={{') | Out-Null
$L.Add('        display: "inline-flex",') | Out-Null
$L.Add('        alignItems: "center",') | Out-Null
$L.Add('        gap: 8,') | Out-Null
$L.Add('        padding: "8px 10px",') | Out-Null
$L.Add('        borderRadius: 12,') | Out-Null
$L.Add('        border: "1px solid #111",') | Out-Null
$L.Add('        background: disabled ? "#eee" : "#fff",') | Out-Null
$L.Add('        color: "#111",') | Out-Null
$L.Add('        fontWeight: 900,') | Out-Null
$L.Add('        cursor: disabled ? "not-allowed" : "pointer",') | Out-Null
$L.Add('        ...props.style,') | Out-Null
$L.Add('      }}') | Out-Null
$L.Add('      title={pid ? "Apoiar este ponto" : "Sem id do ponto"}') | Out-Null
$L.Add('    >') | Out-Null
$L.Add('      🤝 Apoiar') | Out-Null
$L.Add('      {count > 0 ? (') | Out-Null
$L.Add('        <span style={{ marginLeft: 2, padding: "2px 8px", borderRadius: 999, background: "#111", color: "#fff", fontSize: 12, lineHeight: "12px" }}>') | Out-Null
$L.Add('          {count}') | Out-Null
$L.Add('        </span>') | Out-Null
$L.Add('      ) : null}') | Out-Null
$L.Add('    </button>') | Out-Null
$L.Add('  );') | Out-Null
$L.Add('}') | Out-Null

WriteUtf8NoBom $btn ($L -join "`n")
Write-Host ("[PATCH] rewrote: " + $btn)

$rep = Join-Path $reportDir ("eco-step-101-fix-pointid-crash-supportbutton-v0_1-" + $ts + ".md")
$repText = @(
"# eco-step-101-fix-pointid-crash-supportbutton-v0_1",
"",
"- Time: " + $ts,
"- Backup: " + $backupDir,
"",
"## Change",
"- Rewrote src/app/eco/_components/PointSupportButton.tsx to never reference pointId as a free identifier.",
"",
"## Verify",
"1) npm run dev",
"2) abrir /eco/mural/confirmados (nao pode dar 500)",
"3) se aparecer botao 🤝 Apoiar, clicar nao pode crashar"
) -join "`n"

WriteUtf8NoBom $rep $repText
Write-Host ("[REPORT] " + $rep)

Write-Host ""
Write-Host "[VERIFY] npm run dev"
Write-Host "[VERIFY] /eco/mural/confirmados"