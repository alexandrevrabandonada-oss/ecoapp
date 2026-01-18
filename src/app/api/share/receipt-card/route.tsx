import { ImageResponse } from "next/og";

export const runtime = "edge";

function fmtDatePtBR(input: any): string {
  try {
    if (!input) return "";
    const d = new Date(input);
    if (Number.isNaN(d.getTime())) return "";
    return d.toLocaleDateString("pt-BR");
  } catch {
    return "";
  }
}

export async function GET(req: Request) {
  const u = new URL(req.url);
  const code = (u.searchParams.get("code") ?? "").trim();
  if (!code) return new Response("missing code", { status: 400 });
  const format = (u.searchParams.get("format") ?? "3x4").toLowerCase();
  const width = 1080;
  const height = format === "1x1" ? 1080 : 1350;

  const api = new URL("/api/receipts/public", u);
  api.searchParams.set("code", code);
  const r = await fetch(api.toString(), { cache: "no-store" });
  if (!r.ok) return new Response("not found", { status: r.status });
  const j: any = await r.json();
  const c = String(j?.receipt?.code ?? code);
  const d = fmtDatePtBR(j?.receipt?.date);

  const bg = "#0B0F0E";
  const ink = "#F3F4F6";
  const green = "#22C55E";
  const yellow = "#FACC15";

  return new ImageResponse((
    <div style={{ width: "100%", height: "100%", background: bg, display: "flex", flexDirection: "column", padding: 72, color: ink, fontFamily: "ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Arial" }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
        <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
          <div style={{ fontSize: 28, letterSpacing: 2, color: green, fontWeight: 700 }}>RECIBO ECO</div>
          <div style={{ fontSize: 64, lineHeight: 1.05, fontWeight: 900 }}>BORA DE RECIBO?</div>
        </div>
        <div style={{ width: 140, height: 140, borderRadius: 999, border: "10px solid " + green, display: "flex", alignItems: "center", justifyContent: "center", boxShadow: "0 0 0 10px rgba(250,204,21,0.25)" }}>
          <div style={{ width: 86, height: 86, borderRadius: 999, border: "8px dashed " + yellow }} />
        </div>
      </div>

      <div style={{ marginTop: 56, padding: 42, borderRadius: 28, border: "2px solid rgba(34,197,94,0.55)", background: "rgba(255,255,255,0.04)", display: "flex", flexDirection: "column", gap: 14 }}>
        <div style={{ fontSize: 22, letterSpacing: 1.5, opacity: 0.9 }}>CÓDIGO DO RECIBO</div>
        <div style={{ fontSize: 54, fontWeight: 900, letterSpacing: 3 }}>{c}</div>
        {d ? <div style={{ fontSize: 26, opacity: 0.9 }}>Emitido em {d}</div> : null}
      </div>

      <div style={{ marginTop: "auto", display: "flex", flexDirection: "column", gap: 14 }}>
        <div style={{ height: 2, background: "rgba(243,244,246,0.25)" }} />
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", fontSize: 22, opacity: 0.95 }}>
          <div style={{ letterSpacing: 1.4 }}>ECO — ESCUTAR • CUIDAR • ORGANIZAR</div>
          <div style={{ color: yellow, fontWeight: 800 }}>#RECIBOÉLEI</div>
        </div>
      </div>
    </div>
  ), { width, height });
}