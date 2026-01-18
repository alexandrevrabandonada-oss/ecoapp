"use client";

import React from "react";
import { useRouter } from "next/navigation";

function toNum(v: any): number {
  const n = typeof v === "number" ? v : parseFloat(String(v || ""));
  return Number.isFinite(n) ? n : 0;
}

export default function MuralNewPointClient() {
  const router = useRouter();
  const [lat, setLat] = React.useState<string>("");
  const [lng, setLng] = React.useState<string>("");
  const [note, setNote] = React.useState<string>("");
  const [busy, setBusy] = React.useState(false);
  const [msg, setMsg] = React.useState<string | null>(null);

  async function pickGeo() {
    setMsg(null);
    if (typeof window === "undefined") return;

    const g: any = (navigator as any).geolocation;
    if (!g) {
      setMsg("Sem GPS no navegador (ou permissão bloqueada).");
      return;
    }

    try {
      await new Promise<void>((resolve, reject) => {
        g.getCurrentPosition(
          (pos: any) => {
            const la = pos?.coords?.latitude;
            const lo = pos?.coords?.longitude;
            if (typeof la === "number" && typeof lo === "number") {
              setLat(String(la));
              setLng(String(lo));
              setMsg("📍 Localização preenchida. Agora é só registrar.");
              resolve();
            } else {
              reject(new Error("gps_bad_coords"));
            }
          },
          (err: any) => reject(err),
          { enableHighAccuracy: true, timeout: 12000, maximumAge: 15000 }
        );
      });
    } catch {
      setMsg("Não consegui pegar a localização (permite o GPS e tenta de novo).");
    }
  }

  async function submit() {
    setMsg(null);
    const la = toNum(lat);
    const lo = toNum(lng);
    if (!la || !lo) {
      setMsg("Preenche lat/lng (ou aperta 📍).");
      return;
    }

    setBusy(true);
    try {
      const payload: any = { lat: la, lng: lo, kind: "LIXO_ACUMULADO", status: "OPEN" };
      const n = note.trim();
      if (n) payload.note = n;

      const r = await fetch("/api/eco/points", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify(payload),
      });

      const j = await r.json().catch(() => ({} as any));

      if (!r.ok || !j?.ok) {
        const e = String(j?.error || r.status || "erro");
        setMsg("Erro ao registrar: " + e);
      } else {
        setMsg("✅ Ponto registrado!");
        setNote("");
        try { router.refresh(); } catch {}
      }
    } catch {
      setMsg("Falha ao registrar (rede/servidor).");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div
      style={{
        border: "1px solid #111",
        borderRadius: 14,
        padding: 12,
        background: "#fff",
        margin: "10px 0 14px 0",
      }}
    >
      <div style={{ fontWeight: 900, marginBottom: 8 }}>➕ Registrar ponto rápido</div>

      <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
        <input
          value={lat}
          onChange={(e) => setLat(e.target.value)}
          placeholder="lat (-22.52...)"
          style={{ padding: 10, borderRadius: 12, border: "1px solid #111", width: 170 }}
        />
        <input
          value={lng}
          onChange={(e) => setLng(e.target.value)}
          placeholder="lng (-44.10...)"
          style={{ padding: 10, borderRadius: 12, border: "1px solid #111", width: 170 }}
        />
        <button
          onClick={pickGeo}
          disabled={busy}
          style={{
            padding: "10px 12px",
            borderRadius: 12,
            border: "1px solid #111",
            fontWeight: 900,
            background: "#fff",
            cursor: "pointer",
          }}
        >
          📍 Usar minha localização
        </button>
      </div>

      <div style={{ marginTop: 8 }}>
        <input
          value={note}
          onChange={(e) => setNote(e.target.value)}
          placeholder="nota (opcional)"
          style={{ padding: 10, borderRadius: 12, border: "1px solid #111", width: "100%" }}
        />
      </div>

      <div style={{ display: "flex", gap: 8, alignItems: "center", marginTop: 10, flexWrap: "wrap" }}>
        <button
          onClick={submit}
          disabled={busy}
          style={{
            padding: "10px 12px",
            borderRadius: 12,
            border: "1px solid #111",
            fontWeight: 900,
            background: busy ? "#eee" : "#ff0",
            cursor: busy ? "default" : "pointer",
          }}
        >
          {busy ? "Registrando..." : "✅ Registrar"}
        </button>

        <div style={{ fontSize: 12, opacity: 0.85 }}>
          Tipo atual: <b>LIXO_ACUMULADO</b> (por enquanto).
        </div>
      </div>

      {msg ? <div style={{ marginTop: 8, fontSize: 12, opacity: 0.95 }}>{msg}</div> : null}
    </div>
  );
}