"use client";

import { useEffect, useMemo, useState } from "react";

type AnyObj = Record<string, any>;

async function jget(url: string): Promise<AnyObj> {
  const res = await fetch(url, { headers: { Accept: "application/json" }, cache: "no-store" });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) return { ok: false, status: res.status, ...data };
  return data;
}

function fmtDate(day: string) {
  const s = String(day || "");
  if (/^\\d{4}-\\d{2}-\\d{2}$/.test(s)) {
    const y = s.slice(0, 4);
    const m = s.slice(5, 7);
    const d = s.slice(8, 10);
    return d + "/" + m + "/" + y;
  }
  return s;
}

function clip(text: string) {
  try {
    if (navigator && navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(text);
    }
  } catch {}
}

export default function RecibosClient() {
  const [data, setData] = useState<AnyObj | null>(null);
  const [status, setStatus] = useState<string>("carregando");
  const [msg, setMsg] = useState<string>("");
  const [limit, setLimit] = useState<number>(30);

  const url = useMemo(() => "/api/eco/recibo/list?limit=" + encodeURIComponent(String(limit)), [limit]);

  async function refresh() {
    setStatus("carregando");
    setMsg("");
    const d = await jget(url);
    if (d && d.ok) {
      setData(d);
      setStatus("ok");
    } else {
      setData(null);
      setStatus("erro");
      setMsg("Erro: " + String(d?.error || d?.detail || "unknown"));
    }
  }

  // eslint-disable-next-line react-hooks/exhaustive-deps

  // eslint-disable-next-line react-hooks/exhaustive-deps

// eslint-disable-next-line react-hooks/exhaustive-deps
  useEffect(() => { refresh(); }, []);
  const dayCloses = Array.isArray(data?.dayCloses) ? data!.dayCloses : [];
  const mutiroes = Array.isArray(data?.mutiroes) ? data!.mutiroes : [];

  return (
    <section style={{ display: "grid", gap: 14 }}>
      <div style={{ display: "flex", gap: 10, flexWrap: "wrap", alignItems: "center" }}>
        <a href="/eco" style={{ textDecoration: "none", padding: "8px 10px", borderRadius: 10, border: "1px solid #111" }}>Voltar</a>
        <button onClick={refresh} style={{ padding: "8px 10px", borderRadius: 10, border: "1px solid #111", background: "#fff", cursor: "pointer" }}>Atualizar</button>
        <label style={{ display: "flex", gap: 8, alignItems: "center" }}>
          <span style={{ opacity: 0.75 }}>limite</span>
          <input value={String(limit)} onChange={(e) => setLimit(Number(e.target.value || 30))} style={{ width: 90, padding: "8px 10px", borderRadius: 10, border: "1px solid #ccc" }} />
        </label>
        <div style={{ opacity: 0.7 }}>status: {status}</div>
      </div>

      {msg ? <div style={{ padding: 10, borderRadius: 10, background: "#fff7cc", border: "1px solid #f0d000" }}>{msg}</div> : null}

      <div style={{ display: "grid", gap: 10, padding: 12, border: "1px solid #ddd", borderRadius: 12 }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline" }}>
          <div style={{ fontWeight: 900 }}>Fechamentos do dia</div>
          <div style={{ opacity: 0.7, fontSize: 12 }}>fonte: {String(data?.sources?.dayClose || "—")}</div>
        </div>

        {dayCloses.length === 0 ? <div style={{ opacity: 0.7 }}>Nenhum fechamento encontrado.</div> : null}

        <div style={{ display: "grid", gap: 10 }}>
          {dayCloses.map((it: AnyObj) => {
            const day = String(it.day || "");
            const share = "/eco/share/dia/" + encodeURIComponent(day);
            const card = "/api/eco/day-close/card?format=3x4&day=" + encodeURIComponent(day);
            const totalKg = it?.summary?.totals?.totalKg;
            const count = it?.summary?.totals?.count;
            const legend = "ECO — Fechamento do dia " + day + "\\n" +
              "Total: " + String(totalKg ?? "—") + " kg • Itens: " + String(count ?? "—") + "\\n" +
              "#ECO — Escutar • Cuidar • Organizar";

            return (
              <div key={day} style={{ display: "grid", gap: 8, padding: 12, borderRadius: 12, border: "1px solid #eee" }}>
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline" }}>
                  <div style={{ fontWeight: 900 }}>{fmtDate(day)}</div>
                  <div style={{ opacity: 0.8, fontSize: 12 }}>kg: {String(totalKg ?? "—")} • itens: {String(count ?? "—")}</div>
                </div>
                <div style={{ display: "flex", gap: 10, flexWrap: "wrap", alignItems: "center" }}>
                  <a href={share} style={{ textDecoration: "none", padding: "8px 10px", borderRadius: 10, border: "1px solid #111" }}>Abrir share</a>
                  <a href={card} target="_blank" rel="noreferrer" style={{ textDecoration: "none", padding: "8px 10px", borderRadius: 10, border: "1px solid #111" }}>Abrir card 3:4</a>
                  <button onClick={() => clip(legend)} style={{ padding: "8px 10px", borderRadius: 10, border: "1px solid #111", background: "#fff", cursor: "pointer" }}>Copiar legenda</button>
                </div>
              </div>
            );
          })}
        </div>
      </div>

      <div style={{ display: "grid", gap: 10, padding: 12, border: "1px solid #ddd", borderRadius: 12 }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline" }}>
          <div style={{ fontWeight: 900 }}>Mutirões concluídos</div>
          <div style={{ opacity: 0.7, fontSize: 12 }}>fonte: {String(data?.sources?.mutirao || "—")}</div>
        </div>

        {mutiroes.length === 0 ? <div style={{ opacity: 0.7 }}>Nenhum mutirão concluído encontrado.</div> : null}

        <div style={{ display: "grid", gap: 10 }}>
          {mutiroes.map((it: AnyObj) => {
            const id = String(it.id || "");
            const startAt = String(it.startAt || "");
            const day = startAt ? startAt.slice(0, 10) : "";
            const share = "/eco/share/mutirao/" + encodeURIComponent(id);
            const card = "/api/eco/mutirao/card?format=3x4&id=" + encodeURIComponent(id);
            const kind = String(it?.point?.kind || "PONTO");
            const note = String(it?.point?.note || "");
            const confirm = String(it?.point?.confirmCount || 0);

            const legend = "ECO — Mutirão concluído\\n" +
              (day ? ("Data: " + day + "\\n") : "") +
              "Ponto: " + kind + "\\n" +
              (note ? ("Obs: " + note + "\\n") : "") +
              "Confirmações: " + confirm + "\\n" +
              "#ECO — Escutar • Cuidar • Organizar";

            return (
              <div key={id} style={{ display: "grid", gap: 8, padding: 12, borderRadius: 12, border: "1px solid #eee" }}>
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline", gap: 10 }}>
                  <div style={{ fontWeight: 900 }}>{kind}</div>
                  <div style={{ opacity: 0.75, fontSize: 12 }}>conf.: {confirm}</div>
                </div>
                {note ? <div style={{ opacity: 0.85 }}>{note}</div> : null}
                <div style={{ display: "flex", gap: 10, flexWrap: "wrap", alignItems: "center" }}>
                  <a href={share} style={{ textDecoration: "none", padding: "8px 10px", borderRadius: 10, border: "1px solid #111" }}>Abrir share</a>
                  <a href={card} target="_blank" rel="noreferrer" style={{ textDecoration: "none", padding: "8px 10px", borderRadius: 10, border: "1px solid #111" }}>Abrir card 3:4</a>
                  <button onClick={() => clip(legend)} style={{ padding: "8px 10px", borderRadius: 10, border: "1px solid #111", background: "#fff", cursor: "pointer" }}>Copiar legenda</button>
                </div>
              </div>
            );
          })}
        </div>
      </div>

      <div style={{ opacity: 0.7, fontSize: 12 }}>
        Dica: esse hub é pra operar “prova forte”: fechamento do dia e mutirão com antes/depois.
      </div>
    </section>
  );
}
