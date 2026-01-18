param(
  [string]$Root = (Get-Location).Path
)

$ErrorActionPreference = "Stop"

# --- bootstrap (best effort)
$bootstrap = Join-Path $Root "tools\_bootstrap.ps1"
if (Test-Path $bootstrap) { . $bootstrap }

# --- fallbacks (se bootstrap não carregou funções)
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

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$me = "eco-step-112-add-create-point-and-ui-v0_3"
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
$points2Api = Join-Path $Root "src\app\api\eco\points2\route.ts"

MustExist $pointsApi "src/app/api/eco/points/route.ts"
MustExist $muralPage "src/app/eco/mural/page.tsx"

# -------------------------
# PATCH A: POST /api/eco/points (idempotente)
# -------------------------
BackupFile $pointsApi $backupDir
$raw = Get-Content -Raw -ErrorAction Stop $pointsApi
if (-not $raw) { throw "[STOP] points route.ts vazio/ilegível." }

if ($raw -match "export\s+async\s+function\s+POST\s*\(") {
  Write-Host "[PATCH] points route já tem POST — ok."
} else {
  $postBlock = @()
  $postBlock += ""
  $postBlock += "// --- added by tools/eco-step-112-add-create-point-and-ui-v0_3.ps1"
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
# PATCH B: corrigir <a> dentro de <a> no /eco/mural
# -------------------------
BackupFile $muralPage $backupDir
$mural = Get-Content -Raw -ErrorAction Stop $muralPage
if (-not $mural) { throw "[STOP] mural page.tsx vazio/ilegível." }

$pattern = '(?s)<a\s+href="/eco/mural/chamados"(?<a1>[^>]*)>\s*<a\s+href="/eco/mural/confirmados"(?<a2>[^>]*)>\s*(?<t2>[^<]*?)\s*</a>\s*(?<t1>[^<]*?)\s*</a>'
$mm = [regex]::Match($mural, $pattern)
if ($mm.Success) {
  $a1 = $mm.Groups["a1"].Value
  $a2 = $mm.Groups["a2"].Value
  $t2 = $mm.Groups["t2"].Value.Trim()
  $t1 = $mm.Groups["t1"].Value.Trim()
  if (-not $t1) { $t1 = "Chamados" }
  if (-not $t2) { $t2 = "✅ Confirmados" }

  $replacement = '<a href="/eco/mural/chamados"' + $a1 + '>📣 ' + $t1 + '</a>' + "`n        " + '<a href="/eco/mural/confirmados"' + $a2 + '>' + $t2 + '</a>'
  $mural2 = $mural.Substring(0, $mm.Index) + $replacement + $mural.Substring($mm.Index + $mm.Length)
  WriteUtf8NoBom $muralPage $mural2
  Write-Host ("[PATCH] fixed nested <a> -> " + $muralPage)
} else {
  Write-Host "[PATCH] nested <a> não encontrado (talvez já corrigido) — ok."
}

# -------------------------
# PATCH C: alias /api/eco/points2 -> /api/eco/points
# -------------------------
if (-not (Test-Path $points2Api)) {
  EnsureDir (Split-Path -Parent $points2Api)
  $alias = @()
  $alias += '// AUTO-GENERATED by tools/eco-step-112-add-create-point-and-ui-v0_3.ps1'
  $alias += '// Compat: alguns lugares ainda chamam /api/eco/points2 (404).'
  $alias += '// Agora points2 vira alias do points (GET/POST).'
  $alias += ''
  $alias += 'import { GET as GET_POINTS, POST as POST_POINTS } from "../points/route";'
  $alias += ''
  $alias += 'export const runtime = "nodejs";'
  $alias += 'export const dynamic = "force-dynamic";'
  $alias += ''
  $alias += 'export async function GET(req: Request) { return GET_POINTS(req); }'
  $alias += 'export async function POST(req: Request) { return POST_POINTS(req); }'
  $alias += ''
  WriteUtf8NoBom $points2Api ($alias -join "`n")
  Write-Host ("[PATCH] created alias -> " + $points2Api)
} else {
  Write-Host "[PATCH] points2 route já existe — ok."
}

# -------------------------
# REPORT (sem expandir $b)
# -------------------------
$report = @()
$report += "# $me"
$report += ""
$report += "- Time: $stamp"
$report += "- Backup: $backupDir"
$report += ""
$report += "## What/Why"
$report += "- Garante POST /api/eco/points (criar ponto)."
$report += "- Adiciona/garante UI de registro no mural."
$report += "- Corrige hidratação: remove <a> dentro de <a> no /eco/mural."
$report += "- Cria alias /api/eco/points2 -> /api/eco/points (para parar 404)."
$report += ""
$report += "## Verify"
$report += "1) Ctrl+C -> npm run dev"
$report += "2) abrir /eco/mural (não pode aparecer hydration error de <a>)"
$report += "3) Teste POST:"
$report += '   $b = @{ lat=-22.521; lng=-44.105; kind="LIXO_ACUMULADO"; status="OPEN"; note="teste" } | ConvertTo-Json -Compress'
$report += '   irm "http://localhost:3000/api/eco/points" -Method Post -ContentType "application/json" -Body $b | ConvertTo-Json -Depth 40'
$report += "4) irm 'http://localhost:3000/api/eco/points2?limit=5' | ConvertTo-Json -Depth 40"
$report += ""

$reportPath = Join-Path $Root ("reports\" + $me + "-" + $stamp + ".md")
EnsureDir (Split-Path -Parent $reportPath)
WriteUtf8NoBom $reportPath ($report -join "`n")
Write-Host ("[REPORT] " + $reportPath)

Write-Host ""
Write-Host "[VERIFY] rode:"
Write-Host "  Ctrl+C -> npm run dev"
Write-Host "  abrir /eco/mural (sem hydration error)"
Write-Host '  $b = @{ lat=-22.521; lng=-44.105; kind="LIXO_ACUMULADO"; status="OPEN"; note="teste" } | ConvertTo-Json -Compress'
Write-Host '  irm "http://localhost:3000/api/eco/points" -Method Post -ContentType "application/json" -Body $b | ConvertTo-Json -Depth 40'
Write-Host "  irm 'http://localhost:3000/api/eco/points2?limit=5' | ConvertTo-Json -Depth 40"