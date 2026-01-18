"use client";

import { useEffect, useMemo, useState } from "react";

type AnyObj = Record<string, any>;

function monthNow(): string {
  const d = new Date();
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, "0");
  return String(y) + "-" + m;
}

async function jget(url: string): Promise<AnyObj> {
  const res = await fetch(url, { headers: { Accept: "application/json" }, cache: "no-store" });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) return { ok: false, status: res.status, ...data };
  return data;
}

export default function TransparenciaClient() {
  const [items, setItems] = useState<AnyObj[]>([]);
  const [status, setStatus] = useState<string>("carregando");

  const listUrl = useMemo(() => "/api/eco/month-close/list?limit=24", []);
  const m0 = useMemo(() => monthNow(), []);

  useEffect(() => {
    let alive = true;
    (async () => {
      setStatus("carregando");
      const d = await jget(listUrl);
      if (!alive) return;
      if (d && d.ok && Array.isArray(d.items)) {
        setItems(d.items);
        setStatus("ok");
      } else {
        setItems([]);
        setStatus("erro");
      }
    })();
    return () => { alive = false; };
  }, [listUrl]);

  return (
    <section style={{ display: "grid", gap: 12 }}>
      <div style={{ display: "flex", gap: 10, flexWrap: "wrap", alignItems: "center" }}>
        <a href={"/eco/share/mes/" + m0} style={{ textDecoration: "none", padding: "8px 10px", borderRadius: 10, border: "1px solid #111", background: "#F7D500", color: "#111", fontWeight: 800 }}>
          Compartilhar mês atual ({m0})
        </a>
        <a href={"/api/eco/month-close?month=" + m0 + "&fresh=1"} target="_blank" rel="noreferrer" style={{ textDecoration: "none", padding: "8px 10px", borderRadius: 10, border: "1px solid #111" }}>
          Recalcular mês atual
        </a>
        <div style={{ opacity: 0.75 }}>status: {status} • itens: {items.length}</div>
      </div>

      <div style={{ display: "grid", gap: 10 }}>
        {items.length ? items.map((it) => {
          const month = String(it.month || "");
          const sum = (it.summary || {}) as any;
          const totals = (sum.totals || {}) as any;
          const totalKg = totals.totalKg != null ? totals.totalKg : 0;
          return (
            <div key={month} style={{ display: "flex", justifyContent: "space-between", gap: 10, padding: 12, border: "1px solid #ddd", borderRadius: 12, alignItems: "center" }}>
              <div style={{ display: "grid", gap: 4 }}>
                <div style={{ fontWeight: 900 }}>{month}</div>
                <div style={{ opacity: 0.8 }}>totalKg: {String(totalKg)}</div>
              </div>
              <div style={{ display: "flex", gap: 8, flexWrap: "wrap", justifyContent: "flex-end" }}>
                <a href={"/eco/share/mes/" + month} style={{ textDecoration: "none", padding: "8px 10px", borderRadius: 10, border: "1px solid #111", background: "#F7D500", color: "#111", fontWeight: 800 }}>
                  Share
                </a>
                <a href={"/api/eco/month-close/card?format=3x4&month=" + month} target="_blank" rel="noreferrer" style={{ textDecoration: "none", padding: "8px 10px", borderRadius: 10, border: "1px solid #111" }}>
                  Card 3:4
                </a>
                <a href={"/api/eco/month-close/card?format=1x1&month=" + month} target="_blank" rel="noreferrer" style={{ textDecoration: "none", padding: "8px 10px", borderRadius: 10, border: "1px solid #111" }}>
                  Card 1:1
                </a>
              </div>
            </div>
          );
        }) : (
          <div style={{ padding: 12, border: "1px solid #ddd", borderRadius: 12, opacity: 0.8 }}>
            Sem fechamentos mensais ainda. Clique em “Compartilhar mês atual” para gerar o primeiro.
          </div>
        )}
      </div>
    </section>
  );
}

