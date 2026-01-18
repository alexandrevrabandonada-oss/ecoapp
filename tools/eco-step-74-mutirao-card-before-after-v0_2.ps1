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

$backupDir = Join-Path $Root ('tools/_patch_backup/' + $ts + '-eco-step-74-mutirao-card-before-after-v0_2')
$reportDir = Join-Path $Root 'reports'
EnsureDir $backupDir
EnsureDir $reportDir

Write-Host ('== eco-step-74-mutirao-card-before-after-v0_2 == ' + $ts)
Write-Host ('[DIAG] Root: ' + $Root)

$api = Join-Path $Root 'src/app/api/eco/mutirao/card/route.tsx'
if (-not (Test-Path -LiteralPath $api)) { throw ('[STOP] Não achei: ' + $api) }

BackupFile $Root $api $backupDir

$L = @(
'import { ImageResponse } from "next/og";',
'import { prisma } from "@/lib/prisma";',
'',
'export const runtime = "edge";',
'export const dynamic = "force-dynamic";',
'',
'function pickStr(o: any, keys: string[]) {',
'  for (const k of keys) {',
'    const v = o?.[k];',
'    if (typeof v === "string" && v.trim()) return v.trim();',
'  }',
'  return "";',
'}',
'function findMeta(o: any) {',
'  const m = o?.meta;',
'  if (m && typeof m === "object") return m;',
'  return null;',
'}',
'function getMutiraoModel() {',
'  const pc: any = prisma as any;',
'  const candidates = ["ecoMutirao", "mutirao", "ecoCleanup", "cleanup", "ecoMutiraoEvent", "mutiraoEvent"];',
'  for (const k of candidates) {',
'    const m = pc?.[k];',
'    if (m && typeof m.findUnique === "function") return { key: k, model: m as any };',
'  }',
'  return null;',
'}',
'function safeFmt(s: any, max = 120) {',
'  const t = String(s || "").trim();',
'  return t.length > max ? (t.slice(0, max - 3) + "...") : t;',
'}',
'function fmtStatus(s: any) {',
'  const t = String(s || "").toUpperCase().trim();',
'  if (!t) return "MUTIRÃO";',
'  if (t.includes("FINISH") || t === "DONE" || t === "RESOLVED") return "FINALIZADO";',
'  if (t.includes("OPEN") || t.includes("PLAN")) return "ABERTO";',
'  return t;',
'}',
'function boxStyle(bg: string, br: string) {',
'  return {',
'    background: bg,',
'    border: "2px solid " + br,',
'    borderRadius: 22,',
'    padding: 22,',
'    display: "flex",',
'    flexDirection: "column",',
'  } as const;',
'}',
'',
'function photoBlock(opts: { beforeUrl: string; afterUrl: string; isSquare: boolean }) {',
'  const beforeUrl = opts.beforeUrl;',
'  const afterUrl = opts.afterUrl;',
'  const isSquare = opts.isSquare;',
'',
'  const hSingle = isSquare ? 460 : 560;',
'  const hDouble = isSquare ? 420 : 500;',
'',
'  const one = (src: string, label: string) => (',
'    <div style={{ display: "flex", flexDirection: "column", gap: 8, width: "100%" }}>',
'      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>',
'        <div style={{ display: "flex", padding: "6px 10px", borderRadius: 999, border: "2px solid #111", background: "#fff", fontWeight: 900, fontSize: 14 }}>',
'          {label}',
'        </div>',
'      </div>',
'      <div style={{ display: "flex", width: "100%", borderRadius: 22, overflow: "hidden", border: "2px solid #111" }}>',
'        {/* eslint-disable-next-line @next/next/no-img-element */}',
'        <img src={src} alt={label} style={{ width: "100%", height: hSingle, objectFit: "cover" }} />',
'      </div>',
'    </div>',
'  );',
'',
'  const two = (b: string, a: string) => (',
'    <div style={{ display: "flex", gap: 12, width: "100%" }}>',
'      <div style={{ display: "flex", flexDirection: "column", gap: 8, flex: 1 }}>',
'        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>',
'          <div style={{ display: "flex", padding: "6px 10px", borderRadius: 999, border: "2px solid #111", background: "#fff", fontWeight: 900, fontSize: 14 }}>ANTES</div>',
'        </div>',
'        <div style={{ display: "flex", width: "100%", borderRadius: 22, overflow: "hidden", border: "2px solid #111" }}>',
'          {/* eslint-disable-next-line @next/next/no-img-element */}',
'          <img src={b} alt="ANTES" style={{ width: "100%", height: hDouble, objectFit: "cover" }} />',
'        </div>',
'      </div>',
'      <div style={{ display: "flex", flexDirection: "column", gap: 8, flex: 1 }}>',
'        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>',
'          <div style={{ display: "flex", padding: "6px 10px", borderRadius: 999, border: "2px solid #111", background: "#FFDD00", fontWeight: 900, fontSize: 14 }}>DEPOIS</div>',
'        </div>',
'        <div style={{ display: "flex", width: "100%", borderRadius: 22, overflow: "hidden", border: "2px solid #111" }}>',
'          {/* eslint-disable-next-line @next/next/no-img-element */}',
'          <img src={a} alt="DEPOIS" style={{ width: "100%", height: hDouble, objectFit: "cover" }} />',
'        </div>',
'      </div>',
'    </div>',
'  );',
'',
'  if (beforeUrl && afterUrl) return two(beforeUrl, afterUrl);',
'  if (afterUrl) return one(afterUrl, "PROVA");',
'  if (beforeUrl) return one(beforeUrl, "ANTES");',
'  return null;',
'}',
'',
'export async function GET(req: Request) {',
'  const { searchParams } = new URL(req.url);',
'  const id = String(searchParams.get("id") || searchParams.get("mutiraoId") || "").trim();',
'  const format = String(searchParams.get("format") || "3x4").trim();',
'  if (!id) return new Response("bad_id", { status: 400 });',
'',
'  const mm = getMutiraoModel();',
'  if (!mm?.model) return new Response("model_not_ready", { status: 503 });',
'',
'  const item = await mm.model.findUnique({ where: { id } });',
'  if (!item) return new Response("not_found", { status: 404 });',
'',
'  const meta = findMeta(item) || {};',
'  const title = safeFmt(pickStr(item, ["title","name","titulo"]) || "Mutirão", 110);',
'  const bairro = safeFmt(pickStr(item, ["bairro","neighborhood","area","regiao","region"]) || "", 60);',
'  const status = fmtStatus(item?.status);',
'  const proofNote = safeFmt(pickStr(item, ["proofNote","note","obs"]) || (meta as any).proofNote || "", 140);',
'  const beforeUrl = String((item as any).beforeUrl || (meta as any).beforeUrl || "").trim();',
'  const afterUrl  = String((item as any).afterUrl  || (meta as any).afterUrl  || "").trim();',
'',
'  const isSquare = format === "1x1";',
'  const W = 1080;',
'  const H = isSquare ? 1080 : 1350;',
'',
'  const topTag = "ECO • MUTIRÃO";',
'  const stamp = "RECIBO É LEI";',
'  const subStamp = "ESCUTAR • CUIDAR • ORGANIZAR";',
'',
'  const header = (',
'    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", width: "100%" }}>',
'      <div style={{ display: "flex", flexDirection: "column" }}>',
'        <div style={{ fontSize: 26, fontWeight: 900, letterSpacing: 1 }}>{topTag}</div>',
'        <div style={{ fontSize: 18, opacity: 0.9 }}>{bairro ? ("Bairro: " + bairro) : "Volta Redonda"}</div>',
'      </div>',
'      <div style={{ display: "flex" }}>',
'        <div style={{',
'          display: "flex",',
'          padding: "10px 14px",',
'          borderRadius: 999,',
'          border: "2px solid #111",',
'          background: "#FFDD00",',
'          fontWeight: 900,',
'          fontSize: 18,',
'        }}>{status}</div>',
'      </div>',
'    </div>',
'  );',
'',
'  const body = (',
'    <div style={{ display: "flex", flexDirection: "column", gap: 16, width: "100%" }}>',
'      <div style={{ fontSize: isSquare ? 54 : 60, fontWeight: 1000, lineHeight: 1.05 }}>{title}</div>',
'      {proofNote ? <div style={{ fontSize: 24, opacity: 0.92, lineHeight: 1.25 }}>Prova: {proofNote}</div> : <div style={{ fontSize: 22, opacity: 0.7 }}>Cuidado coletivo em prática.</div>}',
'      {photoBlock({ beforeUrl, afterUrl, isSquare })}',
'    </div>',
'  );',
'',
'  const footer = (',
'    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-end", width: "100%" }}>',
'      <div style={{ display: "flex", flexDirection: "column", gap: 6 }}>',
'        <div style={{ display: "flex", padding: "10px 14px", borderRadius: 999, border: "2px solid #111", background: "#111", color: "#fff", fontWeight: 900 }}>{stamp}</div>',
'        <div style={{ fontSize: 16, opacity: 0.85 }}>{subStamp}</div>',
'      </div>',
'      <div style={{ display: "flex", flexDirection: "column", alignItems: "flex-end", gap: 6 }}>',
'        <div style={{ fontSize: 14, opacity: 0.8 }}>eco/share/mutirao/{id}</div>',
'        <div style={{ fontSize: 14, opacity: 0.8 }}>@VR_ABANDONADA</div>',
'      </div>',
'    </div>',
'  );',
'',
'  return new ImageResponse(',
'    (',
'      <div style={{',
'        width: W,',
'        height: H,',
'        display: "flex",',
'        flexDirection: "column",',
'        padding: 26,',
'        background: "#F5F5F5",',
'        color: "#111",',
'        fontFamily: "Arial",',
'      }}>',
'        <div style={{ ...boxStyle("#FFFFFF", "#111"), gap: 18, flex: 1 }}>',
'          {header}',
'          <div style={{ display: "flex", flexDirection: "column", gap: 18, flex: 1 }}>',
'            {body}',
'          </div>',
'          {footer}',
'        </div>',
'      </div>',
'    ),',
'    { width: W, height: H }',
'  );',
'}',
''
)

WriteUtf8NoBom $api ($L -join "`n")
Write-Host "[PATCH] mutirao/card v0.2 (ANTES/DEPOIS)"

$rep = Join-Path $reportDir ('eco-step-74-mutirao-card-before-after-v0_2-' + $ts + '.md')
$repLines = @(
"# eco-step-74-mutirao-card-before-after-v0_2",
"",
"- Time: " + $ts,
"- Backup: " + $backupDir,
"- File: src/app/api/eco/mutirao/card/route.tsx",
"",
"## O que mudou",
"- Card agora mostra ANTES/DEPOIS lado a lado quando houver ambos",
"- Continua aceitando format=3x4 ou 1x1",
"",
"## Verify",
"1) Ctrl+C -> npm run dev",
"2) /api/eco/mutirao/card?format=3x4&id=<id> (ver antes/depois)",
"3) /eco/share/mutirao/<id> (previews OK)"
)
WriteUtf8NoBom $rep ($repLines -join "`n")
Write-Host ('[REPORT] ' + $rep)

Write-Host ""
Write-Host "[VERIFY] Ctrl+C -> npm run dev"
Write-Host "[VERIFY] /api/eco/mutirao/card?format=3x4&id=<id>"
Write-Host "[VERIFY] /eco/share/mutirao/<id>"