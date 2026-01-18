"use client";

import { useEffect, useMemo, useState } from "react";

type AnyObj = Record<string, any>;

function brDayToday(): string {
  try {
    const parts = new Intl.DateTimeFormat("en-CA", { timeZone: "America/Sao_Paulo", year: "numeric", month: "2-digit", day: "2-digit" }).formatToParts(new Date());
    const y = parts.find(p => p.type === "year")?.value || "";
    const m = parts.find(p => p.type === "month")?.value || "";
    const d = parts.find(p => p.type === "day")?.value || "";
    if (y && m && d) return y + "-" + m + "-" + d;
  } catch {}
  const dt = new Date();
  const y = String(dt.getFullYear());
  const m = String(dt.getMonth() + 1).padStart(2, "0");
  const d = String(dt.getDate()).padStart(2, "0");
  return y + "-" + m + "-" + d;
}

async function jget(url: string): Promise<AnyObj> {
  const res = await fetch(url, { headers: { Accept: "application/json" }, cache: "no-store" });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) return { ok: false, status: res.status, ...data };
  return data;
}

export default function FechamentoClient() {
  const [day, setDay] = useState<string>(brDayToday());
  const [busy, setBusy] = useState(false);
  const [result, setResult] = useState<AnyObj | null>(null);
  const [history, setHistory] = useState<AnyObj | null>(null);

  const dayCloseUrl = useMemo(() => "/api/eco/day-close?day=" + encodeURIComponent(day), [day]);
  const card34 = useMemo(() => "/api/eco/day-close/card?format=3x4&day=" + encodeURIComponent(day), [day]);
  const card11 = useMemo(() => "/api/eco/day-close/card?format=1x1&day=" + encodeURIComponent(day), [day]);
  const shareDay = useMemo(() => "/eco/share/dia/" + encodeURIComponent(day), [day]);

  async function loadHistory() {
    const data = await jget("/api/eco/day-close/list?limit=30");
    setHistory(data);
  }

  async function doClose(fresh: boolean) {
    setBusy(true);
    try {
      const url = dayCloseUrl + (fresh ? "&fresh=1" : "");
      const data = await jget(url);
      setResult(data);
      await loadHistory();
    } finally {
      setBusy(false);
    }
  }

  useEffect(() => {
    loadHistory();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return (
    <section style={{ display: "grid", gap: 12, maxWidth: 980 }}>
      <div style={{ display: "flex", gap: 10, alignItems: "center", flexWrap: "wrap" }}>
        <label style={{ display: "flex", gap: 8, alignItems: "center" }}>
          <span>Dia:</span>
          <input
            value={day}
            onChange={(e) => setDay(e.target.value)}
            placeholder="YYYY-MM-DD"
            style={{ padding: "6px 8px", border: "1px solid #ccc", borderRadius: 6, minWidth: 150 }}
          />
        </label>

        <button onClick={() => doClose(false)} disabled={busy} style={{ padding: "8px 10px", borderRadius: 8, border: "1px solid #111", cursor: busy ? "not-allowed" : "pointer" }}>
          Fechar / Buscar cache
        </button>

        <button onClick={() => doClose(true)} disabled={busy} style={{ padding: "8px 10px", borderRadius: 8, border: "1px solid #111", cursor: busy ? "not-allowed" : "pointer" }}>
          Recalcular (fresh=1)
        </button>

        <button onClick={() => loadHistory()} disabled={busy} style={{ padding: "8px 10px", borderRadius: 8, border: "1px solid #111", cursor: busy ? "not-allowed" : "pointer" }}>
          Atualizar histórico
        </button>

        <a href={shareDay} style={{ padding: "8px 10px", borderRadius: 8, border: "1px solid #111", textDecoration: "none", color: "#111", background: "#E0E0E0", fontWeight: 800 }}>
          Abrir Share
        </a>

        <a href={card34} target="_blank" rel="noreferrer" style={{ padding: "8px 10px", borderRadius: 8, border: "1px solid #111", textDecoration: "none", color: "#111", background: "#F7D500", fontWeight: 800 }}>
          Abrir Card 3:4
        </a>

        <a href={card11} target="_blank" rel="noreferrer" style={{ padding: "8px 10px", borderRadius: 8, border: "1px solid #111", textDecoration: "none", color: "#111", background: "#F7D500", fontWeight: 800 }}>
          Abrir Card 1:1
        </a>
      </div>

      <div style={{ display: "grid", gap: 12, gridTemplateColumns: "1fr 1fr" }}>
        <div>
          <h2 style={{ margin: "0 0 8px 0" }}>Resultado</h2>
          <pre style={{ whiteSpace: "pre-wrap", wordBreak: "break-word", padding: 12, border: "1px solid #ddd", borderRadius: 10, minHeight: 160 }}>
            {result ? JSON.stringify(result, null, 2) : "—"}
          </pre>
        </div>
        <div>
          <h2 style={{ margin: "0 0 8px 0" }}>Histórico (últimos 30)</h2>
          <pre style={{ whiteSpace: "pre-wrap", wordBreak: "break-word", padding: 12, border: "1px solid #ddd", borderRadius: 10, minHeight: 160 }}>
            {history ? JSON.stringify(history, null, 2) : "—"}
          </pre>
        </div>
      </div>
    </section>
  );
}

