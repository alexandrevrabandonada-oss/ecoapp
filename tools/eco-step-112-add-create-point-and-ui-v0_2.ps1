// eco-step-112-add-create-point-and-ui-v0_2
param(
  [string]$Root = (Get-Location).Path
)

$ErrorActionPreference = "Stop"

# --- bootstrap (best effort)
$bootstrap = Join-Path $Root "tools\_bootstrap.ps1"
if (Test-Path $bootstrap) { . $bootstrap }

# --- fallbacks (se bootstrap não carregou)
if (-not (Get-Command EnsureDir -ErrorAction SilentlyContinue)) {
  function EnsureDir([string]$p) { New-Item -ItemType Directory -Force -Path $p | Out-Null }
}
if (-not (Get-Command WriteUtf8NoBom -ErrorAction SilentlyContinue)) {
  function WriteUtf8NoBom([string]$path, [string]$content) {
    $enc = New-Object System.Text.UTF8Encoding($false)
    EnsureDir (Split-Path -Parent $path)
    [System.IO.File]::WriteAllText($path, $content, $enc)
  }
}
if (-not (Get-Command BackupFile -ErrorAction SilentlyContinue)) {
  function BackupFile([string]$path, [string]$backupDir) {
    EnsureDir $backupDir
    if (Test-Path $path) {
      $rel = $path.Replace((Join-Path $Root ""), "")
      $rel = $rel.TrimStart("\","/")
      $dest = Join-Path $backupDir $rel
      EnsureDir (Split-Path -Parent $dest)
      Copy-Item -Force $path $dest
    }
  }
}

function MustExist($p, $label) {
  if (-not (Test-Path $p)) { throw ("[STOP] não achei " + $label + ": " + $p) }
}

function RandId([string]$prefix) {
  return ($prefix + "-" + (Get-Random).ToString("x") + "-" + ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds().ToString("x")))
}

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$me = "eco-step-112-add-create-point-and-ui-v0_2"
Write-Host ("== " + $me + " == " + $stamp)
Write-Host ("[DIAG] Root: " + $Root)

$backupDir = Join-Path $Root ("tools\_patch_backup\" + $stamp + "-" + $me)
EnsureDir $backupDir

# -------------------------
# PATHS
# -------------------------
$pointsApi = Join-Path $Root "src\app\api\eco\points\route.ts"
$muralPage = Join-Path $Root "src\app\eco\mural\page.tsx"
$newClient = Join-Path $Root "src\app\eco\mural\_components\MuralNewPointClient.tsx"

MustExist $pointsApi "src/app/api/eco/points/route.ts"
MustExist $muralPage "src/app/eco/mural/page.tsx"

# -------------------------
# PATCH A: POST /api/eco/points (sem mexer no GET)
# -------------------------
BackupFile $pointsApi $backupDir
$raw = Get-Content -Raw -ErrorAction Stop $pointsApi
if (-not $raw) { throw "[STOP] points route.ts vazio/ilegível." }

if ($raw -match "export\s+async\s+function\s+POST\s*\(") {
  Write-Host "[PATCH] points route já tem POST — pulando."
} else {
  $postBlock = @()

  $postBlock += ""
  $postBlock += "// --- added by tools/eco-step-112-add-create-point-and-ui-v0_2.ps1"
  $postBlock += "// POST /api/eco/points : cria ponto crítico (lat/lng + defaults + best-effort required fields)."
  $postBlock += "export async function POST(req: Request) {"
  $postBlock += "  try {"
  $postBlock += "    const body: any = await req.json().catch(() => ({}));"
  $postBlock += "    const lat = Number(body.lat);"
  $postBlock += "    const lng = Number(body.lng);"
  $postBlock += "    if (!Number.isFinite(lat) || !Number.isFinite(lng)) {"
  $postBlock += "      return NextResponse.json({ ok: false, error: 'bad_latlng' }, { status: 400 });"
  $postBlock += "    }"
  $postBlock += "    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {"
  $postBlock += "      return NextResponse.json({ ok: false, error: 'latlng_out_of_range' }, { status: 400 });"
  $postBlock += "    }"
  $postBlock += ""
  $postBlock += "    const actor = (typeof body.actor === 'string' && body.actor.trim().length) ? body.actor.trim().slice(0, 80) : 'anon';"
  $postBlock += "    const note = (typeof body.note === 'string' && body.note.trim().length) ? body.note.trim().slice(0, 500) : null;"
  $postBlock += "    const photoUrl = (typeof body.photoUrl === 'string' && body.photoUrl.trim().length) ? body.photoUrl.trim().slice(0, 500) : null;"
  $postBlock += ""
  $postBlock += "    const pc: any = prisma as any;"
  $postBlock += "    const keys = Object.keys(pc);"
  $postBlock += "    const pointKey = (pc.ecoCriticalPoint ? 'ecoCriticalPoint' : (keys.find((k) => /point/i.test(k) && /eco/i.test(k)) || null));"
  $postBlock += "    if (!pointKey) return NextResponse.json({ ok: false, error: 'point_model_not_found' }, { status: 500 });"
  $postBlock += ""
  $postBlock += "    // DMMF (runtime) para validar enums e preencher required sem default"
  $postBlock += "    const mod: any = await import('@prisma/client');"
  $postBlock += "    const dmmf: any = mod && mod.Prisma ? (mod.Prisma as any).dmmf : null;"
  $postBlock += "    const models: any[] = dmmf && dmmf.datamodel && Array.isArray(dmmf.datamodel.models) ? dmmf.datamodel.models : [];"
  $postBlock += "    const enums: any[] = dmmf && dmmf.datamodel && Array.isArray(dmmf.datamodel.enums) ? dmmf.datamodel.enums : [];"
  $postBlock += "    const toDelegate = (name: string) => name && name.length ? name.slice(0,1).toLowerCase() + name.slice(1) : name;"
  $postBlock += "    const model = models.find((m: any) => m && toDelegate(m.name) === pointKey) || null;"
  $postBlock += "    const hasField = (n: string) => !!(model && Array.isArray(model.fields) && model.fields.some((f: any) => f && f.name === n));"
  $postBlock += "    const getField = (n: string) => (model && Array.isArray(model.fields) ? model.fields.find((f: any) => f && f.name === n) : null);"
  $postBlock += "    const enumAllowed = (enumName: string) => {"
  $postBlock += "      const e = enums.find((x: any) => x && x.name === enumName);"
  $postBlock += "      return e && Array.isArray(e.values) ? e.values.map((v: any) => v && v.name).filter(Boolean) : [];"
  $postBlock += "    };"
  $postBlock += ""
  $postBlock += "    let kind = (typeof body.kind === 'string' && body.kind.trim().length) ? body.kind.trim() : 'LIXO_ACUMULADO';"
  $postBlock += "    let status = (typeof body.status === 'string' && body.status.trim().length) ? body.status.trim() : 'OPEN';"
  $postBlock += ""
  $postBlock += "    const kindField: any = getField('kind');"
  $postBlock += "    if (kindField && kindField.kind === 'enum') {"
  $postBlock += "      const allowed = enumAllowed(kindField.type);"
  $postBlock += "      if (allowed.length && !allowed.includes(kind)) kind = allowed[0];"
  $postBlock += "    }"
  $postBlock += "    const statusField: any = getField('status');"
  $postBlock += "    if (statusField && statusField.kind === 'enum') {"
  $postBlock += "      const allowed = enumAllowed(statusField.type);"
  $postBlock += "      if (allowed.length && !allowed.includes(status)) status = allowed[0];"
  $postBlock += "    }"
  $postBlock += ""
  $postBlock += "    const data: any = {};"
  $postBlock += "    // id (se necessário e sem default) — best-effort"
  $postBlock += "    const idField: any = getField('id');"
  $postBlock += "    if (idField && idField.isRequired && !idField.hasDefaultValue) {"
  $postBlock += "      data.id = (typeof body.id === 'string' && body.id.trim().length) ? body.id.trim().slice(0, 64) : ('p-' + Math.random().toString(36).slice(2,8) + '-' + Date.now().toString(36));"
  $postBlock += "    }"
  $postBlock += "    if (hasField('lat')) data.lat = lat;"
  $postBlock += "    if (hasField('lng')) data.lng = lng;"
  $postBlock += "    if (hasField('kind')) data.kind = kind;"
  $postBlock += "    if (hasField('status')) data.status = status;"
  $postBlock += "    if (hasField('note')) data.note = note;"
  $postBlock += "    if (hasField('photoUrl')) data.photoUrl = photoUrl;"
  $postBlock += "    if (hasField('actor')) data.actor = actor;"
  $postBlock += "    if (hasField('createdAt')) data.createdAt = new Date();"
  $postBlock += "    if (hasField('updatedAt')) data.updatedAt = new Date();"
  $postBlock += ""
  $postBlock += "    // preencher required scalars/enums sem default (best-effort)"
  $postBlock += "    if (model && Array.isArray(model.fields)) {"
  $postBlock += "      for (const f of model.fields) {"
  $postBlock += "        if (!f || f.isList) continue;"
  $postBlock += "        if (f.kind !== 'scalar' && f.kind !== 'enum') continue;"
  $postBlock += "        if (!f.isRequired) continue;"
  $postBlock += "        if (f.hasDefaultValue) continue;"
  $postBlock += "        if (data[f.name] !== undefined) continue;"
  $postBlock += "        if (f.name === 'id') continue;"
  $postBlock += "        if (f.kind === 'enum') {"
  $postBlock += "          const allowed = enumAllowed(f.type);"
  $postBlock += "          data[f.name] = allowed.length ? allowed[0] : kind;"
  $postBlock += "          continue;"
  $postBlock += "        }"
  $postBlock += "        if (f.type === 'String') { data[f.name] = actor; continue; }"
  $postBlock += "        if (f.type === 'Int' || f.type === 'Float') { data[f.name] = 0; continue; }"
  $postBlock += "        if (f.type === 'Boolean') { data[f.name] = false; continue; }"
  $postBlock += "        if (f.type === 'DateTime') { data[f.name] = new Date(); continue; }"
  $postBlock += "        data[f.name] = actor;"
  $postBlock += "      }"
  $postBlock += "    }"
  $postBlock += ""
  $postBlock += "    const created = await pc[pointKey].create({ data });"
  $postBlock += "    return NextResponse.json({ ok: true, error: null, item: created, meta: { pointKey } }, { status: 201 });"
  $postBlock += "  } catch (e: any) {"
  $postBlock += "    const msg = e && e.message ? String(e.message) : String(e);"
  $postBlock += "    return NextResponse.json({ ok: false, error: 'create_failed', message: msg }, { status: 500 });"
  $postBlock += "  }"
  $postBlock += "}"
  $postBlock += ""

  WriteUtf8NoBom $pointsApi ($raw + ($postBlock -join "`n"))
  Write-Host ("[PATCH] added POST -> " + $pointsApi)
}

# -------------------------
# PATCH B: UI no /eco/mural (botão + modal client)
# -------------------------
BackupFile $muralPage $backupDir
$mural = Get-Content -Raw -ErrorAction Stop $muralPage
if (-not $mural) { throw "[STOP] mural page.tsx vazio/ilegível." }

EnsureDir (Split-Path -Parent $newClient)
if (Test-Path $newClient) { BackupFile $newClient $backupDir }

$ui = @()
$ui += '"use client";'
$ui += ''
$ui += 'import { useMemo, useState } from "react";'
$ui += 'import { useRouter } from "next/navigation";'
$ui += ''
$ui += 'type FormState = { kind: string; status: string; lat: string; lng: string; note: string; photoUrl: string };'
$ui += ''
$ui += 'export default function MuralNewPointClient() {'
$ui += '  const router = useRouter();'
$ui += '  const [open, setOpen] = useState(false);'
$ui += '  const [busy, setBusy] = useState(false);'
$ui += '  const [msg, setMsg] = useState<string | null>(null);'
$ui += ''
$ui += '  const defaults = useMemo<FormState>(() => ({'
$ui += '    kind: "LIXO_ACUMULADO",'
$ui += '    status: "OPEN",'
$ui += '    lat: "-22.5200",'
$ui += '    lng: "-44.1040",'
$ui += '    note: "",'
$ui += '    photoUrl: "",'
$ui += '  }), []);'
$ui += ''
$ui += '  const [f, setF] = useState<FormState>(defaults);'
$ui += '  function reset() { setF(defaults); setMsg(null); }'
$ui += ''
$ui += '  async function useGeo() {'
$ui += '    setMsg(null);'
$ui += '    if (!navigator.geolocation) { setMsg("Seu navegador não tem geolocalização."); return; }'
$ui += '    navigator.geolocation.getCurrentPosition('
$ui += '      (pos) => setF((x) => ({ ...x, lat: String(pos.coords.latitude), lng: String(pos.coords.longitude) })),'
$ui += '      () => setMsg("Não consegui pegar sua localização (permissão/erro)."),'
$ui += '      { enableHighAccuracy: true, timeout: 8000 }'
$ui += '    );'
$ui += '  }'
$ui += ''
$ui += '  async function submit() {'
$ui += '    setBusy(true); setMsg(null);'
$ui += '    try {'
$ui += '      const payload: any = {'
$ui += '        kind: f.kind, status: f.status,'
$ui += '        lat: Number(f.lat), lng: Number(f.lng),'
$ui += '        note: f.note, photoUrl: f.photoUrl,'
$ui += '        actor: "app",'
$ui += '      };'
$ui += '      const r = await fetch("/api/eco/points", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(payload) });'
$ui += '      const j = await r.json().catch(() => null);'
$ui += '      if (!r.ok) {'
$ui += '        const em = j && (j.error || j.message) ? String(j.error || j.message) : ("HTTP " + r.status);'
$ui += '        setMsg("Erro ao registrar: " + em);'
$ui += '        return;'
$ui += '      }'
$ui += '      setMsg("Registrado! Atualizando mural...");'
$ui += '      setOpen(false);'
$ui += '      try { router.refresh(); } catch {}'
$ui += '      setTimeout(() => { window.location.reload(); }, 120);'
$ui += '    } finally { setBusy(false); }'
$ui += '  }'
$ui += ''
$ui += '  return ('
$ui += '    <div style={{ display: "flex", gap: 10, alignItems: "center", flexWrap: "wrap", margin: "10px 0 12px 0" }}>'
$ui += '      <button onClick={() => { setOpen(true); reset(); }} style={{ padding: "10px 12px", borderRadius: 12, border: "1px solid #111", background: "#111", color: "#fff", fontWeight: 900, cursor: "pointer" }}>'
$ui += '        ＋ Registrar ponto'
$ui += '      </button>'
$ui += '      {msg ? <span style={{ fontWeight: 700 }}>{msg}</span> : null}'
$ui += '      {open ? ('
$ui += '        <div style={{ position: "fixed", inset: 0, background: "rgba(0,0,0,0.35)", display: "flex", alignItems: "center", justifyContent: "center", padding: 16, zIndex: 50 }}>'
$ui += '          <div style={{ width: "min(720px, 100%)", background: "#fff", border: "2px solid #111", borderRadius: 16, padding: 14 }}>'
$ui += '            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", gap: 10 }}>'
$ui += '              <div style={{ fontWeight: 1000, fontSize: 18 }}>Registrar ponto crítico</div>'
$ui += '              <button onClick={() => setOpen(false)} style={{ padding: "8px 10px", borderRadius: 12, border: "1px solid #111", background: "#fff", fontWeight: 900, cursor: "pointer" }}>Fechar</button>'
$ui += '            </div>'
$ui += '            <div style={{ marginTop: 10, display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10 }}>'
$ui += '              <label style={{ display: "flex", flexDirection: "column", gap: 6, fontWeight: 900 }}>'
$ui += '                Tipo (kind)'
$ui += '                <input value={f.kind} onChange={(e) => setF((x) => ({ ...x, kind: e.target.value }))} style={{ padding: 10, borderRadius: 12, border: "1px solid #111" }} />'
$ui += '              </label>'
$ui += '              <label style={{ display: "flex", flexDirection: "column", gap: 6, fontWeight: 900 }}>'
$ui += '                Status'
$ui += '                <input value={f.status} onChange={(e) => setF((x) => ({ ...x, status: e.target.value }))} style={{ padding: 10, borderRadius: 12, border: "1px solid #111" }} />'
$ui += '              </label>'
$ui += '              <label style={{ display: "flex", flexDirection: "column", gap: 6, fontWeight: 900 }}>'
$ui += '                Latitude'
$ui += '                <input value={f.lat} onChange={(e) => setF((x) => ({ ...x, lat: e.target.value }))} style={{ padding: 10, borderRadius: 12, border: "1px solid #111" }} />'
$ui += '              </label>'
$ui += '              <label style={{ display: "flex", flexDirection: "column", gap: 6, fontWeight: 900 }}>'
$ui += '                Longitude'
$ui += '                <input value={f.lng} onChange={(e) => setF((x) => ({ ...x, lng: e.target.value }))} style={{ padding: 10, borderRadius: 12, border: "1px solid #111" }} />'
$ui += '              </label>'
$ui += '            </div>'
$ui += '            <div style={{ marginTop: 10, display: "grid", gridTemplateColumns: "1fr", gap: 10 }}>'
$ui += '              <label style={{ display: "flex", flexDirection: "column", gap: 6, fontWeight: 900 }}>'
$ui += '                Observação (note)'
$ui += '                <textarea value={f.note} onChange={(e) => setF((x) => ({ ...x, note: e.target.value }))} rows={3} style={{ padding: 10, borderRadius: 12, border: "1px solid #111" }} />'
$ui += '              </label>'
$ui += '              <label style={{ display: "flex", flexDirection: "column", gap: 6, fontWeight: 900 }}>'
$ui += '                Foto (URL opcional)'
$ui += '                <input value={f.photoUrl} onChange={(e) => setF((x) => ({ ...x, photoUrl: e.target.value }))} style={{ padding: 10, borderRadius: 12, border: "1px solid #111" }} />'
$ui += '              </label>'
$ui += '            </div>'
$ui += '            <div style={{ marginTop: 12, display: "flex", gap: 10, flexWrap: "wrap" }}>'
$ui += '              <button onClick={useGeo} disabled={busy} style={{ padding: "10px 12px", borderRadius: 12, border: "1px solid #111", background: "#fff", fontWeight: 900, cursor: "pointer" }}>📍 Usar minha localização</button>'
$ui += '              <button onClick={submit} disabled={busy} style={{ padding: "10px 12px", borderRadius: 12, border: "1px solid #111", background: "#111", color: "#fff", fontWeight: 1000, cursor: "pointer" }}>{busy ? "Enviando..." : "Registrar"}</button>'
$ui += '              <button onClick={reset} disabled={busy} style={{ padding: "10px 12px", borderRadius: 12, border: "1px solid #111", background: "#fff", fontWeight: 900, cursor: "pointer" }}>Limpar</button>'
$ui += '            </div>'
$ui += '            <div style={{ marginTop: 10, fontSize: 12, opacity: 0.85 }}>Dica: o servidor valida lat/lng e aplica defaults seguros.</div>'
$ui += '          </div>'
$ui += '        </div>'
$ui += '      ) : null}'
$ui += '    </div>'
$ui += '  );'
$ui += '}'
$ui += ''

WriteUtf8NoBom $newClient ($ui -join "`n")
Write-Host ("[PATCH] wrote -> " + $newClient)

# inserir no page.tsx perto do MuralNavPillsClient
if (-not ($mural -match "MuralNewPointClient")) {
  if (-not ($mural -match "import\s+MuralNewPointClient")) {
    $mural = $mural -replace "(import\s+MuralNavPillsClient[^\r\n]*\r?\n)", ('$1' + 'import MuralNewPointClient from "./_components/MuralNewPointClient";' + "`n")
  }

  if ($mural -match "<MuralNavPillsClient\s*/>") {
    $mural = $mural -replace "<MuralNavPillsClient\s*/>", "<MuralNavPillsClient />`n      <MuralNewPointClient />"
    WriteUtf8NoBom $muralPage $mural
    Write-Host ("[PATCH] inserted <MuralNewPointClient /> -> " + $muralPage)
  } else {
    Write-Host "[WARN] Não achei <MuralNavPillsClient /> no mural/page.tsx. Não inseri o botão automaticamente."
  }
} else {
  Write-Host "[PATCH] mural/page.tsx já referencia MuralNewPointClient — pulando."
}

# -------------------------
# REPORT
# -------------------------
$report = @()
$report += "# $me"
$report += ""
$report += "- Time: $stamp"
$report += "- Backup: $backupDir"
$report += ""
$report += "## What/Why"
$report += "- Adiciona POST /api/eco/points para criar ponto (lat/lng + defaults)."
$report += "- Adiciona UI no /eco/mural: botão + modal + geolocalização opcional."
$report += ""
$report += "## Patched"
$report += "- src/app/api/eco/points/route.ts (POST)"
$report += "- src/app/eco/mural/_components/MuralNewPointClient.tsx (novo)"
$report += "- src/app/eco/mural/page.tsx (inserção do componente)"
$report += ""
$report += "## Verify"
$report += "1) Ctrl+C -> npm run dev"
$report += "2) abrir /eco/mural -> clicar 'Registrar ponto' -> enviar"
$report += "3) irm 'http://localhost:3000/api/eco/points?limit=5' | ConvertTo-Json -Depth 40"
$report += "4) Teste direto (sem JSON com aspas escapadas):"
$report += "   \$b = @{ lat=-22.521; lng=-44.105; kind='LIXO_ACUMULADO'; status='OPEN'; note='teste' } | ConvertTo-Json -Compress"
$report += "   irm 'http://localhost:3000/api/eco/points' -Method Post -ContentType 'application/json' -Body \$b | ConvertTo-Json -Depth 40"
$report += ""

$reportPath = Join-Path $Root ("reports\" + $me + "-" + $stamp + ".md")
EnsureDir (Split-Path -Parent $reportPath)
WriteUtf8NoBom $reportPath ($report -join "`n")
Write-Host ("[REPORT] " + $reportPath)

Write-Host ""
Write-Host "[VERIFY] rode:"
Write-Host "  Ctrl+C -> npm run dev"
Write-Host "  abrir /eco/mural -> Registrar ponto"
Write-Host "  irm 'http://localhost:3000/api/eco/points?limit=5' | ConvertTo-Json -Depth 40"
Write-Host "  \$b = @{ lat=-22.521; lng=-44.105; kind='LIXO_ACUMULADO'; status='OPEN'; note='teste' } | ConvertTo-Json -Compress"
Write-Host "  irm 'http://localhost:3000/api/eco/points' -Method Post -ContentType 'application/json' -Body \$b | ConvertTo-Json -Depth 40"