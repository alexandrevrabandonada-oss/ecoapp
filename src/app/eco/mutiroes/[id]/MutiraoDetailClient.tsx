"use client";

import { useEffect, useMemo, useState } from "react";

type AnyObj = Record<string, any>;

async function jget(url: string): Promise<AnyObj> {
  const res = await fetch(url, { headers: { Accept: "application/json" }, cache: "no-store" });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) return { ok: false, status: res.status, ...data };
  return data;
}
async function jpost(url: string, body: AnyObj): Promise<AnyObj> {
  const res = await fetch(url, { method: "POST", headers: { "Content-Type": "application/json", Accept: "application/json" }, body: JSON.stringify(body), cache: "no-store" });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) return { ok: false, status: res.status, ...data };
  return data;
}

function chkDefault() {
  return { proofNote: "", luvas: false, sacos: false, agua: false, separacao: false, destino: false, aviso_vizinhos: false };
}

async function uploadEco(file: File, prefix: string) {
  const fd = new FormData();
  fd.append("file", file);
  fd.append("prefix", prefix);
  const res = await fetch("/api/eco/upload", { method: "POST", body: fd, cache: "no-store" });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) return { ok: false, status: res.status, ...data };
  return data;
}

export default function MutiraoDetailClient({ id }: { id: string }) {
  const [status, setStatus] = useState<string>("carregando");
  const [item, setItem] = useState<AnyObj | null>(null);
  const [msg, setMsg] = useState<string>("");

  const [beforeUrl, setBeforeUrl] = useState<string>("");
  const [afterUrl, setAfterUrl] = useState<string>("");
  const [check, setCheck] = useState<AnyObj>(chkDefault());

  const [upBefore, setUpBefore] = useState<boolean>(false);
  const [upAfter, setUpAfter] = useState<boolean>(false);

  const card3x4 = useMemo(() => "/api/eco/mutirao/card?format=3x4&id=" + encodeURIComponent(id), [id]);
  const shareUrl = useMemo(() => "/eco/share/mutirao/" + encodeURIComponent(id), [id]);

  async function refresh() {
    setStatus("carregando");
    setMsg("");
    const d = await jget("/api/eco/mutirao/get?id=" + encodeURIComponent(id));
    if (d && d.ok && d.item) {
      setItem(d.item);
      setBeforeUrl(String(d.item.beforeUrl || ""));
      setAfterUrl(String(d.item.afterUrl || ""));
      setCheck(d.item.checklist && typeof d.item.checklist === "object" ? d.item.checklist : chkDefault());
      setStatus("ok");
    } else {
      setItem(null);
      setStatus("erro");
      setMsg("Erro: " + String(d?.error || d?.detail || "unknown"));
    }
  }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  // eslint-disable-next-line react-hooks/exhaustive-deps
  useEffect(() => { refresh(); }, []);
  function toggle(k: string) { setCheck((prev: AnyObj) => ({ ...prev, [k]: !prev?.[k] })); }

  async function saveDraft() {
    setMsg("");
    const d = await jpost("/api/eco/mutirao/update", { id, beforeUrl, afterUrl, checklist: check });
    if (d && d.ok) { setMsg("Rascunho salvo."); await refresh(); }
    else setMsg("Erro: " + String(d?.error || d?.detail || "unknown"));
  }
  async function finish() {
    setMsg("");
    const d = await jpost("/api/eco/mutirao/finish", { id, beforeUrl, afterUrl, checklist: check });
    if (d && d.ok) { setMsg("Mutirão finalizado (DONE)."); await refresh(); }
    else setMsg("Erro: " + String(d?.error || d?.detail || "unknown"));
  }

  async function onPickBefore(f: File | null) {
    if (!f) return;
    setUpBefore(true);
    setMsg("");
    const r = await uploadEco(f, "mutirao_before");
    setUpBefore(false);
    if (r && r.ok && r.url) { setBeforeUrl(String(r.url)); setMsg("Upload (antes) ok."); }
    else setMsg("Upload falhou: " + String(r?.error || r?.detail || "unknown"));
  }
  async function onPickAfter(f: File | null) {
    if (!f) return;
    setUpAfter(true);
    setMsg("");
    const r = await uploadEco(f, "mutirao_after");
    setUpAfter(false);
    if (r && r.ok && r.url) { setAfterUrl(String(r.url)); setMsg("Upload (depois) ok."); }
    else setMsg("Upload falhou: " + String(r?.error || r?.detail || "unknown"));
  }

  const p = item?.point || {};

  return (
    <section style={{ display: "grid", gap: 12 }}>
      <div style={{ display: "flex", gap: 10, flexWrap: "wrap", alignItems: "center" }}>
        <a href="/eco/mutiroes" style={{ textDecoration: "none", padding: "8px 10px", borderRadius: 10, border: "1px solid #111" }}>Voltar</a>
        <a href={shareUrl} style={{ textDecoration: "none", padding: "8px 10px", borderRadius: 10, border: "1px solid #111" }}>Página de share</a>
        <a href={card3x4} target="_blank" rel="noreferrer" style={{ textDecoration: "none", padding: "8px 10px", borderRadius: 10, border: "1px solid #111" }}>Ver card (3:4)</a>
        <div style={{ opacity: 0.7 }}>status: {status}</div>
      </div>

      <div style={{ display: "grid", gap: 8, padding: 12, border: "1px solid #ddd", borderRadius: 12 }}>
        <div style={{ fontWeight: 900 }}>Ponto</div>
        <div style={{ opacity: 0.9 }}>{String(p.kind || "—")}</div>
        <div style={{ opacity: 0.85 }}>{p.note ? String(p.note) : "—"}</div>
        <div style={{ opacity: 0.7, fontSize: 12 }}>confirmações: {String(p.confirmCount || 0)}</div>
      </div>

      <div style={{ display: "grid", gap: 10, padding: 12, border: "1px solid #ddd", borderRadius: 12 }}>
        <div style={{ fontWeight: 900 }}>Antes / Depois (upload simples)</div>

        <div style={{ display: "grid", gap: 8 }}>
          <div style={{ display: "flex", gap: 10, flexWrap: "wrap", alignItems: "center" }}>
            <label style={{ display: "grid", gap: 6 }}>
              <span>Foto ANTES</span>
              <input type="file" accept="image/*" disabled={upBefore} onChange={(e) => onPickBefore(e.target.files && e.target.files[0] ? e.target.files[0] : null)} />
            </label>
            <div style={{ opacity: 0.7 }}>{upBefore ? "enviando..." : (beforeUrl ? "ok" : "sem foto")}</div>
          </div>
{/* eslint-disable-next-line @next/next/no-img-element */}
          {beforeUrl ? <img src={beforeUrl} alt="antes" style={{ width: "100%", maxWidth: 520, borderRadius: 12, border: "1px solid #eee" }} /> : null}
          <label style={{ display: "grid", gap: 4 }}>
            <span>Antes (URL manual — opcional)</span>
            <input value={beforeUrl} onChange={(e) => setBeforeUrl(e.target.value)} placeholder="/eco-uploads/... ou https://..." style={{ padding: 10, borderRadius: 10, border: "1px solid #ccc" }} />
          </label>
        </div>

        <div style={{ display: "grid", gap: 8 }}>
          <div style={{ display: "flex", gap: 10, flexWrap: "wrap", alignItems: "center" }}>
            <label style={{ display: "grid", gap: 6 }}>
              <span>Foto DEPOIS</span>
              <input type="file" accept="image/*" disabled={upAfter} onChange={(e) => onPickAfter(e.target.files && e.target.files[0] ? e.target.files[0] : null)} />
            </label>
            <div style={{ opacity: 0.7 }}>{upAfter ? "enviando..." : (afterUrl ? "ok" : "sem foto")}</div>
          </div>
{/* eslint-disable-next-line @next/next/no-img-element */}
          {afterUrl ? <img src={afterUrl} alt="depois" style={{ width: "100%", maxWidth: 520, borderRadius: 12, border: "1px solid #eee" }} /> : null}
          <label style={{ display: "grid", gap: 4 }}>
            <span>Depois (URL manual — opcional)</span>
            <input value={afterUrl} onChange={(e) => setAfterUrl(e.target.value)} placeholder="/eco-uploads/... ou https://..." style={{ padding: 10, borderRadius: 10, border: "1px solid #ccc" }} />
          </label>
        </div>

        <div style={{ opacity: 0.7, fontSize: 12 }}>Depois do upload, clique em “Salvar rascunho” ou “Finalizar (DONE)” pra gravar no banco.</div>
      </div>

      <div style={{ display: "grid", gap: 10, padding: 12, border: "1px solid #ddd", borderRadius: 12 }}>
        <div style={{ fontWeight: 900 }}>Checklist do mutirão</div>
        <div style={{ opacity: 0.7, fontSize: 12 }}>Regra: pra finalizar (DONE), precisa ANTES+DEPOIS ou uma justificativa.</div>
        <label style={{ display: "grid", gap: 6 }}>
          <span>Justificativa (se faltar foto)</span>
          <textarea value={String((check as any)?.proofNote || "")} onChange={(e) => setCheck((prev: any) => ({ ...prev, proofNote: e.target.value }))} rows={3} placeholder="Explique por que faltou foto (mín 10 caracteres)..." style={{ padding: 10, borderRadius: 10, border: "1px solid #ccc" }} />
        </label>
        <div style={{ display: "grid", gap: 8 }}>
          {["luvas","sacos","agua","separacao","destino","aviso_vizinhos"].map((k) => (
            <label key={k} style={{ display: "flex", gap: 10, alignItems: "center" }}>
              <input type="checkbox" checked={!!check?.[k]} onChange={() => toggle(k)} />
              <span style={{ opacity: 0.9 }}>{k}</span>
            </label>
          ))}
        </div>
      </div>

      <div style={{ display: "flex", gap: 10, flexWrap: "wrap", alignItems: "center" }}>
        <button onClick={saveDraft} style={{ padding: "10px 12px", borderRadius: 12, border: "1px solid #111", background: "#fff", cursor: "pointer" }}>Salvar rascunho</button>
        <button onClick={finish} style={{ padding: "10px 12px", borderRadius: 12, border: "1px solid #111", background: "#111", color: "#F7D500", fontWeight: 900, cursor: "pointer" }}>Finalizar (DONE)</button>
      </div>

      {msg ? <div style={{ padding: 10, borderRadius: 10, background: "#fff7cc", border: "1px solid #f0d000" }}>{msg}</div> : null}
    </section>
  );
}
