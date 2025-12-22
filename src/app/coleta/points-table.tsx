"use client";

import Link from "next/link";
import { useEffect, useMemo, useState } from "react";

const MATERIALS = [
  "PAPEL","PAPELAO","PET","PLASTICO_MISTO","ALUMINIO","VIDRO","FERRO","ELETRONICOS","OUTRO",
] as const;

function waLink(contact?: string | null) {
  if (!contact) return null;
  const c = String(contact).trim();
  if (!c) return null;
  if (/^https?:\/\//i.test(c)) return c;

  const digits = c.replace(/\D/g, "");
  if (!digits) return null;

  let num = digits;
  if (digits.length === 11) num = "55" + digits;
  if (digits.length === 13 && digits.startsWith("55")) num = digits;
  if (!num.startsWith("55")) return null;

  return `https://wa.me/${num}`;
}

function mapLink(address?: string | null, neighborhood?: string | null) {
  const a = String(address ?? "").trim();
  const b = String(neighborhood ?? "").trim();
  const q = [a, b].filter(Boolean).join(" - ");
  if (!q) return null;
  return `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(q)}`;
}

function uniqSorted(arr: string[]) {
  return Array.from(new Set(arr.map(s => s.trim()).filter(Boolean))).sort((a,b) => a.localeCompare(b));
}

export default function PointsTable() {
  const [points, setPoints] = useState<any[]>([]);
  const [busyId, setBusyId] = useState<string>("");
  const [loading, setLoading] = useState(false);

  const [showAll, setShowAll] = useState(false);
  const [q, setQ] = useState("");
  const [bairro, setBairro] = useState("");
  const [materials, setMaterials] = useState<Set<string>>(new Set());

  async function load(all = showAll) {
    setLoading(true);
    try {
      const url = all ? "/api/points?all=1" : "/api/points";
      const res = await fetch(url, { cache: "no-store" });
      const data: any = await res.json().catch(() => ({}));
      const raw = data?.points ?? data?.items ?? data?.data ?? data;
      setPoints(Array.isArray(raw) ? raw : []);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    load(false);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const bairros = useMemo(() => {
    return uniqSorted(points.map(p => String(p?.neighborhood ?? "")).filter(Boolean));
  }, [points]);

  const counts = useMemo(() => {
    const total = points.length;
    const ativos = points.filter(p => !!p?.isActive).length;
    return { total, ativos };
  }, [points]);

  const filtered = useMemo(() => {
    const qq = q.trim().toLowerCase();
    const hasM = materials.size > 0;

    return points.filter((p: any) => {
      if (!showAll && p?.isActive === false) return false;
      if (bairro && String(p?.neighborhood ?? "").trim() !== bairro) return false;
      if (hasM && !materials.has(String(p?.materialKind ?? ""))) return false;

      if (qq) {
        const hay = [
          p?.title, p?.name, p?.address, p?.neighborhood, p?.hours, p?.contact,
          p?.materialKind, p?.service?.name, p?.service?.kind,
        ].map(x => String(x ?? "")).join(" ").toLowerCase();
        if (!hay.includes(qq)) return false;
      }

      return true;
    });
  }, [points, q, bairro, materials, showAll]);

  function toggleMaterial(m: string) {
    setMaterials(prev => {
      const next = new Set(Array.from(prev));
      if (next.has(m)) next.delete(m); else next.add(m);
      return next;
    });
  }

  function clearFilters() {
    setQ("");
    setBairro("");
    setMaterials(new Set());
  }

  async function toggleActive(p: any) {
    setBusyId(p.id);
    try {
      const res = await fetch(`/api/points/${p.id}`, {
        method: "PATCH",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ isActive: !p.isActive }),
      });
      if (!res.ok) throw new Error(await res.text());
      const data: any = await res.json().catch(() => ({}));
      const next = data?.point;
      setPoints(prev => prev.map(x => (x.id === p.id ? next : x)));
    } catch (e: any) {
      alert(e?.message ?? "Falha ao atualizar");
    } finally {
      setBusyId("");
    }
  }

  async function delPoint(p: any) {
    if (!confirm(`Excluir o ponto "${p.title ?? p.name ?? p.id}"?`)) return;
    setBusyId(p.id);
    try {
      const res = await fetch(`/api/points/${p.id}`, { method: "DELETE" });
      if (!res.ok) throw new Error(await res.text());
      setPoints(prev => prev.filter(x => x.id !== p.id));
    } catch (e: any) {
      alert(e?.message ?? "Falha ao excluir");
    } finally {
      setBusyId("");
    }
  }

  return (
    <div className="card">
      <div className="toolbar" style={{ alignItems: "flex-start", gap: 12, flexWrap: "wrap" }}>
        <div style={{ minWidth: 240 }}>
          <label>Buscar</label>
          <input
            placeholder="Título, endereço, bairro, serviço..."
            value={q}
            onChange={(e) => setQ(e.target.value)}
          />
        </div>

        <div style={{ minWidth: 220 }}>
          <label>Bairro</label>
          <select value={bairro} onChange={(e) => setBairro(e.target.value)}>
            <option value="">(todos)</option>
            {bairros.map((b) => <option key={b} value={b}>{b}</option>)}
          </select>
        </div>

        <div style={{ flex: 1, minWidth: 260 }}>
          <label>Materiais (chips)</label>
          <div className="toolbar" style={{ flexWrap: "wrap" }}>
            {MATERIALS.map((m) => {
              const on = materials.has(m);
              return (
                <button
                  key={m}
                  type="button"
                  className={on ? "btn btn-primary" : "btn"}
                  onClick={() => toggleMaterial(m)}
                >
                  {m}
                </button>
              );
            })}
            <button type="button" className="btn" onClick={clearFilters}>Limpar</button>
          </div>
        </div>

        <div style={{ minWidth: 220 }}>
          <label>Status</label>
          <div className="toolbar">
            <button
              type="button"
              className={showAll ? "btn btn-primary" : "btn"}
              onClick={async () => { const next = !showAll; setShowAll(next); await load(next); }}
            >
              {showAll ? "Mostrando tudo" : "Só ativos"}
            </button>
            <button type="button" className="btn" onClick={() => load(showAll)} disabled={loading}>
              {loading ? "Atualizando..." : "Atualizar"}
            </button>
          </div>
        </div>

        <div style={{ minWidth: 180 }}>
          <label>Resumo</label>
          <p style={{ margin: 0 }}>
            <small>
              Total: <b>{counts.total}</b> • Ativos: <b>{counts.ativos}</b><br />
              Exibindo: <b>{filtered.length}</b>
            </small>
          </p>
          <div className="toolbar" style={{ marginTop: 6 }}>
            <Link className="btn" href="/coleta/novo">+ Novo</Link>
          </div>
        </div>
      </div>

      <hr />

      {filtered.length === 0 ? (
        <p><small>Nenhum ponto bateu com os filtros. Tenta limpar e buscar de novo.</small></p>
      ) : (
        <table>
          <thead>
            <tr>
              <th>Ponto</th>
              <th>Material</th>
              <th>Serviço</th>
              <th>Contato</th>
              <th>Status</th>
              <th style={{ width: 360 }}>Ações</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map((p: any) => {
              const w = waLink(p.contact);
              const m = mapLink(p.address, p.neighborhood);
              const isBusy = busyId === p.id;
              return (
                <tr key={p.id}>
                  <td>
                    <b>{p.title ?? p.name ?? "Ponto"}</b><br />
                    <small>{p.address ?? ""}{p.neighborhood ? ` • ${p.neighborhood}` : ""}</small><br />
                    {p.hours ? <small>⏱ {p.hours}</small> : null}
                  </td>
                  <td><small>{p.materialKind ?? "-"}</small></td>
                  <td><small>{p.service?.name ?? "-"}</small></td>
                  <td><small>{p.contact ?? "-"}</small></td>
                  <td>
                    {p.isActive ? <span className="badge ok">ATIVO</span> : <span className="badge">INATIVO</span>}
                  </td>
                  <td>
                    <div className="toolbar">
                      {w ? <a className="btn" href={w} target="_blank" rel="noreferrer">WhatsApp</a> : null}
                      {m ? <a className="btn" href={m} target="_blank" rel="noreferrer">Mapa</a> : null}
                      <button className="btn" disabled={isBusy} onClick={() => toggleActive(p)}>
                        {p.isActive ? "Desativar" : "Ativar"}
                      </button>
                      <button className="btn danger" disabled={isBusy} onClick={() => delPoint(p)}>
                        Excluir
                      </button>
                    </div>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      )}
    </div>
  );
}