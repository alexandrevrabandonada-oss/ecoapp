"use client";

import Link from "next/link";
import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";

const MATERIALS = [
  "PAPEL","PAPELAO","PET","PLASTICO_MISTO","ALUMINIO","VIDRO","FERRO","ELETRONICOS","OUTRO",
] as const;

function mapsLink(address?: string, neighborhood?: string) {
  const a = (address ?? "").trim();
  const b = (neighborhood ?? "").trim();
  const q = [a,b].filter(Boolean).join(" - ");
  if (!q) return null;
  return `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(q)}`;
}

export default function NovoPontoPage() {
  const router = useRouter();
  const [services, setServices] = useState<any[]>([]);
  const [serviceId, setServiceId] = useState<string>("");

  const [title, setTitle] = useState("");
  const [materialKind, setMaterialKind] = useState<(typeof MATERIALS)[number]>("PET");
  const [address, setAddress] = useState("");
  const [neighborhood, setNeighborhood] = useState("");
  const [hours, setHours] = useState("");
  const [contact, setContact] = useState("");

  const [loading, setLoading] = useState(false);
  const [msg, setMsg] = useState("");

  useEffect(() => {
    (async () => {
      try {
        const res = await fetch("/api/services", { cache: "no-store" });
        const data: any = await res.json().catch(() => ({}));
        const raw = data?.services ?? data?.items ?? data?.data ?? data;
        const list = Array.isArray(raw) ? raw : [];
        setServices(list);
        if (!serviceId && list[0]?.id) setServiceId(list[0].id);
      } catch {
        setServices([]);
      }
    })();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const canSubmit = useMemo(() => {
    return !loading && serviceId && title.trim().length >= 2;
  }, [loading, serviceId, title]);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setMsg("");
    setLoading(true);
    try {
      const payload: any = {
        serviceId,
        title: title.trim(),
        name: title.trim(),
        materialKind,
        address: address.trim() || undefined,
        neighborhood: neighborhood.trim() || undefined,
        hours: hours.trim() || undefined,
        contact: contact.trim() || undefined,
        isActive: true,
      };

      const res = await fetch("/api/points", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify(payload),
      });

      const text = await res.text();
      if (!res.ok) throw new Error(text || "Falha ao criar ponto");
      setMsg("✅ Ponto criado! Indo pra lista…");
      router.push("/coleta");
      router.refresh();
    } catch (err: any) {
      setMsg(`❌ ${err?.message ?? "Erro"}`);
    } finally {
      setLoading(false);
    }
  }

  const m = mapsLink(address, neighborhood);

  return (
    <div className="stack">
      <div className="toolbar">
        <h1 style={{ marginRight: 10 }}>Novo ponto</h1>
        <Link className="btn" href="/coleta">Voltar</Link>
      </div>

      <div className="grid2">
        <form className="card" onSubmit={onSubmit}>
          <h2>Cadastro</h2>

          <label>Serviço</label>
          <select value={serviceId} onChange={(e) => setServiceId(e.target.value)}>
            {services.map((s: any) => (
              <option key={s.id} value={s.id}>
                {s.name} ({s.kind})
              </option>
            ))}
          </select>
          {services.length === 0 ? (
            <p><small>Não achei serviços ainda. Crie um em /servicos/novo.</small></p>
          ) : null}

          <label>Título do ponto</label>
          <input
            placeholder="Ex: Coleta Solidária — Rua 33"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
          />

          <label>Material (principal)</label>
          <select value={materialKind} onChange={(e) => setMaterialKind(e.target.value as any)}>
            {MATERIALS.map((mm) => (
              <option key={mm} value={mm}>{mm}</option>
            ))}
          </select>

          <label>Endereço (opcional)</label>
          <input
            placeholder="Ex: Rua, número, referência"
            value={address}
            onChange={(e) => setAddress(e.target.value)}
          />

          <label>Bairro (opcional)</label>
          <input
            placeholder="Ex: Aterrado, Retiro, Vila Santa Cecília"
            value={neighborhood}
            onChange={(e) => setNeighborhood(e.target.value)}
          />

          <label>Horários (opcional)</label>
          <input
            placeholder="Ex: Seg–Sex 8h–18h • Sáb 9h–12h"
            value={hours}
            onChange={(e) => setHours(e.target.value)}
          />

          <label>Contato (opcional)</label>
          <input
            placeholder="WhatsApp/Instagram/telefone"
            value={contact}
            onChange={(e) => setContact(e.target.value)}
          />

          {m ? (
            <div className="toolbar">
              <a className="btn" href={m} target="_blank" rel="noreferrer">Abrir no mapa (preview)</a>
            </div>
          ) : null}

          <div className="toolbar">
            <button className="primary" type="submit" disabled={!canSubmit}>
              {loading ? "Salvando..." : "Salvar ponto"}
            </button>
            <Link className="btn" href="/coleta">Cancelar</Link>
          </div>

          {msg ? <p>{msg}</p> : <p><small>Depois a gente adiciona: geolocalização, botão direto de WhatsApp e filtro por bairro.</small></p>}
        </form>

        <div className="card">
          <h2>Dica rápida</h2>
          <p><small>
            Bairro + horário é o mínimo pra virar “serviço de verdade” (o povo entende e usa).
          </small></p>
          <hr />
          <Link className="btn" href="/servicos/novo">+ Criar serviço</Link>
        </div>
      </div>
    </div>
  );
}