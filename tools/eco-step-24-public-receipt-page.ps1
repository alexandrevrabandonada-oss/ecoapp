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
  if(!(Test-Path -LiteralPath $root)){ return $null }
  $f = Get-ChildItem -Recurse -File -Path $root -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -match $pattern } |
    Select-Object -First 1
  if($f){ return $f.FullName }
  return $null
}
function DetectModelField([string[]]$lines, [string]$modelName, [string[]]$candidates){
  $start = -1
  for($i=0; $i -lt $lines.Count; $i++){
    if($lines[$i] -match "^\s*model\s+$modelName\s*\{"){ $start = $i; break }
  }
  if($start -lt 0){ return $null }
  $end = -1
  for($j=$start+1; $j -lt $lines.Count; $j++){
    if($lines[$j] -match "^\s*\}\s*$"){ $end = $j; break }
  }
  if($end -lt 0){ return $null }

  $found = @{}
  for($k=$start; $k -le $end; $k++){
    $line = $lines[$k].Trim()
    if($line -match "^\s*([A-Za-z_][A-Za-z0-9_]*)\b"){
      $fname = $Matches[1]
      $found[$fname] = $true
    }
  }
  foreach($c in $candidates){
    if($found.ContainsKey($c)){ return $c }
  }
  return $null
}

$rep = NewReport "eco-step-24-public-receipt-page"
$log = @()
$log += "# ECO — STEP 24 — Página pública do Recibo (/r/[code])"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

# --- DIAG (schema) ---
$schema = "prisma/schema.prisma"
if(!(Test-Path -LiteralPath $schema)){ $schema = FindFirst "." "\\prisma\\schema\.prisma$" }

$receiptCodeField = "code"
$receiptPublicField = "public"

if($schema -and (Test-Path -LiteralPath $schema)){
  $lines = Get-Content -LiteralPath $schema
  $fCode = (DetectModelField $lines "Receipt" @("code","shareCode","publicCode","slug","id"))
  if($fCode){ $receiptCodeField = $fCode }
  $fPub = (DetectModelField $lines "Receipt" @("public","isPublic"))
  if($fPub){ $receiptPublicField = $fPub }
}

$log += "## DIAG"
$log += ("schema: {0}" -f ($schema ? $schema : "(não achei)"))
$log += ("Receipt code field  : {0}" -f $receiptCodeField)
$log += ("Receipt public field: {0}" -f $receiptPublicField)
$log += ""

# --- PATCH ---
$root = "src/app/r/[code]"
$page = Join-Path $root "page.tsx"
$nf   = Join-Path $root "not-found.tsx"

$log += "## PATCH"
if(Test-Path -LiteralPath $page){
  $log += ("- INFO: já existe: {0} (skip)" -f $page)
} else {
  EnsureDir $root

  $pageTsx = @"
import { notFound } from 'next/navigation';
import { PrismaClient } from '@prisma/client';

export const runtime = 'nodejs';

const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };
const prisma = globalForPrisma.prisma ?? new PrismaClient();
if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma;

type Params = { code: string };

export default async function PublicReceiptPage({ params }: { params: Promise<Params> }) {
  const { code } = await params;

  const receipt = await (prisma as any).receipt.findUnique({
    where: { $receiptCodeField: code },
  });

  if (!receipt) return notFound();

  const isPublic = (receipt as any)['$receiptPublicField'] === true;
  if (!isPublic) return notFound();

  return (
    <main style={{ maxWidth: 860, margin: '0 auto', padding: 16 }}>
      <h1 style={{ fontSize: 22, fontWeight: 800 }}>Recibo ECO</h1>
      <p style={{ opacity: 0.8, marginTop: 6 }}>
        Código: <strong>{code}</strong>
      </p>

      <div style={{ marginTop: 16, border: '1px solid rgba(0,0,0,0.12)', borderRadius: 12, padding: 12 }}>
        <p style={{ fontWeight: 700, marginBottom: 8 }}>Resumo (MVP)</p>
        <pre style={{ whiteSpace: 'pre-wrap', wordBreak: 'break-word', margin: 0 }}>
{JSON.stringify(receipt, null, 2)}
        </pre>
      </div>

      <div style={{ marginTop: 18, opacity: 0.85, fontSize: 13 }}>
        <p style={{ margin: 0 }}>
          #ÉLUTA — Escutar • Cuidar • Organizar
        </p>
      </div>
    </main>
  );
}
"@

  # substitui placeholders (sem template literal)
  $pageTsx = $pageTsx.Replace('$receiptCodeField', $receiptCodeField)
  $pageTsx = $pageTsx.Replace('$receiptPublicField', $receiptPublicField)

  WriteUtf8NoBom $page $pageTsx
  $log += ("- OK: criado {0}" -f $page)
}

if(Test-Path -LiteralPath $nf){
  $log += ("- INFO: já existe: {0} (skip)" -f $nf)
} else {
  $nfTsx = @"
export default function NotFound() {
  return (
    <main style={{ maxWidth: 860, margin: '0 auto', padding: 16 }}>
      <h1 style={{ fontSize: 22, fontWeight: 800 }}>Recibo não disponível</h1>
      <p style={{ marginTop: 8, opacity: 0.85 }}>
        Esse recibo não existe ou não está público.
      </p>
      <p style={{ marginTop: 16, opacity: 0.85 }}>
        #ÉLUTA — Escutar • Cuidar • Organizar
      </p>
    </main>
  );
}
"@
  WriteUtf8NoBom $nf $nfTsx
  $log += ("- OK: criado {0}" -f $nf)
}

$log += ""
$log += "## VERIFY"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1"
$log += "3) Pegue um recibo com public=true e abra: http://localhost:3000/r/<CODE>"
$log += "4) Aba anônima também deve abrir (sem token)."
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 24 aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) Teste /r/<CODE> com recibo público (aba normal e anônima)" -ForegroundColor Yellow