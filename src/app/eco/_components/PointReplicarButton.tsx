"use client";

import { useMemo, useState } from "react";

export default function PointReplicarButton({
  pointId,
  counts,
}: {
  pointId: string;
  counts?: any;
}) {
  const initial = useMemo(() => {
    const c = counts || {};
    const n = Number(c.replicate ?? c.replicar ?? c.replica ?? 0);
    return Number.isFinite(n) ? n : 0;
  }, [counts]);

  const [n, setN] = useState<number>(initial);
  const [busy, setBusy] = useState(false);

  async function onClick() {
    if (busy) return;
    setBusy(true);
    try {
      const res = await fetch("/api/eco/points/replicar", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ pointId }),
      });
      const j = await res.json().catch(() => null);
      if (j && j.ok) setN(Number(j.count || 0));
    } finally {
      setBusy(false);
    }
  }

  return (
    <button
      type="button"
      onClick={onClick}
      disabled={busy}
      title="Replicar (boa prática)"
      style={{
        padding: "8px 10px",
        borderRadius: 12,
        border: "1px solid #111",
        background: "#fff",
        fontWeight: 900,
        cursor: busy ? "not-allowed" : "pointer",
        display: "inline-flex",
        alignItems: "center",
        gap: 8,
      }}
    >
      ♻️ Replicar
      <span
        style={{
          display: "inline-flex",
          alignItems: "center",
          justifyContent: "center",
          minWidth: 18,
          padding: "2px 8px",
          borderRadius: 999,
          background: "#111",
          color: "#fff",
          fontSize: 12,
          lineHeight: "12px",
        }}
      >
        {n}
      </span>
    </button>
  );
}