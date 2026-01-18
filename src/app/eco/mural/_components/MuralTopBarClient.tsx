"use client";

import Link from "next/link";
import { useEffect, useMemo, useState } from "react";

type AnyRow = any;

function num(v: any) {
  const n = Number(v);
  return Number.isFinite(n) ? n : 0;
}

function pickCount(p: any, keys: string[]) {
  for (const k of keys) {
    const v = p?.[k] ?? p?.counts?.[k] ?? p?.actions?.[k] ?? p?.stats?.[k];
    const n = num(v);
    if (n) return n;
  }
  return 0;
}

function localDay(d = new Date()) {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const dd = String(d.getDate()).padStart(2, "0");
  return String(y) + "-" + m + "-" + dd;
}

function localMonth(d = new Date()) {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, "0");
  return String(y) + "-" + m;
}

async function tryJson(url: string) {
  const res = await fetch(url, { cache: "no-store" });
  if (!res.ok) throw new Error("fetch_failed:" + res.status);
  return await res.json();
}

async function loadList(tries: string[]) {
  for (const t of tries) {
    try {
      const j = await tryJson(t);
      const items = j?.items ?? j?.data ?? j?.list ?? j?.rows ?? j?.points ?? j?.mutiroes ?? j?.criticalPoints;
      if (Array.isArray(items)) return { ok: true as const, items, src: t };
    } catch {}
  }
  return { ok: false as const, items: [] as AnyRow[], src: "none" };
}

async function loadDayCloseList() {
  const tries = [
    "/api/eco/day-close/list?limit=60",
    "/api/eco/day-close/list?limit=45",
    "/api/eco/day-close/list?limit=30",
  ];
  for (const t of tries) {
    try {
      const j = await tryJson(t);
      const items = j?.items ?? j?.data ?? j?.list ?? j?.rows;
      if (Array.isArray(items)) return { ok: true as const, items, src: t };
    } catch {}
  }
  return { ok: false as const, items: [] as AnyRow[], src: "none" };
}

function sumKgFromDayCloseItems(items: AnyRow[]) {
  let total = 0;
  const byMat: Record<string, number> = {};
  for (const it of items || []) {
    const s = it?.summary ?? it?.data?.summary ?? it?.item?.summary ?? it?.payload?.summary;
    const totals = s?.totals ?? s?.summary?.totals ?? {};
    const kg = num(totals?.totalKg ?? totals?.kg ?? totals?.total ?? 0);
    total += kg;
    const bm = totals?.byMaterialKg ?? totals?.byMaterial ?? {};
    if (bm && typeof bm === "object") {
      for (const k of Object.keys(bm)) {
        const v = num((bm as any)[k]);
        byMat[k] = (byMat[k] || 0) + v;
      }
    }
  }
  return { totalKg: total, byMat };
}

function fmtKg(v: number) {
  const n = Math.round((v || 0) * 10) / 10;
  return String(n).replace(".", ",") + " kg";
}

function matLabel(k: string) {
  const t = String(k || "").toLowerCase();
  if (t.includes("papel")) return "Papel";
  if (t.includes("plast")) return "Plástico";
  if (t.includes("metal")) return "Metal";
  if (t.includes("vidro")) return "Vidro";
  if (t.includes("oleo")) return "Óleo";
  if (t.includes("e-lixo") || t.includes("elixo")) return "E-lixo";
  if (t.includes("reje")) return "Rejeito";
  if (t.includes("org")) return "Orgânico";
  return "Outros";
}

export default function MuralTopBarClient() {
  const [pointsRes, setPointsRes] = useState<{ ok: boolean; items: AnyRow[]; src: string }>({ ok: false, items: [], src: "loading" });
  const [mutRes, setMutRes] = useState<{ ok: boolean; items: AnyRow[]; src: string }>({ ok: false, items: [], src: "loading" });
  const [dayCloseRes, setDayCloseRes] = useState<{ ok: boolean; items: AnyRow[]; src: string }>({ ok: false, items: [], src: "loading" });

  useEffect(() => {
    let alive = true;
    ;(async () => {
      const p = await loadList([
        "/api/eco/points?limit=200",
        "/api/eco/points?limit=200",
        "/api/eco/critical/list?limit=200",
        "/api/eco/critical?limit=200",
      ]);
      const m = await loadList([
        "/api/eco/mutirao/list?limit=20",
        "/api/eco/mutiroes/list?limit=20",
        "/api/eco/mutirao?limit=20",
      ]);
      const dc = await loadDayCloseList();
      if (!alive) return;
      setPointsRes(p as any);
      setMutRes(m as any);
      setDayCloseRes(dc as any);
    })();
    return () => { alive = false; };
  }, []);

  const computed = useMemo(() => {
    const points = pointsRes.items || [];
    const chamados = points
      .filter((p: any) => String(p?.status || p?.state || "").toUpperCase() === "OPEN")
      .map((p: any) => ({
        p,
        called: pickCount(p, ["call", "callCount", "chamado", "chamados", "CALL", "CALLED"]),
        confirm: pickCount(p, ["confirm", "confirmCount", "confirmar", "seen", "ok", "OK"]),
      }))
      .sort((a: any, b: any) => (b.called - a.called) || (b.confirm - a.confirm))
      .slice(0, 6);

    const confirmados = points
      .map((p: any) => ({
        p,
        confirm: pickCount(p, ["confirm", "confirmCount", "confirmar", "seen", "ok", "OK"]),
        called: pickCount(p, ["call", "callCount", "chamado", "chamados", "CALL", "CALLED"]),
      }))
      .sort((a: any, b: any) => (b.confirm - a.confirm) || (b.called - a.called))
      .slice(0, 6);

    const mutiroes = (mutRes.items || []).slice(0, 6);

    // Transparência (day-close)
    const raw = (dayCloseRes.items || []).slice();
    raw.sort((a: any, b: any) => String(b?.day || "").localeCompare(String(a?.day || "")));
    const last7 = raw.slice(0, 7);
    const mo = localMonth(new Date());
    const monthItems = raw.filter((x: any) => String(x?.day || "").startsWith(mo + "-"));

    const s7 = sumKgFromDayCloseItems(last7);
    const sm = sumKgFromDayCloseItems(monthItems);

    const lastDay = String(last7?.[0]?.day || localDay(new Date()));
    const mats = Object.keys(sm.byMat || {})
      .map((k) => ({ k, v: num((sm.byMat as any)[k]) }))
      .sort((a, b) => b.v - a.v)
      .slice(0, 3);

    return { chamados, confirmados, mutiroes, last7, monthItems, s7, sm, mo, lastDay, mats };
  }, [pointsRes, mutRes, dayCloseRes]);

  const box: any = { border: "1px solid #111", borderRadius: 14, padding: 12, background: "#fff" };
  const h: any = { margin: "0 0 6px 0", fontSize: 12, fontWeight: 950, letterSpacing: 0.2, opacity: 0.9 };
  const a: any = { textDecoration: "none", color: "#111" };
  const row: any = { display: "flex", justifyContent: "space-between", gap: 10, fontSize: 12, padding: "6px 0", borderTop: "1px dashed rgba(0,0,0,0.15)" };

  return (
    <section
      style={{
        position: "sticky",
        top: 0,
        zIndex: 50,
        background: "rgba(245,245,245,0.92)",
        backdropFilter: "blur(6px)",
        padding: "10px 0 12px 0",
        borderBottom: "1px solid rgba(0,0,0,0.15)",
      }}
    >
      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(240px, 1fr))", gap: 10 }}>
        <div style={box}>
          <div style={h}>📣 Chamados ativos</div>
          <div style={{ fontSize: 12, opacity: 0.75, marginBottom: 6 }}>Pontos OPEN com chamado</div>
          <div>
            {computed.chamados.length === 0 ? (
              <div style={{ fontSize: 12, opacity: 0.75 }}>Nenhum chamado encontrado.</div>
            ) : (
              computed.chamados.map((x: any, idx: number) => (
                <div key={idx} style={row}>
                  <Link href={"/eco/pontos/" + String(x.p?.id || "")} style={a}>
                    {String(x.p?.title || x.p?.name || x.p?.bairro || "Ponto")}
                  </Link>
                  <span style={{ fontWeight: 950 }}>📣 {x.called || 0}</span>
                </div>
              ))
            )}
          </div>
          <div style={{ marginTop: 8, fontSize: 11, opacity: 0.6 }}>src: {pointsRes.src}</div>
        </div>

        <div style={box}>
          <div style={h}>✅ Mais confirmados</div>
          <div style={{ fontSize: 12, opacity: 0.75, marginBottom: 6 }}>Onde mais gente disse “eu vi também”</div>
          <div>
            {computed.confirmados.length === 0 ? (
              <div style={{ fontSize: 12, opacity: 0.75 }}>Sem dados ainda.</div>
            ) : (
              computed.confirmados.map((x: any, idx: number) => (
                <div key={idx} style={row}>
                  <Link href={"/eco/pontos/" + String(x.p?.id || "")} style={a}>
                    {String(x.p?.title || x.p?.name || x.p?.bairro || "Ponto")}
                  </Link>
                  <span style={{ fontWeight: 950 }}>✅ {x.confirm || 0}</span>
                </div>
              ))
            )}
          </div>
          <div style={{ marginTop: 8, fontSize: 11, opacity: 0.6 }}>src: {pointsRes.src}</div>
        </div>

        <div style={box}>
          <div style={h}>🧹 Mutirões recentes</div>
          <div style={{ fontSize: 12, opacity: 0.75, marginBottom: 6 }}>Antes/depois + prova</div>
          <div>
            {computed.mutiroes.length === 0 ? (
              <div style={{ fontSize: 12, opacity: 0.75 }}>Sem mutirões listados.</div>
            ) : (
              computed.mutiroes.map((m: any, idx: number) => (
                <div key={idx} style={row}>
                  <Link href={"/eco/mutiroes/" + String(m?.id || "")} style={a}>
                    {String(m?.title || m?.bairro || "Mutirão")}
                  </Link>
                  <span style={{ fontWeight: 950, opacity: 0.9 }}>→</span>
                </div>
              ))
            )}
          </div>
          <div style={{ marginTop: 8, fontSize: 11, opacity: 0.6 }}>src: {mutRes.src}</div>
        </div>

        <div style={box}>
          <div style={h}>📊 Transparência</div>
          <div style={{ fontSize: 12, opacity: 0.75, marginBottom: 8 }}>Recibo é lei. 7 dias + mês atual.</div>
          <div style={{ display: "grid", gap: 8 }}>
            <div style={{ display: "flex", justifyContent: "space-between", gap: 10 }}>
              <span style={{ fontSize: 12, opacity: 0.85 }}>Últimos 7 dias</span>
              <span style={{ fontWeight: 950 }}>{fmtKg(computed.s7.totalKg)}</span>
            </div>
            <div style={{ display: "flex", justifyContent: "space-between", gap: 10 }}>
              <span style={{ fontSize: 12, opacity: 0.85 }}>Mês {computed.mo}</span>
              <span style={{ fontWeight: 950 }}>{fmtKg(computed.sm.totalKg)}</span>
            </div>
            {computed.mats.length > 0 ? (
              <div style={{ fontSize: 12, opacity: 0.9 }}>
                {computed.mats.map((x, i) => (
                  <span key={i} style={{ display: "inline-block", marginRight: 8, marginTop: 4, padding: "2px 8px", border: "1px solid rgba(0,0,0,0.25)", borderRadius: 999, background: "rgba(0,0,0,0.03)" }}>
                    {matLabel(x.k)}: {fmtKg(x.v)}
                  </span>
                ))}
              </div>
            ) : (
              <div style={{ fontSize: 12, opacity: 0.65 }}>Ainda sem fechamento consolidado no mês.</div>
            )}
            <div style={{ display: "flex", gap: 8, flexWrap: "wrap", marginTop: 2 }}>
              <Link href={"/eco/share/mes/" + computed.mo} style={{ textDecoration: "none", color: "#111", fontWeight: 950, padding: "7px 10px", borderRadius: 12, border: "1px solid #111", background: "#fff" }}>
                Compartilhar mês
              </Link>
              <Link href={"/eco/share/dia/" + computed.lastDay} style={{ textDecoration: "none", color: "#111", fontWeight: 950, padding: "7px 10px", borderRadius: 12, border: "1px solid rgba(0,0,0,0.35)", background: "rgba(255,255,255,0.6)" }}>
                Compartilhar dia
              </Link>
              <Link href={"/eco/fechamento"} style={{ textDecoration: "none", color: "#111", fontWeight: 950, padding: "7px 10px", borderRadius: 12, border: "1px dashed rgba(0,0,0,0.35)", background: "rgba(255,255,255,0.45)" }}>
                Ir pro fechamento
              </Link>
            </div>
          </div>
          <div style={{ marginTop: 8, fontSize: 11, opacity: 0.6 }}>src: {dayCloseRes.src}</div>
        </div>
      </div>
    </section>
  );
}
