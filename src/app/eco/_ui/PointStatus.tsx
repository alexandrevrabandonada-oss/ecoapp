"use client";

import React from "react";

export function normStatus(v: any) {
  return String(v || "").trim().toUpperCase();
}
export function isResolvedStatus(s: string) {
  const t = normStatus(s);
  return t === "RESOLVED" || t === "RESOLVIDO" || t === "DONE" || t === "CLOSED" || t === "FINALIZADO";
}
export function getPointStatus(p: any) {
  const m = (p && p.meta && typeof p.meta === "object") ? p.meta : null;
  return normStatus(p?.status || p?.state || m?.status || m?.state || "");
}
export function markerFill(p: any) {
  const s = getPointStatus(p);
  return isResolvedStatus(s) ? "#2EEB2E" : "#FFDD00";
}
export function markerBorder(p: any) {
  const s = getPointStatus(p);
  return isResolvedStatus(s) ? "#0A7A0A" : "#111111";
}
export function badgeLabel(p: any) {
  const s = getPointStatus(p);
  return isResolvedStatus(s) ? "RESOLVIDO" : (s || "ABERTO");
}
export function PointBadge(props: { p: any }) {
  const s = getPointStatus(props.p);
  const ok = isResolvedStatus(s);
  const label = badgeLabel(props.p);
  return (
    <span
      style={{
        display: "inline-block",
        padding: "6px 10px",
        borderRadius: 999,
        border: "1px solid #111",
        fontWeight: 900,
        background: ok ? "#B7FFB7" : "#FFDD00",
        color: "#111",
        textTransform: "uppercase",
        letterSpacing: 0.4,
        fontSize: 12,
        lineHeight: "12px",
        marginBottom: 8,
      }}
    >
      {label}
    </span>
  );
}
