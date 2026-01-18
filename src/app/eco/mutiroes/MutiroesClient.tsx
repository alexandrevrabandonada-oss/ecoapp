"use client";

import { useEffect, useMemo, useState } from "react";

type AnyObj = Record<string, any>;

async function jget(url: string): Promise<AnyObj> {
  const res = await fetch(url, { headers: { Accept: "application/json" }, cache: "no-store" });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) return { ok: false, status: res.status, ...data };
  return data;
}

function fmt(dt: string) {
  try {
    const d = new Date(dt);
    return d.toLocaleString();
  } catch {
    return dt;
  }
}
function gmaps(lat: number, lng: number) {
  return "https://www.google.com/maps?q=" + encodeURIComponent(String(lat) + "," + String(lng));
}

export default function MutiroesClient() {
  const [items, setItems] = useState<AnyObj[]>([]);
  const [status, setStatus] = useState<string>("carregando");
  const url = useMemo(() => "/api/eco/mutirao/list?limit=120", []);

  async function refresh() {
    setStatus("carregando");
    const d = await jget(url);
    if (d && d.ok && Array.isArray(d.items)) { setItems(d.items); setStatus("ok"); }
    else { setItems([]); setStatus("erro"); }
  }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  // eslint-disable-next-line react-hooks/exhaustive-deps
  useEffect(() => { refresh(); }, []);
  return (
    <section style={{ display: "grid", gap: 10 }}>
      <div style={{ display: "flex", gap: 10, alignItems: "center", flexWrap: "wrap" }}>
        <button onClick={refresh} style={{ padding: "8px 10px", borderRadius: 10, border: "1px solid #111", background: "#F7D500", color: "#111", fontWeight: 900, cursor: "pointer" }}>
          Atualizar
        </button>
        <a href="/eco/pontos" style={{ textDecoration: "none", padding: "8px 10px", borderRadius: 10, border: "1px solid #111" }}>
          Voltar aos pontos
        </a>
        <div style={{ opacity: 0.7 }}>status: {status} • itens: {items.length}</div>
      </div>

      {items.length ? items.map((it) => {
        const p = it.point || {};
        const lat = Number(p.lat);
        const lng = Number(p.lng);
        const maps = Number.isFinite(lat) && Number.isFinite(lng) ? gmaps(lat, lng) : "#";
        const id = String(it.id);
        return (
          <div key={id} style={{ display: "flex", justifyContent: "space-between", gap: 10, padding: 12, border: "1px solid #ddd", borderRadius: 12, alignItems: "center" }}>
            <div style={{ display: "grid", gap: 4 }}>
              <div style={{ fontWeight: 900 }}>{it.title ? String(it.title) : "Mutirão"}</div>
              <div style={{ opacity: 0.85 }}>🗓 {it.startAt ? fmt(String(it.startAt)) : ""} • ⏱ {String(it.durationMin || 90)} min • {String(it.status || "SCHEDULED")}</div>
              <div style={{ opacity: 0.8 }}>Ponto: {String(p.kind || "")} • confirmações: {String(p.confirmCount || 0)}</div>
              <div style={{ opacity: 0.75, fontSize: 12 }}>{p.note ? String(p.note) : "—"}</div>
            </div>
            <div style={{ display: "flex", gap: 8, flexWrap: "wrap", justifyContent: "flex-end" }}>
              <a href={maps} target="_blank" rel="noreferrer" style={{ textDecoration: "none", padding: "8px 10px", borderRadius: 10, border: "1px solid #111" }}>
                Ver no mapa
              </a>
              <a href={"/eco/mutiroes/" + encodeURIComponent(id)} style={{ textDecoration: "none", padding: "8px 10px", borderRadius: 10, border: "1px solid #111" }}>
                Abrir
              </a>
              <a href={"/eco/share/mutirao/" + encodeURIComponent(id)} style={{ textDecoration: "none", padding: "8px 10px", borderRadius: 10, border: "1px solid #111" }}>
                Compartilhar
              </a>
            </div>
          </div>
        );
      }) : (
        <div style={{ padding: 12, border: "1px solid #ddd", borderRadius: 12, opacity: 0.8 }}>
          Nenhum mutirão ainda. Vá em /eco/pontos e clique em “Virar mutirão”.
        </div>
      )}
    </section>
  );
}

