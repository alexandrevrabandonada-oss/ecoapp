// ECO — points/card — v0.1 (ImageResponse)

import { ImageResponse } from "next/og";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

function safeFmt(v: string | null) {
  const s = String(v || "").toLowerCase().trim();
  if (s === "1x1") return "1x1";
  return "3x4";
}
function clampTxt(s: string, max: number) {
  const t = String(s || "");
  if (t.length <= max) return t;
  return t.slice(0, Math.max(0, max - 1)) + "…";
}
function normStatus(v: any) { return String(v || "").trim().toUpperCase(); }
function isResolved(s: string) {
  const t = normStatus(s);
  return t === "RESOLVED" || t === "RESOLVIDO" || t === "DONE" || t === "CLOSED" || t === "FINALIZADO";
}

export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const id = String(searchParams.get("id") || "").trim();
  const format = safeFmt(searchParams.get("format"));
  if (!id) return new Response("missing id", { status: 400 });

  // fetch point data from internal API (node runtime ok)
  const base = new URL(req.url);
  base.pathname = "/api/eco/points/get";
  base.search = "id=" + encodeURIComponent(id);

  let item: any = null;
  try {
    const r = await fetch(base.toString(), { cache: "no-store" });
    const j: any = await r.json().catch(() => null);
    if (j && j.ok) item = j.item;
  } catch { void 0; }

  const title = clampTxt(String(item?.title || "Ponto critico"), 72);
  const status = normStatus(item?.status || "OPEN") || "OPEN";
  const resolved = isResolved(status) || Boolean(item?.resolved);
  const bairro = clampTxt(String(item?.bairro || ""), 36);
  const cidade = clampTxt(String(item?.cidade || "Volta Redonda"), 36);
  const place = bairro ? (bairro + " — " + cidade) : cidade;
  const idShort = clampTxt(id, 18);

  const W = 1080;
  const H = (format === "1x1") ? 1080 : 1350;

  const bg = "#0b0b0b";
  const yellow = "#FFDD00";
  const white = "#F5F5F5";
  const red = "#FF3B30";
  const pill = resolved ? "#B7FFB7" : yellow;
  const pillTxt = resolved ? "#082b08" : "#111";

  return new ImageResponse(
    (
      <div style={{ width: W, height: H, display: "flex", flexDirection: "column", background: bg, padding: 48 }}>
        <div style={{ display: "flex", flexDirection: "column", gap: 18, padding: 28, borderRadius: 26, border: "2px solid #1b1b1b", background: "#111" }}>
          <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: 14 }}>
            <div style={{ display: "flex", alignItems: "center", gap: 14 }}>
              <div style={{ width: 14, height: 44, display: "flex", background: yellow, borderRadius: 8 }} />
              <div style={{ display: "flex", flexDirection: "column", gap: 6 }}>
                <div style={{ display: "flex", color: white, fontSize: 34, fontWeight: 900, letterSpacing: 1 }}>
                  MURAL DO CUIDADO
                </div>
                <div style={{ display: "flex", color: "#cfcfcf", fontSize: 18, fontWeight: 800 }}>
                  Reacao vira acao — confirmar, apoiar, organizar
                </div>
              </div>
            </div>
            <div style={{ display: "flex", padding: "10px 14px", borderRadius: 999, background: pill, color: pillTxt, fontWeight: 950, fontSize: 18, border: "2px solid #111" }}>
              {resolved ? "RESOLVIDO" : "ABERTO"}
            </div>
          </div>

          <div style={{ display: "flex", flexDirection: "column", gap: 14, padding: 18, borderRadius: 18, background: "#0e0e0e", border: "1px solid #222" }}>
            <div style={{ display: "flex", color: yellow, fontSize: 22, fontWeight: 950, letterSpacing: 0.6 }}>
              PONTO CRITICO
            </div>
            <div style={{ display: "flex", color: white, fontSize: 54, fontWeight: 950, lineHeight: 1.05 }}>
              {title}
            </div>
            <div style={{ display: "flex", color: "#d9d9d9", fontSize: 22, fontWeight: 850 }}>
              {place}
            </div>
            <div style={{ display: "flex", color: "#9f9f9f", fontSize: 18, fontWeight: 800 }}>
              ID: {idShort}
            </div>
          </div>
        </div>

        <div style={{ flex: 1, display: "flex" }} />

        <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
          <div style={{ display: "flex", padding: 18, borderRadius: 18, background: yellow, border: "2px solid #111", justifyContent: "space-between", alignItems: "center", gap: 16 }}>
            <div style={{ display: "flex", flexDirection: "column", gap: 6 }}>
              <div style={{ display: "flex", fontSize: 24, fontWeight: 950, color: "#111" }}>O que fazer agora:</div>
              <div style={{ display: "flex", fontSize: 18, fontWeight: 900, color: "#111" }}>CONFIRME • APOIE • CHAME MUTIRAO</div>
            </div>
            <div style={{ display: "flex", padding: "10px 14px", borderRadius: 14, background: "#111", color: yellow, fontWeight: 950, fontSize: 18 }}>
              #ECO  #ReciboECO
            </div>
          </div>

          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", gap: 14 }}>
            <div style={{ display: "flex", color: "#cfcfcf", fontWeight: 850, fontSize: 16 }}>
              Trabalho digno no centro • Sem greenwashing
            </div>
            <div style={{ display: "flex", color: red, fontWeight: 950, fontSize: 16 }}>
              Abandono x Cuidado
            </div>
          </div>
        </div>
      </div>
    ),
    { width: W, height: H }
  );
}
