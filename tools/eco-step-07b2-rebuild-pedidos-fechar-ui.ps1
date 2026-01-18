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

$rep = NewReport "eco-step-07b2-rebuild-pedidos-fechar-ui"
$log = @()
$log += "# ECO — STEP 07b2 — Rebuild UI /pedidos/fechar/[id] (sem Base64, sem here-string aninhado)"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

$targetDir = "src/app/pedidos/fechar/[id]"
$pageFile  = Join-Path $targetDir "page.tsx"
$cliFile   = Join-Path $targetDir "fechar-client.tsx"

$log += "## DIAG (antes)"
$log += ("Exists page.tsx? " + (Test-Path -LiteralPath $pageFile))
$log += ("Exists fechar-client.tsx? " + (Test-Path -LiteralPath $cliFile))
$log += ""

EnsureDir $targetDir
if(Test-Path -LiteralPath $pageFile){ $log += ("Backup page.tsx: " + (BackupFile $pageFile)) }
if(Test-Path -LiteralPath $cliFile){  $log += ("Backup fechar-client.tsx: " + (BackupFile $cliFile)) }

# page.tsx
$pageLines = @(
'import Link from "next/link";'
'import FecharClient from "./fechar-client";'
''
'export const runtime = "nodejs";'
''
'export default async function FecharPedidoPage({ params }: { params: any }) {'
'  const p = await Promise.resolve(params);'
'  const id = p?.id as string;'
''
'  return ('
'    <main className="p-4 max-w-3xl mx-auto space-y-4">'
'      <header className="space-y-2">'
'        <h1 className="text-2xl font-bold">Fechar pedido</h1>'
'        <p className="text-sm opacity-80">'
'          Emite um recibo e (quando suportado) marca o pedido como concluído.'
'        </p>'
'        <div className="flex gap-3">'
'          <Link className="underline" href="/pedidos">← Voltar</Link>'
'          <span className="text-sm opacity-70">ID: {id}</span>'
'        </div>'
'      </header>'
''
'      <FecharClient requestId={id} />'
'    </main>'
'  );'
'}'
)
WriteUtf8NoBom $pageFile ($pageLines -join "`n")

# fechar-client.tsx
$cliLines = @(
'"use client";'
''
'import Link from "next/link";'
'import { useEffect, useMemo, useState } from "react";'
''
'type ApiGetPickup = any;'
'type ApiIssueReceipt = any;'
''
'function pickRequestItem(payload: ApiGetPickup) {'
'  return payload?.item ?? payload?.request ?? payload?.data ?? payload;'
'}'
''
'function prettify(v: any) {'
'  try { return JSON.stringify(v, null, 2); } catch { return String(v); }'
'}'
''
'export default function FecharClient({ requestId }: { requestId: string }) {'
'  const [loading, setLoading] = useState(true);'
'  const [reqData, setReqData] = useState<any>(null);'
'  const [err, setErr] = useState<string | null>(null);'
''
'  const [summary, setSummary] = useState("");'
'  const [items, setItems] = useState("");'
'  const [operator, setOperator] = useState("");'
'  const [isPublic, setIsPublic] = useState(false);'
''
'  const [issuing, setIssuing] = useState(false);'
'  const [issued, setIssued] = useState<any>(null);'
'  const [issueErr, setIssueErr] = useState<string | null>(null);'
''
'  const derivedCode = useMemo(() => {'
'    const r = issued?.receipt ?? issued;'
'    return r?.shareCode ?? r?.code ?? r?.id ?? null;'
'  }, [issued]);'
''
'  useEffect(() => {'
'    let alive = true;'
'    async function run() {'
'      setLoading(true);'
'      setErr(null);'
'      setReqData(null);'
''
'      try {'
'        const res = await fetch(`/api/pickup-requests/${encodeURIComponent(requestId)}`, { cache: "no-store" });'
'        const txt = await res.text();'
'        let json: any = null;'
'        try { json = JSON.parse(txt); } catch { json = { raw: txt }; }'
''
'        if (!res.ok) throw new Error(json?.error ?? `GET pickup-requests falhou (${res.status})`);'
'        if (!alive) return;'
''
'        const item = pickRequestItem(json);'
'        setReqData(item);'
'      } catch (e: any) {'
'        if (!alive) return;'
'        setErr(e?.message ?? String(e));'
'      } finally {'
'        if (!alive) return;'
'        setLoading(false);'
'      }'
'    }'
'    if (requestId) run();'
'    return () => { alive = false; };'
'  }, [requestId]);'
''
'  async function onIssue() {'
'    setIssuing(true);'
'    setIssueErr(null);'
'    setIssued(null);'
'    try {'
'      const body = {'
'        requestId,'
'        summary: summary || null,'
'        items: items || null,'
'        operator: operator || null,'
'        public: !!isPublic,'
'      };'
''
'      const res = await fetch("/api/receipts", {'
'        method: "POST",'
'        headers: { "content-type": "application/json" },'
'        body: JSON.stringify(body),'
'      });'
''
'      const txt = await res.text();'
'      let json: ApiIssueReceipt = null as any;'
'      try { json = JSON.parse(txt); } catch { json = { raw: txt } as any; }'
''
'      if (!res.ok) throw new Error(json?.error ?? `POST /api/receipts falhou (${res.status})`);'
'      setIssued(json);'
'    } catch (e: any) {'
'      setIssueErr(e?.message ?? String(e));'
'    } finally {'
'      setIssuing(false);'
'    }'
'  }'
''
'  return ('
'    <section className="space-y-4">'
'      <div className="rounded border p-3">'
'        <h2 className="font-semibold mb-2">Pedido</h2>'
''
'        {loading && <p className="text-sm opacity-70">Carregando…</p>}'
'        {err && ('
'          <div className="text-sm">'
'            <p className="font-semibold text-red-600">Erro ao carregar pedido</p>'
'            <pre className="whitespace-pre-wrap break-words">{err}</pre>'
'          </div>'
'        )}'
'        {!loading && !err && ('
'          <pre className="text-xs whitespace-pre-wrap break-words max-h-72 overflow-auto bg-black/5 p-2 rounded">'
'            {prettify(reqData)}'
'          </pre>'
'        )}'
'      </div>'
''
'      <div className="rounded border p-3 space-y-3">'
'        <h2 className="font-semibold">Emitir recibo</h2>'
''
'        <label className="block space-y-1">'
'          <span className="text-sm opacity-80">Resumo</span>'
'          <textarea className="w-full border rounded p-2" rows={3} value={summary} onChange={(e) => setSummary(e.target.value)} />'
'        </label>'
''
'        <label className="block space-y-1">'
'          <span className="text-sm opacity-80">Itens / Observações</span>'
'          <textarea className="w-full border rounded p-2" rows={4} value={items} onChange={(e) => setItems(e.target.value)} />'
'        </label>'
''
'        <div className="grid md:grid-cols-2 gap-3">'
'          <label className="block space-y-1">'
'            <span className="text-sm opacity-80">Operador</span>'
'            <input className="w-full border rounded p-2" value={operator} onChange={(e) => setOperator(e.target.value)} />'
'          </label>'
''
'          <label className="flex items-center gap-2 pt-6">'
'            <input type="checkbox" checked={isPublic} onChange={(e) => setIsPublic(e.target.checked)} />'
'            <span className="text-sm">Recibo público (quando suportado)</span>'
'          </label>'
'        </div>'
''
'        <button'
'          onClick={onIssue}'
'          disabled={issuing || !requestId}'
'          className="px-3 py-2 rounded bg-black text-white disabled:opacity-50"'
'        >'
'          {issuing ? "Emitindo…" : "Emitir recibo"}'
'        </button>'
''
'        {issueErr && ('
'          <div className="text-sm">'
'            <p className="font-semibold text-red-600">Falha ao emitir recibo</p>'
'            <pre className="whitespace-pre-wrap break-words">{issueErr}</pre>'
'          </div>'
'        )}'
''
'        {issued && ('
'          <div className="text-sm space-y-2">'
'            <p className="font-semibold text-green-700">Recibo emitido ✅</p>'
''
'            {derivedCode ? ('
'              <div className="flex gap-3 items-center flex-wrap">'
'                <Link className="underline" href={`/recibo/${derivedCode}`}>Ver recibo</Link>'
'                <span className="text-xs opacity-70">code: {derivedCode}</span>'
'              </div>'
'            ) : ('
'              <p className="text-xs opacity-70">Emitido, mas não consegui derivar code (shareCode/code/id).</p>'
'            )}'
''
'            <details>'
'              <summary className="cursor-pointer opacity-80">Resposta completa</summary>'
'              <pre className="text-xs whitespace-pre-wrap break-words max-h-72 overflow-auto bg-black/5 p-2 rounded">'
'                {prettify(issued)}'
'              </pre>'
'            </details>'
'          </div>'
'        )}'
'      </div>'
'    </section>'
'  );'
'}'
)
WriteUtf8NoBom $cliFile ($cliLines -join "`n")

$log += "## PATCH"
$log += "- OK: /pedidos/fechar/[id] criado/atualizado (page.tsx + fechar-client.tsx)"
$log += ""
$log += "## DIAG (depois)"
$log += ("Exists page.tsx? " + (Test-Path -LiteralPath $pageFile))
$log += ("Exists fechar-client.tsx? " + (Test-Path -LiteralPath $cliFile))
$log += ""
WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 07b2 aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) (Terminal A) npm run dev" -ForegroundColor Yellow
Write-Host "2) (Terminal B) pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) Abra /pedidos e clique Fechar/Emitir recibo (ou /pedidos/fechar/SEU_ID)" -ForegroundColor Yellow