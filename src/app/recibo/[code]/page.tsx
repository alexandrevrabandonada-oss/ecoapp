"use client";

import Link from "next/link";
import { useEffect, useMemo, useState } from "react";
import { useParams } from "next/navigation";

type Receipt = {
  shareCode: string;
  createdAt: string;
  summary?: string | null;
  items?: string | null;
  operator?: string | null;
  request?: {
    name?: string | null;
    phone?: string | null;
    address?: string | null;
    notes?: string | null;
  } | null;
};

export default function ReciboPublicoPage() {
  const params = useParams<{ code: string }>();
  const code = params?.code ?? "";
  const [item, setItem] = useState<Receipt | null>(null);
  const [loading, setLoading] = useState(true);

  const shareUrl = useMemo(() => {
    if (typeof window === "undefined") return "";
    return window.location.href;
  }, []);

  useEffect(() => {
    async function load() {
      setLoading(true);
      const res = await fetch("/api/receipts/" + code, { cache: "no-store" });
      if (!res.ok) { setItem(null); setLoading(false); return; }
      const json = (await res.json()) as Receipt;
      setItem(json);
      setLoading(false);
    }
    if (code) load().catch(() => setLoading(false));
  }, [code]);

  function copy() {
    navigator.clipboard.writeText(shareUrl || window.location.href).catch(() => {});
  }

  return (
    <div className="stack">
      <div className="card">
        <div className="toolbar">
          <h1 style={{ margin: 0 }}>Recibo ECO</h1>
          <span className="badge">público</span>
        </div>
        <p style={{ marginTop: 8 }}>
          <small>Transparência simples (v0). Link compartilhável.</small>
        </p>

        <div className="toolbar" style={{ marginTop: 10 }}>
          <button className="btn" onClick={copy}>Copiar link</button>
          <a className="btn" href={"https://wa.me/?text=" + encodeURIComponent(shareUrl || "")} target="_blank" rel="noreferrer">WhatsApp</a>
          <Link className="btn" href="/recibos">Voltar</Link>
          <Link className="btn" href="/">HUB</Link>
        </div>
      </div>

      <div className="card">
        {loading ? <p><small>Carregando…</small></p> : null}
        {!loading && !item ? <p><small>Recibo não encontrado.</small></p> : null}

        {!loading && item ? (
          <div className="stack" style={{ marginTop: 10 }}>
            <p><small className="muted">{new Date(item.createdAt).toLocaleString()}</small></p>
            {item.summary ? <p><small><b>{item.summary}</b></small></p> : null}
            {item.request?.name ? <p><small><b>Nome:</b> {item.request.name}</small></p> : null}
            {item.request?.phone ? <p><small><b>Tel:</b> {item.request.phone}</small></p> : null}
            {item.request?.address ? <p><small><b>End:</b> {item.request.address}</small></p> : null}
            {item.request?.notes ? <p><small><b>Obs:</b> {item.request.notes}</small></p> : null}
            {item.items ? <p><small><b>Itens:</b> {item.items}</small></p> : null}
          </div>
        ) : null}
      </div>
    </div>
  );
}