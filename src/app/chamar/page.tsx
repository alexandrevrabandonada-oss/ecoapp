"use client";

import Link from "next/link";
import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";

const MATERIALS = [
  "PAPEL","PAPELAO","PET","PLASTICO_MISTO","ALUMINIO","VIDRO","FERRO","ELETRONICOS","OUTRO",
] as const;

export default function ChamarColetaPage() {
  const router = useRouter();

  const [services, setServices] = useState<any[]>([]);
  const [serviceId, setServiceId] = useState<string>("");

  const [materialKind, setMaterialKind] = useState<(typeof MATERIALS)[number]>("PET");
  const [quantity, setQuantity] = useState("");
  const [address, setAddress] = useState("");
  const [contact, setContact] = useState("");
  const [notes, setNotes] = useState("");
  const [isPublic, setIsPublic] = useState(false);

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
    return !loading && address.trim().length >= 5;
  }, [loading, address]);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setMsg("");
    setLoading(true);
    try {
      const payload: any = {
        serviceId: serviceId || undefined,
        materialKind,
        quantity: quantity.trim() || undefined,
        address: address.trim(),
        contact: contact.trim() || undefined,
        notes: notes.trim() || undefined,
        isPublic,
      };

      const res = await fetch("/api/requests", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify(payload),
      });

      const data = await res.json().catch(() => ({}));
      if (!res.ok) throw new Error(data?.error || "Falha ao criar pedido");

      const id = data?.request?.id;
      setMsg("✅ Pedido registrado!");
      router.push(`/chamar/sucesso?id=${encodeURIComponent(id || "")}`);
      router.refresh();
    } catch (err: any) {
      setMsg(`❌ ${err?.message ?? "Erro"}`);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="stack">
      <div className="toolbar">
        <h1>Chamar Coleta</h1>
        <Link className="btn" href="/">Voltar</Link>
      </div>

      <div className="grid2">
        <form className="card" onSubmit={onSubmit}>
          <h2>Seu pedido</h2>

          <label>Material (principal)</label>
          <select value={materialKind} onChange={(e) => setMaterialKind(e.target.value as any)}>
            {MATERIALS.map((m) => <option key={m} value={m}>{m}</option>)}
          </select>

          <label>Quantidade (opcional)</label>
          <input placeholder="Ex: 2 sacos / 1 caixa / 5 garrafas" value={quantity} onChange={(e)=>setQuantity(e.target.value)} />

          <label>Endereço (obrigatório)</label>
          <input placeholder="Bairro, rua, número, referência" value={address} onChange={(e)=>setAddress(e.target.value)} />

          <label>Contato (opcional)</label>
          <input placeholder="WhatsApp/Instagram/telefone" value={contact} onChange={(e)=>setContact(e.target.value)} />

          <label>Observações (opcional)</label>
          <textarea rows={3} placeholder="Ex: melhor horário, portaria, ponto de referência" value={notes} onChange={(e)=>setNotes(e.target.value)} />

          <div style={{ display:"flex", gap:10, alignItems:"center", marginTop:6 }}>
            <input id="pub" type="checkbox" checked={isPublic} onChange={(e)=>setIsPublic(e.target.checked)} />
            <label htmlFor="pub" style={{ margin:0 }}>
              Permitir uso público (transparência do bairro)
            </label>
          </div>

          {services.length ? (
            <>
              <label>Vincular a um serviço (opcional)</label>
              <select value={serviceId} onChange={(e) => setServiceId(e.target.value)}>
                <option value="">(sem vínculo)</option>
                {services.map((s:any)=>(
                  <option key={s.id} value={s.id}>{s.name} ({s.kind})</option>
                ))}
              </select>
            </>
          ) : null}

          <div className="toolbar">
            <button className="primary" type="submit" disabled={!canSubmit}>
              {loading ? "Enviando..." : "Enviar pedido"}
            </button>
            <Link className="btn" href="/coleta">Ver pontos</Link>
          </div>

          {msg ? <p>{msg}</p> : <p><small>Depois a gente liga isso ao Recibo ECO e às rotas.</small></p>}
        </form>

        <div className="card">
          <h2>Operação</h2>
          <p><small>Pra testar agora:</small></p>
          <ol className="list">
            <li>Faz um pedido aqui</li>
            <li>Abre <Link className="pill" href="/pedidos">/pedidos</Link></li>
            <li>Confere se chegou</li>
          </ol>
          <hr />
          <Link className="btn" href="/pedidos">Abrir lista de pedidos</Link>
        </div>
      </div>
    </div>
  );
}