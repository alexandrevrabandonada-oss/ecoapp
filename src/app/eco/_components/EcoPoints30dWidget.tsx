"use client";

import { useEffect, useState } from "react";

export default function EcoPoints30dWidget(props: { days?: number; bairro?: string }) {
  const days = props?.days ?? 30;
  const bairro = props?.bairro || "";
  const [data, setData] = useState<any>(null);
  const [err, setErr] = useState<string | null>(null);
  const [loading, setLoading] = useState<boolean>(false);

  async function load() {
    setLoading(true);
    setErr(null);
    try {
      const qs = new URLSearchParams();
      qs.set("days", String(days));
      if (bairro) qs.set("bairro", bairro);
      const res = await fetch("/api/eco/points/stats?" + qs.toString(), { cache: "no-store" } as any);
      const j = await res.json().catch(() => null);
      if (!res.ok || !j?.ok) throw new Error(j?.detail || j?.error || ("HTTP " + res.status));
      setData(j);
    } catch (e: any) {
      setErr(e?.message || String(e));
    } finally {
      setLoading(false);
    }
  }

// eslint-disable-next-line react-hooks/exhaustive-deps
  useEffect(() => { void load(); }, [days, bairro]);

  const t = data?.totals;
  const open = Number(t?.open || 0);
  const resolved = Number(t?.resolved || 0);
  const total = Number(t?.total || 0);
  const ratio = total > 0 ? Math.round((resolved / total) * 100) : 0;

  return (
    <section style={{ margin: "14px 0", padding: 12, border: "1px solid #e5e5e5", borderRadius: 12, background: "#fff" }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", gap: 10 }}>
        <div style={{ fontWeight: 900 }}>Vitrine (últimos {days} dias): Pontos</div>
        <button onClick={() => void load()} disabled={loading} style={{ padding: "6px 10px", borderRadius: 10, border: "1px solid #ccc", background: "#fff" }}>
          Atualizar
        </button>
      </div>

      <div style={{ marginTop: 6, opacity: 0.75, fontSize: 12 }}>
        {bairro ? ("Bairro: " + bairro) : "Cidade (geral)"}
      </div>

      {err ? <div style={{ marginTop: 10, color: "#b00020" }}>{err}</div> : null}

      <div style={{ marginTop: 10, display: "grid", gridTemplateColumns: "repeat(3, minmax(0, 1fr))", gap: 10 }}>
        <div style={{ padding: 10, borderRadius: 12, border: "1px solid #111" }}>
          <div style={{ fontSize: 12, opacity: 0.75 }}>Abertos</div>
          <div style={{ fontSize: 28, fontWeight: 900 }}>{open}</div>
        </div>
        <div style={{ padding: 10, borderRadius: 12, border: "1px solid #111" }}>
          <div style={{ fontSize: 12, opacity: 0.75 }}>Resolvidos</div>
          <div style={{ fontSize: 28, fontWeight: 900 }}>{resolved}</div>
        </div>
        <div style={{ padding: 10, borderRadius: 12, border: "1px solid #111" }}>
          <div style={{ fontSize: 12, opacity: 0.75 }}>Taxa</div>
          <div style={{ fontSize: 28, fontWeight: 900 }}>{ratio}%</div>
        </div>
      </div>

      <div style={{ marginTop: 10, opacity: 0.8, fontSize: 12 }}>
        Regra política do ECO: <b>ponto só vira “resolvido” com mutirão finalizado (DONE)</b>. Recibo é lei.
      </div>
    </section>
  );
}
