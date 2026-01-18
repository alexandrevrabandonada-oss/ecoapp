"use client";

import { useEffect, useMemo, useState } from "react";

type AnyObj = Record<string, any>;

function uid() {
  const k = "eco_actor_v0";
  const cur = typeof window !== "undefined" ? window.localStorage.getItem(k) : null;
  if (cur) return cur;
  const v = "anon-" + Math.random().toString(16).slice(2) + "-" + Date.now().toString(16);
  if (typeof window !== "undefined") window.localStorage.setItem(k, v);
  return v;
}

async function jpost(url: string, body: AnyObj): Promise<AnyObj> {
  const res = await fetch(url, { method: "POST", headers: { "Content-Type": "application/json", Accept: "application/json" }, body: JSON.stringify(body), cache: "no-store" });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) return { ok: false, status: res.status, ...data };
  return data;
}
async function jget(url: string): Promise<AnyObj> {
  const res = await fetch(url, { headers: { Accept: "application/json" }, cache: "no-store" });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) return { ok: false, status: res.status, ...data };
  return data;
}

const KINDS = [
  ["LIXO_ACUMULADO", "Lixo acumulado"],
  ["ENTULHO_VOLUMOSO", "Entulho/volumoso"],
  ["QUEIMADA_FUMACA", "Queimada/fumaça"],
  ["ESGOTO_VAZAMENTO", "Esgoto/vazamento"],
  ["OLEO_QUIMICO", "Óleo/químico"],
  ["SENSIVEL_INDUSTRIAL", "Sensível/industrial"],
  ["OUTRO", "Outro"],
] as const;

function gmaps(lat: number, lng: number) {
  return "https://www.google.com/maps?q=" + encodeURIComponent(String(lat) + "," + String(lng));
}

export default function PontosClient() {
  const actor = useMemo(() => uid(), []);
  const [kind, setKind] = useState<string>("LIXO_ACUMULADO");
  const [note, setNote] = useState<string>("");
  const [lat, setLat] = useState<string>("");
  const [lng, setLng] = useState<string>("");
  const [msg, setMsg] = useState<string>("");
  const [items, setItems] = useState<AnyObj[]>([]);
  const [status, setStatus] = useState<string>("carregando");
  const [viewStatus, setViewStatus] = useState<string>("OPEN");

  // mutirão quick-form
  const [mutiraoId, setMutiraoId] = useState<string | null>(null);
  const [mutiraoStart, setMutiraoStart] = useState<string>("");
  const [mutiraoDur, setMutiraoDur] = useState<string>("90");

  const listUrl = useMemo(() => "/api/eco/critical/list?limit=120&status=" + encodeURIComponent(viewStatus), [viewStatus]);

  async function refresh() {
    setStatus("carregando");
    const d = await jget(listUrl);
    if (d && d.ok && Array.isArray(d.items)) { setItems(d.items); setStatus("ok"); }
    else { setItems([]); setStatus("erro"); }
  }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  // eslint-disable-next-line react-hooks/exhaustive-deps
  useEffect(() => { refresh(); }, []);
  async function useGeo() {
    setMsg("");
    if (!navigator.geolocation) { setMsg("Seu navegador não suporta geolocalização."); return; }
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        setLat(String(pos.coords.latitude));
        setLng(String(pos.coords.longitude));
        setMsg("Local capturado.");
      },
      () => setMsg("Não consegui pegar sua localização. Tente preencher manualmente."),
      { enableHighAccuracy: true, timeout: 8000 }
    );
  }

  async function createPoint() {
    setMsg("");
    const latN = Number(lat);
    const lngN = Number(lng);
    if (!Number.isFinite(latN) || !Number.isFinite(lngN)) { setMsg("Lat/Lng inválidos."); return; }
    const d = await jpost("/api/eco/critical/create", { kind, note: note.trim(), lat: latN, lng: lngN, actor });
    if (d && d.ok) {
      setMsg(d.deduped ? "Já existia ponto perto — usei o existente (dedupe)." : "Ponto criado.");
      setNote("");
      setViewStatus("OPEN");
      await refresh();
    } else {
      setMsg("Erro: " + String(d?.error || d?.detail || "unknown"));
    }
  }

  async function confirm(id: string) {
    setMsg("");
    const d = await jpost("/api/eco/critical/confirm", { pointId: id, actor });
    if (d && d.ok) {
      setMsg(d.confirmed ? "Confirmado: eu vi também." : "Você já tinha confirmado antes.");
      await refresh();
    } else {
      setMsg("Erro ao confirmar: " + String(d?.error || d?.detail || "unknown"));
    }
  }

  function openMutirao(id: string) {
    setMutiraoId(id);
    // prefill: amanhã 09:00 (local) sem Date.now() no SSR (isso roda em evento)
    try {
      const now = new Date();
      const d = new Date(now.getTime() + 24 * 60 * 60 * 1000);
      d.setHours(9, 0, 0, 0);
      const pad = (n: number) => String(n).padStart(2, "0");
      const v = d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate()) + "T" + pad(d.getHours()) + ":" + pad(d.getMinutes());
      setMutiraoStart(v);
    } catch {
      setMutiraoStart("");
    }
    setMutiraoDur("90");
  }

  async function createMutirao(pointId: string) {
    setMsg("");
    if (!mutiraoStart) { setMsg("Escolha data/hora do mutirão."); return; }
    const start = new Date(mutiraoStart);
    if (Number.isNaN(start.getTime())) { setMsg("Data/hora inválida."); return; }
    const dur = Math.max(15, Math.min(600, Number(mutiraoDur || 90) || 90));
    const d = await jpost("/api/eco/mutirao/create", { pointId, startAt: start.toISOString(), durationMin: dur, note: null, title: "Mutirão" });
    if (d && d.ok) {
      setMsg("Mutirão criado. Ponto entrou em MUTIRAO.");
      setMutiraoId(null);
      setViewStatus("MUTIRAO");
      await refresh();
    } else {
      setMsg("Erro ao criar mutirão: " + String(d?.error || d?.detail || "unknown"));
    }
  }

  return (
    <section style={{ display: "grid", gap: 12 }}>
      <div style={{ display: "flex", gap: 10, flexWrap: "wrap", alignItems: "center" }}>
        <a href="/eco/mutiroes" style={{ textDecoration: "none", padding: "8px 10px", borderRadius: 10, border: "1px solid #111" }}>
          Ver mutirões
        </a>
        <div style={{ opacity: 0.7 }}>lista: {viewStatus} • status: {status} • itens: {items.length}</div>
      </div>

      <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
        <button onClick={() => setViewStatus("OPEN")} style={{ padding: "8px 10px", borderRadius: 10, border: "1px solid #111", background: viewStatus === "OPEN" ? "#F7D500" : "#fff", fontWeight: 900, cursor: "pointer" }}>
          Pontos abertos
        </button>
        <button onClick={() => setViewStatus("MUTIRAO")} style={{ padding: "8px 10px", borderRadius: 10, border: "1px solid #111", background: viewStatus === "MUTIRAO" ? "#F7D500" : "#fff", fontWeight: 900, cursor: "pointer" }}>
          Viraram mutirão
        </button>
        <button onClick={refresh} style={{ padding: "8px 10px", borderRadius: 10, border: "1px solid #111", background: "#fff", cursor: "pointer" }}>
          Atualizar
        </button>
      </div>

      <div style={{ display: "grid", gap: 10, padding: 12, border: "1px solid #ddd", borderRadius: 12 }}>
        <div style={{ display: "flex", gap: 8, flexWrap: "wrap", alignItems: "center" }}>
          <div style={{ fontWeight: 900 }}>Marcar ponto</div>
          <button onClick={useGeo} style={{ padding: "8px 10px", borderRadius: 10, border: "1px solid #111", background: "#F7D500", color: "#111", fontWeight: 800, cursor: "pointer" }}>
            Usar minha localização
          </button>
        </div>

        <label style={{ display: "grid", gap: 4 }}>
          <span>Tipo</span>
          <select value={kind} onChange={(e) => setKind(e.target.value)} style={{ padding: 10, borderRadius: 10, border: "1px solid #ccc" }}>
            {KINDS.map(([k, label]) => (<option key={k} value={k}>{label}</option>))}
          </select>
        </label>

        <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
          <label style={{ display: "grid", gap: 4, flex: "1 1 160px" }}>
            <span>Lat</span>
            <input value={lat} onChange={(e) => setLat(e.target.value)} placeholder="-22.5" style={{ padding: 10, borderRadius: 10, border: "1px solid #ccc" }} />
          </label>
          <label style={{ display: "grid", gap: 4, flex: "1 1 160px" }}>
            <span>Lng</span>
            <input value={lng} onChange={(e) => setLng(e.target.value)} placeholder="-44.1" style={{ padding: 10, borderRadius: 10, border: "1px solid #ccc" }} />
          </label>
        </div>

        <label style={{ display: "grid", gap: 4 }}>
          <span>Observação (opcional)</span>
          <textarea value={note} onChange={(e) => setNote(e.target.value)} rows={3} placeholder="Ex.: na esquina tal, perto de..." style={{ padding: 10, borderRadius: 10, border: "1px solid #ccc" }} />
        </label>

        <button onClick={createPoint} style={{ padding: "10px 12px", borderRadius: 12, border: "1px solid #111", background: "#111", color: "#F7D500", fontWeight: 900, cursor: "pointer" }}>
          Criar ponto
        </button>

        {msg ? <div style={{ padding: 10, borderRadius: 10, background: "#fff7cc", border: "1px solid #f0d000" }}>{msg}</div> : null}
      </div>

      <div style={{ display: "grid", gap: 10 }}>
        {items.length ? items.map((it) => {
          const latN = Number(it.lat);
          const lngN = Number(it.lng);
          const maps = Number.isFinite(latN) && Number.isFinite(lngN) ? gmaps(latN, lngN) : "#";
          const id = String(it.id);
          const showMutirao = viewStatus === "OPEN";
          return (
            <div key={id} style={{ display: "grid", gap: 10, padding: 12, border: "1px solid #ddd", borderRadius: 12 }}>
              <div style={{ display: "flex", justifyContent: "space-between", gap: 10, alignItems: "center", flexWrap: "wrap" }}>
                <div style={{ display: "grid", gap: 4 }}>
                  <div style={{ fontWeight: 900 }}>{String(it.kind || "OUTRO")}</div>
                  <div style={{ opacity: 0.85 }}>{it.note ? String(it.note) : "—"}</div>
                  <div style={{ opacity: 0.7, fontSize: 12 }}>confirm: {String(it.confirmCount || 0)} • {it.createdAt ? String(it.createdAt) : ""}</div>
                </div>
                <div style={{ display: "flex", gap: 8, flexWrap: "wrap", justifyContent: "flex-end" }}>
                  <a href={maps} target="_blank" rel="noreferrer" style={{ textDecoration: "none", padding: "8px 10px", borderRadius: 10, border: "1px solid #111" }}>
                    Ver no mapa
                  </a>
                  <button onClick={() => confirm(id)} style={{ padding: "8px 10px", borderRadius: 10, border: "1px solid #111", background: "#F7D500", color: "#111", fontWeight: 900, cursor: "pointer" }}>
                    Eu vi também
                  </button>
                  {showMutirao ? (
                    <button onClick={() => openMutirao(id)} style={{ padding: "8px 10px", borderRadius: 10, border: "1px solid #111", background: "#111", color: "#F7D500", fontWeight: 900, cursor: "pointer" }}>
                      Virar mutirão
                    </button>
                  ) : null}
                </div>
              </div>

              {showMutirao && mutiraoId === id ? (
                <div style={{ display: "flex", gap: 10, flexWrap: "wrap", alignItems: "center", padding: 10, borderRadius: 12, border: "1px dashed #999" }}>
                  <label style={{ display: "grid", gap: 4 }}>
                    <span>Data/hora</span>
                    <input type="datetime-local" value={mutiraoStart} onChange={(e) => setMutiraoStart(e.target.value)} style={{ padding: 10, borderRadius: 10, border: "1px solid #ccc" }} />
                  </label>
                  <label style={{ display: "grid", gap: 4 }}>
                    <span>Duração (min)</span>
                    <input value={mutiraoDur} onChange={(e) => setMutiraoDur(e.target.value)} style={{ padding: 10, borderRadius: 10, border: "1px solid #ccc", width: 120 }} />
                  </label>
                  <button onClick={() => createMutirao(id)} style={{ padding: "10px 12px", borderRadius: 12, border: "1px solid #111", background: "#F7D500", color: "#111", fontWeight: 900, cursor: "pointer" }}>
                    Criar mutirão
                  </button>
                  <button onClick={() => setMutiraoId(null)} style={{ padding: "10px 12px", borderRadius: 12, border: "1px solid #111", background: "#fff", cursor: "pointer" }}>
                    Cancelar
                  </button>
                </div>
              ) : null}
            </div>
          );
        }) : (
          <div style={{ padding: 12, border: "1px solid #ddd", borderRadius: 12, opacity: 0.8 }}>
            Nenhum item nessa lista ({viewStatus}).
          </div>
        )}
      </div>
    </section>
  );
}

