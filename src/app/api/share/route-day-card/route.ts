import React from "react";
import { ImageResponse } from "next/og";

export const runtime = "edge";

function safeDay(input: string | null): string {
  const s = String(input || "").trim();
  if (/^\d{4}-\d{2}-\d{2}$/.test(s)) return s;
  const d = new Date();
  const yyyy = d.getUTCFullYear();
  const mm = String(d.getUTCMonth() + 1).padStart(2, "0");
  const dd = String(d.getUTCDate()).padStart(2, "0");
  return `${yyyy}-${mm}-${dd}`;
}

function sizeFor(format: string | null) {
  const f = String(format || "").toLowerCase();
  if (f === "1x1") return { w: 1080, h: 1080, label: "1:1" as const };
  return { w: 1080, h: 1350, label: "3:4" as const };
}

export async function GET(req: Request) {
  try {
    const { searchParams } = new URL(req.url);
    const day = safeDay(searchParams.get("day"));
    const fmt = sizeFor(searchParams.get("format"));

    const bg = "#0b0b0b";
    const yellow = "#ffd400";
    const red = "#ff3b30";
    const off = "#f5f5f5";
    const gray = "#bdbdbd";

    const rootStyle: React.CSSProperties = {
      width: "100%",
      height: "100%",
      display: "flex",
      flexDirection: "column",
      background: bg,
      color: off,
      padding: 64,
      boxSizing: "border-box",
      fontFamily: "system-ui, -apple-system, Segoe UI, Roboto, Ubuntu, Cantarell, Helvetica Neue, Arial",
      border: `10px solid ${yellow}`,
    };

    const pill = (text: string) =>
      React.createElement("div", {
        style: { display: "flex", padding: "10px 14px", borderRadius: 999, border: `2px solid ${gray}`, fontSize: 20 },
      }, text);

    const titleLine = React.createElement(
      "div",
      { style: { display: "flex", alignItems: "baseline", gap: 10, fontSize: 64, fontWeight: 900, lineHeight: 1.0 } },
      "FECHAMENTO",
      React.createElement("span", { style: { color: yellow } }, " DO DIA")
    );

    const headerLeft = React.createElement(
      "div",
      { style: { display: "flex", flexDirection: "column", gap: 10 } },
      React.createElement("div", { style: { display: "flex", fontSize: 22, letterSpacing: 2, color: gray } }, "#ECO — Escutar • Cuidar • Organizar"),
      titleLine,
      React.createElement("div", { style: { display: "flex", fontSize: 42, fontWeight: 800, color: off } }, day)
    );

    const headerBadge = React.createElement(
      "div",
      { style: { display: "flex", width: 120, height: 120, borderRadius: 999, border: `8px solid ${yellow}`, alignItems: "center", justifyContent: "center", fontSize: 34, fontWeight: 900, color: yellow } },
      fmt.label
    );

    const header = React.createElement(
      "div",
      { style: { display: "flex", justifyContent: "space-between", alignItems: "flex-start" } },
      headerLeft,
      headerBadge
    );

    const pills = React.createElement(
      "div",
      { style: { display: "flex", gap: 14, flexWrap: "wrap" } },
      pill("Recibo é lei"),
      pill("Cuidado é coletivo"),
      pill("Trabalho digno no centro")
    );

    const footer = React.createElement(
      "div",
      { style: { display: "flex", justifyContent: "space-between", alignItems: "flex-end" } },
      React.createElement("div", { style: { display: "flex", fontSize: 22, opacity: 0.9, color: gray } }, `Compartilhe: /s/dia/${day}`),
      React.createElement("div", { style: { display: "flex", fontSize: 18, color: red, opacity: 0.95 } }, "Sem greenwashing • Abandono × Cuidado")
    );

    const bottom = React.createElement(
      "div",
      { style: { display: "flex", flex: 1, flexDirection: "column", justifyContent: "flex-end", gap: 18 } },
      pills,
      footer
    );

    const tree = React.createElement("div", { style: rootStyle }, header, bottom);

    return new ImageResponse(tree, {
      width: fmt.w,
      height: fmt.h,
      headers: { "cache-control": "public, max-age=0, s-maxage=3600, stale-while-revalidate=86400" },
    });
  } catch (err: any) {
    return new Response("route-day-card error: " + (err?.message || "unknown"), { status: 500 });
  }
}