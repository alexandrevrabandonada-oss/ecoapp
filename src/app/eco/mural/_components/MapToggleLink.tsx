"use client";

import Link from "next/link";
import { usePathname, useSearchParams } from "next/navigation";
import { useMemo } from "react";

export default function MapToggleLink() {
  const pathname = usePathname();
  const sp = useSearchParams();

  const isOpen = (sp.get("map") === "1" || sp.get("map") === "true");

  const href = useMemo(() => {
    const p = new URLSearchParams(sp.toString());
    const mapVal = p.get("map");
    const open = (mapVal === "1" || mapVal === "true");
    if (open) { p.delete("map"); } else { p.set("map", "1"); }
    const q = p.toString();
    return q ? (pathname + "?" + q) : pathname;
  }, [pathname, sp]);

  return (
    <Link
      href={href}
      prefetch={false}
      style={{
        display: "inline-flex",
        alignItems: "center",
        justifyContent: "center",
        gap: 8,
        padding: "7px 12px",
        borderRadius: 999,
        border: "1px solid rgba(255,255,255,0.25)",
        background: "rgba(0,0,0,0.35)",
        color: "#eaeaea",
        fontSize: 12,
        fontWeight: 700,
        textDecoration: "none",
        letterSpacing: "0.2px",
        userSelect: "none"
      }}
      aria-label={isOpen ? "Fechar mapa" : "Abrir mapa"}
      title={isOpen ? "Fechar mapa" : "Abrir mapa"}
    >
      {isOpen ? "Fechar mapa" : "Abrir mapa"}
    </Link>
  );
}