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
function DetectTokenKeyFromText([string]$txt){
  if(!$txt){ return $null }
  $ms = [regex]::Matches($txt, "localStorage\.getItem\(\s*['""]([^'""]+)['""]\s*\)")
  foreach($m in $ms){
    $k = $m.Groups[1].Value
    if($k -match "token"){ return $k }
  }
  return $null
}
function DetectTokenKeyFromRepo(){
  $files = Get-ChildItem -Recurse -File -Path "src" -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -match "\.(ts|tsx|js|jsx)$" } |
    Select-Object -ExpandProperty FullName
  foreach($f in $files){
    $t = Get-Content -LiteralPath $f -Raw -ErrorAction SilentlyContinue
    if(!$t){ continue }
    if($t -match "localStorage\.getItem" -and $t -match "token"){
      $k = DetectTokenKeyFromText $t
      if($k){ return $k }
    }
  }
  return $null
}

$rep = NewReport "eco-step-34-operator-triage-bulk-ui"
$log = @()
$log += "# ECO — STEP 34 — /operador/triagem (V2) com seleção + ações em massa (bulk)"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

# localizar page atual
$page = "src/app/operador/triagem/page.tsx"
if(!(Test-Path -LiteralPath $page)){
  $page = FindFirst "." "\\src\\app\\operador\\triagem\\page\.tsx$"
}
if(!(Test-Path -LiteralPath $page)){
  $log += "## ERRO"
  $log += "Não achei src/app/operador/triagem/page.tsx"
  WriteUtf8NoBom $rep ($log -join "`n")
  throw "Não achei /operador/triagem/page.tsx"
}

$log += "## DIAG"
$log += ("Page atual: {0}" -f $page)
$log += ""

$txtOld = Get-Content -LiteralPath $page -Raw

if($txtOld -match "OperatorTriageV2"){
  $log += "## PATCH"
  $log += "- INFO: page já usa OperatorTriageV2 (skip)."
  WriteUtf8NoBom $rep ($log -join "`n")
  Write-Host ("✅ STEP 34 já aplicado (idempotente). Report -> {0}" -f $rep) -ForegroundColor Green
  exit 0
}

# detectar chave do token (preferir a que já existe no legado)
$tokenKey = DetectTokenKeyFromText $txtOld
if(!$tokenKey){ $tokenKey = DetectTokenKeyFromRepo }
if(!$tokenKey){ $tokenKey = "eco_token" }

$log += ("Token localStorage key (detect): {0}" -f $tokenKey)
$log += ""

# salvar legado
$legacy = Join-Path (Split-Path -Parent $page) "page.legacy.tsx"
if(!(Test-Path -LiteralPath $legacy)){
  WriteUtf8NoBom $legacy $txtOld
  $log += "## PATCH"
  $log += ("- OK: legado salvo em {0}" -f $legacy)
} else {
  $log += "## PATCH"
  $log += ("- INFO: {0} já existe (mantive)." -f $legacy)
}

# criar V2 component
$dirTri = Split-Path -Parent $page
$v2 = Join-Path $dirTri "OperatorTriageV2.tsx"
BackupFile $v2 | Out-Null

$tsx = @"
'use client';

import React, { useEffect, useMemo, useState } from 'react';

type AnyItem = any;

function todayYmd(){
  const d = new Date();
  const y = d.getFullYear();
  const m = String(d.getMonth()+1).padStart(2,'0');
  const da = String(d.getDate()).padStart(2,'0');
  return y + '-' + m + '-' + da;
}

function safeStr(v: any){
  if(v === null || v === undefined) return '';
  if(typeof v === 'string') return v;
  try { return String(v); } catch { return ''; }
}

function pickLabel(it: AnyItem){
  const parts: string[] = [];
  const a = it?.address || it?.endereco || it?.local || it?.location;
  const n = it?.name || it?.nome || it?.contactName;
  const p = it?.phone || it?.telefone || it?.contactPhone;
  if(n) parts.push(safeStr(n));
  if(p) parts.push(safeStr(p));
  if(a) parts.push(safeStr(a));
  const s = parts.filter(Boolean).join(' — ');
  if(s) return s;
  return safeStr(it?.id || '');
}

function receiptCode(it: AnyItem){
  const r = it?.receipt;
  if(!r) return '';
  return safeStr(r?.code || r?.shareCode || r?.publicCode || r?.id || '');
}

export default function OperatorTriageV2(){
  const [token, setToken] = useState<string>('');
  const [items, setItems] = useState<AnyItem[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string>('');

  const [selected, setSelected] = useState<Record<string, boolean>>({});
  const [routeDay, setRouteDay] = useState<string>(todayYmd());
  const [filter, setFilter] = useState<string>('ALL'); // ALL | NEW | IN_ROUTE | DONE | CANCELED
  const [onlyRouteDay, setOnlyRouteDay] = useState<boolean>(false);

  useEffect(() => {
    try {
      const t = window.localStorage.getItem('__TOKEN_KEY__') || '';
      setToken(t);
    } catch {
      setToken('');
    }
  }, []);

  const headers = useMemo(() => {
    const h: Record<string,string> = { 'cache-control': 'no-store' };
    if(token){
      h['x-eco-token'] = token;
      h['authorization'] = 'Bearer ' + token;
    }
    return h;
  }, [token]);

  async function load(){
    setLoading(true);
    setError('');
    try{
      const res = await fetch('/api/pickup-requests/triage', { headers, cache: 'no-store' as any });
      if(!res.ok){
        const txt = await res.text();
        throw new Error('GET /triage ' + res.status + ' ' + txt);
      }
      const j = await res.json();
      const arr = (j?.items || j?.data || j) as AnyItem[];
      setItems(Array.isArray(arr) ? arr : []);
    }catch(e: any){
      setError(e?.message || 'erro');
    }finally{
      setLoading(false);
    }
  }

  useEffect(() => { load(); }, [headers]);

  const visible = useMemo(() => {
    let arr = items.slice();
    if(filter !== 'ALL'){
      arr = arr.filter(it => safeStr(it?.status) === filter);
    }
    if(onlyRouteDay){
      arr = arr.filter(it => safeStr(it?.routeDay) === routeDay);
    }
    return arr;
  }, [items, filter, onlyRouteDay, routeDay]);

  const selectedIds = useMemo(() => {
    return Object.keys(selected).filter(id => selected[id]);
  }, [selected]);

  function toggle(id: string){
    setSelected(prev => ({ ...prev, [id]: !prev[id] }));
  }

  function selectAllVisible(){
    const next: Record<string, boolean> = { ...selected };
    visible.forEach(it => {
      const id = safeStr(it?.id);
      if(id) next[id] = true;
    });
    setSelected(next);
  }

  function clearSelection(){
    setSelected({});
  }

  async function bulkPatch(data: any){
    if(selectedIds.length === 0){
      alert('Selecione pelo menos 1 pedido.');
      return;
    }
    try{
      const res = await fetch('/api/pickup-requests/bulk', {
        method: 'PATCH',
        headers: { ...headers, 'content-type': 'application/json' },
        body: JSON.stringify({ ids: selectedIds, ...data }),
      });
      if(!res.ok){
        const txt = await res.text();
        throw new Error('PATCH /bulk ' + res.status + ' ' + txt);
      }
      clearSelection();
      await load();
    }catch(e: any){
      alert(e?.message || 'erro');
    }
  }

  function openReceipt(it: AnyItem){
    const c = receiptCode(it);
    if(!c) return;
    window.open('/r/' + encodeURIComponent(c), '_blank', 'noopener,noreferrer');
  }

  function copyRouteText(){
    const day = routeDay;
    const inRoute = items.filter(it => safeStr(it?.status) === 'IN_ROUTE' && safeStr(it?.routeDay) === day);
    const lines = inRoute.map((it, idx) => {
      const l = pickLabel(it);
      return String(idx+1).padStart(2,'0') + '. ' + l;
    });
    const text = 'ROTA ECO — ' + day + '\n' + lines.join('\n');
    try{
      navigator.clipboard.writeText(text);
      alert('Rota copiada.');
    }catch{
      alert(text);
    }
  }

  function waRoute(){
    const day = routeDay;
    const inRoute = items.filter(it => safeStr(it?.status) === 'IN_ROUTE' && safeStr(it?.routeDay) === day);
    const lines = inRoute.map((it, idx) => {
      const l = pickLabel(it);
      return String(idx+1).padStart(2,'0') + '. ' + l;
    });
    const text = 'ROTA ECO — ' + day + '\n' + lines.join('\n');
    const url = 'https://wa.me/?text=' + encodeURIComponent(text);
    window.open(url, '_blank', 'noopener,noreferrer');
  }

  return (
    <div style={{ padding: 16, maxWidth: 1100, margin: '0 auto' }}>
      <h1 style={{ fontSize: 22, fontWeight: 800 }}>Operador — Triagem</h1>

      <div style={{ marginTop: 8, display: 'flex', gap: 10, flexWrap: 'wrap', alignItems: 'center' }}>
        <button type="button" onClick={load} disabled={loading} style={{ padding: '6px 10px' }}>
          Atualizar
        </button>

        <label style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
          <span>Filtro:</span>
          <select value={filter} onChange={(e) => setFilter(e.target.value)} style={{ padding: 6 }}>
            <option value="ALL">Todos</option>
            <option value="NEW">NEW</option>
            <option value="IN_ROUTE">IN_ROUTE</option>
            <option value="DONE">DONE</option>
            <option value="CANCELED">CANCELED</option>
          </select>
        </label>

        <label style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
          <span>Rota (dia):</span>
          <input value={routeDay} onChange={(e) => setRouteDay(e.target.value)} placeholder="YYYY-MM-DD" style={{ padding: 6, width: 130 }} />
        </label>

        <label style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
          <input type="checkbox" checked={onlyRouteDay} onChange={(e) => setOnlyRouteDay(e.target.checked)} />
          <span>mostrar só esse dia</span>
        </label>

        <button type="button" onClick={copyRouteText} style={{ padding: '6px 10px' }}>Copiar rota do dia</button>
        <button type="button" onClick={waRoute} style={{ padding: '6px 10px' }}>WhatsApp rota</button>
      </div>

      {error ? (
        <div style={{ marginTop: 10, padding: 10, border: '1px solid #f00', color: '#b00' }}>
          <b>Erro:</b> {error}
        </div>
      ) : null}

      <div style={{ marginTop: 12, padding: 10, border: '1px solid #ddd', borderRadius: 8 }}>
        <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap', alignItems: 'center' }}>
          <b>Selecionados:</b> {selectedIds.length}

          <button type="button" onClick={selectAllVisible} style={{ padding: '6px 10px' }}>
            Selecionar visíveis
          </button>
          <button type="button" onClick={clearSelection} style={{ padding: '6px 10px' }}>
            Limpar seleção
          </button>

          <span style={{ marginLeft: 10, opacity: 0.8 }}>Ações em massa:</span>

          <button type="button" onClick={() => bulkPatch({ status: 'IN_ROUTE', routeDay })} style={{ padding: '6px 10px' }}>
            Marcar IN_ROUTE (dia)
          </button>
          <button type="button" onClick={() => bulkPatch({ status: 'DONE' })} style={{ padding: '6px 10px' }}>
            Marcar DONE
          </button>
          <button type="button" onClick={() => bulkPatch({ status: 'CANCELED' })} style={{ padding: '6px 10px' }}>
            Marcar CANCELED
          </button>
          <button type="button" onClick={() => bulkPatch({ status: 'NEW', routeDay: null })} style={{ padding: '6px 10px' }}>
            Voltar p/ NEW
          </button>
        </div>
      </div>

      <div style={{ marginTop: 12, opacity: 0.8 }}>
        {loading ? 'Carregando...' : ('Pedidos: ' + visible.length)}
      </div>

      <div style={{ marginTop: 10, overflowX: 'auto' }}>
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead>
            <tr>
              <th style={{ textAlign: 'left', borderBottom: '1px solid #ddd', padding: 8 }}></th>
              <th style={{ textAlign: 'left', borderBottom: '1px solid #ddd', padding: 8 }}>Status</th>
              <th style={{ textAlign: 'left', borderBottom: '1px solid #ddd', padding: 8 }}>Dia</th>
              <th style={{ textAlign: 'left', borderBottom: '1px solid #ddd', padding: 8 }}>Resumo</th>
              <th style={{ textAlign: 'left', borderBottom: '1px solid #ddd', padding: 8 }}>Recibo</th>
            </tr>
          </thead>
          <tbody>
            {visible.map((it) => {
              const id = safeStr(it?.id);
              const st = safeStr(it?.status);
              const rd = safeStr(it?.routeDay);
              const rc = receiptCode(it);
              const checked = !!selected[id];
              return (
                <tr key={id}>
                  <td style={{ borderBottom: '1px solid #eee', padding: 8 }}>
                    <input type="checkbox" checked={checked} onChange={() => toggle(id)} />
                  </td>
                  <td style={{ borderBottom: '1px solid #eee', padding: 8 }}>{st || '-'}</td>
                  <td style={{ borderBottom: '1px solid #eee', padding: 8 }}>{rd || '-'}</td>
                  <td style={{ borderBottom: '1px solid #eee', padding: 8 }}>{pickLabel(it)}</td>
                  <td style={{ borderBottom: '1px solid #eee', padding: 8 }}>
                    {rc ? (
                      <button type="button" onClick={() => openReceipt(it)} style={{ textDecoration: 'underline' }}>
                        abrir /r/{rc}
                      </button>
                    ) : (
                      <span style={{ opacity: 0.6 }}>—</span>
                    )}
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>

      <div style={{ marginTop: 14, opacity: 0.7, fontSize: 12 }}>
        Token (localStorage): {token ? 'OK' : 'vazio'} — chave: <code>__TOKEN_KEY__</code>
      </div>
    </div>
  );
}
"@

$tsx = $tsx.Replace("__TOKEN_KEY__", $tokenKey)
WriteUtf8NoBom $v2 $tsx
$log += ("- OK: criado {0}" -f $v2)

# substituir page.tsx por wrapper
$bkPage = BackupFile $page
$log += ("- Backup page: {0}" -f $bkPage)

$wrapper = @"
import OperatorTriageV2 from "./OperatorTriageV2";

export const dynamic = "force-dynamic";

export default function Page(){
  return <OperatorTriageV2 />;
}
"@
WriteUtf8NoBom $page $wrapper
$log += "- OK: page.tsx agora aponta para OperatorTriageV2 (legado em page.legacy.tsx)."

$log += ""
$log += "## VERIFY"
$log += "1) Reinicie o dev: npm run dev"
$log += "2) Rode smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1"
$log += "3) Abra /operador/triagem e teste:"
$log += "   - Selecionar visíveis"
$log += "   - Marcar IN_ROUTE (dia) / DONE / CANCELED / NEW"
$log += "   - Copiar/WhatsApp rota do dia"
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 34 aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) Teste /operador/triagem (seleção + bulk)" -ForegroundColor Yellow