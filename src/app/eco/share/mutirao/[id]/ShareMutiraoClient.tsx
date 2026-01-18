"use client";

import { useMemo, useState } from "react";

function enc(s: string) { return encodeURIComponent(s); }

export default function ShareMutiraoClient({ id }: { id: string }) {
  const [copied, setCopied] = useState(false);

  const base = useMemo(() => {
    if (typeof window === "undefined") return "";
    return window.location.origin;
  }, []);

  const shareUrl = useMemo(() => (base ? (base + "/eco/share/mutirao/" + enc(id)) : ("/eco/share/mutirao/" + enc(id))), [base, id]);
  const card34 = useMemo(() => ("/api/eco/mutirao/card?format=3x4&id=" + enc(id)), [id]);
  const card11 = useMemo(() => ("/api/eco/mutirao/card?format=1x1&id=" + enc(id)), [id]);

  const legend = useMemo(() => {
    const parts: string[] = [];
    parts.push("ECO — Mutirão (prova do cuidado)");
    parts.push("");
    parts.push("Mutirão: " + id);
    parts.push("Recibo é lei. Cuidado é coletivo.");
    parts.push("");
    parts.push("Link: " + shareUrl);
    return parts.join("\\n");
  }, [id, shareUrl]);

  const wa = useMemo(() => {
    return "https://wa.me/?text=" + enc(legend);
  }, [legend]);

  async function copyLink() {
    setCopied(false);
    try {
      await navigator.clipboard.writeText(shareUrl);
      setCopied(true);
      setTimeout(() => setCopied(false), 1200);
    } catch {
      // ignore
    }
  }
  async function copyLegend() {
    setCopied(false);
    try {
      await navigator.clipboard.writeText(legend);
      setCopied(true);
      setTimeout(() => setCopied(false), 1200);
    } catch {
      // ignore
    }
  }

  return (
    <section style={{ display: "grid", gap: 12 }}>
      <div style={{ display: "flex", gap: 10, flexWrap: "wrap" }}>
        <button onClick={() => void copyLink()} style={{ padding: "10px 12px", borderRadius: 12, border: "1px solid #111", background: "#111", color: "#fff" }}>
          Copiar link
        </button>
        <button onClick={() => void copyLegend()} style={{ padding: "10px 12px", borderRadius: 12, border: "1px solid #111", background: "#fff", color: "#111" }}>
          Copiar legenda
        </button>
        <a href={wa} target="_blank" rel="noreferrer" style={{ padding: "10px 12px", borderRadius: 12, border: "1px solid #111", textDecoration: "none", color: "#111", background: "#FFDD00", fontWeight: 900 }}>
          WhatsApp
        </a>
        {copied ? <span style={{ alignSelf: "center", opacity: 0.85 }}>Copiado ✅</span> : null}
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>
        <div style={{ padding: 12, border: "1px solid #e5e5e5", borderRadius: 12, background: "#fff" }}>
          <div style={{ fontWeight: 900, marginBottom: 8 }}>Card 3x4</div>
          <a href={card34} target="_blank" rel="noreferrer" style={{ display: "inline-block", textDecoration: "none", border: "1px solid #111", padding: "10px 12px", borderRadius: 12, color: "#111" }}>Abrir PNG</a>
          <div style={{ marginTop: 10, borderRadius: 12, overflow: "hidden", border: "1px solid #ddd" }}>
{/* eslint-disable-next-line @next/next/no-img-element */}
            <img src={card34} alt="card 3x4" style={{ width: "100%", height: "auto", display: "block" }} />
          </div>
        </div>
        <div style={{ padding: 12, border: "1px solid #e5e5e5", borderRadius: 12, background: "#fff" }}>
          <div style={{ fontWeight: 900, marginBottom: 8 }}>Card 1x1</div>
          <a href={card11} target="_blank" rel="noreferrer" style={{ display: "inline-block", textDecoration: "none", border: "1px solid #111", padding: "10px 12px", borderRadius: 12, color: "#111" }}>Abrir PNG</a>
          <div style={{ marginTop: 10, borderRadius: 12, overflow: "hidden", border: "1px solid #ddd" }}>
{/* eslint-disable-next-line @next/next/no-img-element */}
            <img src={card11} alt="card 1x1" style={{ width: "100%", height: "auto", display: "block" }} />
          </div>
        </div>
      </div>

      <div style={{ padding: 12, border: "1px solid #e5e5e5", borderRadius: 12, background: "#fff" }}>
        <div style={{ fontWeight: 900, marginBottom: 8 }}>Legenda</div>
        <pre style={{ margin: 0, whiteSpace: "pre-wrap", fontFamily: "ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace", fontSize: 13, lineHeight: 1.35 }}>{legend}</pre>
      </div>
    </section>
  );
}
