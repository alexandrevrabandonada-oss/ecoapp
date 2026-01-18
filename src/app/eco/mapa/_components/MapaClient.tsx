"use client";

import React, { useEffect, useMemo, useState } from "react";

type Counts = { confirm: number; support: number; replicar: number };
type AnyRec = Record<string, any>;

function num(v: any) { const n = Number(v); return Number.isFinite(n) ? n : 0; }
function getCounts(p: AnyRec): Counts {
  const c = (p && p.counts) ? p.counts : {};
  return {
    confirm: num(c.confirm ?? p.confirmCount ?? p.confirmados ?? 0),
    support: num(c.support ?? p.supportCount ?? p.apoioCount ?? 0),
    replicar: num(c.replicar ?? p.replicarCount ?? p.replicados ?? 0),
  };
}
function setCounts(p: AnyRec, counts: Counts) { return { ...p, counts }; }

function osmEmbedUrl(lat: number, lng: number) {
  const d = 0.005;
  const left = lng - d;
  const right = lng + d;
  const top = lat + d;
  const bottom = lat - d;
  const bbox = [left, bottom, right, top].map((x) => x.toFixed(6)).join("%2C");
  return "https://www.openstreetmap.org/export/embed.html?bbox=" + bbox + "&layer=mapnik&marker=" + lat.toFixed(6) + "%2C" + lng.toFixed(6);
}
function osmLink(lat: number, lng: number) {
  return "https://www.openstreetmap.org/?mlat=" + lat.toFixed(6) + "&mlon=" + lng.toFixed(6) + "#map=18/" + lat.toFixed(6) + "/" + lng.toFixed(6);
}

export default function MapaClient() {
  const [items, setItems] = useState<AnyRec[]>([]);
  const [loading, setLoading] = useState(true);
  const [err, setErr] = useState<string | null>(null);
  const [tab, setTab] = useState<"open" | "confirmed" | "all">("open");
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    let alive = true;
    (async () => {
      setLoading(true); setErr(null);
      try {
        const res = await fetch("/api/eco/points?limit=400", { cache: "no-store" });
        const j = await res.json();
        const arr = Array.isArray(j && j.items) ? j.items : (Array.isArray(j) ? j : []);
        if (!alive) return;
        setItems(arr);
        if (!selectedId && arr.length) setSelectedId(String(arr[0].id));
      } catch (e: any) {
        if (!alive) return;
        setErr(e && e.message ? String(e.message) : String(e));
      } finally {
        if (alive) setLoading(false);
      }
    })();
    return () => { alive = false; };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const filtered = useMemo(() => {
    const norm = (s: any) => String(s || "").toUpperCase();
    const isConfirmed = (p: AnyRec) => { const s = norm(p && p.status); return s === "CONFIRMED" || s === "DONE" || s === "RESOLVED" || s === "CLOSED"; };
    const isOpen = (p: AnyRec) => { const s = norm(p && p.status); return s === "" || s === "OPEN" || s === "NEW" || s === "PENDING"; };
    const pick = (p: AnyRec) => { if (tab === "all") return true; if (tab === "confirmed") return isConfirmed(p); return isOpen(p); };
    const out = (items || []).filter(pick);
    out.sort((a: AnyRec, b: AnyRec) => {
      const ad = Date.parse(String((a && (a.createdAt || a.created_at || a.ts)) || ""));
      const bd = Date.parse(String((b && (b.createdAt || b.created_at || b.ts)) || ""));
      return (Number.isFinite(bd) ? bd : 0) - (Number.isFinite(ad) ? ad : 0);
    });
    return out;
  }, [items, tab]);

  const selected = useMemo(() => {
    if (!selectedId) return null;
    return (items || []).find((x: AnyRec) => String(x && x.id) === String(selectedId)) || null;
  }, [items, selectedId]);

  async function doAction(action: "confirm" | "support" | "replicar") {
    if (!selected) return;
    setBusy(true);
    try {
      const body = { pointId: selected.id, action, actor: "dev" };
      const res = await fetch("/api/eco/points/action", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify(body),
      });
      const j = await res.json();
      if (!j || !j.ok) throw new Error(String((j && j.error) || "action_failed"));
      if (j && j.counts) {
        const counts = { confirm: num(j.counts.confirm), support: num(j.counts.support), replicar: num(j.counts.replicar) };
        setItems((prev) => (prev || []).map((p: AnyRec) => String(p && p.id) === String(selected.id) ? setCounts(p, counts) : p));
      }
    } catch (e: any) {
      alert("Falhou: " + (e && e.message ? String(e.message) : String(e)));
    } finally {
      setBusy(false);
    }
  }

  const lat = selected ? Number((selected as AnyRec).lat ?? (selected as AnyRec).latitude) : NaN;
  const lng = selected ? Number((selected as AnyRec).lng ?? (selected as AnyRec).lon ?? (selected as AnyRec).longitude) : NaN;
  const hasGeo = Number.isFinite(lat) && Number.isFinite(lng);
  const c = selected ? getCounts(selected as AnyRec) : { confirm: 0, support: 0, replicar: 0 };

  return (
    <div className="eco-mapa-grid" style={{ display: "grid", gridTemplateColumns: "1fr 1.2fr", gap: 16, alignItems: "start" }}>
      <div>
        <div style={{ display: "flex", gap: 8, flexWrap: "wrap", marginBottom: 12 }}>
          <button onClick={() => setTab("open")} disabled={loading} aria-pressed={tab === "open"}>Chamados</button>
          <button onClick={() => setTab("confirmed")} disabled={loading} aria-pressed={tab === "confirmed"}>Confirmados</button>
          <button onClick={() => setTab("all")} disabled={loading} aria-pressed={tab === "all"}>Todos</button>
          <button onClick={() => location.reload()} disabled={loading}>Atualizar</button>
        </div>

        {loading && <p>Carregando...</p>}
        {err && <p style={{ color: "#b00" }}>Erro: {err}</p>}
        {!loading && !filtered.length && <p>Sem pontos.</p>}

        <div style={{ display: "grid", gap: 10 }}>
          {filtered.map((p: AnyRec) => {
            const id = String((p && p.id) || "");
            const active = id === String(selectedId || "");
            const kind = String((p && p.kind) || "PONTO");
            const status = String((p && p.status) || "OPEN");
            const bairro = String((p && (p.bairro || p.neighborhood)) || "").trim();
            const note = String((p && p.note) || "").trim();
            const cc = getCounts(p);
            return (
              <button
                key={id}
                onClick={() => setSelectedId(id)}
                style={{
                  textAlign: "left",
                  padding: "10px 12px",
                  borderRadius: 12,
                  border: active ? "2px solid #111" : "1px solid #111",
                  background: active ? "#fff7cc" : "#fff",
                }}
              >
                <div style={{ display: "flex", justifyContent: "space-between", gap: 10, alignItems: "baseline" }}>
                  <strong style={{ textTransform: "uppercase" }}>{kind}</strong>
                  <span style={{ fontSize: 12, opacity: 0.75 }}>{status}</span>
                </div>
                <div style={{ fontSize: 13, opacity: 0.9, marginTop: 2 }}>
                  {bairro ? ("Bairro: " + bairro) : "Bairro: —"}{note ? (" · " + note) : ""}
                </div>
                <div style={{ display: "flex", gap: 10, marginTop: 8, fontSize: 12 }}>
                  <span>✅ {cc.confirm}</span>
                  <span>🤝 {cc.support}</span>
                  <span>♻️ {cc.replicar}</span>
                </div>
              </button>
            );
          })}
        </div>
      </div>

      <div>
        <div style={{ marginBottom: 12 }}>
          <h2 style={{ margin: 0 }}>Mapa</h2>
          {selected ? (
            <div style={{ fontSize: 13, opacity: 0.85 }}><strong>{String((selected as AnyRec).kind || "PONTO")}</strong> · {String(((selected as AnyRec).bairro || (selected as AnyRec).neighborhood) || "—")}</div>
          ) : (
            <div style={{ fontSize: 13, opacity: 0.85 }}>Selecione um ponto.</div>
          )}
        </div>

        {selected && (
          <div style={{ display: "flex", gap: 8, flexWrap: "wrap", marginBottom: 10 }}>
            <button onClick={() => doAction("confirm")} disabled={busy}>✅ Confirmar ({c.confirm})</button>
            <button onClick={() => doAction("support")} disabled={busy}>🤝 Apoiar ({c.support})</button>
            <button onClick={() => doAction("replicar")} disabled={busy}>♻️ Replicar ({c.replicar})</button>
            {hasGeo && (
              <a href={osmLink(lat, lng)} target="_blank" rel="noreferrer" style={{ padding: "10px 12px", border: "1px solid #111", borderRadius: 12, background: "#fff", fontWeight: 900 }}>
                Abrir no OpenStreetMap
              </a>
            )}
          </div>
        )}

        {selected && hasGeo ? (
          <iframe
            title="OpenStreetMap"
            src={osmEmbedUrl(lat, lng)}
            style={{ width: "100%", height: 520, border: "1px solid #111", borderRadius: 12, background: "#fff" }}
            loading="lazy"
          />
        ) : (
          <div style={{ padding: 16, border: "1px solid #111", borderRadius: 12, background: "#fff" }}>
            Sem coordenadas nesse ponto (ou selecione outro).
          </div>
        )}
      </div>

      <style>{
        "@media (max-width: 980px) { .eco-mapa-grid { grid-template-columns: 1fr !important; } }"
      }</style>
    </div>
  );
}