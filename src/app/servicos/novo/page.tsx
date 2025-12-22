"use client";

import { useMemo, useState } from "react";

const KINDS = ["COLETA","REPARO","FEIRA","FORMACAO","DOACAO","OUTRO"];

export default function NovoServicoPage() {
  const [name, setName] = useState("");
  const [kind, setKind] = useState("COLETA");
  const [msg, setMsg] = useState("");

  const canSave = useMemo(() => name.trim().length > 0, [name]);

  async function onSave() {
    setMsg("");
    const res = await fetch("/api/services", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name, kind }),
    });
    const j = await res.json().catch(() => ({}));
    if (!res.ok) return setMsg("Erro: " + String(j?.message ?? j?.error ?? "unknown"));
    setMsg("✅ Serviço criado. Volte para /servicos.");
    setName("");
  }

  return (
    <main style={{ padding: 24, maxWidth: 720 }}>
      <h1 style={{ marginTop: 0 }}>Cadastrar serviço</h1>

      <label style={{ display: "block", marginTop: 12 }}>
        Nome
        <input value={name} onChange={(e) => setName(e.target.value)} style={{ width: "100%", padding: 8 }} />
      </label>

      <label style={{ display: "block", marginTop: 12 }}>
        Tipo
        <select value={kind} onChange={(e) => setKind(e.target.value)} style={{ width: "100%", padding: 8 }}>
          {KINDS.map((k) => <option key={k} value={k}>{k}</option>)}
        </select>
      </label>

      <div style={{ display: "flex", gap: 12, marginTop: 16 }}>
        <button disabled={!canSave} onClick={onSave} type="button">Salvar</button>
        <a href="/servicos">Voltar</a>
      </div>

      {msg ? <p style={{ marginTop: 12 }}>{msg}</p> : null}
    </main>
  );
}