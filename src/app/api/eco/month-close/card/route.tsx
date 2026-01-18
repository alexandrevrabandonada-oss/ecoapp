import { ImageResponse } from "next/og";
import { prisma } from "@/lib/prisma";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

function safeMonth(input: string | null): string | null {
  const s = String(input || "").trim();
  if (/^\\d{4}-\\d{2}$/.test(s)) return s;
  return null;
}

function fmtKg(n: any): string {
  const v = Number(n || 0) || 0;
  const s = Math.round(v * 10) / 10;
  return String(s).replace(".", ",") + " kg";
}

function topMaterials(by: any): Array<{ k: string; v: number }> {
  const out: Array<{ k: string; v: number }> = [];
  if (by && typeof by === "object") {
    for (const k of Object.keys(by)) out.push({ k, v: Number(by[k] || 0) || 0 });
  }
  out.sort((a, b) => b.v - a.v);
  return out.slice(0, 5);
}

function bump(obj: any, key: string, inc: number) {
  if (!obj[key]) obj[key] = 0;
  obj[key] += inc;
}

function normalizeMaterial(s: string) {
  const t = String(s || "").toLowerCase();
  if (t.includes("papel")) return "papel";
  if (t.includes("plasti")) return "plastico";
  if (t.includes("metal")) return "metal";
  if (t.includes("vidro")) return "vidro";
  if (t.includes("oleo")) return "oleo";
  if (t.includes("org")) return "organico";
  if (t.includes("reje")) return "rejeito";
  return "outros";
}

function monthRange(month: string) {
  const start = new Date(month + "-01T00:00:00-03:00");
  const next = new Date(start.getTime());
  next.setMonth(next.getMonth() + 1);
  const end = new Date(next.getTime() - 1);
  return { start, end };
}

function getDayCloseModel() {
  const pc: any = prisma as any;
  return pc?.ecoDayClose;
}

function getTriagemModel() {
  const pc: any = prisma as any;
  const candidates = ["ecoTriagem", "triagem", "ecoSorting", "sorting"];
  for (const k of candidates) {
    const m = pc?.["k"];
    if (m && typeof m.findMany === "function") return { key: k, model: m as any };
  }
  return null;
}

async function computeSummary(month: string) {
  const { start, end } = monthRange(month);
  const dc = getDayCloseModel();
  const tri = getTriagemModel();
  const totals: any = { totalKg: 0, byMaterialKg: {}, days: 0, count: 0 };
  const meta: any = { computedAt: new Date().toISOString(), source: [] as string[] };

  if (dc && typeof dc.findMany === "function") {
    meta.source.push("dayClose");
    const rows = await dc.findMany({
      where: { day: { gte: month + "-01", lt: month + "-32" } },
      orderBy: { day: "asc" },
    });
    totals.days = rows.length;
    for (const r of rows) {
      const summary = (r && (r.summary as any)) || {};
      const t = (summary && (summary.totals as any)) || {};
      totals.totalKg += Number(t.totalKg || 0) || 0;
      const by = (t.byMaterialKg as any) || {};
      if (by && typeof by === "object") {
        for (const k of Object.keys(by)) bump(totals.byMaterialKg, k, Number(by[k] || 0) || 0);
      }
    }
    return { month, totals, meta, notes: [], version: "v0" };
  }

  meta.source.push("dayClose:missing");

  if (tri) {
    meta.source.push("triagem:" + tri.key);
    const rows = await tri.model.findMany({ where: { createdAt: { gte: start, lte: end } } });
    totals.count = rows.length;
    for (const r of rows) {
      const kg = Number((r && (r.weightKg ?? r.kg ?? r.weight ?? 0)) || 0) || 0;
      const mat = normalizeMaterial(String((r && (r.material ?? r.kind ?? r.type ?? "")) || ""));
      totals.totalKg += kg;
      bump(totals.byMaterialKg, mat, kg);
    }
  } else {
    meta.source.push("triagem:missing");
  }
  return { month, totals, meta, notes: [], version: "v0" };
}

async function ensureMonthClose(month: string) {
  const pc: any = prisma as any;
  const model = pc?.ecoMonthClose;
  if (!model?.upsert) return null;
  const summary = await computeSummary(month);
  const item = await model.upsert({ where: { month }, update: { summary }, create: { month, summary } });
  return item;
}

export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const month = safeMonth(searchParams.get("month") ?? searchParams.get("m"));
  const format = String(searchParams.get("format") || "3x4");
  if (!month) return new ImageResponse(<div style={{ display: "flex" }}>bad_month</div>, { width: 1080, height: 1350 });

  const item = await ensureMonthClose(month);
  const summary: any = (item && (item.summary as any)) || {};
  const totals: any = (summary && (summary.totals as any)) || {};
  const totalKg = fmtKg(totals.totalKg || 0);
  const days = Number(totals.days || 0) || 0;
  const mats = topMaterials(totals.byMaterialKg || {});

  const W = format === "1x1" ? 1080 : 1080;
  const H = format === "1x1" ? 1080 : 1350;

  return new ImageResponse(
    (
      <div
        style={{
          width: W,
          height: H,
          display: "flex",
          flexDirection: "column",
          justifyContent: "space-between",
          padding: 60,
          background: "#0B0B0B",
          color: "#F7D500",
          fontFamily: "ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Arial",
        }}
      >
        <div style={{ display: "flex", flexDirection: "column", gap: 18 }}>
          <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
            <div style={{ display: "flex", flexDirection: "column", gap: 6 }}>
              <div style={{ fontSize: 24, letterSpacing: 2, color: "#F7D500", opacity: 0.95 }}>ECO</div>
              <div style={{ fontSize: 46, fontWeight: 900, lineHeight: 1.05 }}>TRANSPARÊNCIA DO MÊS</div>
            </div>
            <div style={{ display: "flex", flexDirection: "column", alignItems: "flex-end", gap: 6 }}>
              <div style={{ fontSize: 22, opacity: 0.9 }}>MÊS</div>
              <div style={{ fontSize: 44, fontWeight: 900, color: "#F7D500" }}>{month}</div>
            </div>
          </div>

          <div style={{ display: "flex", flexDirection: "column", gap: 10, background: "#111", border: "2px solid #F7D500", borderRadius: 18, padding: 22 }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline" }}>
              <div style={{ fontSize: 24, opacity: 0.9 }}>Total do mês</div>
              <div style={{ fontSize: 44, fontWeight: 900 }}>{totalKg}</div>
            </div>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline" }}>
              <div style={{ fontSize: 20, opacity: 0.85 }}>Dias fechados</div>
              <div style={{ fontSize: 26, fontWeight: 800, color: "#F7D500" }}>{String(days)}</div>
            </div>
          </div>

          <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
            <div style={{ fontSize: 22, fontWeight: 800, color: "#F7D500" }}>Por material (top 5)</div>
            <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
              {mats.length ? mats.map((m) => (
                <div key={m.k} style={{ display: "flex", justifyContent: "space-between", gap: 16, borderBottom: "1px solid rgba(247,213,0,0.25)", paddingBottom: 6 }}>
                  <div style={{ display: "flex" , fontSize: 22, fontWeight: 800, color: "#F7D500" }}>{String(m.k).toUpperCase()}</div>
                  <div style={{ display: "flex" , fontSize: 22, fontWeight: 800, color: "#F7D500" }}>{fmtKg(m.v)}</div>
                </div>
              )) : (
                <div style={{ display: "flex", fontSize: 20, opacity: 0.8 }}>Sem dados ainda.</div>
              )}
            </div>
          </div>
        </div>

        <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
          <div style={{ display: "flex", gap: 12, flexWrap: "wrap" }}>
            <div style={{ display: "flex", padding: "10px 14px", borderRadius: 999, background: "#F7D500", color: "#111", fontWeight: 900 }}>RECIBO É LEI</div>
            <div style={{ display: "flex", padding: "10px 14px", borderRadius: 999, border: "2px solid #F7D500", color: "#F7D500", fontWeight: 900 }}>CUIDADO É COLETIVO</div>
            <div style={{ display: "flex", padding: "10px 14px", borderRadius: 999, border: "2px solid #F7D500", color: "#F7D500", fontWeight: 900 }}>TRABALHO DIGNO NO CENTRO</div>
          </div>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <div style={{ display: "flex", fontSize: 18, opacity: 0.9 }}>#ECO — Escutar • Cuidar • Organizar</div>
            <div style={{ display: "flex", fontSize: 18, opacity: 0.8 }}>eco/share/mes/{month}</div>
          </div>
        </div>
      </div>
    ),
    { width: W, height: H }
  );
}

