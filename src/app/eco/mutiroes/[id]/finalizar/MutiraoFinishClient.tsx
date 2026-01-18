"use client";

import React, { useEffect, useMemo, useState } from "react";

type Props = { id: string };

function asMsg(e: unknown) {
  if (e instanceof Error) return e.message;
  try { return String(e); } catch { return "unknown"; }
}

async function jfetch(url: string, init?: RequestInit) {
  const res = await fetch(url, init);
  const data = await res.json().catch(() => null);
  if (!res.ok) {
    const msg = (data && (data.detail || data.error)) ? String(data.detail || data.error) : ("HTTP " + String(res.status));
    throw new Error(msg);
  }
  return data;
}

export default function MutiraoFinishClient(props: Props) {
  const id = String(props.id || "").trim();
  const shareHref = useMemo(() => ("/eco/share/mutirao/" + encodeURIComponent(id)), [id]);

  const [loading, setLoading] = useState(true);
  const [err, setErr] = useState<string>("");
  const [item, setItem] = useState<any>(null);

  const [proofNote, setProofNote] = useState<string>("");
  const [afterUrl, setAfterUrl] = useState<string>("");
  const [file, setFile] = useState<File | null>(null);

  const [busyUpload, setBusyUpload] = useState(false);
  const [busyFinish, setBusyFinish] = useState(false);
  const [done, setDone] = useState(false);

  async function load() {
    setLoading(true);
    setErr("");
    try {
      const data = await jfetch("/api/eco/mutirao/get?id=" + encodeURIComponent(id));
      const it = data?.item ?? data?.mutirao ?? null;
      setItem(it);
      const meta = (it && it.meta && typeof it.meta === "object") ? it.meta : null;
      if (meta) {
        if (!afterUrl && typeof meta.afterUrl === "string") setAfterUrl(meta.afterUrl);
        if (!proofNote && typeof meta.proofNote === "string") setProofNote(meta.proofNote);
      }
    } catch (e) {
      setErr(asMsg(e));
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    if (!id) { setErr("bad_id"); setLoading(false); return; }
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id]);

  async function doUpload() {
    if (!file) return;
    setBusyUpload(true);
    setErr("");
    try {
      const fd = new FormData();
      fd.append("file", file);
      fd.append("kind", "mutirao_after");
      fd.append("mutiraoId", id);
      const res = await fetch("/api/eco/upload", { method: "POST", body: fd });
      const j = await res.json().catch(() => null);
      if (!res.ok) {
        const msg = (j && (j.detail || j.error)) ? String(j.detail || j.error) : ("HTTP " + String(res.status));
        throw new Error(msg);
      }
      const url = String(j?.url || j?.item?.url || j?.publicUrl || j?.data?.url || j?.file?.url || "").trim();
      if (!url) throw new Error("upload_sem_url");
      setAfterUrl(url);
    } catch (e) {
      setErr(asMsg(e));
    } finally {
      setBusyUpload(false);
    }
  }

  async function saveProofBestEffort() {
    // Salva no meta do mutirão (não finaliza ainda)
    if (!afterUrl && !proofNote) return;
    try {
      await jfetch("/api/eco/mutirao/proof", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ id, afterUrl: afterUrl || "", proofNote: proofNote || "" }),
      });
    } catch (e) {
      // best-effort: não impede finalizar
      console.warn("proof_save_failed", e);
    }
  }

  async function doFinish() {
    setBusyFinish(true);
    setErr("");
    try {
      await saveProofBestEffort();
      // Finaliza (e tenta resolver ponto vinculado)
      await jfetch("/api/eco/mutirao/finish", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ id, afterUrl: afterUrl || "", proofNote: proofNote || "" }),
      });
      setDone(true);
      await load();
    } catch (e) {
      setErr(asMsg(e));
    } finally {
      setBusyFinish(false);
    }
  }

  const title = String(item?.title || item?.name || "Mutirão").trim();

  return (
    <section style={{ display: "grid", gap: 12 }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", gap: 10, flexWrap: "wrap" }}>
        <div style={{ display: "grid", gap: 4 }}>
          <div style={{ fontSize: 18, fontWeight: 900 }}>{title}</div>
          <div style={{ opacity: 0.75, fontSize: 13 }}>ID: {id}</div>
        </div>
        <div style={{ display: "flex", gap: 10, flexWrap: "wrap" }}>
          <a href={shareHref} target="_blank" rel="noreferrer" style={{ padding: "10px 12px", borderRadius: 12, border: "1px solid #111", textDecoration: "none", color: "#111", background: "#FFDD00", fontWeight: 900 }}>
            Abrir Share
          </a>
          <a href={"/eco/mutiroes/" + encodeURIComponent(id)} style={{ padding: "10px 12px", borderRadius: 12, border: "1px solid #111", textDecoration: "none", color: "#111" }}>
            Voltar
          </a>
        </div>
      </div>

      {loading ? <div style={{ opacity: 0.8 }}>Carregando…</div> : null}
      {err ? <div style={{ border: "1px solid #b00", background: "#ffecec", padding: 10, borderRadius: 12 }}>Erro: {err}</div> : null}

      <div style={{ border: "1px solid #111", borderRadius: 16, padding: 12, background: "#fff" }}>
        <div style={{ fontWeight: 900, marginBottom: 8 }}>Prova do mutirão</div>

        <div style={{ display: "grid", gap: 8 }}>
          <label style={{ display: "grid", gap: 6 }}>
            <div style={{ fontSize: 13, opacity: 0.85 }}>Nota (o que foi feito / como ficou)</div>
            <textarea value={proofNote} onChange={(e) => setProofNote(e.target.value)} rows={3} style={{ width: "100%", borderRadius: 12, border: "1px solid #111", padding: 10 }} />
          </label>

          <label style={{ display: "grid", gap: 6 }}>
            <div style={{ fontSize: 13, opacity: 0.85 }}>Foto do DEPOIS (opcional)</div>
            <input type="file" accept="image/*" onChange={(e) => setFile(e.target.files && e.target.files[0] ? e.target.files[0] : null)} />
          </label>

          <label style={{ display: "grid", gap: 6 }}>
            <div style={{ fontSize: 13, opacity: 0.85 }}>Ou cole um link de imagem (se já tiver hospedada)</div>
            <input value={afterUrl} onChange={(e) => setAfterUrl(e.target.value)} placeholder="https://..." style={{ width: "100%", borderRadius: 12, border: "1px solid #111", padding: 10 }} />
          </label>

          <div style={{ display: "flex", gap: 10, flexWrap: "wrap" }}>
            <button
              onClick={doUpload}
              disabled={!file || busyUpload || busyFinish}
              style={{ padding: "10px 12px", borderRadius: 12, border: "1px solid #111", background: "#111", color: "#fff", fontWeight: 900 }}
            >
              {busyUpload ? "Enviando…" : "Enviar foto"}
            </button>

            <button
              onClick={doFinish}
              disabled={busyFinish || busyUpload}
              style={{ padding: "10px 12px", borderRadius: 12, border: "1px solid #111", background: "#FFDD00", fontWeight: 900 }}
            >
              {busyFinish ? "Finalizando…" : "Finalizar mutirão"}
            </button>
          </div>

          {afterUrl ? (
            <div style={{ display: "grid", gap: 6 }}>
              <div style={{ fontSize: 13, opacity: 0.8 }}>Preview:</div>
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img src={afterUrl} alt="Depois" style={{ width: "100%", maxWidth: 520, borderRadius: 14, border: "1px solid #111" }} />
            </div>
          ) : null}

          {done ? (
            <div style={{ border: "1px solid #0a0", background: "#eaffea", padding: 10, borderRadius: 12 }}>
              <div style={{ fontWeight: 900 }}>Finalizado!</div>
              <div style={{ opacity: 0.85 }}>Agora é só compartilhar: <a href={shareHref} target="_blank" rel="noreferrer">abrir card</a></div>
            </div>
          ) : null}
        </div>
      </div>
    </section>
  );
}
