"use client";

import Link from "next/link";
import { useState } from "react";

export default function ChamarColetaNovoPage() {
  const [name, setName] = useState("");
  const [phone, setPhone] = useState("");
  const [address, setAddress] = useState("");
  const [notes, setNotes] = useState("");
  const [saving, setSaving] = useState(false);
  const [ok, setOk] = useState<string | null>(null);
  const [err, setErr] = useState<string | null>(null);

  async function submit() {
    setSaving(true);
    setErr(null);
    setOk(null);
    try {
      const res = await fetch("/api/pickup-requests", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ name, phone, address, notes }),
      });
      if (!res.ok) throw new Error("Falha ao criar pedido");
      const json = (await res.json()) as { id?: string };
      setOk(json?.id ? "Pedido criado: " + json.id : "Pedido criado.");
      setName(""); setPhone(""); setAddress(""); setNotes("");
    } catch (e) {
      setErr(e instanceof Error ? e.message : "Erro");
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="stack">
      <div className="card">
        <div className="toolbar">
          <h1 style={{ margin: 0 }}>Novo pedido</h1>
          <span className="badge">v0</span>
        </div>
        <p style={{ marginTop: 8 }}><small>Cadastro rápido do pedido de coleta.</small></p>

        <div className="stack" style={{ gap: 10, marginTop: 10 }}>
          <label>
            <small><b>Nome</b></small><br />
            <input className="input" value={name} onChange={(e) => setName(e.target.value)} />
          </label>
          <label>
            <small><b>Telefone</b></small><br />
            <input className="input" value={phone} onChange={(e) => setPhone(e.target.value)} />
          </label>
          <label>
            <small><b>Endereço</b></small><br />
            <input className="input" value={address} onChange={(e) => setAddress(e.target.value)} />
          </label>
          <label>
            <small><b>Observações</b></small><br />
            <textarea className="input" rows={3} value={notes} onChange={(e) => setNotes(e.target.value)} />
          </label>

          {ok ? <p><small className="muted">✅ {ok}</small></p> : null}
          {err ? <p><small>❌ {err}</small></p> : null}

          <div className="toolbar">
            <button className="primary" disabled={saving} onClick={submit}>{saving ? "Salvando…" : "Criar pedido"}</button>
            <Link className="btn" href="/chamar-coleta">Voltar</Link>
            <Link className="btn" href="/">HUB</Link>
          </div>
        </div>
      </div>
    </div>
  );
}