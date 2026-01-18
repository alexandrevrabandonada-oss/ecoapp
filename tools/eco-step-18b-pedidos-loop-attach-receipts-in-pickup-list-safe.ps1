$ErrorActionPreference = "Stop"

function EnsureDir([string]$p){
  if($p -and !(Test-Path -LiteralPath $p)){
    New-Item -ItemType Directory -Force -Path $p | Out-Null
  }
}
function WriteUtf8NoBom([string]$path, [string]$content){
  $dir = Split-Path -Parent $path
  if($dir){ EnsureDir $dir }
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
}
function BackupFile([string]$path){
  if(!(Test-Path -LiteralPath $path)){ return $null }
  EnsureDir "tools/_patch_backup"
  $ts = Get-Date -Format "yyyyMMdd-HHmmss"
  $safe = ($path -replace '[\\/:*?"<>|]', '_')
  $dst = "tools/_patch_backup/$ts-$safe"
  Copy-Item -Force -LiteralPath $path $dst
  return $dst
}
function NewReport([string]$name){
  EnsureDir "reports"
  $ts = Get-Date -Format "yyyyMMdd-HHmmss"
  return "reports/$ts-$name.md"
}
function FindFirst([string]$root, [string]$pattern){
  $f = Get-ChildItem -Recurse -File -Path $root -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -match $pattern } |
    Select-Object -First 1
  if($f){ return $f.FullName }
  return $null
}

$rep = NewReport "eco-step-18b-pedidos-loop-attach-receipts-in-pickup-list-safe"
$log = @()
$log += "# ECO — STEP 18b — /pedidos: /api/pickup-requests lista já traz receipt + receiptCode"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

# =========
# DIAG
# =========
$apiPickups = "src/app/api/pickup-requests/route.ts"
if(!(Test-Path -LiteralPath $apiPickups)){
  $apiPickups = FindFirst "src/app" "\\api\\pickup-requests\\route\.ts$"
}
if(-not $apiPickups){ throw "Não achei /api/pickup-requests/route.ts" }

$pedidosPage = "src/app/pedidos/page.tsx"
if(!(Test-Path -LiteralPath $pedidosPage)){
  $pedidosPage = FindFirst "src/app" "\\pedidos\\page\.tsx$"
}

$log += "## DIAG"
$log += ("API pickup-requests: {0}" -f $apiPickups)
$log += ("Pedidos page      : {0}" -f ($pedidosPage ?? "(não achei; ok)"))
$log += ""

# =========
# BACKUP
# =========
$log += "## PATCH"
$log += ("Backup API pickups: {0}" -f (BackupFile $apiPickups))
if($pedidosPage){ $log += ("Backup Pedidos    : {0}" -f (BackupFile $pedidosPage)) }
$log += ""

# =========
# PATCH: /api/pickup-requests
# =========
$txt = Get-Content -LiteralPath $apiPickups -Raw

if($txt -match "attachReceiptsToPickupList" -or $txt -match "receiptCode"){
  $log += "- INFO: /api/pickup-requests já parece anexar receipt/receiptCode (skip)."
} else {

  $needle = "export async function GET"
  $idx = $txt.IndexOf($needle)
  if($idx -lt 0){ throw "Não achei 'export async function GET' em /api/pickup-requests." }

  $helper = @"
async function attachReceiptsToPickupList(items: any[]) {
  const safeItems = Array.isArray(items) ? items : [];
  const ids = safeItems.map((i: any) => i?.id).filter(Boolean);

  if (!ids.length) {
    return safeItems.map((it: any) => ({ ...it, receipt: it?.receipt ?? null, receiptCode: null }));
  }

  let receipts: any[] = [];
  try {
    receipts = await (prisma as any).receipt.findMany({
      where: { requestId: { in: ids } },
      orderBy: { createdAt: "desc" },
    });
  } catch {
    receipts = [];
  }

  const byReq = new Map<string, any>();
  for (const r of receipts) {
    const rid = (r as any)?.requestId;
    if (rid && !byReq.has(rid)) byReq.set(rid, r);
  }

  return safeItems.map((it: any) => {
    const r = it?.receipt ?? byReq.get(it?.id) ?? null;
    const code = r ? ((r as any).shareCode ?? (r as any).code ?? (r as any).id ?? null) : null;
    return { ...it, receipt: r, receiptCode: code };
  });
}

"@

  $txt2 = $txt.Substring(0, $idx) + $helper + $txt.Substring($idx)

  $did = $false

  # Substituições seguras (sem regex com aspas malucas)
  $patterns = @(
    @{ p = 'return\s+NextResponse\.json\(\s*\{\s*items\s*\}\s*\)\s*;'; r = 'const items2 = await attachReceiptsToPickupList(items as any[]); return NextResponse.json({ items: items2 });' },
    @{ p = 'return\s+NextResponse\.json\(\s*\{\s*items\s*:\s*items\s*\}\s*\)\s*;'; r = 'const items2 = await attachReceiptsToPickupList(items as any[]); return NextResponse.json({ items: items2 });' },
    @{ p = 'return\s+NextResponse\.json\(\s*\{\s*ok\s*:\s*true\s*,\s*items\s*\}\s*\)\s*;'; r = 'const items2 = await attachReceiptsToPickupList(items as any[]); return NextResponse.json({ ok: true, items: items2 });' },
    @{ p = 'return\s+NextResponse\.json\(\s*\{\s*ok\s*:\s*true\s*,\s*items\s*:\s*items\s*\}\s*\)\s*;'; r = 'const items2 = await attachReceiptsToPickupList(items as any[]); return NextResponse.json({ ok: true, items: items2 });' }
  )

  foreach($it in $patterns){
    if(-not $did -and [regex]::IsMatch($txt2, $it.p)){
      $txt2 = [regex]::Replace($txt2, $it.p, $it.r, 1)
      $did = $true
    }
  }

  if(-not $did){
    throw "Não consegui achar um return NextResponse.json(...) com 'items' em /api/pickup-requests para injetar attachReceipts."
  }

  WriteUtf8NoBom $apiPickups $txt2
  $log += "- OK: /api/pickup-requests agora retorna receipt + receiptCode por item (quando existir)."
}

# =========
# PATCH: /pedidos (best effort, sem regex perigoso)
# =========
if($pedidosPage){
  $p = Get-Content -LiteralPath $pedidosPage -Raw

  if($p.Contains("cache: 'no-store'") -or $p.Contains('cache: "no-store"')){
    $log += "- INFO: /pedidos já usa no-store em algum fetch (skip)."
  } elseif($p.Contains("fetch('/api/pickup-requests')")){
    $p2 = $p.Replace("fetch('/api/pickup-requests')", "fetch('/api/pickup-requests', { cache: 'no-store' })")
    WriteUtf8NoBom $pedidosPage $p2
    $log += "- OK: /pedidos agora usa fetch('/api/pickup-requests', { cache: 'no-store' })."
  } elseif($p.Contains('fetch("/api/pickup-requests")')){
    $p2 = $p.Replace('fetch("/api/pickup-requests")', 'fetch("/api/pickup-requests", { cache: "no-store" })')
    WriteUtf8NoBom $pedidosPage $p2
    $log += "- OK: /pedidos agora usa fetch(\"/api/pickup-requests\", { cache: \"no-store\" })."
  } else {
    $log += "- WARN: Não encontrei fetch direto de /api/pickup-requests em /pedidos para ajustar no-store (ok)."
  }
}

# =========
# REGISTRO
# =========
$log += ""
$log += "## Próximos passos"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1"
$log += "3) Teste /pedidos -> Fechar -> emitir -> voltar e ver 'Ver recibo' na linha"
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 18b aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) Teste /pedidos -> Fechar -> emitir -> voltar e ver 'Ver recibo' na linha" -ForegroundColor Yellow