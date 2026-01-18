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

function GetBlockRange([string[]]$lines, [string]$kind, [string]$name){
  $start = -1
  for($i=0; $i -lt $lines.Count; $i++){
    if($lines[$i] -match ("^\s*" + [regex]::Escape($kind) + "\s+" + [regex]::Escape($name) + "\s*\{")){ $start = $i; break }
  }
  if($start -lt 0){ return $null }
  $end = -1
  for($j=$start+1; $j -lt $lines.Count; $j++){
    if($lines[$j] -match "^\s*\}\s*$"){ $end = $j; break }
  }
  if($end -lt 0){ return $null }
  return @{ start=$start; end=$end }
}

function ParseModelFields([string[]]$lines, [string]$modelName){
  $r = GetBlockRange $lines "model" $modelName
  if(!$r){ return $null }

  $fields = @{}
  $idField = $null

  for($k=$r.start+1; $k -lt $r.end; $k++){
    $raw = $lines[$k]
    $t = $raw.Trim()
    if(!$t){ continue }
    if($t.StartsWith("//")){ continue }
    if($t.StartsWith("@@")){ continue }
    if($t.StartsWith("@")){ continue }
    if($t -match "^\s*([A-Za-z_][A-Za-z0-9_]*)\s+([A-Za-z_][A-Za-z0-9_]*\??)\b"){
      $fname = $Matches[1]
      $ftype = $Matches[2]
      $fields[$fname] = $ftype
      if(!$idField -and $t -match "\s@id(\s|$)"){ $idField = $fname }
    }
  }

  if(!$idField){
    if($fields.ContainsKey("id")){ $idField = "id" }
    else { $idField = "id" }
  }

  return @{ range=$r; fields=$fields; idField=$idField }
}

function ParseEnumValues([string[]]$lines, [string]$enumName){
  $r = GetBlockRange $lines "enum" $enumName
  if(!$r){ return @() }
  $vals = @()
  for($k=$r.start+1; $k -lt $r.end; $k++){
    $t = $lines[$k].Trim()
    if(!$t){ continue }
    if($t.StartsWith("//")){ continue }
    if($t -match "^([A-Za-z_][A-Za-z0-9_]*)\b"){
      $vals += $Matches[1]
    }
  }
  return $vals
}

function DetectReceiptRelationFieldInPickup([hashtable]$fields){
  foreach($k in $fields.Keys){
    $t = [string]$fields[$k]
    $tn = $t.TrimEnd("?")
    if($tn -eq "Receipt"){ return $k }
  }
  return $null
}

$rep = NewReport "eco-step-29-operator-panel-mvp"
$log = @()
$log += "# ECO — STEP 29 — Painel do Operador (MVP) + PATCH /api/pickup-requests/[id]"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

# locate schema
$schema = "prisma/schema.prisma"
if(!(Test-Path -LiteralPath $schema)){ $schema = FindFirst "." "\\prisma\\schema\.prisma$" }

$statusField = "status"
$statusType  = "String"
$statusEnumValues = @()
$idField = "id"
$noteField = $null
$receiptField = $null

if($schema -and (Test-Path -LiteralPath $schema)){
  $lines = Get-Content -LiteralPath $schema
  $m = ParseModelFields $lines "PickupRequest"
  if($m){
    $idField = $m.idField
    $fields = $m.fields

    foreach($c in @("status","state","stage")){
      if($fields.ContainsKey($c)){ $statusField = $c; break }
    }
    $statusType = [string]$fields[$statusField]

    foreach($c in @("operatorNote","internalNote","note","notes","obs","observacao")){
      if($fields.ContainsKey($c)){ $noteField = $c; break }
    }

    $receiptField = DetectReceiptRelationFieldInPickup $fields

    $scalar = @("String","Int","Boolean","DateTime","Float","Decimal","Json","Bytes","BigInt")
    $tn = $statusType.TrimEnd("?")
    if($scalar -notcontains $tn){
      $statusEnumValues = ParseEnumValues $lines $tn
    }
  }
}

if(!$statusEnumValues -or $statusEnumValues.Count -lt 1){
  $statusEnumValues = @("NEW","PENDING","IN_ROUTE","PICKED_UP","RECEIVED","DONE","CANCELLED")
}

$log += "## DIAG"
$log += ("schema: {0}" -f ($schema ? $schema : "(não achei)"))
$log += ("PickupRequest idField: {0}" -f $idField)
$log += ("PickupRequest statusField: {0} (type {1})" -f $statusField, $statusType)
$log += ("PickupRequest noteField: {0}" -f ($noteField ? $noteField : "(nenhum)"))
$log += ("PickupRequest receipt relation: {0}" -f ($receiptField ? $receiptField : "(nenhum)"))
$log += ("Status options: {0}" -f ($statusEnumValues -join ", "))
$log += ""

# targets
$apiDir = "src/app/api/pickup-requests/[id]"
$pagePath = "src/app/operador/page.tsx"
$panelPath = "src/components/eco/OperatorPanel.tsx"
$smokePath = "tools/eco-smoke.ps1"

if(!(Test-Path -LiteralPath "src/app")){ 
  $alt = FindFirst "." "\\src\\app$"
  if(!$alt){ throw "Não achei src/app (estrutura diferente)."; }
}

EnsureDir $apiDir
EnsureDir (Split-Path -Parent $pagePath)
EnsureDir (Split-Path -Parent $panelPath)

$log += "## PATCH"
$log += ""

# 1) API PATCH route
$apiFile = Join-Path $apiDir "route.ts"
$bkApi = BackupFile $apiFile

$noteLine = ""
if($noteField){
  $noteLine = "    if (typeof body.note === 'string') data['" + $noteField + "'] = body.note;"
}

$apiTs = @"
import { NextResponse } from 'next/server';
import { PrismaClient } from '@prisma/client';

export const runtime = 'nodejs';

const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };
const prisma = globalForPrisma.prisma ?? new PrismaClient();
if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma;

function eco29GetToken(req: Request): string | null {
  const h = req.headers.get('x-eco-token') ?? req.headers.get('authorization') ?? '';
  if (h.startsWith('Bearer ')) return h.slice(7).trim();
  if (h && !h.includes(' ')) return h.trim();
  return null;
}

function eco29AllowedTokens(): string[] {
  const raw = (process.env.ECO_OPERATOR_TOKENS ?? process.env.ECO_OPERATOR_TOKEN ?? process.env.ECO_TOKEN ?? '').trim();
  if (!raw) return [];
  return raw.split(',').map(s => s.trim()).filter(Boolean);
}

function eco29IsOperator(req: Request): boolean {
  const tok = eco29GetToken(req);
  if (!tok) return false;
  const allowed = eco29AllowedTokens();
  if (allowed.length === 0) return true; // dev fallback
  return allowed.includes(tok);
}

export async function PATCH(req: Request, ctx: { params: { id: string } }) {
  try {
    if (!eco29IsOperator(req)) {
      return NextResponse.json({ ok: false, error: 'forbidden' }, { status: 403 });
    }

    const id = String(ctx?.params?.id ?? '').trim();
    if (!id) return NextResponse.json({ ok: false, error: 'missing id' }, { status: 400 });

    const body = await req.json().catch(() => ({} as any));
    const data: any = {};

    if (typeof body.status === 'string') data['$statusField'] = body.status;
$noteLine

    if (Object.keys(data).length === 0) {
      return NextResponse.json({ ok: false, error: 'no changes' }, { status: 400 });
    }

    const updated = await (prisma as any).pickupRequest.update({
      where: { '$idField': id },
      data,
    });

    return NextResponse.json({ ok: true, item: updated });
  } catch (e: any) {
    return NextResponse.json({ ok: false, error: String(e?.message ?? e) }, { status: 500 });
  }
}
"@

$log += ("- API: {0}" -f $apiFile)
$log += ("  Backup: {0}" -f ($bkApi ? $bkApi : "(novo arquivo)"))
WriteUtf8NoBom $apiFile $apiTs
$log += "  OK: criado/atualizado PATCH /api/pickup-requests/[id]"
$log += ""

# 2) Operator panel component
$bkPanel = BackupFile $panelPath

# build status array TS
$stLines = @()
foreach($s in $statusEnumValues){
  $stLines += ("'" + $s + "'")
}
$stArray = $stLines -join ", "

$panelTs = @"
'use client';

import React, { useEffect, useMemo, useState } from 'react';

type AnyObj = Record<string, any>;

const STATUS_FIELD = '$statusField';
const STATUS_OPTIONS = [$stArray] as const;

function findEcoToken(): string | null {
  try {
    const tries = [
      'eco_token','ecoToken','ECO_TOKEN',
      'eco_operator_token','ecoOperatorToken',
      'eco_admin_token','ecoAdminToken',
      'eco_client_token','ecoClientToken'
    ];
    for (const k of tries) {
      const v = localStorage.getItem(k);
      if (v && v.trim()) return v.trim();
    }
    const keys = Object.keys(localStorage);
    for (const k of keys) {
      const kl = k.toLowerCase();
      if (kl.includes('eco') && kl.includes('token')) {
        const v = localStorage.getItem(k);
        if (v && v.trim()) return v.trim();
      }
    }
  } catch {}
  return null;
}

export default function OperatorPanel() {
  const [token, setToken] = useState<string>('');
  const [loading, setLoading] = useState(false);
  const [err, setErr] = useState<string>('');
  const [items, setItems] = useState<AnyObj[]>([]);

  const headers = useMemo(() => {
    const h: Record<string, string> = { 'content-type': 'application/json' };
    const t = token.trim();
    if (t) h['x-eco-token'] = t;
    return h;
  }, [token]);

  const load = async () => {
    setLoading(true);
    setErr('');
    try {
      const res = await fetch('/api/pickup-requests', { headers, cache: 'no-store' });
      const j = await res.json().catch(() => null);
      if (!res.ok) {
        throw new Error((j && (j.error || j.message)) ? String(j.error || j.message) : ('HTTP ' + res.status));
      }
      const list = Array.isArray(j) ? j : (j?.items ?? j?.data ?? []);
      setItems(Array.isArray(list) ? list : []);
    } catch (e: any) {
      setErr(String(e?.message ?? e));
    } finally {
      setLoading(false);
    }
  };

  const setStatus = async (id: string, status: string) => {
    setLoading(true);
    setErr('');
    try {
      const url = '/api/pickup-requests/' + encodeURIComponent(id);
      const res = await fetch(url, {
        method: 'PATCH',
        headers,
        body: JSON.stringify({ status }),
      });
      const j = await res.json().catch(() => null);
      if (!res.ok) {
        throw new Error((j && (j.error || j.message)) ? String(j.error || j.message) : ('HTTP ' + res.status));
      }
      await load();
    } catch (e: any) {
      setErr(String(e?.message ?? e));
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    const t = findEcoToken();
    if (t) setToken(t);
  }, []);

  const saveToken = () => {
    try {
      localStorage.setItem('eco_token', token.trim());
    } catch {}
  };

  return (
    <div className="mx-auto max-w-5xl p-4">
      <h1 className="text-2xl font-bold">Operador ECO</h1>
      <p className="text-sm opacity-80">Fila de pedidos + atualização rápida de status.</p>

      <div className="mt-4 rounded border p-3">
        <div className="flex flex-col gap-2 md:flex-row md:items-end">
          <div className="flex-1">
            <label className="text-sm font-semibold">Token de Operador</label>
            <input
              value={token}
              onChange={(e) => setToken(e.target.value)}
              placeholder="cole aqui o token (x-eco-token / Bearer)"
              className="mt-1 w-full rounded border px-3 py-2"
            />
          </div>
          <div className="flex gap-2">
            <button type="button" onClick={saveToken} className="rounded bg-black px-3 py-2 text-white">
              Salvar token
            </button>
            <button type="button" onClick={load} className="rounded border px-3 py-2">
              Atualizar
            </button>
          </div>
        </div>

        {err ? <div className="mt-3 rounded border border-red-400 bg-red-50 p-2 text-sm">{err}</div> : null}
        {loading ? <div className="mt-3 text-sm">Carregando…</div> : null}
      </div>

      <div className="mt-4 overflow-auto rounded border">
        <table className="w-full text-sm">
          <thead className="bg-gray-50">
            <tr>
              <th className="p-2 text-left">ID</th>
              <th className="p-2 text-left">Status</th>
              <th className="p-2 text-left">Ações</th>
              <th className="p-2 text-left">Resumo</th>
            </tr>
          </thead>
          <tbody>
            {items.map((it) => {
              const id = String(it.id ?? it.code ?? it.requestId ?? '');
              const st = String(it[STATUS_FIELD] ?? it.status ?? '');
              return (
                <tr key={id} className="border-t">
                  <td className="p-2 font-mono">{id}</td>
                  <td className="p-2">{st}</td>
                  <td className="p-2">
                    <div className="flex flex-wrap gap-2">
                      {STATUS_OPTIONS.map((s) => (
                        <button
                          key={String(s)}
                          type="button"
                          onClick={() => setStatus(id, String(s))}
                          className="rounded border px-2 py-1"
                          disabled={!token.trim()}
                          title={!token.trim() ? 'Precisa de token' : 'Atualizar status'}
                        >
                          {String(s)}
                        </button>
                      ))}
                    </div>
                  </td>
                  <td className="p-2">
                    <details>
                      <summary className="cursor-pointer underline">ver</summary>
                      <pre className="mt-2 whitespace-pre-wrap break-words p-2 text-xs">{JSON.stringify(it, null, 2)}</pre>
                    </details>
                  </td>
                </tr>
              );
            })}
            {!items.length ? (
              <tr>
                <td className="p-3 text-sm opacity-70" colSpan={4}>Sem itens carregados (clique em Atualizar).</td>
              </tr>
            ) : null}
          </tbody>
        </table>
      </div>

      <p className="mt-4 text-xs opacity-70">
        Dica: se você não tiver ENV de operador configurada, o PATCH aceita qualquer token (fallback de dev). Em produção, configure ECO_OPERATOR_TOKENS (csv) ou ECO_OPERATOR_TOKEN.
      </p>
    </div>
  );
}
"@

$log += ("- UI: {0}" -f $panelPath)
$log += ("  Backup: {0}" -f ($bkPanel ? $bkPanel : "(novo arquivo)"))
WriteUtf8NoBom $panelPath $panelTs
$log += "  OK: criado OperatorPanel.tsx"
$log += ""

# 3) /operador page
$bkPage = BackupFile $pagePath
$pageTs = @"
import OperatorPanel from '../../components/eco/OperatorPanel';

export const runtime = 'nodejs';

export default function OperadorPage() {
  return <OperatorPanel />;
}
"@
$log += ("- PAGE: {0}" -f $pagePath)
$log += ("  Backup: {0}" -f ($bkPage ? $bkPage : "(novo arquivo)"))
WriteUtf8NoBom $pagePath $pageTs
$log += "  OK: criado /operador"
$log += ""

# 4) smoke add /operador
if(Test-Path -LiteralPath $smokePath){
  $bkSmoke = BackupFile $smokePath
  $sm = Get-Content -LiteralPath $smokePath -Raw
  if($sm -match "/operador"){
    $log += "- SMOKE: já contém /operador (skip)."
  } else {
    $anchor = '"/recibos"'
    $idx = $sm.IndexOf($anchor)
    if($idx -ge 0){
      $nl = $sm.IndexOf("`n", $idx)
      if($nl -gt 0){
        $insertAt = $nl + 1
        $sm = $sm.Insert($insertAt, "Hit `"/operador`"`n")
        WriteUtf8NoBom $smokePath $sm
        $log += ("- SMOKE: inseri Hit `"/operador`" após /recibos. Backup: {0}" -f $bkSmoke)
      } else {
        $sm = $sm + "`nHit `"/operador`"`n"
        WriteUtf8NoBom $smokePath $sm
        $log += ("- SMOKE: anexei Hit `"/operador`" no final. Backup: {0}" -f $bkSmoke)
      }
    } else {
      $sm = $sm + "`nHit `"/operador`"`n"
      WriteUtf8NoBom $smokePath $sm
      $log += ("- SMOKE: anexei Hit `"/operador`" no final (sem âncora). Backup: {0}" -f $bkSmoke)
    }
  }
} else {
  $log += "- SMOKE: tools/eco-smoke.ps1 não encontrado (skip)."
}

$log += ""
$log += "## VERIFY"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1"
$log += "3) Abra /operador, cole um token e clique Atualizar"
$log += "4) Teste atualizar status (botões)"
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")
Write-Host ("✅ STEP 29 aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) Abra /operador e teste load + status (com token)" -ForegroundColor Yellow