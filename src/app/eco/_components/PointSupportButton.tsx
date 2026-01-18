"use client";

import React from "react";

type AnyObj = any;

function n(v: any): number {
  const x = Number(v);
  return Number.isFinite(x) ? x : 0;
}

function pickId(pointId?: any, point?: AnyObj): string {
  const pid = pointId ?? point?.id ?? point?.pointId ?? point?.criticalPointId ?? point?.ecoCriticalPointId ?? "";
  return String(pid || "");
}

function pickCount(initialCount?: any, point?: AnyObj): number {
  if (initialCount != null) return n(initialCount);
  const c = point?.counts?.support ?? point?.supportCount ?? point?.counts?.apoio ?? point?.apoioCount ?? 0;
  return n(c);
}

export default function PointSupportButton(props: { pointId?: string; point?: AnyObj; initialCount?: number; className?: string; style?: React.CSSProperties }) {
  const pid = pickId(props.pointId, props.point);
  const [count, setCount] = React.useState<number>(() => pickCount(props.initialCount, props.point));
  const [busy, setBusy] = React.useState(false);

  async function onClick() {
    if (!pid || busy) return;
    setBusy(true);
    try {
      const r = await fetch("/api/eco/points/support", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ pointId: pid }),
      });
      const j = await r.json().catch(() => ({} as any));
      if (r.ok && j && typeof j.count === "number") {
        setCount(j.count);
      } else if (r.ok) {
        setCount((c) => c + 1);
      }
    } finally {
      setBusy(false);
    }
  }

  const disabled = !pid || busy;

  return (
    <button
      type="button"
      onClick={onClick}
      disabled={disabled}
      className={props.className}
      style={{
        display: "inline-flex",
        alignItems: "center",
        gap: 8,
        padding: "8px 10px",
        borderRadius: 12,
        border: "1px solid #111",
        background: disabled ? "#eee" : "#fff",
        color: "#111",
        fontWeight: 900,
        cursor: disabled ? "not-allowed" : "pointer",
        ...props.style,
      }}
      title={pid ? "Apoiar este ponto" : "Sem id do ponto"}
    >
      🤝 Apoiar
      {count > 0 ? (
        <span style={{ marginLeft: 2, padding: "2px 8px", borderRadius: 999, background: "#111", color: "#fff", fontSize: 12, lineHeight: "12px" }}>
          {count}
        </span>
      ) : null}
    </button>
  );
}