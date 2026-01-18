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

$rep = NewReport "eco-step-07e2-add-fechar-on-sucesso"
$log = @()
$log += "# ECO — STEP 07e2 — Botão Fechar/Emitir recibo na tela de sucesso"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

# acha a página de sucesso
$candidates = @(
  "src/app/chamar/sucesso/page.tsx",
  "src/app/chamar-coleta/sucesso/page.tsx"
)

$target = $null
foreach($c in $candidates){
  if(Test-Path -LiteralPath $c){ $target = $c; break }
}

if(-not $target){
  $found = Get-ChildItem -Recurse -File -Path "src/app" -Filter "page.tsx" |
    Where-Object { $_.FullName -match "\\chamar" -and $_.FullName -match "\\sucesso" } |
    Select-Object -First 1
  if($found){ $target = $found.FullName }
}

if(-not $target){
  throw "Não achei a página de sucesso. Procurei em src/app/chamar/sucesso/page.tsx e similares."
}

$bak = BackupFile $target

$log += "## DIAG"
$log += ("Target: " + $target)
$log += ("Backup: " + $bak)
$log += ""

# conteúdo do page.tsx (botão só aparece quando houver ?id=...)
$tsx = @"
import Link from "next/link";

export const runtime = "nodejs";

export default async function ChamarSucessoPage({ searchParams }: { searchParams: any }) {
  const sp = await Promise.resolve(searchParams);
  const id = typeof sp?.id === "string" ? sp.id : "";
  const closeHref = id ? "/pedidos/fechar/" + encodeURIComponent(id) : null;

  return (
    <main className="p-4 max-w-2xl mx-auto">
      <div className="rounded border p-4 space-y-3">
        <div className="flex items-center gap-2">
          <span className="inline-block h-2 w-2 rounded-full bg-green-500" />
          <h1 className="text-2xl font-bold">Pedido enviado</h1>
        </div>

        <p className="text-sm opacity-80">Registrado</p>

        {id ? (
          <div className="text-xs opacity-80 space-y-1">
            <p>Se precisar, guarde esse id:</p>
            <code className="px-2 py-1 rounded bg-black/5 inline-block break-all">{id}</code>
          </div>
        ) : (
          <p className="text-xs opacity-70">Sem id na URL (adicione ?id=...).</p>
        )}

        <div className="flex flex-wrap gap-2">
          <Link className="px-3 py-2 rounded border" href="/chamar">Fazer outro</Link>
          <Link className="px-3 py-2 rounded border" href="/pedidos">Ver pedidos</Link>

          {closeHref && (
            <Link className="px-3 py-2 rounded bg-black text-white" href={closeHref}>
              Fechar / Emitir recibo
            </Link>
          )}
        </div>

        <p className="text-xs opacity-60">
          Dica: você também pode fechar pelo /pedidos (na linha do pedido).
        </p>
      </div>
    </main>
  );
}
"@

WriteUtf8NoBom $target $tsx

$log += "## PATCH"
$log += "- OK: reescreveu a página de sucesso com botão Fechar/Emitir recibo (quando houver ?id=...)"
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 07e2 aplicado. Target -> {0}" -f $target) -ForegroundColor Green
Write-Host ("Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Envie um pedido em /chamar" -ForegroundColor Yellow
Write-Host "3) Na tela /chamar/sucesso?id=..., clique: Fechar / Emitir recibo" -ForegroundColor Yellow