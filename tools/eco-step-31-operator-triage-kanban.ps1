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
  for($k=$r.start+1; $k -lt $r.end; $k++){
    $t = $lines[$k].Trim()
    if(!$t){ continue }
    if($t.StartsWith("//")){ continue }
    if($t.StartsWith("@@")){ continue }
    if($t -match "^\s*([A-Za-z_][A-Za-z0-9_]*)\s+([A-Za-z_][A-Za-z0-9_]*\??)\b"){
      $fname = $Matches[1]
      $ftype = $Matches[2]
      $fields[$fname] = $ftype
    }
  }
  return @{ fields=$fields }
}

function GetEnumValues([string[]]$lines, [string]$enumName){
  $r = GetBlockRange $lines "enum" $enumName
  if(!$r){ return @() }
  $vals = @()
  for($k=$r.start+1; $k -lt $r.end; $k++){
    $t = $lines[$k].Trim()
    if(!$t){ continue }
    if($t.StartsWith("//")){ continue }
    if($t -match "^([A-Za-z_][A-Za-z0-9_]*)\b"){ $vals += $Matches[1] }
  }
  return $vals
}

$rep = NewReport "eco-step-31-operator-triage-kanban"
$log = @()
$log += "# ECO — STEP 31 — /operador/triagem (kanban de triagem + contadores por bairro)"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

# Detect status field + values (best effort)
$schema = "prisma/schema.prisma"
if(!(Test-Path -LiteralPath $schema)){ $schema = FindFirst "." "\\prisma\\schema\.prisma$" }

$statusField = "status"
$statusType = "String"
$enumVals = @()

if($schema -and (Test-Path -LiteralPath $schema)){
  $lines = Get-Content -LiteralPath $schema
  $m = ParseModelFields $lines "PickupRequest"
  if($m){
    $fields = $m.fields
    foreach($c in @("status","state","stage")){
      if($fields.ContainsKey($c)){ $statusField = $c; break }
    }
    $statusType = [string]$fields[$statusField]
    $tn = $statusType.TrimEnd("?")
    $scalar = @("String","Int","Boolean","DateTime","Float","Decimal","Json","Bytes","BigInt")
    if($scalar -notcontains $tn){
      $enumVals = GetEnumValues $lines $tn
    }
  }
}

if(!$enumVals -or $enumVals.Count -lt 1){
  $enumVals = @("NEW","PENDING","IN_ROUTE","PICKED_UP","RECEIVED","DONE","CANCELLED")
}

# Build TS arrays and choose defaults for columns by heuristics
$stLines = @()
foreach($s in $enumVals){ $stLines += ("'" + $s + "'") }
$stArray = $stLines -join ", "

function HasAny($arr, $names){
  foreach($n in $names){
    if($arr -contains $n){ return $true }
  }
  return $false
}

$colNew = @()
if(HasAny $enumVals @("NEW","PENDING")){
  if($enumVals -contains "NEW"){ $colNew += "NEW" }
  if($enumVals -contains "PENDING"){ $colNew += "PENDING" }
} else {
  $colNew += $enumVals[0]
}

$colRoute = @()
if($enumVals -contains "IN_ROUTE"){ $colRoute += "IN_ROUTE" }
elseif($enumVals -contains "ON_ROUTE"){ $colRoute += "ON_ROUTE" }
elseif($enumVals -contains "ROUTE"){ $colRoute += "ROUTE" }

$colDone = @()
foreach($x in @("DONE","RECEIVED","PICKED_UP","COMPLETED","FINISHED")){
  if($enumVals -contains $x){ $colDone += $x }
}

$colCancel = @()
foreach($x in @("CANCELLED","CANCELED","CANCEL")){
  if($enumVals -contains $x){ $colCancel += $x }
}

# Fallbacks if empty
if($colRoute.Count -lt 1){ $colRoute += ($enumVals | Select-Object -First 1) }
if($colDone.Count -lt 1){ $colDone += ($enumVals | Select-Object -Last 1) }

$colNewTS = (@($colNew | ForEach-Object { "'" + $_ + "'" }) -join ", ")
$colRouteTS = (@($colRoute | ForEach-Object { "'" + $_ + "'" }) -join ", ")
$colDoneTS = (@($colDone | ForEach-Object { "'" + $_ + "'" }) -join ", ")
$colCancelTS = (@($colCancel | ForEach-Object { "'" + $_ + "'" }) -join ", ")

$log += "## DIAG"
$log += ("schema: {0}" -f ($schema ? $schema : "(não achei)"))
$log += ("statusField: {0} (type {1})" -f $statusField, $statusType)
$log += ("enum: {0}" -f ($enumVals -join ", "))
$log += ("columns: novos=[{0}] rota=[{1}] done=[{2}] cancel=[{3}]" -f ($colNew -join ","), ($colRoute -join ","), ($colDone -join ","), ($colCancel -join ","))
$log += ""

# Paths
$comp = "src/components/eco/OperatorTriageBoard.tsx"
$page = "src/app/operador/triagem/page.tsx"

# write component (idempotent marker)
$marker = "ECO_STEP31_OPERATOR_TRIAGE"
$needsComp = $true
if(Test-Path -LiteralPath $comp){
  $existing = Get-Content -LiteralPath $comp -Raw
  if($existing -match $marker){
    $needsComp = $false
    $log += "- INFO: OperatorTriageBoard.tsx já contém marker ($marker). Skip."
  } else {
    $log += ("- Backup component: {0}" -f (BackupFile $comp))
  }
}

if($needsComp){
  $ts = @"
'use client';

// $marker

import React, { useEffect, useMemo, useState } from 'react';

type AnyObj = Record<string, any>;

const STATUS_FIELD = '$statusField';
const STATUS_OPTIONS = [$stArray] as const;

const COL_NEW = [$colNewTS] as const;
const COL_ROUTE = [$colRouteTS] as const;
const COL_DONE = [$colDoneTS] as const;
const COL_CANCEL = [$colCancelTS] as const;

type ShareNav = Navigator & { share?: (data: ShareData) => Promise<void>; canShare?: (data: ShareData) => boolean };

function eco31Str(v: any): string {
  if (v === null || v === undefined) return '';
  if (typeof v === 'string') return v;
  if (typeof v === 'number' || typeof v === 'boolean') return String(v);
  try { return JSON.stringify(v); } catch { return String(v); }
}

function eco31Get(it: AnyObj, keys: string[]): string {
  for (const k of keys) {
    const v = it?.[k];
    if (v === null || v === undefined) continue;
    const s = eco31Str(v).trim();
    if (s) return s;
  }
  return '';
}

function eco31Id(it: AnyObj): string {
  return eco31Get(it, ['id','code','requestId','pickupId','publicCode','shareCode']);
}

function eco31Status(it: AnyObj): string {
  return eco31Str(it?.[STATUS_FIELD] ?? it?.status ?? '').trim();
}

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

function groupCountsByBairro(items: AnyObj[]): { bairro: string; n: number }[] {
  const map = new Map<string, number>();
  for (const it of items) {
    const bairro = eco31Get(it, ['bairro','neighborhood','district','regiao','região','area','local']).trim() || '(sem bairro)';
    map.set(bairro, (map.get(bairro) ?? 0) + 1);
  }
  const arr = Array.from(map.entries()).map(([bairro, n]) => ({ bairro, n }));
  arr.sort((a, b) => b.n - a.n);
  return arr;
}

function pickColumns(items: AnyObj[]) {
  const col = { novos: [] as AnyObj[], rota: [] as AnyObj[], concluidos: [] as AnyObj[], cancelados: [] as AnyObj[], outros: [] as AnyObj[] };
  for (const it of items) {
    const st = eco31Status(it);
    if ((COL_NEW as readonly string[]).includes(st)) col.novos.push(it);
    else if ((COL_ROUTE as readonly string[]).includes(st)) col.rota.push(it);
    else if ((COL_DONE as readonly string[]).includes(st)) col.concluidos.push(it);
    else if ((COL_CANCEL as readonly string[]).includes(st)) col.cancelados.push(it);
    else col.outros.push(it);
  }
  return col;
}

export default function OperatorTriageBoard() {
  const [token, setToken] = useState<string>('');
  const [loading, setLoading] = useState(false);
  const [err, setErr] = useState<string>('');
  const [items, setItems] = useState<AnyObj[]>([]);
  const [q, setQ] = useState('');
  const [showOther, setShowOther] = useState(false);

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
      if (!res.ok) throw new Error((j && (j.error || j.message)) ? String(j.error || j.message) : ('HTTP ' + res.status));
      const list = Array.isArray(j) ? j : (j?.items ?? j?.data ?? []);
      const arr = Array.isArray(list) ? list : [];
      // sort by createdAt desc when possible
      arr.sort((a, b) => {
        const da = new Date(a?.createdAt ?? a?.created_at ?? 0).getTime();
        const db = new Date(b?.createdAt ?? b?.created_at ?? 0).getTime();
        return (db || 0) - (da || 0);
      });
      setItems(arr);
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
      if (!res.ok) throw new Error((j && (j.error || j.message)) ? String(j.error || j.message) : ('HTTP ' + res.status));
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
    try { localStorage.setItem('eco_token', token.trim()); } catch {}
  };

  const filtered = useMemo(() => {
    const qq = q.trim().toLowerCase();
    if (!qq) return items;

    return items.filter((it) => {
      const hay = [
        eco31Id(it),
        eco31Status(it),
        eco31Get(it, ['name','nome','contactName','responsavel','responsável']),
        eco31Get(it, ['bairro','neighborhood','district','regiao','região']),
        eco31Get(it, ['address','endereco','endereço','rua','logradouro','street','location']),
        eco31Get(it, ['phone','telefone','tel','cel','whatsapp','zap']),
      ].join(' ').toLowerCase();
      return hay.includes(qq);
    });
  }, [items, q]);

  const cols = useMemo(() => pickColumns(filtered), [filtered]);

  const bairroTop = useMemo(() => ({
    novos: groupCountsByBairro(cols.novos).slice(0, 10),
    rota: groupCountsByBairro(cols.rota).slice(0, 10),
  }), [cols]);

  const nextStatus = (target: 'rota' | 'done' | 'cancel') => {
    const prefer = (arr: readonly string[]) => (arr.length ? String(arr[0]) : '');
    if (target === 'rota') return prefer(COL_ROUTE as readonly string[]);
    if (target === 'done') return prefer(COL_DONE as readonly string[]);
    return prefer(COL_CANCEL as readonly string[]);
  };

  const Card = ({ it }: { it: AnyObj }) => {
    const id = eco31Id(it);
    const st = eco31Status(it);
    const nome = eco31Get(it, ['name','nome','contactName','responsavel','responsável']);
    const tel  = eco31Get(it, ['phone','telefone','tel','cel','whatsapp','zap','contactPhone']);
    const bairro = eco31Get(it, ['bairro','neighborhood','district','regiao','região','area','local']);
    const end = eco31Get(it, ['address','endereco','endereço','rua','logradouro','street','location']);
    const itens = eco31Get(it, ['items','itens','materials','materiais','bag','bags','sacos','observacao','observação','notes','note']);

    return (
      <div className="rounded border bg-white p-2 shadow-sm">
        <div className="flex items-start justify-between gap-2">
          <div className="min-w-0">
            <div className="font-mono text-xs opacity-70">{id}</div>
            <div className="text-sm font-semibold">{bairro || '(sem bairro)'}</div>
            <div className="text-xs opacity-80">{end || '(sem endereço)'}</div>
            {(nome || tel) ? <div className="mt-1 text-xs">{nome ? nome : ''}{tel ? (' • ' + tel) : ''}</div> : null}
            {itens ? <div className="mt-1 text-xs opacity-90">itens: {itens}</div> : null}
            {st ? <div className="mt-1 text-[11px] opacity-60">status: {st}</div> : null}
          </div>
          <details>
            <summary className="cursor-pointer text-xs underline">debug</summary>
            <pre className="mt-2 max-h-64 overflow-auto whitespace-pre-wrap break-words p-2 text-[11px]">{JSON.stringify(it, null, 2)}</pre>
          </details>
        </div>

        <div className="mt-2 flex flex-wrap gap-2">
          <button
            type="button"
            className="rounded border px-2 py-1 text-xs"
            disabled={!token.trim() || !id}
            onClick={() => setStatus(id, nextStatus('rota'))}
            title="Mover para Em rota"
          >
            Em rota
          </button>
          <button
            type="button"
            className="rounded border px-2 py-1 text-xs"
            disabled={!token.trim() || !id}
            onClick={() => setStatus(id, nextStatus('done'))}
            title="Marcar como Concluído"
          >
            Concluir
          </button>
          {(COL_CANCEL as readonly string[]).length ? (
            <button
              type="button"
              className="rounded border px-2 py-1 text-xs"
              disabled={!token.trim() || !id}
              onClick={() => setStatus(id, nextStatus('cancel'))}
              title="Cancelar"
            >
              Cancelar
            </button>
          ) : null}
        </div>
      </div>
    );
  };

  const Column = ({ title, items }: { title: string; items: AnyObj[] }) => (
    <div className="rounded border bg-gray-50 p-2">
      <div className="mb-2 flex items-center justify-between">
        <div className="font-semibold">{title}</div>
        <div className="text-xs opacity-70">{items.length}</div>
      </div>
      <div className="flex flex-col gap-2">
        {items.map((it) => (
          <Card key={eco31Id(it)} it={it} />
        ))}
        {!items.length ? <div className="text-xs opacity-60">(vazio)</div> : null}
      </div>
    </div>
  );

  return (
    <div className="mx-auto max-w-7xl p-4">
      <div className="flex flex-col gap-2 md:flex-row md:items-end md:justify-between">
        <div>
          <h1 className="text-2xl font-bold">Triagem ECO</h1>
          <p className="text-sm opacity-80">Kanban rápido pra rodar o dia.</p>
          <p className="text-xs opacity-60">StatusField: <span className="font-mono">{STATUS_FIELD}</span></p>
        </div>

        <div className="flex flex-col gap-2 md:flex-row md:items-end">
          <div className="min-w-[280px]">
            <label className="text-sm font-semibold">Token de Operador</label>
            <input
              value={token}
              onChange={(e) => setToken(e.target.value)}
              placeholder="cole o token (x-eco-token / Bearer)"
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
      </div>

      <div className="mt-3 flex flex-col gap-2 md:flex-row md:items-end">
        <div className="flex-1">
          <label className="text-sm font-semibold">Busca</label>
          <input
            value={q}
            onChange={(e) => setQ(e.target.value)}
            placeholder="bairro, endereço, nome, telefone…"
            className="mt-1 w-full rounded border px-3 py-2"
          />
        </div>
        <label className="flex items-center gap-2 text-sm">
          <input type="checkbox" checked={showOther} onChange={(e) => setShowOther(e.target.checked)} />
          Mostrar coluna “Outros”
        </label>
      </div>

      {err ? <div className="mt-3 rounded border border-red-400 bg-red-50 p-2 text-sm">{err}</div> : null}
      {loading ? <div className="mt-2 text-sm">Carregando…</div> : null}

      <div className="mt-4 grid grid-cols-1 gap-2 md:grid-cols-2">
        <div className="rounded border p-2">
          <div className="mb-2 text-sm font-semibold">Top bairros — Novos</div>
          <div className="flex flex-wrap gap-2">
            {bairroTop.novos.length ? bairroTop.novos.map((b) => (
              <span key={b.bairro} className="rounded border bg-white px-2 py-1 text-xs">
                {b.bairro} • {b.n}
              </span>
            )) : <span className="text-xs opacity-60">(sem dados)</span>}
          </div>
        </div>

        <div className="rounded border p-2">
          <div className="mb-2 text-sm font-semibold">Top bairros — Em rota</div>
          <div className="flex flex-wrap gap-2">
            {bairroTop.rota.length ? bairroTop.rota.map((b) => (
              <span key={b.bairro} className="rounded border bg-white px-2 py-1 text-xs">
                {b.bairro} • {b.n}
              </span>
            )) : <span className="text-xs opacity-60">(sem dados)</span>}
          </div>
        </div>
      </div>

      <div className="mt-4 grid grid-cols-1 gap-3 lg:grid-cols-4">
        <Column title="Novos" items={cols.novos} />
        <Column title="Em rota" items={cols.rota} />
        <Column title="Concluídos" items={cols.concluidos} />
        <Column title="Cancelados" items={cols.cancelados} />
      </div>

      {showOther ? (
        <div className="mt-4">
          <Column title="Outros (status não mapeados)" items={cols.outros} />
        </div>
      ) : null}

      <div className="mt-6 text-xs opacity-70">
        Dica: se um status não cair em nenhuma coluna, marque “Outros” e me diga qual é o valor — aí eu mapeio no próximo tijolo.
      </div>
    </div>
  );
}
"@

  EnsureDir (Split-Path -Parent $comp)
  WriteUtf8NoBom $comp $ts
  $log += "- OK: criei/atualizei src/components/eco/OperatorTriageBoard.tsx"
}

# write page (idempotent marker)
$needsPage = $true
if(Test-Path -LiteralPath $page){
  $existingP = Get-Content -LiteralPath $page -Raw
  if($existingP -match $marker){
    $needsPage = $false
    $log += "- INFO: page.tsx já contém marker. Skip."
  } else {
    $log += ("- Backup page: {0}" -f (BackupFile $page))
  }
}

if($needsPage){
  $pg = @"
import OperatorTriageBoard from '@/components/eco/OperatorTriageBoard';

// $marker
export const dynamic = 'force-dynamic';

export default function Page() {
  return <OperatorTriageBoard />;
}
"@
  EnsureDir (Split-Path -Parent $page)
  WriteUtf8NoBom $page $pg
  $log += "- OK: criei src/app/operador/triagem/page.tsx"
}

$log += ""
$log += "## VERIFY"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1"
$log += "3) Abra: /operador/triagem"
$log += "   - Atualizar (carrega /api/pickup-requests)"
$log += "   - Ver colunas (Novos/Em rota/Concluídos/Cancelados)"
$log += "   - Clicar Em rota / Concluir (PATCH) e ver mover de coluna"
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")
Write-Host ("✅ STEP 31 aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) Teste /operador/triagem (kanban)" -ForegroundColor Yellow