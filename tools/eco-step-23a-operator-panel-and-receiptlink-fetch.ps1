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

$rep = NewReport "eco-step-23a-operator-panel-and-receiptlink-fetch"
$log = @()
$log += "# ECO — STEP 23a — /operador (token) + ReceiptLink busca code via API"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

# Paths
$receiptLink = "src/components/eco/ReceiptLink.tsx"
if(!(Test-Path -LiteralPath $receiptLink)){
  $receiptLink = FindFirst "." "\\src\\components\\eco\\ReceiptLink\.tsx$"
}
$operadorPage = "src/app/operador/page.tsx"
if(!(Test-Path -LiteralPath $operadorPage)){
  $operadorPage = "src/app/operador/page.tsx"
}
$apiReceipt = "src/app/api/pickup-requests/[id]/receipt/route.ts"

# Detect localStorage key from existing ReceiptLink (fallback)
$tokenKey = "eco_operator_token"
if($receiptLink -and (Test-Path -LiteralPath $receiptLink)){
  $txt0 = Get-Content -LiteralPath $receiptLink -Raw
  $m = [regex]::Match($txt0, "localStorage\.getItem\(\s*['""]([^'""]+)['""]\s*\)")
  if($m.Success){ $tokenKey = $m.Groups[1].Value }
}

$log += "## DIAG"
$log += ("ReceiptLink.tsx: {0}" -f ($receiptLink ? $receiptLink : "(não achei)"))
$log += ("Token localStorage key (detectado): {0}" -f $tokenKey)
$log += ("Operador page: {0}" -f $operadorPage)
$log += ("API receipt endpoint: {0}" -f $apiReceipt)
$log += ""

$log += "## PATCH"
# 1) /operador page (UI pra setar/limpar token)
EnsureDir (Split-Path -Parent $operadorPage)
$bk1 = BackupFile $operadorPage
$log += ("- Backup /operador: {0}" -f ($bk1 ? $bk1 : "(novo)"))

$operadorTsx = @"
'use client';

import { useEffect, useMemo, useState } from 'react';

const LS_KEY = '$tokenKey';

function safeGet(): string | null {
  try { return localStorage.getItem(LS_KEY); } catch { return null; }
}
function safeSet(v: string) {
  try { localStorage.setItem(LS_KEY, v); } catch {}
}
function safeDel() {
  try { localStorage.removeItem(LS_KEY); } catch {}
}

export default function OperadorPage() {
  const [current, setCurrent] = useState<string | null>(null);
  const [value, setValue] = useState('');

  useEffect(() => {
    const t = safeGet();
    setCurrent(t);
    setValue(t ?? '');
  }, []);

  const status = useMemo(() => {
    if (!current) return 'Sem token salvo';
    if (current.length < 8) return 'Token salvo (curto — confira)';
    return 'Token salvo';
  }, [current]);

  return (
    <main className="mx-auto max-w-2xl p-4">
      <h1 className="text-2xl font-bold">Operador ECO</h1>
      <p className="mt-2 text-sm opacity-80">
        Este token fica no <code>localStorage</code> (chave: <code>{LS_KEY}</code>).
        Use só em ambiente controlado. Depois, abra <code>/pedidos</code> e veja o link <b>Ver recibo</b>.
      </p>

      <div className="mt-4 rounded-xl border p-4">
        <div className="text-sm"><b>Status:</b> {status}</div>

        <label className="mt-3 block text-sm font-semibold">Token</label>
        <input
          className="mt-1 w-full rounded-lg border px-3 py-2 font-mono text-sm"
          value={value}
          onChange={(e) => setValue(e.target.value)}
          placeholder="cole aqui o ECO_OPERATOR_TOKEN"
        />

        <div className="mt-3 flex flex-wrap gap-2">
          <button
            className="rounded-lg bg-black px-4 py-2 text-white"
            onClick={() => {
              const v = value.trim();
              if (!v) return;
              safeSet(v);
              setCurrent(v);
            }}
          >
            Salvar token
          </button>

          <button
            className="rounded-lg border px-4 py-2"
            onClick={() => {
              safeDel();
              setCurrent(null);
              setValue('');
            }}
          >
            Limpar token
          </button>

          <a className="rounded-lg border px-4 py-2" href="/pedidos">
            Ir para /pedidos
          </a>
        </div>
      </div>

      <div className="mt-4 rounded-xl border p-4 text-sm">
        <b>Teste rápido</b>
        <ol className="mt-2 list-decimal pl-5">
          <li>Abra <code>/pedidos</code> numa aba normal (com token) e veja se aparece <b>Ver recibo</b>.</li>
          <li>Abra uma aba anônima e confirme que o link some.</li>
        </ol>
      </div>
    </main>
  );
}
"@

WriteUtf8NoBom $operadorPage $operadorTsx
$log += "- OK: /operador criado/atualizado."

# 2) API: /api/pickup-requests/[id]/receipt (retorna {code, public} com token)
EnsureDir (Split-Path -Parent $apiReceipt)
$bk2 = BackupFile $apiReceipt
$log += ("- Backup API receipt: {0}" -f ($bk2 ? $bk2 : "(novo)"))

$apiTs = @"
import { NextResponse } from 'next/server';
import { PrismaClient } from '@prisma/client';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

const prisma = new PrismaClient();

function ecoGetToken(req: Request): string | null {
  const h = req.headers.get('x-eco-token') ?? req.headers.get('authorization') ?? '';
  if (h.startsWith('Bearer ')) return h.slice(7).trim();
  if (h && !h.includes(' ')) return h.trim();
  return null;
}

function ecoIsOperator(req: Request): boolean {
  const token = ecoGetToken(req);
  const expected =
    process.env.ECO_OPERATOR_TOKEN ??
    process.env.ECO_TOKEN ??
    process.env.ECO_ADMIN_TOKEN ??
    '';
  return !!token && !!expected && token === expected;
}

export async function GET(req: Request, ctx: { params: { id: string } }) {
  try {
    const id = ctx?.params?.id;
    if (!id) return NextResponse.json({ error: 'missing_id' }, { status: 400 });

    const row: any = await (prisma as any).pickupRequest.findUnique({
      where: { id },
      select: { receipt: { select: { code: true, public: true } } },
    });

    const receipt = row?.receipt;
    if (!receipt) return NextResponse.json({ error: 'not_found' }, { status: 404 });

    const isOp = ecoIsOperator(req);
    if (!isOp && !receipt.public) {
      // não vaza existência/privacidade
      return NextResponse.json({ error: 'not_found' }, { status: 404 });
    }

    return NextResponse.json({ code: receipt.code, public: !!receipt.public }, { status: 200 });
  } catch (e: any) {
    return NextResponse.json({ error: 'internal_error', detail: String(e?.message ?? e) }, { status: 500 });
  }
}
"@

WriteUtf8NoBom $apiReceipt $apiTs
$log += "- OK: endpoint /api/pickup-requests/[id]/receipt criado."

# 3) Atualizar ReceiptLink para buscar code via endpoint (com token)
if(!$receiptLink -or !(Test-Path -LiteralPath $receiptLink)){
  $log += "- WARN: não achei ReceiptLink.tsx; pulei patch do componente."
} else {
  $bk3 = BackupFile $receiptLink
  $log += ("- Backup ReceiptLink: {0}" -f $bk3)

  $receiptLinkTsx = @"
'use client';

import Link from 'next/link';
import { useEffect, useState } from 'react';

const LS_KEY = '$tokenKey';

function safeGet(): string | null {
  try { return localStorage.getItem(LS_KEY); } catch { return null; }
}

async function fetchReceiptCode(pickupId: string, token: string): Promise<string | null> {
  try {
    const res = await fetch('/api/pickup-requests/' + pickupId + '/receipt', {
      headers: { 'x-eco-token': token },
      cache: 'no-store',
    });
    if (!res.ok) return null;
    const data: any = await res.json();
    const code = data?.code;
    return typeof code === 'string' && code.length > 0 ? code : null;
  } catch {
    return null;
  }
}

export function ReceiptLinkFromItem(props: { item: any }) {
  const item = props?.item;
  const pickupId = item?.id as string | undefined;

  const [token, setToken] = useState<string | null>(null);
  const [code, setCode] = useState<string | null>(null);

  useEffect(() => {
    setToken(safeGet());
  }, []);

  useEffect(() => {
    let alive = true;
    async function run() {
      if (!pickupId) return;
      if (!token) return;
      const c = await fetchReceiptCode(pickupId, token);
      if (!alive) return;
      setCode(c);
    }
    run();
    return () => { alive = false; };
  }, [pickupId, token]);

  if (!token) return null;
  if (!code) return null;

  return (
    <Link className="underline" href={'/recibos/' + code}>
      Ver recibo
    </Link>
  );
}
"@

  WriteUtf8NoBom $receiptLink $receiptLinkTsx
  $log += "- OK: ReceiptLink.tsx atualizado (busca code via API + token)."
}

$log += ""
$log += "## VERIFY"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1"
$log += "3) Abra /operador -> salve token -> abra /pedidos e veja 'Ver recibo'."
$log += "4) Aba anônima: /pedidos não deve mostrar 'Ver recibo'."
$log += "5) Teste rápido do endpoint:"
$log += "   - Com token: GET /api/pickup-requests/<id>/receipt -> 200 {code}"
$log += "   - Sem token: se receipt não for public -> 404"

WriteUtf8NoBom $rep ($log -join "`n")
Write-Host ("✅ STEP 23a aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) Abra /operador e salve o token. Depois abra /pedidos." -ForegroundColor Yellow