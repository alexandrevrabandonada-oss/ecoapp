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
      const t = window.localStorage.getItem('eco_token') || '';
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

// eslint-disable-next-line react-hooks/exhaustive-deps
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

// ECO_STEP35_DAY_CLOSE_START
  const dayStats = useMemo(() => {
    const dayItems = items.filter((it: any) => safeStr(it?.routeDay) === routeDay);
    const s: any = { total: dayItems.length, NEW: 0, IN_ROUTE: 0, DONE: 0, CANCELED: 0, OTHER: 0 };
    dayItems.forEach((it: any) => {
      const st = safeStr(it?.status) || "NEW";
      if (st === "NEW" || st === "IN_ROUTE" || st === "DONE" || st === "CANCELED") s[st] = (s[st] || 0) + 1;
      else s.OTHER = (s.OTHER || 0) + 1;
    });
    return s;
  }, [items, routeDay]);

  const dailyBulletinText = () => {
    const s: any = dayStats as any;
    const lines: string[] = [];
    lines.push("ECO — FECHAMENTO " + routeDay);
    lines.push("Total: " + String(s.total || 0));
    lines.push("NEW: " + String(s.NEW || 0));
    lines.push("IN_ROUTE: " + String(s.IN_ROUTE || 0));
    lines.push("DONE: " + String(s.DONE || 0));
    lines.push("CANCELED: " + String(s.CANCELED || 0));
    if (s.OTHER) lines.push("OUTROS: " + String(s.OTHER || 0));
    return lines.join("\n");
  };

  const onCopyDailyBulletin = () => {
    const text = dailyBulletinText();
    try {
      navigator.clipboard.writeText(text);
      alert("Boletim copiado.");
    } catch {
      alert(text);
    }
  };

  const onWaDailyBulletin = () => {
    const text = dailyBulletinText();
    const url = "https://wa.me/?text=" + encodeURIComponent(text);
    window.open(url, "_blank", "noopener,noreferrer");
  };
// ECO_STEP35_DAY_CLOSE_END

/* ECO_STEP38_DAY_SHARE_LINK_HELPERS_START */
const ecoDayPublicSharePath = () => `/s/dia/${encodeURIComponent(routeDay)}`;
const ecoDayPublicShareUrl = () => {
  try {
    return window.location.origin + ecoDayPublicSharePath();
  } catch {
    return ecoDayPublicSharePath();
  }
};

const onOpenDaySharePage = () => {
  window.open(ecoDayPublicSharePath(), "_blank", "noopener,noreferrer");
};

const onCopyDayShareLink = async () => {
  const link = ecoDayPublicShareUrl();
  try {
    await navigator.clipboard.writeText(link);
    alert("Link copiado!");
  } catch {
    prompt("Copie o link:", link);
  }
};

const onWaDayShareLink = () => {
  const link = ecoDayPublicShareUrl();
  const text = `ECO — Fechamento do dia ${routeDay}\n${link}`;
  const wa = `https://wa.me/?text=${encodeURIComponent(text)}`;
  window.open(wa, "_blank", "noopener,noreferrer");
};
/* ECO_STEP38_DAY_SHARE_LINK_HELPERS_END */

  /* ECO_STEP36C_DAY_CARD_HELPERS_START */
  type ShareNav = Navigator & { share?: (data: ShareData) => Promise<void>; canShare?: (data: ShareData) => boolean };

  const __ecoDayStr = () => String(routeDay ?? "").trim();

  const ecoDayCardUrl = (fmt: "3x4" | "1x1" = "3x4") => {
    const d = encodeURIComponent(__ecoDayStr());
    return "/api/share/route-day-card?day=" + d + "&format=" + fmt;
  };

  const onDayCard3x4 = () => {
    const d = __ecoDayStr();
    if(!d) return;
    window.open(ecoDayCardUrl("3x4"), "_blank", "noopener,noreferrer");
  };

  const onShareDayCard3x4 = async () => {
    const d = __ecoDayStr();
    if(!d) return;

    const card = ecoDayCardUrl("3x4");
    let res: Response | null = null;
    try { res = await fetch(card, { cache: "no-store" }); } catch { res = null; }

    if(!res || !res.ok){
      window.open(card, "_blank", "noopener,noreferrer");
      return;
    }

    const blob = await res.blob();
    const fileName = "eco-fechamento-" + d + "-3x4.png";
    const file = new File([blob], fileName, { type: "image/png" });

    const nav = navigator as ShareNav;
    const data: ShareData = { title: "ECO — Fechamento do dia", text: "ECO — Fechamento do dia " + d, files: [file] };

    if(nav.share && (!nav.canShare || nav.canShare(data))){
      await nav.share(data);
      return;
    }

    const a = document.createElement("a");
    const obj = URL.createObjectURL(blob);
    a.href = obj;
    a.download = fileName;
    document.body.appendChild(a);
    a.click();
    a.remove();
    setTimeout(() => URL.revokeObjectURL(obj), 1200);
  };
  /* ECO_STEP36C_DAY_CARD_HELPERS_END */


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

            {/* ECO_STEP35_DAY_CLOSE_UI_START */}
      <div style={{ marginTop: 12, padding: 12, border: '1px solid #ddd', borderRadius: 8 }}>
        <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap', alignItems: 'center' }}>
          <b>Fechamento do dia</b>
          <span style={{ opacity: 0.8 }}>({routeDay})</span>
          <span style={{ marginLeft: 8, opacity: 0.9 }}>
            Total: {dayStats.total} • NEW: {dayStats.NEW} • IN_ROUTE: {dayStats.IN_ROUTE} • DONE: {dayStats.DONE} • CANCELED: {dayStats.CANCELED}{dayStats.OTHER ? (" • OUTROS: " + dayStats.OTHER) : ""}
          </span>
        </div>
        <div style={{ marginTop: 8, display: 'flex', gap: 10, flexWrap: 'wrap' }}>
          <button type="button" onClick={onCopyDailyBulletin} style={{ padding: '6px 10px' }}>Copiar boletim do dia</button>
          <button type="button" onClick={onWaDailyBulletin} style={{ padding: '6px 10px' }}>WhatsApp boletim</button>
          {/* ECO_STEP38_DAY_SHARE_LINK_UI_START */}
          <button type="button" onClick={onOpenDaySharePage} style={{ padding: "6px 10px" }}>Página pública do dia</button>
          <button type="button" onClick={onCopyDayShareLink} style={{ padding: "6px 10px" }}>Copiar link do dia</button>
          <button type="button" onClick={onWaDayShareLink} style={{ padding: "6px 10px" }}>WhatsApp (link do dia)</button>
          {/* ECO_STEP38_DAY_SHARE_LINK_UI_END */}

          {/* ECO_STEP36C_DAY_CARD_UI_START */}
          <button type="button" onClick={onDayCard3x4} style={{ padding: '6px 10px' }}>Baixar card do dia (3:4)</button>
          <button type="button" onClick={onShareDayCard3x4} style={{ padding: '6px 10px' }}>Compartilhar card (3:4)</button>
          {/* ECO_STEP36C_DAY_CARD_UI_END */}
        </div>
      </div>
      {/* ECO_STEP35_DAY_CLOSE_UI_END */}
<div style={{ marginTop: 14, opacity: 0.7, fontSize: 12 }}>
        Token (localStorage): {token ? 'OK' : 'vazio'} — chave: <code>eco_token</code>
      </div>
    </div>
  );
}
