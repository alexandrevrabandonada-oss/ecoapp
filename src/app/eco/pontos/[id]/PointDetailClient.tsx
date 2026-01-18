"use client";

import { useEffect, useMemo, useState } from "react";

import { PointBadge as _PointBadge, markerFill as _markerFill, markerBorder as _markerBorder } from "@/app/eco/_ui/PointStatus";
function normStatus(v: any) {
  return String(v || "").trim().toUpperCase();
}
function isResolved(s: string) {
  const t = normStatus(s);
  return t === "RESOLVED" || t === "RESOLVIDO" || t === "DONE" || t === "CLOSED" || t === "FINALIZADO";
}
function pickMeta(p: any) {
  const m = (p && p.meta && typeof p.meta === "object") ? p.meta : null;
  return m || null;
}
function pickProof(p: any) {
  const m: any = pickMeta(p);
  const status = normStatus(p?.status || p?.state || m?.status || m?.state || "");
  const url = String(
    p?.proofUrl || p?.afterUrl || p?.resolvedProofUrl || p?.resolvedAfterUrl || p?.resolutionUrl ||
    m?.proofUrl || m?.afterUrl || m?.resolvedProofUrl || m?.resolvedAfterUrl || m?.resolutionUrl || m?.mutiraoAfterUrl ||
    ""
  ).trim();
  const note = String(
    p?.proofNote || p?.resolvedNote || p?.resolutionNote || p?.noteResolved ||
    m?.proofNote || m?.resolvedNote || m?.resolutionNote || m?.noteResolved ||
    ""
  ).trim();
  const mutiraoId = String(
    p?.mutiraoId || p?.mutiraoRefId || m?.mutiraoId || m?.mutiraoRefId || m?.mutirao || (p?.mutirao && p.mutirao.id) || ""
  ).trim();
  return { status, url, note, mutiraoId };
}
function StatusStamp(props: { status: string }) {
  const s = normStatus(props.status);
  const ok = isResolved(s);
  const label = ok ? "RESOLVIDO" : (s || "ABERTO");
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
      }}
    >
      {label}
    </span>
  );
}
function _ProofBlock(props: { p: any }) {
  const pr = pickProof(props.p);
  const show = isResolved(pr.status) || !!pr.url || !!pr.note;
  if (!show) return null;
  return (
    <section style={{ border: "1px solid #111", borderRadius: 16, padding: 12, background: "#fff", margin: "12px 0" }}>
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: 10, flexWrap: "wrap" }}>
        <div style={{ fontWeight: 900 }}>Status do ponto</div>
        <StatusStamp status={pr.status} />
      </div>

      <div style={{ marginTop: 10, display: "grid", gap: 10 }}>
        {pr.url ? (
          <div style={{ display: "grid", gap: 6 }}>
            <div style={{ fontSize: 13, opacity: 0.8 }}>Última prova (DEPOIS)</div>
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img src={pr.url} alt="Prova" style={{ width: "100%", maxWidth: 520, borderRadius: 14, border: "1px solid #111" }} />
          </div>
        ) : null}

        {pr.note ? (
          <div style={{ border: "1px dashed #111", borderRadius: 14, padding: 10, background: "#fffef1" }}>
            <div style={{ fontSize: 13, opacity: 0.8, marginBottom: 6 }}>Nota</div>
            <div style={{ whiteSpace: "pre-wrap" }}>{pr.note}</div>
          </div>
        ) : null}

        {pr.mutiraoId ? (
          <div style={{ display: "flex", gap: 10, flexWrap: "wrap" }}>
            <a href={"/eco/mutiroes/" + encodeURIComponent(pr.mutiraoId)} style={{ padding: "10px 12px", borderRadius: 12, border: "1px solid #111", textDecoration: "none", color: "#111" }}>
              Ver mutirão
            </a>
            <a href={"/eco/share/mutirao/" + encodeURIComponent(pr.mutiraoId)} target="_blank" rel="noreferrer" style={{ padding: "10px 12px", borderRadius: 12, border: "1px solid #111", textDecoration: "none", color: "#111", background: "#FFDD00", fontWeight: 900 }}>
              Compartilhar (card)
            </a>
          </div>
        ) : null}
      </div>
    </section>
  );
}


type AnyObj = any;

function pickNum(r: AnyObj, keys: string[]) {
  for (const k of keys) {
    const v = r?.[k];
    const n = Number(v);
    if (Number.isFinite(n)) return n;
  }
  return null;
}
function pickStr(r: AnyObj, keys: string[]) {
  for (const k of keys) {
    const v = r?.[k];
    if (typeof v === "string" && v.trim()) return v.trim();
  }
  return "";
}
function fmtDate(s: AnyObj) {
  if (!s) return "";
  try {
    const d = new Date(String(s));
    return d.toLocaleString();
  } catch {
    return String(s);
  }
}

export default function PointDetailClient({ id }: { id: string }) {
  const [item, setItem] = useState<AnyObj | null>(null);
  const [loading, setLoading] = useState(false);
  const [err, setErr] = useState<string | null>(null);
  const [proofNote, setProofNote] = useState("");
  const [proofUrl, setProofUrl] = useState("");
  const [msg, setMsg] = useState("");

  const lat = useMemo(() => (item ? pickNum(item, ["lat","latitude","geoLat"]) : null), [item]);
  const lng = useMemo(() => (item ? pickNum(item, ["lng","lon","longitude","geoLng"]) : null), [item]);
  const status = useMemo(() => (item ? String(item?.status || "") : ""), [item]);
  const category = useMemo(() => (item ? pickStr(item, ["category","kind","type","categoria"]) : ""), [item]);
  const bairro = useMemo(() => (item ? pickStr(item, ["bairro","neighborhood","area","regiao","region"]) : ""), [item]);
  const title = useMemo(() => (item ? pickStr(item, ["title","name","titulo"]) : ""), [item]);
  const description = useMemo(() => (item ? pickStr(item, ["description","desc","details","detalhes","note","notes","obs"]) : ""), [item]);
  const confirmations = useMemo(() => (item ? (pickNum(item, ["confirmations","confirmCount","votes","upvotes","confirmationsCount"]) ?? 0) : 0), [item]);

  async function load() {
    setLoading(true);
    setErr(null);
    setMsg("");
    try {
      const res = await fetch("/api/eco/points/get?id=" + encodeURIComponent(id), { cache: "no-store" } as any);
      const j = await res.json().catch(() => null);
      if (!res.ok || !j?.ok) throw new Error(j?.detail || j?.error || ("HTTP " + res.status));
      setItem(j.item);
    } catch (e: any) {
      setErr(e?.message || String(e));
    } finally {
      setLoading(false);
    }
  }

// eslint-disable-next-line react-hooks/exhaustive-deps
  useEffect(() => { void load(); }, [id]);

  async function confirm() {
    setErr(null);
    setMsg("");
    try {
      const res = await fetch("/api/eco/points/confirm", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ id }),
      });
      const j = await res.json().catch(() => null);
      if (!res.ok || !j?.ok) throw new Error(j?.detail || j?.error || ("HTTP " + res.status));
      setMsg("Confirmacao registrada (eu vi tambem).");
      await load();
    } catch (e: any) {
      setErr(e?.message || String(e));
    }
  }

  async function resolve() {
    setErr(null);
    setMsg("");
    try {
      if (proofNote.trim().length < 6) throw new Error("Escreva uma nota de prova (>= 6 caracteres).");
      const res = await fetch("/api/eco/points/resolve", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ id, proofNote: proofNote.trim(), proofUrl: proofUrl.trim() || undefined }),
      });
      const j = await res.json().catch(() => null);
      if (!res.ok || !j?.ok) throw new Error(j?.detail || j?.error || ("HTTP " + res.status));
      setMsg("Ponto marcado como RESOLVIDO (cuidado) com prova.");
      await load();
    } catch (e: any) {
      setErr(e?.message || String(e));
    }
  }

  const mapsHref = (lat != null && lng != null) ? ("https://www.google.com/maps?q=" + String(lat) + "," + String(lng)) : "";

  return (
    <section style={{ display: "grid", gap: 12 }}>
      <div style={{ padding: 12, border: "1px solid #e5e5e5", borderRadius: 12, background: "#fff" }}>
        <div style={{ display: "flex", justifyContent: "space-between", gap: 10, flexWrap: "wrap", alignItems: "center" }}>
          <div style={{ fontWeight: 900 }}>Detalhe</div>
          <button onClick={() => void load()} disabled={loading} style={{ padding: "8px 10px", borderRadius: 10, border: "1px solid #ccc", background: "#fff" }}>
            Atualizar
          </button>
        </div>

        {loading ? <div style={{ marginTop: 10, opacity: 0.75 }}>Carregando...</div> : null}
        {err ? <div style={{ marginTop: 10, color: "#b00020" }}>{err}</div> : null}
        {msg ? <div style={{ marginTop: 10, opacity: 0.9 }}>{msg}</div> : null}

        {item ? (
          <div style={{ marginTop: 10, display: "grid", gap: 8 }}>
            <div style={{ fontWeight: 900 }}>
              {status === "OPEN" ? "ABANDONO" : (status === "RESOLVED" ? "CUIDADO" : status)}
              {category ? (" - " + category) : ""}
              {bairro ? (" - " + bairro) : ""}
            </div>
            {title ? <div style={{ opacity: 0.95 }}>{title}</div> : null}
            {description ? <div style={{ opacity: 0.9 }}>{description}</div> : null}
            <div style={{ display: "flex", gap: 10, flexWrap: "wrap", alignItems: "center" }}>
              <div style={{ fontSize: 12, opacity: 0.75 }}>ID: {String(item?.id || id)}</div>
              <div style={{ fontSize: 12, opacity: 0.75 }}>Criado: {fmtDate(item?.createdAt)}</div>
              <div style={{ fontSize: 12, opacity: 0.75 }}>Atualizado: {fmtDate(item?.updatedAt)}</div>
            </div>
            <div style={{ display: "flex", gap: 10, flexWrap: "wrap" }}>
              <button onClick={() => void confirm()} style={{ padding: "10px 12px", borderRadius: 12, border: "1px solid #111", background: "#fff" }}>
                Eu vi tambem ({Number(confirmations || 0)})
              </button>
              {mapsHref ? (
                <a href={mapsHref} target="_blank" rel="noreferrer" style={{ textDecoration: "none", padding: "10px 12px", borderRadius: 12, border: "1px solid #111", color: "#111" }}>
                  Abrir no mapa
                </a>
              ) : null}
            </div>
          </div>
        ) : null}
      </div>

      <div style={{ padding: 12, border: "1px solid #e5e5e5", borderRadius: 12, background: "#fff" }}>
        <div style={{ fontWeight: 900, marginBottom: 8 }}>Marcar como resolvido (com prova)</div>
        <div style={{ opacity: 0.8, fontSize: 12, marginBottom: 10 }}>
          Regra: cuidado tem prova. Escreva o que foi feito, por quem (coletivo), e se tem registro (foto/link).
        </div>
        <label style={{ display: "grid", gap: 6 }}>
          <span>Nota de prova</span>
          <textarea value={proofNote} onChange={(e) => setProofNote((e.target as any).value)} rows={3} placeholder="Ex: mutirao fez limpeza, retirou sacos, area sinalizada, contato do operador..." style={{ padding: 10, borderRadius: 10, border: "1px solid #ccc" }} />
        </label>
        <label style={{ display: "grid", gap: 6, marginTop: 10 }}>
          <span>Link da prova (opcional)</span>
          <input value={proofUrl} onChange={(e) => setProofUrl((e.target as any).value)} placeholder="https://..." style={{ padding: 10, borderRadius: 10, border: "1px solid #ccc" }} />
        </label>
        <div style={{ marginTop: 10, display: "flex", gap: 10, flexWrap: "wrap" }}>
          <button onClick={() => void resolve()} style={{ padding: "10px 12px", borderRadius: 12, border: "1px solid #111", background: "#111", color: "#fff" }}>
            Marcar RESOLVIDO
          </button>
        </div>
      </div>
    </section>
  );
}
