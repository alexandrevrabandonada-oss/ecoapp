param([switch]$OpenReport)

$ErrorActionPreference = "Stop"

function EnsureDir([string]$p){
  if(!(Test-Path $p)){
    New-Item -ItemType Directory -Force -Path $p | Out-Null
  }
}

function WriteUtf8NoBom([string]$path, [string]$content){
  [IO.File]::WriteAllText($path, $content, [Text.UTF8Encoding]::new($false))
}

function NowStamp(){
  return (Get-Date).ToString('yyyyMMdd-HHmmss')
}

if (!(Test-Path 'package.json')) {
  throw 'Rode na raiz do repo (onde tem package.json).'
}

$stamp = NowStamp
EnsureDir 'reports'
$reportPath = Join-Path 'reports' ('eco-step-147-contract-snapshot-' + $stamp + '.md')
$nl = [Environment]::NewLine

# ---- DB info
$envPath = '.env'
$dbUrl = ''
if (Test-Path $envPath) {
  $envTxt = Get-Content $envPath -Raw
  $m = [regex]::Match($envTxt, '(?m)^\s*DATABASE_URL\s*=\s*(.+)\s*$')
  if ($m.Success) { $dbUrl = $m.Groups[1].Value.Trim() }
}

$dbFile = Join-Path 'prisma' 'dev.db'
$dbExists = Test-Path $dbFile

# ---- Routes scan
$ecoPages = @()
if (Test-Path 'src\app\eco') {
  $ecoPages = Get-ChildItem -Recurse -File 'src\app\eco' |
    Where-Object { $_.Name -eq 'page.tsx' } |
    Select-Object -ExpandProperty FullName
}

$ecoApi = @()
if (Test-Path 'src\app\api\eco') {
  $ecoApi = Get-ChildItem -Recurse -File 'src\app\api\eco' |
    Where-Object { $_.Name -match '^route\.tsx?$' } |
    Select-Object -ExpandProperty FullName
}

# ---- Get real IDs via Prisma (best-effort)
$ids = @{ pointId = ''; mutiraoId = ''; dayCloseId = '' }

$tmpJs = Join-Path $env:TEMP ('eco-step-147-' + $stamp + '.js')
$jsLines = @(
  'const { PrismaClient } = require("@prisma/client");',
  'const p = new PrismaClient();',
  '(async () => {',
  '  const out = { pointId:"", mutiraoId:"", dayCloseId:"" };',
  '  try { const cp = await p.ecoCriticalPoint.findFirst({ select:{ id:true }, orderBy:{ createdAt:"desc" } }); if (cp) out.pointId = cp.id; } catch(e) {}',
  '  try { const m  = await p.ecoMutirao.findFirst({ select:{ id:true }, orderBy:{ createdAt:"desc" } }); if (m) out.mutiraoId = m.id; } catch(e) {}',
  '  try { const d  = await p.ecoDayClose.findFirst({ select:{ id:true }, orderBy:{ day:"desc" } }); if (d) out.dayCloseId = d.id; } catch(e) {}',
  '  process.stdout.write(JSON.stringify(out));',
  '  await p.$disconnect();',
  '})();'
)

try {
  [IO.File]::WriteAllText($tmpJs, ($jsLines -join $nl), [Text.UTF8Encoding]::new($false))
  $json = node $tmpJs 2>$null
  if ($json) {
    $o = $json | ConvertFrom-Json
    if ($o.pointId)    { $ids.pointId = [string]$o.pointId }
    if ($o.mutiraoId)  { $ids.mutiraoId = [string]$o.mutiraoId }
    if ($o.dayCloseId) { $ids.dayCloseId = [string]$o.dayCloseId }
  }
} catch {
  # ignore
} finally {
  Remove-Item $tmpJs -Force -ErrorAction SilentlyContinue
}

# ---- HTTP snapshot (best-effort)
function TryGetJson([string]$url) {
  try {
    return (Invoke-RestMethod -Uri $url -Headers @{ Accept = 'application/json' })
  } catch {
    return @{ _error = ($_.Exception.Message) }
  }
}

$base = 'http://localhost:3000'
$targets = @(
  @{ name='points_list'; url=($base + '/api/eco/points/list') },
  @{ name='points_list2'; url=($base + '/api/eco/points/list2') },
  @{ name='points2'; url=($base + '/api/eco/points2') },
  @{ name='points_map'; url=($base + '/api/eco/points/map') },
  @{ name='points_stats'; url=($base + '/api/eco/points/stats') },
  @{ name='mural_list'; url=($base + '/api/eco/mural/list') },
  @{ name='mutirao_list'; url=($base + '/api/eco/mutirao/list') },
  @{ name='day_close_list'; url=($base + '/api/eco/day-close/list') },
  @{ name='month_close_list'; url=($base + '/api/eco/month-close/list') }
)

if ($ids.pointId) {
  $targets += @{ name='points_get'; url=($base + '/api/eco/points/get?id=' + $ids.pointId) }
  $targets += @{ name='point_detail'; url=($base + '/api/eco/point/detail?id=' + $ids.pointId) }
}
if ($ids.mutiraoId) {
  $targets += @{ name='mutirao_get'; url=($base + '/api/eco/mutirao/get?id=' + $ids.mutiraoId) }
}

$snap = @{}
foreach ($t in $targets) {
  $snap[$t.name] = TryGetJson $t.url
}

# ---- Report
$r = @()
$r += ('# eco-step-147 - contract snapshot - ' + $stamp)
$r += ''
$r += '## DB'
$r += ('- DATABASE_URL: ' + ($(if($dbUrl){$dbUrl}else{'(nao detectado)'})))
$r += ('- prisma/dev.db exists: ' + $dbExists)
$r += ''
$r += '## IDs (best-effort via Prisma)'
$r += ('- pointId: ' + ($(if($ids.pointId){$ids.pointId}else{'(vazio)'})))
$r += ('- mutiraoId: ' + ($(if($ids.mutiraoId){$ids.mutiraoId}else{'(vazio)'})))
$r += ('- dayCloseId: ' + ($(if($ids.dayCloseId){$ids.dayCloseId}else{'(vazio)'})))
$r += ''
$r += '## Pages (/eco)'
$r += ('- count: ' + $ecoPages.Count)
foreach ($p in $ecoPages) { $r += ('- ' + $p) }
$r += ''
$r += '## API routes (/api/eco)'
$r += ('- count: ' + $ecoApi.Count)
foreach ($p in $ecoApi) { $r += ('- ' + $p) }
$r += ''
$r += '## HTTP snapshots (best-effort)'
foreach ($k in $snap.Keys) {
  $r += ''
  $r += ('### ' + $k)
  $r += '```json'
  try { $r += ($snap[$k] | ConvertTo-Json -Depth 20) } catch { $r += '{"_error":"serialize_failed"}' }
  $r += '```'
}

WriteUtf8NoBom $reportPath ($r -join $nl)
Write-Host '[REPORT]' $reportPath

if ($OpenReport) {
  try { Start-Process $reportPath | Out-Null } catch {}
}
