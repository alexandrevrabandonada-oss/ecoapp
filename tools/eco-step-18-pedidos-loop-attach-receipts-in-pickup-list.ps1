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

$rep = NewReport "eco-step-18-pedidos-loop-attach-receipts-in-pickup-list"
$log = @()
$log += "# ECO — STEP 18 — /pedidos: lista já traz recibo (receipt/receiptCode) via /api/pickup-requests"
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
# PATCH (backup)
# =========
$log += "## PATCH"
$log += ("Backup API pickups: {0}" -f (BackupFile $apiPickups))
if($pedidosPage){ $log += ("Backup Pedidos    : {0}" -f (BackupFile $pedidosPage)) }
$log += ""

# =========
# PATCH: /api/pickup-requests — anexar recibos por requestId (sem depender de relation include)
# =========
$txt = Get-Content -LiteralPath $apiPickups -Raw

if($txt -match "attachReceipts\(" -or $txt -match "receiptCode"){
  $log += "- INFO: /api/pickup-requests já parece anexar receipt/receiptCode (skip)."
} else {
  $needleGet = "export async function GET"
  $idx = $txt.IndexOf($needleGet)
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

  # injeta helper logo antes do GET
  $txt2 = $txt.Substring(0, $idx) + $helper + $txt.Substring($idx)

  $didReplace = $false

  # caso 1: return NextResponse.json({ items });
  $pattern1 = "return\s+NextResponse\.json\(\s*\{\s*items\s*\}\s*\)\s*;"
  if($txt2 -match $pattern1){
    $txt2 = [regex]::Replace($txt2, $pattern1, 'const items2 = await attachReceiptsToPickupList(items as any[]); return NextResponse.json({ items: items2 });', 1)
    $didReplace = $true
  }

  # caso 2: return NextResponse.json({ items: items });
  if(-not $didReplace){
    $pattern2 = "return\s+NextResponse\.json\(\s*\{\s*items\s*:\s*items\s*\}\s*\)\s*;"
    if($txt2 -match $pattern2){
      $txt2 = [regex]::Replace($txt2, $pattern2, 'const items2 = await attachReceiptsToPickupList(items as any[]); return NextResponse.json({ items: items2 });', 1)
      $didReplace = $true
    }
  }

  # caso 3: return NextResponse.json({ ok: true, items });
  if(-not $didReplace){
    $pattern3 = "return\s+NextResponse\.json\(\s*\{\s*ok\s*:\s*true\s*,\s*items\s*\}\s*\)\s*;"
    if($txt2 -match $pattern3){
      $txt2 = [regex]::Replace($txt2, $pattern3, 'const items2 = await attachReceiptsToPickupList(items as any[]); return NextResponse.json({ ok: true, items: items2 });', 1)
      $didReplace = $true
    }
  }

  # caso 4: return NextResponse.json({ ok: true, items: items });
  if(-not $didReplace){
    $pattern4 = "return\s+NextResponse\.json\(\s*\{\s*ok\s*:\s*true\s*,\s*items\s*:\s*items\s*\}\s*\)\s*;"
    if($txt2 -match $pattern4){
      $txt2 = [regex]::Replace($txt2, $pattern4, 'const items2 = await attachReceiptsToPickupList(items as any[]); return NextResponse.json({ ok: true, items: items2 });', 1)
      $didReplace = $true
    }
  }

  if(-not $didReplace){
    throw "Não consegui achar um return NextResponse.json(...) com 'items' em /api/pickup-requests para injetar attachReceipts."
  }

  WriteUtf8NoBom $apiPickups $txt2
  $log += "- OK: /api/pickup-requests agora retorna receipt + receiptCode por item (quando existir)."
}

# =========
# PATCH: /pedidos — garantir fetch sem cache (best effort)
# =========
if($pedidosPage){
  $p = Get-Content -LiteralPath $pedidosPage -Raw
  if($p -match "fetch\((['`""])/api/pickup-requests\1\s*,\s*\{"){
    $log += "- INFO: /pedidos já parece usar fetch com options (skip no-store)."
  } elseif($p -match "fetch\((['`""])/api/pickup-requests\1\)"){
    $p2 = [regex]::Replace($p, "fetch\((['`""])/api/pickup-requests\1\)", "fetch('/api/pickup-requests', { cache: 'no-store' })", 1)
    WriteUtf8NoBom $pedidosPage $p2
    $log += "- OK: /pedidos agora busca /api/pickup-requests com cache: 'no-store'."
  } else {
    $log += "- WARN: Não encontrei fetch('/api/pickup-requests') em /pedidos para setar no-store (ok)."
  }
}

# =========
# REGISTRO
# =========
$log += ""
$log += "## Como testar"
$log += "1) /pedidos: em cada linha deve aparecer 'Fechar / Emitir recibo'"
$log += "2) Clique Fechar -> emitir"
$log += "3) Volte em /pedidos: deve aparecer 'Ver recibo' na linha (com receipt/receiptCode)"
$log += "4) Se o recibo estiver PRIVADO e ECO_OPERATOR_TOKEN setado: operador vê; anônimo não."
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 18 aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) Teste /pedidos -> Fechar -> emitir -> voltar e ver 'Ver recibo' na linha" -ForegroundColor Yellow