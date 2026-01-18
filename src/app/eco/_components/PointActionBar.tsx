"use client";

import React, { useMemo, useState } from "react";

type Reactions = {
  confirm?: number;
  support?: number;
  call?: number;
  gratitude?: number;
  replicate?: number;
};

function safeNum(v: any) {
  const n = Number(v || 0);
  return Number.isFinite(n) ? n : 0;
}
function btnStyle(bg: string) {
  return { padding: "9px 10px", borderRadius: 12, border: "1px solid #111", background: bg, fontWeight: 900, cursor: "pointer", whiteSpace: "nowrap" } as const;
}

async function apiReact(id: string, action: string) {
  const r = await fetch("/api/eco/points/react", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ id, action, inc: 1 }),
  });
  return await r.json().catch(() => ({ ok: false, error: "bad_json" }));
}

export function PointActionBar(props: { pointId: string; initial?: any; compact?: boolean }) {
  const pointId = String(props.pointId || "");
  const compact = !!props.compact;

  const init = useMemo(() => {
    const rx = props.initial && typeof props.initial === "object" ? props.initial : null;
    return {
      confirm: safeNum(rx?.confirm),
      support: safeNum(rx?.support),
      call: safeNum(rx?.call),
      gratitude: safeNum(rx?.gratitude),
      replicate: safeNum(rx?.replicate),
    } as Reactions;
  }, [props.initial]);

  const [rx, setRx] = useState<Reactions>(init);
  const [toast, setToast] = useState("");
  const [busy, setBusy] = useState<string>("");

  async function act(action: string, label: string) {
    if (!pointId) return;
    setBusy(action);
    try {
      const j: any = await apiReact(pointId, action);
      if (!j?.ok) throw new Error(String(j?.error || "falha"));
      const next = j.reactions || {};
      setRx({
        confirm: safeNum(next.confirm),
        support: safeNum(next.support),
        call: safeNum(next.call),
        gratitude: safeNum(next.gratitude),
        replicate: safeNum(next.replicate),
      });
      setToast(label + " ✅");
      setTimeout(() => setToast(""), 1100);
    } catch (e: any) {
      setToast("Falhou: " + String(e?.message || e));
      setTimeout(() => setToast(""), 1400);
    } finally {
      setBusy("");
    }
  }

  const wrapStyle = compact
    ? ({ display: "flex", gap: 8, flexWrap: "wrap", alignItems: "center" } as const)
    : ({ display: "flex", gap: 10, flexWrap: "wrap", alignItems: "center" } as const);

  const __counts: any = (rx as any);
  const confirmN = Number(
    __counts?.confirmCount ??
    __counts?.confirm ??
    __counts?.CONFIRM ??
    __counts?.confirmar ??
    __counts?.CONFIRMAR ??
    __counts?.seen ??
    __counts?.ok ??
    __counts?.OK ??
    0
  ) || 0;

  return (
    <div style={{ display: "grid", gap: 8 }}>
      {confirmN > 0 ? (         <div style={{ fontSize: 12, fontWeight: 950, opacity: 0.9 }}>           ✅ Confirmado por {confirmN} pessoas         </div>       ) : null}
      <div style={wrapStyle}>
        <button disabled={!!busy} onClick={() => act("confirm", "Confirmado")} style={btnStyle("#FFDD00")}>✅ Confirmar ({safeNum(rx.confirm)})</button>
        <button disabled={!!busy} onClick={() => act("support", "Apoiado")} style={btnStyle("#fff")}>🤝 Apoiar ({safeNum(rx.support)})</button>
        <button disabled={!!busy} onClick={() => act("call", "Chamado")} style={btnStyle("#fff")}>📣 Chamado ({safeNum(rx.call)})</button>
        <button disabled={!!busy} onClick={() => act("gratitude", "Gratidao")} style={btnStyle("#fff")}>🌱 Gratidao ({safeNum(rx.gratitude)})</button>
        <button disabled={!!busy} onClick={() => act("replicate", "Replicado")} style={btnStyle("#fff")}>♻️ Replicar ({safeNum(rx.replicate)})</button>
      </div>
      {toast ? (
        <div style={{ fontSize: 12, fontWeight: 900, opacity: 0.9 }}>{toast}</div>
      ) : null}
    </div>
  );
}
