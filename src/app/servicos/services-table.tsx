"use client";

import Link from "next/link";
import { useEffect, useMemo, useState } from "react";

function uniqSorted(arr: string[]) {
  return Array.from(new Set(arr.map(s => s.trim()).filter(Boolean))).sort((a,b) => a.localeCompare(b));
}

export default function ServicesTable() {
  const [services, setServices] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [q, setQ] = useState("");
  const [kind, setKind] = useState("");

  async function load() {
    setLoading(true);
    try {
      const res = await fetch("/api/services", { cache: "no-store" });
      const data: any = await res.json().catch(() => ({}));
      const raw = data?.services ?? data?.items ?? data?.data ?? data;
      setServices(Array.isArray(raw) ? raw : []);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { load(); }, []);

  const kinds = useMemo(() => uniqSorted(services.map(s => String(s?.kind ?? "")).filter(Boolean)), [services]);

  const filtered = useMemo(() => {
    const qq = q.trim().toLowerCase();
    return services.filter((s: any) => {
      if (kind && String(s?.kind ?? "") !== kind) return false;
      if (qq) {
        const hay = [s?.name, s?.slug, s?.kind].map(x => String(x ?? "")).join(" ").toLowerCase();
        if (!hay.includes(qq)) return false;
      }
      return true;
    });
  }, [services, q, kind]);

  return (
    <div className="card">
      <div className="toolbar" style={{ flexWrap: "wrap" }}>
        <div style={{ minWidth: 260 }}>
          <label>Buscar</label>
          <input
            placeholder="Nome/slug..."
            value={q}
            onChange={(e) => setQ(e.target.value)}
          />
        </div>

        <div style={{ minWidth: 220 }}>
          <label>Tipo</label>
          <select value={kind} onChange={(e) => setKind(e.target.value)}>
            <option value="">(todos)</option>
            {kinds.map(k => <option key={k} value={k}>{k}</option>)}
          </select>
        </div>

        <div style={{ minWidth: 220 }}>
          <label>Resumo</label>
          <p style={{ margin: 0 }}><small>Total: <b>{services.length}</b> • Exibindo: <b>{filtered.length}</b></small></p>
          <div className="toolbar" style={{ marginTop: 6 }}>
            <button className="btn" type="button" onClick={load} disabled={loading}>
              {loading ? "Atualizando..." : "Atualizar"}
            </button>
            <Link className="btn btn-primary" href="/servicos/novo">+ Novo</Link>
          </div>
        </div>
      </div>

      <hr />

      {filtered.length === 0 ? (
        <p><small>Nenhum serviço ainda. Crie um em <b>/servicos/novo</b>.</small></p>
      ) : (
        <table>
          <thead>
            <tr>
              <th>Nome</th>
              <th>Tipo</th>
              <th>Slug</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map((s: any) => (
              <tr key={s.id}>
                <td><b>{s.name}</b></td>
                <td><small>{s.kind}</small></td>
                <td><small>{s.slug}</small></td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}