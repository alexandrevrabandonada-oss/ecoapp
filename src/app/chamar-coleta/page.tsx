"use client";

import Link from "next/link";
import { useEffect, useState } from "react";

// ECO_STEP21C_PEDIDOS_TOKEN
const ECO_TOKEN_KEY = "eco_operator_token";
function ecoReadToken() {
  if (typeof window === "undefined") return "";
  try { return localStorage.getItem(ECO_TOKEN_KEY) || ""; } catch { return ""; }
}
function ecoAuthHeaders() {
  const t = (ecoReadToken() || "").trim();
  return t ? { "x-eco-token": t } : {};
}
// ECO_STEP21C_PEDIDOS_TOKEN_END
type Receipt = { shareCode: string } | null;

type Item = {
  id: string;
  createdAt: string;
  status: "OPEN" | "SCHEDULED" | "DONE" | "CANCELED";
  name?: string | null;
  phone?: string | null;
  address?: string | null;
  notes?: string | null;
  receipt?: Receipt;
};

export default function ChamarColetaPage() {
  const [items, setItems] = useState<Item[]>([]);
  const [loading, setLoading] = useState(true);
  const [busyId, setBusyId] = useState<string | null>(null);

  async function load() {
    setLoading(true);
    // ECO_HEADERS_CLEAN_START
    const __ecoRawHeaders = (ecoAuthHeaders() as Record<string, unknown>) || {};
    const __ecoHeaders: Record<string, string> = {};
    for (const [k, v] of Object.entries(__ecoRawHeaders)) {
      if (typeof v === "string" && v) __ecoHeaders[k] = v;
    }
    // ECO_HEADERS_CLEAN_END
    const res = await fetch("/api/pickup-requests", {
    headers: __ecoHeaders, cache: "no-store" });
    const json = (await res.json()) as unknown;
    setItems(Array.isArray(json) ? (json as Item[]) : []);
    setLoading(false);
  }

  async function setStatus(id: string, status: Item["status"]) {
    setBusyId(id);
    try {
      await fetch("/api/pickup-requests/" + id, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ status }),
      });
      await load();
    } finally {
      setBusyId(null);
    }
  }

  useEffect(() => {
    load().catch(() => setLoading(false));
  }, []);

  return (
    <div className="stack">
      <div className="card">
        <div className="toolbar">
          <h1 style={{ margin: 0 }}>Chamar Coleta</h1>
          <span className="badge">v0 + recibo</span>
        </div>

        <p style={{ marginTop: 8 }}>
          <small>
            Marque como <b>DONE</b> para gerar <b>Recibo ECO</b>.
          </small>
        </p>

        <div className="toolbar" style={{ marginTop: 10 }}>
          <Link className="primary" href="/chamar-coleta/novo">+ Novo pedido</Link>
          <Link className="btn" href="/recibos">Ver recibos</Link>
          <Link className="btn" href="/">HUB</Link>
          <button className="btn" onClick={() => load()}>Atualizar</button>
        </div>
      </div>

      <div className="card">
        <div className="toolbar">
          <h2 style={{ margin: 0 }}>Pedidos</h2>
          <span className="muted"><small>{items.length} itens</small></span>
        </div>

        {loading ? (
          <p><small>Carregando…</small></p>
        ) : items.length === 0 ? (
          <p><small>Nenhum pedido ainda.</small></p>
        ) : (
          <div className="stack" style={{ marginTop: 10 }}>
            {items.map((it) => (
              <div key={it.id} className="card" style={{ padding: 12 }}>
                <div className="toolbar">
                  <b>{it.name || "Sem nome"}</b>
                  <span className="badge">{it.status}</span>
                </div>

                <p style={{ marginTop: 6 }}>
                  <small className="muted">{new Date(it.createdAt).toLocaleString()}</small>
                </p>

                {it.phone ? <p style={{ marginTop: 6 }}><small><b>Tel:</b> {it.phone}</small></p> : null}
                {it.address ? <p style={{ marginTop: 6 }}><small><b>End:</b> {it.address}</small></p> : null}
                {it.notes ? <p style={{ marginTop: 6 }}><small><b>Obs:</b> {it.notes}</small></p> : null}

                <div className="toolbar" style={{ marginTop: 10 }}>
                  <button className="btn" disabled={busyId === it.id} onClick={() => setStatus(it.id, "OPEN")}>OPEN</button>
                  <button className="btn" disabled={busyId === it.id} onClick={() => setStatus(it.id, "SCHEDULED")}>SCHEDULE</button>
                  <button className="primary" disabled={busyId === it.id} onClick={() => setStatus(it.id, "DONE")}>DONE (gera recibo)</button>
                  <button className="btn" disabled={busyId === it.id} onClick={() => setStatus(it.id, "CANCELED")}>CANCEL</button>

                  {it.receipt?.shareCode ? (
                    <Link className="btn" href={"/recibo/" + it.receipt.shareCode}>Abrir recibo</Link>
                  ) : null}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}