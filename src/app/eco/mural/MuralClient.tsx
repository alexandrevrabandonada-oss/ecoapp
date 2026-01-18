"use client";
// ===== ECO REF GUARD (auto) =====
// Safety-net for accidental leftover identifiers (p/it/item) that cause ReferenceError during SSR/module eval.
// Remove after we fully clean this file.
const __ECO_REF_GUARD__ = 1;
const _p: any = {};
const _it: any = {};
const _item: any = {};
// ===== /ECO REF GUARD =====


import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import PointActionsInline from "../_components/PointActionsInline";
import ConfirmadoBadge from "../_components/ConfirmadoBadge";
import _MuralPointActionsClient from "./_components/MuralPointActionsClient";

type AnyRow = any;

function num(v: any) {
  const n = Number(v);
  return Number.isFinite(n) ? n : 0;
}
function dt(v: any): number {
  const n = Date.parse(String(v || ""));
  return Number.isFinite(n) ? n : 0;
}

function score(p: any): number {
  const c = (p && p.counts) ? p.counts : {};
  const conf = num(c.confirm ?? p?.confirmCount ?? p?.confirm ?? 0);
  const sup  = num(c.support ?? p?.supportCount ?? p?.support ?? 0);
  const rep  = num(c.replicar ?? p?.replicarCount ?? p?.replicar ?? 0);
  return conf + sup + rep;
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
      const items = j?.items ?? j?.data ?? j?.list ?? j?.rows ?? j?.points ?? j?.criticalPoints;
      if (Array.isArray(items)) return { ok: true as const, items, src: t };
    } catch {}
  }
  return { ok: false as const, items: [] as AnyRow[], src: "none" };
}

function isStrong(p: AnyRow) {
  const st = String(p?.status || p?.state || "").toUpperCase();
  if (st === "RESOLVED") return true;
  const keys = ["proofUrl","proofURL","proof","afterUrl","afterURL","photoAfterUrl","mutiraoId","mutiraoID","receiptUrl","reciboUrl"];
  for (const k of keys) {
    const v = p?.[k] ?? p?.meta?.[k] ?? p?.proof?.[k];
    if (v) return true;
  }
  return false;
}

function strengthBadge(p: AnyRow) {
  if (isStrong(p)) return { txt: "🧾 RECIBO ECO", border: "1px solid #111", bg: "#fff" };
  return { txt: "📝 REGISTRO", border: "1px solid rgba(0,0,0,0.25)", bg: "rgba(255,255,255,0.65)" };
}

export default function MuralClient(props: { base?: string; mode?: "all" | "chamados" }) {
  const base = String(props?.base || "pontos");
  const mode = (props?.mode || "all") as any;
  const [state, setState] = useState<{ loading: boolean; err: string; src: string; items: AnyRow[] }>({ loading: true, err: "", src: "", items: [] });

  useEffect(() => {
    let alive = true;
    ;(async () => {
      const tries = base.includes("ponto") ? [
        "/api/eco/points?limit=160",
        "/api/eco/points?limit=160",
        "/api/eco/critical/list?limit=160",
        "/api/eco/critical?limit=160",
      ] : [
        "/api/eco/points?limit=160",
        "/api/eco/points?limit=160",
      ];

      const r = await loadList(tries);
      if (!alive) return;
      if (!r.ok) {
        setState({ loading: false, err: "Sem dados (API nao respondeu).", src: r.src, items: [] });
        return;
      }
      setState({ loading: false, err: "", src: r.src, items: r.items || [] });
    })();
    return () => { alive = false; };
  }, [base]);

  const items = useMemo(() => {
    let arr = (state.items || []).slice();
    if (mode === "chamados") {
      arr = arr.filter((p: any) => {
        const st = String(p?.status || p?.state || "OPEN").toUpperCase();
        return st === "OPEN";
      });
    }
    try {
      arr.sort((a: any, b: any) => {
        const sa = score(a);
        const sb = score(b);
        if (sb !== sa) return sb - sa;
        const ta = dt(a?.createdAt);
        const tb = dt(b?.createdAt);
        return tb - ta;
      });
    } catch (e) { console.warn('[ECO] sort failed', e); }
    if (mode === "chamados") return arr.slice(0, 60);
    return arr;
  }, [state.items, mode]);

  const grid: any = { display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(320px, 1fr))", gap: 12 };
  const cardBase: any = { borderRadius: 16, padding: 12, background: "rgba(255,255,255,0.75)", border: "1px solid rgba(0,0,0,0.20)" };
  const title: any = { margin: 0, fontSize: 15, fontWeight: 950, letterSpacing: 0.2, color: "#111" };
  const meta: any = { margin: "6px 0 0 0", fontSize: 12, opacity: 0.82 };
  const rowTop: any = { display: "flex", justifyContent: "space-between", alignItems: "center", gap: 10, marginBottom: 8 };
  const pill: any = { fontSize: 11, fontWeight: 950, padding: "3px 10px", borderRadius: 999, display: "inline-block" };

  if (state.loading) return <div style={{ opacity: 0.7 }}>Carregando mural...</div>;
  if (state.err) return <div style={{ opacity: 0.8 }}>{state.err} <span style={{ opacity: 0.6 }}>src: {state.src}</span></div>;

  const head = mode === "chamados" ? "Chamados ativos" : "Mural";

  return (
    <section>
      <div style={{ display: "flex", justifyContent: "space-between", gap: 10, marginBottom: 10, flexWrap: "wrap" }}>
        <div style={{ fontSize: 12, opacity: 0.75 }}>{head} — ordenado por chamado/confirmacao (MVP)</div>
        <div style={{ fontSize: 11, opacity: 0.55 }}>src: {state.src}</div>
      </div>
      <div style={grid}>
        {items.length === 0 ? (
          <div style={{ opacity: 0.75 }}>Sem itens.</div>
        ) : (
          items.map((p: any, idx: number) => {
            const id = String(p?.id || p?.pointId || p?.pid || "");
            const t = String(p?.title || p?.name || p?.kind || "Ponto critico");
            const bairro = String(p?.bairro || p?.neighborhood || p?.area || "");
            const st = String(p?.status || p?.state || "").toUpperCase();
            const b = strengthBadge(p);
            const strong = isStrong(p);
            const card = { ...cardBase, border: strong ? "2px solid rgba(0,0,0,0.65)" : cardBase.border, background: strong ? "#fff" : cardBase.background };
            return (
              <article key={id || idx} style={card}>
                <div style={rowTop}>
                  <span style={{ ...pill, border: "1px solid rgba(0,0,0,0.25)", background: "rgba(0,0,0,0.04)" }}>{st || "OPEN"}</span>
                  <span style={{ ...pill, border: b.border, background: b.bg }}>{b.txt}</span>
                </div>
                <h3 style={title}>
                  <Link href={id ? ("/eco/pontos/" + id) : "/eco/mural"} style={{ color: "#111", textDecoration: "none" }}>{t}</Link>
                </h3>
                <div style={meta}><span style={{ fontWeight: 900 }}>Bairro:</span> {bairro || "—"}</div>
                <ConfirmadoBadge data={p} />
                <PointActionsInline point={p} />
              </article>
            );
          })
        )}
      </div>
    </section>
  );
}
