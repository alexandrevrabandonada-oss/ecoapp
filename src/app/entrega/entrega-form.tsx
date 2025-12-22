"use client";

import { useState } from "react";

const materials = [
  "PAPEL","PAPELAO","PET","PLASTICO_MISTO","ALUMINIO","VIDRO","FERRO","ELETRONICOS","OUTRO"
] as const;

export default function EntregaForm({ pointSlug }: { pointSlug: string }) {
  const [material, setMaterial] = useState<(typeof materials)[number]>("PET");
  const [weightKg, setWeightKg] = useState<string>("");
  const [notes, setNotes] = useState<string>("");
  const [msg, setMsg] = useState<string>("");

  async function submit() {
    setMsg("");
    const res = await fetch("/api/delivery", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        pointSlug,
        material,
        weightKg: weightKg ? Number(weightKg) : undefined,
        notes: notes || undefined,
      }),
    });
    const j = await res.json();
    setMsg(j?.ok ? "Entrega registrada. Valeu por fortalecer o comum." : "Erro ao registrar.");
  }

  return (
    <main className="min-h-screen bg-neutral-950 text-emerald-300 p-6">
      <h1 className="text-2xl font-black">Registrar entrega</h1>
      <p className="text-emerald-200/80 mt-2">Ponto: <span className="font-semibold">{pointSlug}</span></p>

      <div className="mt-6 space-y-4 max-w-md">
        <label className="block">
          <div className="text-sm text-emerald-200/70">Material</div>
          <select className="w-full mt-1 p-2 rounded bg-neutral-950 border border-emerald-300/30"
                  value={material} onChange={(e) => setMaterial(e.target.value as any)}>
            {materials.map(m => <option key={m} value={m}>{m}</option>)}
          </select>
        </label>

        <label className="block">
          <div className="text-sm text-emerald-200/70">Peso (kg) — opcional</div>
          <input className="w-full mt-1 p-2 rounded bg-neutral-950 border border-emerald-300/30"
                 value={weightKg} onChange={(e) => setWeightKg(e.target.value)} placeholder="ex: 2.5" />
        </label>

        <label className="block">
          <div className="text-sm text-emerald-200/70">Observação (opcional)</div>
          <input className="w-full mt-1 p-2 rounded bg-neutral-950 border border-emerald-300/30"
                 value={notes} onChange={(e) => setNotes(e.target.value)} placeholder="ex: só papelão limpo" />
        </label>

        <button onClick={submit} className="px-4 py-2 rounded bg-emerald-300 text-black font-semibold">
          Enviar
        </button>

        {msg && <div className="text-emerald-200/90">{msg}</div>}
      </div>
    </main>
  );
}
