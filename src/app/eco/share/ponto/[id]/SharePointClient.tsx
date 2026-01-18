"use client";

import React, { useEffect, useMemo, useState } from "react";

type Reactions = {
  confirm?: number;
  support?: number;
  call?: number;
  gratitude?: number;
  replicate?: number;
};

type Item = {
  id: string;
  title: string;
  status: string;
  resolved: boolean;
  bairro?: string;
  cidade?: string;
  lat?: number | null;
  lng?: number | null;
  meta?: any;
};

async function apiGet(id: string) {
  const r = await fetch("/api/eco/points/get?id=" + encodeURIComponent(id), { cache: "no-store" });
  return await r.json().catch(() => ({ ok: false, error: "bad_json" }));
}

async function apiReact(id: string, action: string) {
  const r = await fetch("/api/eco/points/react", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ id, action, inc: 1 }),
  });
  return await r.json().catch(() => ({ ok: false, error: "bad_json" }));
}

function btn(bg: string) {
  return { padding: "9px 10px", borderRadius: 12, border: "1px solid #111", background: bg, fontWeight: 900, cursor: "pointer" } as const;
}

async function copyText(s: string) {
  try {
    await navigator.clipboard.writeText(s);
    return true;
  } catch {
    try {
      const ta = document.createElement("textarea");
      ta.value = s;
      ta.style.position = "fixed";
      ta.style.left = "-9999px";
      document.body.appendChild(ta);
      ta.select();
      document.execCommand("copy");
      document.body.removeChild(ta);
      return true;
    } catch {
      return false;
    }
  }
}

function safeNum(v: any) {
  const n = Number(v || 0);
  return Number.isFinite(n) ? n : 0;
}
function getRx(item: Item | null): Reactions {
  const m = item?.meta;
  const rx = m && m.reactions && typeof m.reactions === "object" ? m.reactions : null;
  return {
    confirm: safeNum(rx?.confirm),
    support: safeNum(rx?.support),
    call: safeNum(rx?.call),
    gratitude: safeNum(rx?.gratitude),
    replicate: safeNum(rx?.replicate),
  };
}

export function SharePointClient(props: { id: string }) {
  const id = String(props.id || "");
  const [item, setItem] = useState<Item | null>(null);
  const [loading, setLoading] = useState(true);
  const [err, setErr] = useState("");
  const [toast, setToast] = useState("");
  const [mounted, setMounted] = useState(false);
  const [origin, setOrigin] = useState("");
  const [rx, setRx] = useState<Reactions>({});

  useEffect(() => {
    setMounted(true);
    try { setOrigin(window.location.origin || ""); } catch {}
  }, []);

  useEffect(() => {
    let alive = true;
    (async () => {
      setLoading(true); setErr("");
      try {
        const j: any = await apiGet(id);
        if (!j?.ok) throw new Error(String(j?.error || "nao_encontrado"));
        if (!alive) return;
        setItem(j.item as Item);
        setRx(getRx(j.item as Item));
      } catch (e: any) {
        if (!alive) return;
        setErr(String(e?.message || e));
      } finally {
        if (!alive) return;
        setLoading(false);
      }
    })();
    return () => { alive = false; };
  }, [id]);

  const shareLink = useMemo(() => {
    const path = "/eco/share/ponto/" + encodeURIComponent(id);
    return origin ? (origin + path) : path;
  }, [origin, id]);

  const card3x4 = useMemo(() => "/api/eco/points/card?format=3x4&id=" + encodeURIComponent(id), [id]);
  const card1x1 = useMemo(() => "/api/eco/points/card?format=1x1&id=" + encodeURIComponent(id), [id]);

  const legenda = useMemo(() => {
    const t = item?.title ? item.title : "Ponto critico";
    const place = (item?.bairro ? (item.bairro + " — " + (item.cidade || "Volta Redonda")) : (item?.cidade || "Volta Redonda"));
    const st = item?.resolved ? "RESOLVIDO" : (item?.status || "ABERTO");
    const txt = "ECO — Ponto critico\\n" + t + "\\n" + place + "\\nStatus: " + st + "\\n" + shareLink + "\\n\\nAcoes: confirme, apoie e chame mutirao.\\n#ECO #ReciboECO #Reciclagem #VoltaRedonda #EconomiaSolidaria";
    return txt;
  }, [item, shareLink]);

  const waHref = useMemo(() => {
    if (!mounted) return "";
    return "https://wa.me/?text=" + encodeURIComponent(legenda);
  }, [mounted, legenda]);

  const mapsHref = useMemo(() => {
    if (!mounted) return "";
    const lat = item?.lat;
    const lng = item?.lng;
    if (typeof lat !== "number" || typeof lng !== "number") return "";
    return "https://www.google.com/maps?q=" + String(lat) + "," + String(lng);
  }, [mounted, item]);

  async function doCopyLink() {
    const ok = await copyText(shareLink);
    setToast(ok ? "Link copiado" : "Falha ao copiar");
    setTimeout(() => setToast(""), 1200);
  }
  async function doCopyLegenda() {
    const ok = await copyText(legenda);
    setToast(ok ? "Legenda copiada" : "Falha ao copiar");
    setTimeout(() => setToast(""), 1200);
  }

  async function act(action: string, label: string) {
    try {
      const j: any = await apiReact(id, action);
      if (!j?.ok) throw new Error(String(j?.error || "falha"));
      setRx({ ...rx, ...j.reactions });
      setToast(label + " ✅");
      setTimeout(() => setToast(""), 1200);
    } catch (e: any) {
      setToast("Falhou: " + String(e?.message || e));
      setTimeout(() => setToast(""), 1400);
    }
  }

  return (
    <section style={{ display: "grid", gap: 14 }}>
      {loading ? <div style={{ opacity: 0.85 }}>Carregando…</div> : null}
      {err ? <div style={{ padding: 12, border: "1px solid #111", borderRadius: 14, background: "#fff2f2" }}><b>Erro:</b> {err}</div> : null}

      <div style={{ display: "grid", gap: 10, border: "1px solid #111", borderRadius: 16, padding: 12, background: "#fff" }}>
        <div style={{ display: "flex", alignItems: "baseline", justifyContent: "space-between", gap: 10, flexWrap: "wrap" }}>
          <div style={{ display: "grid", gap: 6 }}>
            <div style={{ fontWeight: 950, fontSize: 16 }}>{item?.title || "Ponto critico"}</div>
            <div style={{ fontSize: 13, opacity: 0.8, fontWeight: 800 }}>{item?.bairro ? (item.bairro + " — " + (item.cidade || "Volta Redonda")) : (item?.cidade || "Volta Redonda")}</div>
            <div style={{ fontSize: 12, opacity: 0.7 }}>ID: {id}</div>
          </div>
          <div style={{ display: "flex", padding: "8px 12px", borderRadius: 999, border: "1px solid #111", background: item?.resolved ? "#B7FFB7" : "#FFDD00", fontWeight: 950 }}>
            {item?.resolved ? "RESOLVIDO" : (item?.status || "ABERTO")}
          </div>
        </div>

        <div style={{ display: "grid", gap: 10 }}>
          <div style={{ display: "grid", gap: 8 }}>
            <div style={{ fontWeight: 950 }}>Reacoes viram acoes</div>
            <div style={{ display: "flex", gap: 10, flexWrap: "wrap", alignItems: "center" }}>
              <button onClick={() => act("confirm","Confirmado")} style={btn("#FFDD00")}>✅ Confirmar ({safeNum(rx.confirm)})</button>
              <button onClick={() => act("support","Apoiado")} style={btn("#fff")}>🤝 Apoiar ({safeNum(rx.support)})</button>
              <button onClick={() => act("call","Chamado")} style={btn("#fff")}>📣 Chamado ({safeNum(rx.call)})</button>
              <button onClick={() => act("gratitude","Gratidao")} style={btn("#fff")}>🌱 Gratidao ({safeNum(rx.gratitude)})</button>
              <button onClick={() => act("replicate","Replicado")} style={btn("#fff")}>♻️ Replicar ({safeNum(rx.replicate)})</button>
            </div>
            <div style={{ fontSize: 12, opacity: 0.7 }}>
              (v0) Contadores no meta do ponto — sem login ainda.
            </div>
          </div>

          <div style={{ display: "grid", gap: 8 }}>
            <div style={{ fontWeight: 950 }}>Cards</div>
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10 }}>
              <a href={card3x4} target="_blank" rel="noreferrer" style={{ textDecoration: "none", color: "#111" }}>
                <div style={{ border: "1px solid #111", borderRadius: 14, padding: 10, display: "grid", gap: 8 }}>
                  <div style={{ fontWeight: 900 }}>3:4 (1080×1350)</div>
{/* eslint-disable-next-line @next/next/no-img-element */}
                  <img src={card3x4} alt="card 3x4" style={{ width: "100%", borderRadius: 12, border: "1px solid #111", background: "#111" }} />
                </div>
              </a>
              <a href={card1x1} target="_blank" rel="noreferrer" style={{ textDecoration: "none", color: "#111" }}>
                <div style={{ border: "1px solid #111", borderRadius: 14, padding: 10, display: "grid", gap: 8 }}>
                  <div style={{ fontWeight: 900 }}>1:1 (1080×1080)</div>
{/* eslint-disable-next-line @next/next/no-img-element */}
                  <img src={card1x1} alt="card 1x1" style={{ width: "100%", borderRadius: 12, border: "1px solid #111", background: "#111" }} />
                </div>
              </a>
            </div>
          </div>

          <div style={{ display: "grid", gap: 8 }}>
            <div style={{ fontWeight: 950 }}>Acoes rapidas</div>
            <div style={{ display: "flex", gap: 10, flexWrap: "wrap" }}>
              <button onClick={doCopyLink} style={btn("#FFDD00")}>Copiar link</button>
              <button onClick={doCopyLegenda} style={btn("#fff")}>Copiar legenda</button>
              {mounted ? (
                <a href={waHref} target="_blank" rel="noreferrer" style={{ padding: "9px 10px", borderRadius: 12, border: "1px solid #111", textDecoration: "none", color: "#111", fontWeight: 900, background: "#fff" }}>
                  WhatsApp
                </a>
              ) : (
                <span style={{ padding: "9px 10px", borderRadius: 12, border: "1px solid #111", opacity: 0.6, fontWeight: 900 }}>WhatsApp</span>
              )}
              {mapsHref ? (
                <a href={mapsHref} target="_blank" rel="noreferrer" style={{ padding: "9px 10px", borderRadius: 12, border: "1px solid #111", textDecoration: "none", color: "#111", fontWeight: 900, background: "#fff" }}>
                  Ver no mapa
                </a>
              ) : null}
            </div>
          </div>

          <div style={{ display: "grid", gap: 8 }}>
            <div style={{ fontWeight: 950 }}>Legenda</div>
            <textarea readOnly value={legenda} style={{ width: "100%", minHeight: 140, padding: 10, borderRadius: 12, border: "1px solid #111", fontFamily: "ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace", fontSize: 12 }} />
          </div>
        </div>
      </div>

      {toast ? (
        <div style={{ position: "sticky", bottom: 10, display: "flex", justifyContent: "center" }}>
          <div style={{ padding: "10px 12px", borderRadius: 14, border: "1px solid #111", background: "#FFDD00", fontWeight: 950 }}>
            {toast}
          </div>
        </div>
      ) : null}
    </section>
  );
}
