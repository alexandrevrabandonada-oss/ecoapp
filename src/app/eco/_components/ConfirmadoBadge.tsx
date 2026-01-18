"use client";

type AnyObj = any;

function num(v: any): number {
  const n = Number(v);
  return Number.isFinite(n) ? n : 0;
}

function readCount(data: AnyObj): number {
  if (!data) return 0;
  // direct keys
  const keys = ["confirm","confirmar","confirmed","confirmations","confirmCount","confirmarCount"];
  for (const k of keys) {
    const n = num((data as any)[k]);
    if (n > 0) return n;
  }
  // nested holders
  const holders = [
    (data as any).counts,
    (data as any).stats,
    (data as any).actions,
    (data as any).meta?.counts,
    (data as any).meta?.stats,
  ].filter(Boolean);
  for (const h of holders) {
    for (const k of keys) {
      const n = num((h as any)[k]);
      if (n > 0) return n;
    }
  }
  // arrays fallback
  const arrs = [
    (data as any).confirmations,
    (data as any).confirms,
    (data as any).confirmedBy,
    (data as any).confirmBy,
  ].filter(Boolean);
  for (const a of arrs) {
    if (Array.isArray(a) && a.length > 0) return a.length;
  }
  return 0;
}

export default function ConfirmadoBadge({ data }: { data: AnyObj }) {
  const n = readCount(data);
  if (!n || n <= 0) return null;
  return (
    <span
      title={"Confirmado por " + n}
      style={{
        display: "inline-flex",
        alignItems: "center",
        gap: 8,
        padding: "5px 10px",
        borderRadius: 999,
        border: "1px solid #111",
        background: "#fff",
        fontWeight: 900,
        fontSize: 12,
        lineHeight: "12px",
        whiteSpace: "nowrap",
      }}
    >
      ✅ CONFIRMADO
      <span
        style={{
          display: "inline-flex",
          alignItems: "center",
          justifyContent: "center",
          minWidth: 20,
          padding: "2px 8px",
          borderRadius: 999,
          background: "#111",
          color: "#fff",
          fontWeight: 900,
          fontSize: 12,
          lineHeight: "12px",
        }}
      >
        {n}
      </span>
    </span>
  );
}
