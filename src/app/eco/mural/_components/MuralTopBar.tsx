// MuralTopBar — v0.1
// Topo fixo do Mural: Chamados ativos / Mais confirmados / Mutiroes recentes

import Link from "next/link";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

type PointRow = any;
type MutiraoRow = any;

function num(v: any) {
  const n = Number(v);
  return Number.isFinite(n) ? n : 0;
}

function pickCount(p: any, keys: string[]) {
  for (const k of keys) {
    const v = p?.[k] ?? p?.counts?.[k] ?? p?.actions?.[k];
    const n = num(v);
    if (n) return n;
  }
  return 0;
}

async function getJson(url: string) {
  const res = await fetch(url, { cache: "no-store" });
  if (!res.ok) throw new Error("fetch_failed:" + res.status);
  return await res.json();
}

async function loadPoints(baseUrl: string) {
  // tenta endpoints conhecidos (best-effort)
  const tries = [
    "/api/eco/points?limit=200",
    "/api/eco/points?limit=200",
    "/api/eco/critical/list?limit=200",
    "/api/eco/critical?limit=200",
  ];
  for (const t of tries) {
    try {
      const j = await getJson(baseUrl + t);
      const items = j?.items ?? j?.data ?? j?.list ?? j?.rows ?? j?.points ?? j?.criticalPoints;
      if (Array.isArray(items)) return { ok: true, items: items as PointRow[], src: t };
    } catch {}
  }
  return { ok: false, items: [] as PointRow[], src: "none" };
}

async function loadMutiroes(baseUrl: string) {
  const tries = [
    "/api/eco/mutirao/list?limit=20",
    "/api/eco/mutiroes/list?limit=20",
    "/api/eco/mutirao?limit=20",
  ];
  for (const t of tries) {
    try {
      const j = await getJson(baseUrl + t);
      const items = j?.items ?? j?.data ?? j?.list ?? j?.rows ?? j?.mutiroes;
      if (Array.isArray(items)) return { ok: true, items: items as MutiraoRow[], src: t };
    } catch {}
  }
  return { ok: false, items: [] as MutiraoRow[], src: "none" };
}

export default async function MuralTopBar() {
  const baseUrl = process.env.NEXT_PUBLIC_BASE_URL || "";
  const pointsRes = await loadPoints(baseUrl);
  const mutRes = await loadMutiroes(baseUrl);

  const points = pointsRes.items || [];
  // chamados: OPEN + chamado/call > 0 (quando existir)
  const chamados = points
    .filter((p: any) => String(p?.status || p?.state || "").toUpperCase() === "OPEN")
    .map((p: any) => ({
      p,
      called: pickCount(p, ["call", "callCount", "chamado", "chamados", "CALL", "CALLED"]),
      confirm: pickCount(p, ["confirm", "confirmCount", "confirmar", "seen", "ok", "OK"]),
    }))
    .sort((a, b) => (b.called - a.called) || (b.confirm - a.confirm))
    .slice(0, 6);

  const confirmados = points
    .map((p: any) => ({
      p,
      confirm: pickCount(p, ["confirm", "confirmCount", "confirmar", "seen", "ok", "OK"]),
      called: pickCount(p, ["call", "callCount", "chamado", "chamados", "CALL", "CALLED"]),
    }))
    .sort((a, b) => (b.confirm - a.confirm) || (b.called - a.called))
    .slice(0, 6);

  const mutiroes = (mutRes.items || [])
    .slice(0, 6);

  const box: any = {
    border: "1px solid #111",
    borderRadius: 14,
    padding: 12,
    background: "#fff",
  };
  const h: any = { margin: "0 0 6px 0", fontSize: 12, fontWeight: 950, letterSpacing: 0.2, opacity: 0.9 };
  const a: any = { textDecoration: "none", color: "#111" };
  const row: any = { display: "flex", justifyContent: "space-between", gap: 10, fontSize: 12, padding: "6px 0", borderTop: "1px dashed rgba(0,0,0,0.15)" };

  return (
    <section style={{ position: "sticky", top: 0, zIndex: 50, background: "rgba(245,245,245,0.92)", backdropFilter: "blur(6px)", padding: "10px 0 12px 0", borderBottom: "1px solid rgba(0,0,0,0.15)" }}>
      <div style={{ display: "grid", gridTemplateColumns: "repeat(3, minmax(0, 1fr))", gap: 10 }}>
        <div style={box}>
          <div style={h}>📣 Chamados ativos</div>
          <div style={{ fontSize: 12, opacity: 0.75, marginBottom: 6 }}>Pontos OPEN com chamado</div>
          <div>
            {chamados.length === 0 ? (
              <div style={{ fontSize: 12, opacity: 0.75 }}>Nenhum chamado encontrado.</div>
            ) : (
              chamados.map((x: any, idx: number) => (
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
            {confirmados.length === 0 ? (
              <div style={{ fontSize: 12, opacity: 0.75 }}>Sem dados ainda.</div>
            ) : (
              confirmados.map((x: any, idx: number) => (
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
            {mutiroes.length === 0 ? (
              <div style={{ fontSize: 12, opacity: 0.75 }}>Sem mutirões listados.</div>
            ) : (
              mutiroes.map((m: any, idx: number) => (
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
      </div>
    </section>
  );
}
