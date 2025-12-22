"use client";

import Link from "next/link";
import { useEffect, useState } from "react";

type Receipt = {
  id: string;
  createdAt: string;
  shareCode: string;
  public: boolean;
  summary?: string | null;
  request?: { name?: string | null; address?: string | null } | null;
};

export default function RecibosPage() {
  const [items, setItems] = useState<Receipt[]>([]);
  const [loading, setLoading] = useState(true);

  async function load() {
    setLoading(true);
    const res = await fetch("/api/receipts", { cache: "no-store" });
    const json = (await res.json()) as unknown;
    const anyJson = json as any;
const arr = Array.isArray(anyJson) ? anyJson : Array.isArray(anyJson?.items) ? anyJson.items : [];
setItems(arr as Receipt[]);
setLoading(false);
  }

  useEffect(() => { load().catch(() => setLoading(false)); }, []);

  return (
    <div className="stack">
      <div className="card">
        <div className="toolbar">
          <h1 style={{ margin: 0 }}>Recibos ECO</h1>
          <span className="badge">v0</span>
        </div>
        <p style={{ marginTop: 8 }}>
          <small>Lista de recibos gerados. Cada recibo tem link público.</small>
        </p>
        <div className="toolbar" style={{ marginTop: 10 }}>
          <Link className="btn" href="/">HUB</Link>
          <Link className="btn" href="/chamar-coleta">Chamar Coleta</Link>
          <button className="btn" onClick={() => load()}>Atualizar</button>
        </div>
      </div>

      <div className="card">
        {loading ? <p><small>Carregando…</small></p> : null}
        {!loading && items.length === 0 ? <p><small>Nenhum recibo ainda.</small></p> : null}

        <div className="stack" style={{ marginTop: 10 }}>
          {items.map((r) => (
            <div key={r.id} className="card" style={{ padding: 12 }}>
              <div className="toolbar">
                <b>{r.summary || "Recibo ECO"}</b>
                <span className="badge">{r.public ? "PUBLIC" : "PRIVATE"}</span>
              </div>
              <p style={{ marginTop: 6 }}>
                <small className="muted">{new Date(r.createdAt).toLocaleString()}</small>
              </p>
              {r.request?.name ? <p style={{ marginTop: 6 }}><small><b>Nome:</b> {r.request.name}</small></p> : null}
              {r.request?.address ? <p style={{ marginTop: 6 }}><small><b>End:</b> {r.request.address}</small></p> : null}
              <div className="toolbar" style={{ marginTop: 10 }}>
                <Link className="primary" href={"/recibo/" + r.shareCode}>Abrir</Link>
                <Link className="btn" href="/chamar-coleta">Voltar</Link>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}