"use client";

import { useEffect, useState } from "react";

export default function EcoPointResolutionPanel() {
  const [pointId, setPointId] = useState<string>("");
  const [loading, setLoading] = useState<boolean>(false);
  const [uploading, setUploading] = useState<boolean>(false);
  const [err, setErr] = useState<string | null>(null);
  const [data, setData] = useState<any>(null);
  const [note, setNote] = useState<string>("");
  const [evidenceUrl, setEvidenceUrl] = useState<string>("");

  useEffect(() => {
    try {
      const parts = String(window.location.pathname || "").split("/").filter(Boolean);
      const id = parts.length ? parts[parts.length - 1] : "";
      setPointId(id);
    } catch {
      // ignore
    }
  }, []);

  async function load() {
    if (!pointId) return;
    setLoading(true);
    setErr(null);
    try {
      const res = await fetch("/api/eco/point/detail?id=" + encodeURIComponent(pointId), { cache: "no-store" } as any);
      const j = await res.json().catch(() => null);
      if (!res.ok || !j?.ok) throw new Error(j?.detail || j?.error || ("HTTP " + res.status));
      setData(j);
    } catch (e: any) {
      setErr(e?.message || String(e));
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    void load();
// eslint-disable-next-line react-hooks/exhaustive-deps
  }, [pointId]);

  async function doUpload(file: File) {
    setUploading(true);
    setErr(null);
    try {
      const fd = new FormData();
      fd.append("file", file);
      fd.append("kind", "point_reopen");
      const res = await fetch("/api/eco/upload", { method: "POST", body: fd });
      const j = await res.json().catch(() => null);
      if (!res.ok || !j?.ok) throw new Error(j?.detail || j?.error || ("HTTP " + res.status));
      const url = String(j?.url || j?.fileUrl || j?.item?.url || "");
      if (!url) throw new Error("upload_ok_but_no_url");
      setEvidenceUrl(url);
    } catch (e: any) {
      setErr(e?.message || String(e));
    } finally {
      setUploading(false);
    }
  }

  async function doReopen() {
    if (!pointId) return;
    const n = String(note || "").trim();
    const ev = String(evidenceUrl || "").trim();
    // anti-reincidência: exige nova evidência OU relato bem completo
    if (ev.length < 6 && n.length < 20) {
      setErr("Para reabrir: envie uma evidência (foto/url) OU escreva um relato bem completo (>= 20 caracteres).");
      return;
    }
    setLoading(true);
    setErr(null);
    try {
      const res = await fetch("/api/eco/point/reopen", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ id: pointId, note: n, evidenceUrl: ev }),
      });
      const j = await res.json().catch(() => null);
      if (!res.ok || !j?.ok) throw new Error(j?.detail || j?.error || ("HTTP " + res.status));
      setNote("");
      await load();
    } catch (e: any) {
      setErr(e?.message || String(e));
    } finally {
      setLoading(false);
    }
  }

  const point = data?.point;
  const mut = data?.resolvedByMutirao;
  const status = String(point?.status || "").toUpperCase();
  const isResolved = status === "RESOLVED" || status === "DONE";

  return (
    <section style={{ margin: "14px 0", padding: 12, border: "1px solid #e5e5e5", borderRadius: 12, background: "#fff" }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", gap: 10 }}>
        <div style={{ fontWeight: 900 }}>Resolução & reincidência</div>
        <button onClick={() => void load()} disabled={loading || !pointId} style={{ padding: "6px 10px", borderRadius: 10, border: "1px solid #ccc", background: "#fff" }}>
          Atualizar
        </button>
      </div>

      {!pointId ? <div style={{ opacity: 0.75, marginTop: 8 }}>Carregando id…</div> : null}
      {err ? <div style={{ marginTop: 10, color: "#b00020" }}>{err}</div> : null}

      {isResolved && mut ? (
        <div style={{ marginTop: 10, display: "grid", gap: 6 }}>
          <div style={{ opacity: 0.8 }}>Este ponto foi resolvido por um mutirão.</div>
          <div style={{ display: "flex", gap: 10, flexWrap: "wrap" }}>
            <a href={"/eco/mutiroes/" + String(mut.id)} style={{ textDecoration: "none", padding: "8px 10px", borderRadius: 10, border: "1px solid #111", color: "#111" }}>
              Ver mutirão: {String(mut.id).slice(0, 8)}…
            </a>
          </div>
        </div>
      ) : null}

      {isResolved ? (
        <div style={{ marginTop: 12, display: "grid", gap: 10 }}>
          <div style={{ fontWeight: 800 }}>Reabrir (anti-reincidência)</div>
          <div style={{ opacity: 0.8, fontSize: 12 }}>
            Regra: para reabrir, precisamos de <b>nova evidência</b> (foto/url) ou um relato bem completo. Isso mantém o “recibo” como prova.
          </div>

          <label style={{ display: "grid", gap: 6 }}>
            <span>Nova evidência (URL da foto) — opcional</span>
            <input value={evidenceUrl} onChange={(e) => setEvidenceUrl(e.target.value)} placeholder="https://..." style={{ padding: 10, borderRadius: 10, border: "1px solid #ccc" }} />
          </label>

          <label style={{ display: "grid", gap: 6 }}>
            <span>Ou envie uma foto (upload)</span>
            <input type="file" accept="image/*" disabled={uploading} onChange={(e) => { const f = e.target.files && e.target.files[0]; if (f) void doUpload(f); }} />
            {uploading ? <span style={{ opacity: 0.7, fontSize: 12 }}>Enviando…</span> : null}
          </label>

          <label style={{ display: "grid", gap: 6 }}>
            <span>Justificativa / o que voltou a acontecer</span>
            <textarea value={note} onChange={(e) => setNote(e.target.value)} rows={3} placeholder="Descreva a reincidência (mín 20 caracteres se não tiver foto)..." style={{ padding: 10, borderRadius: 10, border: "1px solid #ccc" }} />
          </label>

          <div style={{ display: "flex", gap: 10, flexWrap: "wrap" }}>
            <button onClick={() => void doReopen()} disabled={loading || !pointId} style={{ padding: "10px 12px", borderRadius: 12, border: "1px solid #111", background: "#111", color: "#fff" }}>
              Reabrir ponto
            </button>
          </div>
        </div>
      ) : (
        <div style={{ marginTop: 10, opacity: 0.75, fontSize: 12 }}>(Este painel aparece quando o ponto está RESOLVIDO.)</div>
      )}
    </section>
  );
}
