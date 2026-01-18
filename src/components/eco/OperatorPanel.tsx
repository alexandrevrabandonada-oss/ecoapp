'use client';

import React, { useEffect, useMemo, useState } from 'react';

type AnyObj = Record<string, any>;

const STATUS_FIELD = 'status';
const STATUS_OPTIONS = ['OPEN', 'SCHEDULED', 'DONE', 'CANCELED'] as const;

// eslint-disable-next-line @typescript-eslint/no-unused-vars
type EcoCardFormat = "3x4" | "1x1";

function eco30Str(v: any): string {
  if (v === null || v === undefined) return '';
  if (typeof v === 'string') return v;
  if (typeof v === 'number' || typeof v === 'boolean') return String(v);
  try { return JSON.stringify(v); } catch { return String(v); }
}

function eco30Get(it: AnyObj, keys: string[]): string {
  for (const k of keys) {
    const v = it?.[k];
    if (v === null || v === undefined) continue;
    const s = eco30Str(v).trim();
    if (s) return s;
  }
  return '';
}

function eco30Id(it: AnyObj): string {
  return eco30Get(it, ['id','code','requestId','pickupId','publicCode','shareCode']);
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
  } catch { void 0; }
  return null;
}

function buildRouteText(items: AnyObj[]): string {
  const lines: string[] = [];
  const now = new Date();
  lines.push('ROTA ECO — ' + now.toLocaleString());
  lines.push('');

  for (const it of items) {
    const id = eco30Id(it);
    const st = eco30Str(it?.[STATUS_FIELD] ?? it?.status ?? '').trim();

    const nome = eco30Get(it, ['name','nome','contactName','responsavel','responsável','pessoa','morador','moradora']);
    const tel  = eco30Get(it, ['phone','telefone','tel','cel','whatsapp','zap','contactPhone']);
    const bairro = eco30Get(it, ['bairro','neighborhood','district','regiao','região','area','local']);
    const end = eco30Get(it, ['address','endereco','endereço','rua','logradouro','street','location','localizacao','localização']);
    const ref = eco30Get(it, ['reference','referencia','referência','complement','complemento','apt','apto']);

    const itens = eco30Get(it, ['items','itens','materials','materiais','bag','bags','sacos','observacao','observação','notes','note']);

    const head = '- [' + id + '] ' + (bairro ? bairro + ' — ' : '') + (end ? end : '(sem endereço)');
    lines.push(head);
    const who = (nome || tel) ? ('  ' + (nome ? nome : '') + (tel ? (' ' + tel) : '')) : '';
    if (who.trim()) lines.push(who);
    if (ref) lines.push('  ref: ' + ref);
    if (itens) lines.push('  itens: ' + itens);
    if (st) lines.push('  status: ' + st);
    lines.push('');
  }

  return lines.join('\n').trim() + '\n';
}

function waLink(text: string): string {
  const e = encodeURIComponent(text);
  return 'https://wa.me/?text=' + e;
}

export default function OperatorPanel() {
  const [token, setToken] = useState<string>('');
  const [loading, setLoading] = useState(false);
  const [err, setErr] = useState<string>('');
  const [items, setItems] = useState<AnyObj[]>([]);

  const [q, setQ] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('ALL');
  const [selected, setSelected] = useState<Record<string, boolean>>({});

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
      const arr = Array.isArray(list) ? list : [];
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
    try { localStorage.setItem('eco_token', token.trim()); } catch { void 0; }
  };

  const filtered = useMemo(() => {
    const qq = q.trim().toLowerCase();
    const stf = statusFilter;

    const arr = items.slice();
    // sort by createdAt if exists
    arr.sort((a, b) => {
      const da = new Date(a?.createdAt ?? a?.created_at ?? 0).getTime();
      const db = new Date(b?.createdAt ?? b?.created_at ?? 0).getTime();
      return (db || 0) - (da || 0);
    });

    return arr.filter((it) => {
      const st = eco30Str(it?.[STATUS_FIELD] ?? it?.status ?? '').trim();
      if (stf !== 'ALL' && st !== stf) return false;

      if (!qq) return true;

      const hay = [
        eco30Id(it),
        st,
        eco30Get(it, ['name','nome','contactName','responsavel','responsável']),
        eco30Get(it, ['bairro','neighborhood','district','regiao','região']),
        eco30Get(it, ['address','endereco','endereço','rua','logradouro','street','location']),
        eco30Get(it, ['phone','telefone','tel','cel','whatsapp','zap']),
      ].join(' ').toLowerCase();

      return hay.includes(qq);
    });
  }, [items, q, statusFilter]);

  const selectedItems = useMemo(() => {
    const out: AnyObj[] = [];
    for (const it of filtered) {
      const id = eco30Id(it);
      if (!id) continue;
      if (selected[id]) out.push(it);
    }
    return out;
  }, [filtered, selected]);

  const toggle = (id: string) => {
    setSelected((prev) => ({ ...prev, [id]: !prev[id] }));
  };

  const selectAllFiltered = () => {
    const map: Record<string, boolean> = { ...selected };
    for (const it of filtered) {
      const id = eco30Id(it);
      if (!id) continue;
      map[id] = true;
    }
    setSelected(map);
  };

  const clearSelection = () => setSelected({});

  const copyRoute = async () => {
    const arr = selectedItems.length ? selectedItems : filtered;
    const text = buildRouteText(arr);
    try {
      await navigator.clipboard.writeText(text);
      alert('Rota copiada! (' + arr.length + ' itens)');
      return;
    } catch { void 0; }
    // fallback
    try {
      const ta = document.createElement('textarea');
      ta.value = text;
      document.body.appendChild(ta);
      ta.select();
      document.execCommand('copy');
      ta.remove();
      alert('Rota copiada! (' + arr.length + ' itens)');
    } catch {
      alert('Não consegui copiar automaticamente. Vou abrir em uma nova aba.');
      const blob = new Blob([text], { type: 'text/plain;charset=utf-8' });
      const url = URL.createObjectURL(blob);
      window.open(url, '_blank', 'noopener,noreferrer');
      setTimeout(() => URL.revokeObjectURL(url), 1500);
    }
  };

  const shareWhatsApp = () => {
    const arr = selectedItems.length ? selectedItems : filtered;
    const text = buildRouteText(arr);
    window.open(waLink(text), '_blank', 'noopener,noreferrer');
  };

  return (
    <div className="mx-auto max-w-6xl p-4">
      <h1 className="text-2xl font-bold">Operador ECO</h1>
      <p className="text-sm opacity-80">Fila de pedidos + filtros + rota rápida.</p>

      <div className="mt-4 rounded border p-3">
        <div className="flex flex-col gap-3">
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

          <div className="flex flex-col gap-2 md:flex-row md:items-end">
            <div className="w-full md:w-56">
              <label className="text-sm font-semibold">Status</label>
              <select
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
                className="mt-1 w-full rounded border px-3 py-2"
              >
                <option value="ALL">Todos</option>
                {STATUS_OPTIONS.map((s) => (
                  <option key={String(s)} value={String(s)}>{String(s)}</option>
                ))}
              </select>
            </div>

            <div className="flex-1">
              <label className="text-sm font-semibold">Busca</label>
              <input
                value={q}
                onChange={(e) => setQ(e.target.value)}
                placeholder="nome, bairro, endereço, telefone…"
                className="mt-1 w-full rounded border px-3 py-2"
              />
            </div>

            <div className="flex flex-wrap gap-2">
              <button type="button" onClick={selectAllFiltered} className="rounded border px-3 py-2">
                Selecionar filtrados
              </button>
              <button type="button" onClick={clearSelection} className="rounded border px-3 py-2">
                Limpar seleção
              </button>
              <button type="button" onClick={copyRoute} className="rounded bg-black px-3 py-2 text-white">
                Copiar rota
              </button>
              <button type="button" onClick={shareWhatsApp} className="rounded border px-3 py-2">
                WhatsApp
              </button>
            </div>
          </div>

          {err ? <div className="rounded border border-red-400 bg-red-50 p-2 text-sm">{err}</div> : null}
          {loading ? <div className="text-sm">Carregando…</div> : null}

          <div className="text-xs opacity-70">
            Itens: {filtered.length} • Selecionados: {selectedItems.length}
            {selectedItems.length ? ' (rota usa selecionados; senão, usa filtrados)' : ' (rota usa filtrados)'}
          </div>
        </div>
      </div>

      <div className="mt-4 overflow-auto rounded border">
        <table className="w-full text-sm">
          <thead className="bg-gray-50">
            <tr>
              <th className="p-2 text-left">Sel</th>
              <th className="p-2 text-left">ID</th>
              <th className="p-2 text-left">Status</th>
              <th className="p-2 text-left">Contato</th>
              <th className="p-2 text-left">Local</th>
              <th className="p-2 text-left">Ações</th>
              <th className="p-2 text-left">Debug</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map((it) => {
              const id = eco30Id(it);
              const st = eco30Str(it?.[STATUS_FIELD] ?? it?.status ?? '').trim();

              const nome = eco30Get(it, ['name','nome','contactName','responsavel','responsável']);
              const tel  = eco30Get(it, ['phone','telefone','tel','cel','whatsapp','zap','contactPhone']);
              const contato = (nome || tel) ? ((nome ? nome : '') + (tel ? (' • ' + tel) : '')) : '';

              const bairro = eco30Get(it, ['bairro','neighborhood','district','regiao','região']);
              const end = eco30Get(it, ['address','endereco','endereço','rua','logradouro','street','location']);
              const local = (bairro || end) ? ((bairro ? bairro : '') + (end ? (' — ' + end) : '')) : '';

              return (
                <tr key={id} className="border-t align-top">
                  <td className="p-2">
                    <input
                      type="checkbox"
                      checked={!!selected[id]}
                      onChange={() => toggle(id)}
                      disabled={!id}
                    />
                  </td>
                  <td className="p-2 font-mono">{id}</td>
                  <td className="p-2">{st}</td>
                  <td className="p-2">{contato || <span className="opacity-50">(—)</span>}</td>
                  <td className="p-2">{local || <span className="opacity-50">(—)</span>}</td>
                  <td className="p-2">
                    <div className="flex flex-wrap gap-2">
                      {STATUS_OPTIONS.map((s) => (
                        <button
                          key={String(s)}
                          type="button"
                          onClick={() => setStatus(id, String(s))}
                          className="rounded border px-2 py-1"
                          disabled={!token.trim() || !id}
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
            {!filtered.length ? (
              <tr>
                <td className="p-3 text-sm opacity-70" colSpan={7}>Sem itens com esses filtros.</td>
              </tr>
            ) : null}
          </tbody>
        </table>
      </div>

      <p className="mt-4 text-xs opacity-70">
        Dica: pra “rota do dia”, você pode filtrar por status (ex.: NEW/PENDING), selecionar os pedidos daquele bairro e mandar no WhatsApp com 1 clique.
      </p>
    </div>
  );
}
