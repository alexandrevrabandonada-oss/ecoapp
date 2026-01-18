"use client";

import React, { useEffect, useMemo, useState } from "react";

type ApiResp = { ok: boolean; error?: string; detail?: any; item?: any; model?: string };

function normStatus(v: any) {
  return String(v || "").trim().toUpperCase();
}
function isResolved(s: string) {
  const t = normStatus(s);
  return t === "RESOLVED" || t === "RESOLVIDO" || t === "DONE" || t === "CLOSED" || t === "FINALIZADO";
}
function pickStatus(p: any) {
  const m = (p && p.meta && typeof p.meta === "object") ? p.meta : null;
  return normStatus(p?.status || p?.state || m?.status || m?.state || "");
}
function pickTitle(p: any) {
  return String(p?.title || p?.name || p?.label || p?.kind || "Ponto crítico");
}

async function apiGetPoint(id: string) {
  const r = await fetch("/api/eco/points/get?id=" + encodeURIComponent(id), { cache: "no-store" });
  return (await r.json().catch(() => ({ ok: false, error: "bad_json" }))) as ApiResp;
}

async function apiUpload(file: File) {
  const fd = new FormData();
  fd.append("file", file);
  // best-effort: some implementations accept kind
  fd.append("kind", "proof");
  const r = await fetch("/api/eco/upload", { method: "POST", body: fd });
  const j = await r.json().catch(() => ({} as any));
  // suportar formatos diferentes
  const url = String((j && (j.url || j.fileUrl || j.publicUrl || (j.item && (j.item.url || j.item.fileUrl)))) || "").trim();
  if (!url) throw new Error("upload_sem_url");
  return url;
}

async function apiResolve(id: string, proofUrl: string, proofNote: string) {
  const r = await fetch("/api/eco/points/resolve", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ id, proofUrl, proofNote }),
  });
  return (await r.json().catch(() => ({ ok: false, error: "bad_json" }))) as ApiResp;
}

export function PointResolveClient(props: { id: string }) {
  const id = String(props.id || "").trim();
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [err, setErr] = useState<string>("");
  const [okMsg, setOkMsg] = useState<string>("");
  const [item, setItem] = useState<any>(null);

  const [file, setFile] = useState<File | null>(null);
  const [note, setNote] = useState<string>("");
  const [proofUrl, setProofUrl] = useState<string>("");

  const status = useMemo(() => pickStatus(item), [item]);
  const resolved = useMemo(() => isResolved(status), [status]);

  useEffect(() => {
    let alive = true;
    (async () => {
      setLoading(true); setErr(""); setOkMsg("");
      try {
        const j = await apiGetPoint(id);
        if (!alive) return;
        if (!j.ok) throw new Error(j.error || "erro_get");
        setItem(j.item || null);
        // preload fields from meta if exist
        const m = (j.item && j.item.meta && typeof j.item.meta === "object") ? j.item.meta : null;
        const u = String((j.item && (j.item.proofUrl || j.item.afterUrl || j.item.resolvedProofUrl || j.item.resolvedAfterUrl)) || (m && (m.proofUrl || m.afterUrl || m.resolvedProofUrl || m.resolvedAfterUrl)) || "").trim();
        const n = String((j.item && (j.item.proofNote || j.item.resolvedNote || j.item.resolutionNote)) || (m && (m.proofNote || m.resolvedNote || m.resolutionNote)) || "").trim();
        if (u) setProofUrl(u);
        if (n) setNote(n);
      } catch (e: any) {
        setErr(String(e?.message || e));
      } finally {
        if (alive) setLoading(false);
      }
    })();
    return () => { alive = false; };
  }, [id]);

  async function onSave() {
    setErr(""); setOkMsg("");
    if (!id) { setErr("id_invalido"); return; }
    if (!file && !proofUrl && !note.trim()) { setErr("Envie uma foto OU escreva uma nota."); return; }
    setSaving(true);
    try {
      let url = proofUrl;
      if (file) {
        url = await apiUpload(file);
        setProofUrl(url);
      }
      const j = await apiResolve(id, url, note);
      if (!j.ok) throw new Error(j.error || "erro_resolve");
      setItem(j.item || item);
      setOkMsg("Ponto marcado como RESOLVIDO.");
    } catch (e: any) {
      setErr(String(e?.message || e));
    } finally {
      setSaving(false);
    }
  }

  if (!id) {
    return <div style={{ padding: 12, border: "1px solid #111", borderRadius: 14 }}>ID inválido.</div>;
  }

  return (
    <section style={{ border: "1px solid #111", borderRadius: 16, padding: 12, background: "#fff" }}>
      {loading ? (
        <div style={{ opacity: 0.8 }}>Carregando…</div>
      ) : null}

      {!loading ? (
        <div style={{ display: "grid", gap: 10 }}>
          <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: 10, flexWrap: "wrap" }}>
            <div>
              <div style={{ fontWeight: 900 }}>{pickTitle(item)}</div>
              <div style={{ fontSize: 13, opacity: 0.75 }}>ID: {id}</div>
            </div>
            <span
              style={{
                display: "inline-block",
                padding: "6px 10px",
                borderRadius: 999,
                border: "1px solid #111",
                fontWeight: 900,
                background: resolved ? "#B7FFB7" : "#FFDD00",
                color: "#111",
                textTransform: "uppercase",
                letterSpacing: 0.4,
                fontSize: 12,
              }}
            >
              {resolved ? "RESOLVIDO" : (status || "ABERTO")}
            </span>
          </div>

          {proofUrl ? (
            <div style={{ display: "grid", gap: 6 }}>
              <div style={{ fontSize: 13, opacity: 0.8 }}>Prova atual</div>
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img src={proofUrl} alt="Prova" style={{ width: "100%", maxWidth: 520, borderRadius: 14, border: "1px solid #111" }} />
            </div>
          ) : null}

          <div style={{ display: "grid", gap: 8 }}>
            <div style={{ fontWeight: 900 }}>Nova prova (foto)</div>
            <input type="file" accept="image/*" onChange={(e) => setFile((e.target.files && e.target.files[0]) ? e.target.files[0] : null)} />
            <div style={{ fontSize: 12, opacity: 0.75 }}>Se enviar, fazemos upload e salvamos como “prova (depois)”.</div>
          </div>

          <div style={{ display: "grid", gap: 8 }}>
            <div style={{ fontWeight: 900 }}>Nota</div>
            <textarea value={note} onChange={(e) => setNote(e.target.value)} rows={4} style={{ width: "100%", padding: 10, borderRadius: 12, border: "1px solid #111" }} placeholder="Descreva o que foi feito, data, quem ajudou, riscos, etc." />
          </div>

          {err ? (
            <div style={{ padding: 10, borderRadius: 12, border: "1px solid #111", background: "#fff2f2" }}>
              <b>Erro:</b> {err}
            </div>
          ) : null}
          {okMsg ? (
            <div style={{ padding: 10, borderRadius: 12, border: "1px solid #111", background: "#f0fff0" }}>
              {okMsg}
            </div>
          ) : null}

          <div style={{ display: "flex", gap: 10, flexWrap: "wrap" }}>
            <button onClick={onSave} disabled={saving} style={{ padding: "10px 12px", borderRadius: 12, border: "1px solid #111", background: "#FFDD00", fontWeight: 900 }}>
              {saving ? "Salvando…" : "Marcar como RESOLVIDO"}
            </button>
            <a href="../" style={{ padding: "10px 12px", borderRadius: 12, border: "1px solid #111", textDecoration: "none", color: "#111" }}>
              Voltar ao ponto
            </a>
          </div>
        </div>
      ) : null}
    </section>
  );
}
