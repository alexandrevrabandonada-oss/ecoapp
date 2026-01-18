'use client';

// ECO_STEP31_OPERATOR_TRIAGE

import React, { useEffect, useMemo, useState } from 'react';

type AnyObj = Record<string, any>;

const STATUS_FIELD = 'status';
const _STATUS_OPTIONS = ['OPEN', 'SCHEDULED', 'DONE', 'CANCELED'] as const;

const COL_NEW = ['OPEN'] as const;
const COL_ROUTE = ['OPEN'] as const;
const COL_DONE = ['DONE'] as const;
const COL_CANCEL = ['CANCELED'] as const;

// eslint-disable-next-line @typescript-eslint/no-unused-vars
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

// ECO_STEP32_ROUTE_DAY_START
// Rota do dia: bairro + so NOVOS + copiar/WhatsApp

function eco32ClipboardWrite(text: string): Promise<void> {
  try {
    const nav: any = navigator as any;
    if (nav?.clipboard?.writeText) return nav.clipboard.writeText(text);
  } catch { void 0; }
  return new Promise((resolve, reject) => {
    try {
      const ta = document.createElement('textarea');
      ta.value = text;
      ta.style.position = 'fixed';
      ta.style.opacity = '0';
      ta.style.left = '-9999px';
      document.body.appendChild(ta);
      ta.focus();
      ta.select();
      const ok = document.execCommand('copy');
      ta.remove();
      if (ok) resolve();
      else reject(new Error('clipboard failed'));
    } catch (e) {
      reject(e as any);
    }
  });
}

function eco32BuildRouteText(items: AnyObj[]): string {
  const now = new Date();
  const stamp = now.toLocaleString();
  const lines: string[] = [];
  lines.push('🧾 ECO — Rota do dia');
  lines.push('📅 ' + stamp);
  lines.push('📦 Pedidos: ' + String(items.length));
  lines.push('');

  const by = new Map<string, AnyObj[]>();
  for (const it of items) {
    const bairro = eco31Get(it, ['bairro','neighborhood','district','regiao','região','area','local']).trim() || '(sem bairro)';
    const arr = by.get(bairro) ?? [];
    arr.push(it);
    by.set(bairro, arr);
  }

  const bairros = Array.from(by.keys()).sort((a, b) => a.localeCompare(b));
  for (const b of bairros) {
    lines.push('📍 ' + b + ' — ' + String(by.get(b)?.length ?? 0));
    const arr = by.get(b) ?? [];
    for (const it of arr) {
      const id = eco31Id(it);
      const nome = eco31Get(it, ['name','nome','contactName','responsavel','responsável']);
      const tel  = eco31Get(it, ['phone','telefone','tel','cel','whatsapp','zap','contactPhone']);
      const end  = eco31Get(it, ['address','endereco','endereço','rua','logradouro','street','location']);
      const itens = eco31Get(it, ['items','itens','materials','materiais','bag','bags','sacos','observacao','observação','notes','note']);
      const parts = [
        '• ' + (end || '(sem endereco)'),
        (nome || tel) ? ('— ' + [nome, tel].filter(Boolean).join(' • ')) : '',
        itens ? ('— itens: ' + itens) : '',
        id ? ('— id: ' + id) : '',
      ].filter(Boolean);
      lines.push(parts.join(' '));
    }
    lines.push('');
  }

  lines.push('—');
  lines.push('Assinatura ECO');
  return lines.join('\n');
}

function eco32WhatsAppUrl(text: string): string {
  return 'https://wa.me/?text=' + encodeURIComponent(text);
}
// ECO_STEP32_ROUTE_DAY_END


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
  } catch { void 0; }
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

  
  const [routeBairro, setRouteBairro] = useState<string>('');
  const [routeOnlyNew, setRouteOnlyNew] = useState<boolean>(true);const headers = useMemo(() => {
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
    try { localStorage.setItem('eco_token', token.trim()); } catch { void 0; }
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
  const bairrosAll = useMemo(() => {
    const set = new Set<string>
        {/* ECO_STEP32_ROUTE_UI_START */}
        <div className="mt-3 rounded border bg-white p-3">
          <div className="flex flex-col gap-2 md:flex-row md:items-end md:justify-between">
            <div>
              <div className="text-sm font-semibold">Rota do dia</div>
              <div className="text-xs opacity-70">Filtra por bairro e gera texto pronto pra copiar/WhatsApp.</div>
            </div>

            <div className="flex flex-col gap-2 md:flex-row md:items-end">
              <div>
                <label className="text-sm font-semibold">Bairro</label>
                <select
                  value={routeBairro}
                  onChange={(e) => setRouteBairro(e.target.value)}
                  className="mt-1 w-full rounded border px-3 py-2"
                >
                  <option value="">(todos)</option>
                  {bairrosAll.map((b) => (
                    <option key={b} value={b}>{b}</option>
                  ))}
                </select>
              </div>

              <label className="flex items-center gap-2 text-sm">
                <input type="checkbox" checked={routeOnlyNew} onChange={(e) => setRouteOnlyNew(e.target.checked)} />
                so NOVOS
              </label>

              <div className="flex gap-2">
                <button type="button" onClick={onCopyRoute} className="rounded bg-black px-3 py-2 text-white">
                  Copiar rota
                </button>
                <button type="button" onClick={onWhatsAppRoute} className="rounded border px-3 py-2">
                  WhatsApp
                </button>
              </div>
            </div>
          </div>

          <div className="mt-2 text-xs opacity-70">
            Itens na rota: <span className="font-mono">{routeCandidates.length}</span>
          </div>

          <details className="mt-2">
            <summary className="cursor-pointer text-xs underline">ver texto da rota</summary>
            <pre className="mt-2 max-h-80 overflow-auto whitespace-pre-wrap break-words rounded border bg-gray-50 p-2 text-[11px]">{routeText}</pre>
          </details>
        </div>
        {/* ECO_STEP32_ROUTE_UI_END */}
    for (const it of items) {
      const b = eco31Get(it, ['bairro','neighborhood','district','regiao','região','area','local']).trim();
      if (b) set.add(b);
    }
    return Array.from(set).sort((a, b) => a.localeCompare(b));
// eslint-disable-next-line react-hooks/exhaustive-deps
  }, [items]);

  const routeCandidates = useMemo(() => {
    let arr: AnyObj[] = filtered;
    if (routeOnlyNew) {
      arr = arr.filter((it) => (COL_NEW as readonly string[]).includes(eco31Status(it)));
    }
    if (routeBairro.trim()) {
      const rb = routeBairro.trim();
      arr = arr.filter((it) => eco31Get(it, ['bairro','neighborhood','district','regiao','região','area','local']).trim() === rb);
    }
    return arr;
  }, [filtered, routeOnlyNew, routeBairro]);

  const routeText = useMemo(() => eco32BuildRouteText(routeCandidates), [routeCandidates]);

  const onCopyRoute = async () => {
    try {
      await eco32ClipboardWrite(routeText);
      alert('✅ Rota copiada!');
    } catch {
      alert('⚠️ Não consegui copiar automaticamente. Abra o "ver texto da rota" e copie manualmente.');
    }
  };

  const onWhatsAppRoute = () => {
    const url = eco32WhatsAppUrl(routeText);
    window.open(url, '_blank', 'noopener,noreferrer');
  };

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
