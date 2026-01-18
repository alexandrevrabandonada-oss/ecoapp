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

$rep = NewReport "eco-step-07c-backcompat-api-requests"
$log = @()
$log += "# ECO — STEP 07c — Backcompat /api/requests + /pedidos/fechar (sem id)"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

# ==== DIAG: onde existe /api/requests no código? ====
$log += "## DIAG — ocorrências de /api/requests"
$hits = @()
if(Test-Path -LiteralPath "src"){
  $files = Get-ChildItem -Recurse -File src | Where-Object { $_.FullName -match '\.(ts|tsx|js|jsx)$' }
  foreach($f in $files){
    $m = Select-String -LiteralPath $f.FullName -Pattern "/api/requests" -SimpleMatch -ErrorAction SilentlyContinue
    foreach($x in ($m | ForEach-Object { $_ })){
      $hits += ("- {0}:{1} :: {2}" -f ($x.Path -replace '\\','/'), $x.LineNumber, $x.Line.Trim())
    }
  }
}
if($hits.Count -eq 0){
  $log += "- (nenhuma ocorrência em src/)"
} else {
  $log += $hits
}
$log += ""

# ==== PATCH: criar proxies /api/requests -> /api/pickup-requests ====
$pickupRoot = "src/app/api/pickup-requests/route.ts"
$pickupId   = "src/app/api/pickup-requests/[id]/route.ts"

if(!(Test-Path -LiteralPath $pickupRoot)){
  throw "Não achei $pickupRoot (preciso dele para fazer proxy)"
}

$apiRequestsDir = "src/app/api/requests"
$apiRequestsIdDir = "src/app/api/requests/[id]"
EnsureDir $apiRequestsDir
EnsureDir $apiRequestsIdDir

$reqRoot = Join-Path $apiRequestsDir "route.ts"
$reqId   = Join-Path $apiRequestsIdDir "route.ts"

if(Test-Path -LiteralPath $reqRoot){ $log += ("Backup: " + (BackupFile $reqRoot)) }
if(Test-Path -LiteralPath $reqId){  $log += ("Backup: " + (BackupFile $reqId)) }

$rootLines = @(
'import { NextResponse } from "next/server";'
'export const runtime = "nodejs";'
''
'export async function GET(req: Request) {'
'  const mod: any = await import("../pickup-requests/route");'
'  if (typeof mod.GET === "function") return mod.GET(req);'
'  return NextResponse.json({ error: "pickup_requests_get_missing" }, { status: 500 });'
'}'
''
'export async function POST(req: Request) {'
'  const mod: any = await import("../pickup-requests/route");'
'  if (typeof mod.POST === "function") return mod.POST(req);'
'  return NextResponse.json({ error: "pickup_requests_post_missing" }, { status: 500 });'
'}'
)
WriteUtf8NoBom $reqRoot ($rootLines -join "`n")

# proxy /api/requests/[id] se existir o route do pickup-requests/[id]
if(Test-Path -LiteralPath $pickupId){
  $idLines = @(
'import { NextResponse } from "next/server";'
'export const runtime = "nodejs";'
''
'export async function GET(req: Request, ctx: any) {'
'  const mod: any = await import("../../pickup-requests/[id]/route");'
'  if (typeof mod.GET === "function") return mod.GET(req, ctx);'
'  return NextResponse.json({ error: "pickup_requests_id_get_missing" }, { status: 500 });'
'}'
''
'export async function PATCH(req: Request, ctx: any) {'
'  const mod: any = await import("../../pickup-requests/[id]/route");'
'  if (typeof mod.PATCH === "function") return mod.PATCH(req, ctx);'
'  return NextResponse.json({ error: "pickup_requests_id_patch_missing" }, { status: 500 });'
'}'
  )
  WriteUtf8NoBom $reqId ($idLines -join "`n")
  $log += "- OK: criado proxy /api/requests/[id] -> /api/pickup-requests/[id]"
} else {
  $log += "- SKIP: não existe src/app/api/pickup-requests/[id]/route.ts, então não criei /api/requests/[id]"
}

$log += "- OK: criado proxy /api/requests -> /api/pickup-requests"
$log += ""

# ==== PATCH: page amigável /pedidos/fechar (sem id) ====
$fecharIndexDir = "src/app/pedidos/fechar"
EnsureDir $fecharIndexDir
$fecharIndexPage = Join-Path $fecharIndexDir "page.tsx"
if(Test-Path -LiteralPath $fecharIndexPage){ $log += ("Backup: " + (BackupFile $fecharIndexPage)) }

$fecharLines = @(
'import Link from "next/link";'
''
'export const runtime = "nodejs";'
''
'export default function FecharIndex() {'
'  return ('
'    <main className="p-4 max-w-2xl mx-auto space-y-3">'
'      <h1 className="text-2xl font-bold">Fechar pedido</h1>'
'      <p className="text-sm opacity-80">'
'        Faltou o ID do pedido na URL. Volte para a lista de pedidos e clique em “Fechar/Emitir recibo”.'
'      </p>'
'      <Link className="underline" href="/pedidos">← Ir para /pedidos</Link>'
'    </main>'
'  );'
'}'
)
WriteUtf8NoBom $fecharIndexPage ($fecharLines -join "`n")
$log += "- OK: criado /pedidos/fechar (page.tsx) amigável"
$log += ""

# ==== DIAG depois ====
$log += "## DIAG (depois)"
$log += ("Exists /api/requests route? " + (Test-Path -LiteralPath $reqRoot))
$log += ("Exists /api/requests/[id] route? " + (Test-Path -LiteralPath $reqId))
$log += ("Exists /pedidos/fechar page? " + (Test-Path -LiteralPath $fecharIndexPage))
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 07c aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) Abra /pedidos -> Fechar/Emitir recibo" -ForegroundColor Yellow
Write-Host "4) Opcional: teste /api/requests (deve responder igual /api/pickup-requests)" -ForegroundColor Yellow