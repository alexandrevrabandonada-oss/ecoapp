"use client";

import { useEffect, useMemo, useState } from "react";

type ApiResp =
  | { ok: true; item: { day: string; summary: unknown; updatedAt?: string } }
  | { ok: false; error: string };

function template(day: string) {
  return {
    day,
    totals: {
      "Papel/Papelão": {},
      "Plástico": {},
      "Metal": {},
      "Vidro": {},
      "Óleo": { litros: 0 },
      "E-lixo": { unidades: 0 },
      "Rejeito": {},
    },
    notes: "",
    meta: { unitsV0: true },
  };
}

export default function DayClosePanel({ day }: { day: string }) {
  const [loading, setLoading] = useState(true);
  const [saved, setSaved] = useState<unknown>(null);
  const [err, setErr] = useState<string | null>(null);

  const initialDraft = useMemo(() => JSON.stringify(template(day), null, 2), [day]);
  const [draft, setDraft] = useState<string>(initialDraft);

// eslint-disable-next-line react-hooks/exhaustive-deps
  useEffect(() => {
    setDraft(initialDraft);
    setSaved(null);
    setErr(null);
    setLoading(true);

    fetch("/api/eco/day-close?day=" + encodeURIComponent(day))
      .then(async (r) => {
        const j = (await r.json().catch(() => null)) as ApiResp | null;
        if (!j) throw new Error("Resposta inválida");
        if (j.ok) {
          setSaved(j.item.summary);
          setDraft(JSON.stringify(j.item.summary ?? template(day), null, 2));
        } else {
          if (j.error === "not_found") return;
          if (j.error === "db_not_ready" || j.error === "model_not_ready") { setErr("Banco ainda não pronto (rode migrate/prisma)."); return; }
          throw new Error(j.error);
        }
      })
      .catch((e: unknown) => {
        const msg = e instanceof Error ? e.message : "Erro ao carregar";
        setErr(msg);
      })
      .finally(() => setLoading(false));
  }, [day, initialDraft]);

    const onAutoFill = async () => {
    setErr(null);
    try {
      const url = "/api/eco/day-close/compute?day=" + encodeURIComponent(day);
      const res = await fetch(url);
      const j = (await res.json().catch(() => null)) as any;
      if (!j || !j.ok || !j.summary) {
        setErr("Auto-fill falhou (resposta inválida).");
        return;
      }
      setDraft(JSON.stringify(j.summary, null, 2));
      alert("Auto preenchido ✅ (v0) — revise antes de salvar");
// eslint-disable-next-line @typescript-eslint/no-explicit-any
    } catch (e: any) {
      setErr(e?.message || "Auto-fill falhou");
    }
  };
const onSave = async () => {
    setErr(null);
    let parsed: unknown = null;
    try {
      parsed = JSON.parse(draft);
    } catch {
      setErr("JSON inválido (não consegui dar parse).");
      return;
    }

    const res = await fetch("/api/eco/day-close", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ day, summary: parsed }),
    });

    const j = (await res.json().catch(() => null)) as ApiResp | null;
    if (!j || !("ok" in j)) {
      setErr("Falha ao salvar (resposta inválida).");
      return;
    }
    if (!j.ok) {
      setErr("Falha ao salvar: " + j.error);
      return;
    }
    setSaved(j.item.summary);
    alert("Fechamento salvo ✅");
  };

  return (
    <section style={{ marginTop: 18, border: "1px solid #222", borderRadius: 14, padding: 14 }}>
      <div style={{ display: "flex", flexWrap: "wrap", gap: 10, alignItems: "baseline", justifyContent: "space-between" }}>
        <h2 style={{ fontSize: 16, fontWeight: 900, margin: 0 }}>Fechamento do dia (salvo)</h2>
        <div style={{ fontSize: 12, opacity: 0.75 }}>
          {loading ? "carregando…" : saved ? "existe fechamento salvo" : "ainda não salvo"}
        </div>
      </div>

      {err ? <p style={{ color: "#ff3b30", marginTop: 10 }}>Erro: {err}</p> : null}

      <p style={{ marginTop: 10, fontSize: 13, opacity: 0.85 }}>
        Por enquanto esse painel salva um <strong>JSON</strong> do resumo do dia (v0).
      </p>

      <textarea
        value={draft}
        onChange={(e) => setDraft(e.target.value)}
        spellCheck={false}
        style={{ width: "100%", minHeight: 220, marginTop: 10, padding: 10, borderRadius: 10, border: "1px solid #333", fontFamily: "ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace" }}
      />

      <div style={{ display: "flex", flexWrap: "wrap", gap: 10, marginTop: 10 }}>
                <button type="button" onClick={onAutoFill} style={{ padding: "8px 10px", border: "1px solid #333", borderRadius: 10 }}>
          Auto preencher (triagem)
        </button>
<button type="button" onClick={onSave} style={{ padding: "8px 10px", border: "1px solid #333", borderRadius: 10 }}>
          Salvar fechamento
        </button>
        <button type="button" onClick={() => setDraft(JSON.stringify(template(day), null, 2))} style={{ padding: "8px 10px", border: "1px solid #333", borderRadius: 10 }}>
          Reset template
        </button>
      </div>

      {saved ? (
        <details style={{ marginTop: 12 }}>
          <summary style={{ cursor: "pointer" }}>Ver JSON salvo</summary>
          <pre style={{ whiteSpace: "pre-wrap", marginTop: 10, fontSize: 12, opacity: 0.9 }}>
            {JSON.stringify(saved, null, 2)}
          </pre>
        </details>
      ) : null}
    </section>
  );
}