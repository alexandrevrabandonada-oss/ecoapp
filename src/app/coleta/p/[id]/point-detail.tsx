"use client";

import Link from "next/link";
import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";

const MATERIALS = [
  "PAPEL","PAPELAO","PET","PLASTICO_MISTO","ALUMINIO","VIDRO","FERRO","ELETRONICOS","OUTRO",
] as const;

function waLink(contact?: string | null) {
  if (!contact) return null;
  const c = String(contact).trim();
  if (!c) return null;
  if (/^https?:\/\//i.test(c)) return c;
  const digits = c.replace(/\D/g, "");
  if (!digits) return null;
  let num = digits;
  if (digits.length === 11) num = "55" + digits;
  if (digits.length === 13 && digits.startsWith("55")) num = digits;
  if (!num.startsWith("55")) return null;
  return `https://wa.me/${num}`;
}

function mapLink(address?: string | null, neighborhood?: string | null) {
  const a = String(address ?? "").trim();
  const b = String(neighborhood ?? "").trim();
  const q = [a, b].filter(Boolean).join(" - ");
  if (!q) return null;
  return `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(q)}`;
}

export default function PointDetail({ id }: { id: string }) {
  const router = useRouter();
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [msg, setMsg] = useState("");

  const [point, setPoint] = useState<any>(null);
  const [services, setServices] = useState<any[]>([]);

  const [serviceId, setServiceId] = useState("");
  const [title, setTitle] = useState("");
  const [materialKind, setMaterialKind] = useState<(typeof MATERIALS)[number]>("PET");
  const [address, setAddress] = useState("");
  const [neighborhood, setNeighborhood] = useState("");
  const [hours, setHours] = useState("");
  const [contact, setContact] = useState("");
  const [isActive, setIsActive] = useState(true);

  async function load() {
    setLoading(true);
    setMsg("");
    try {
      const [pRes, sRes] = await Promise.all([
        fetch(`/api/points/${id}`, { cache: "no-store" }),
        fetch("/api/services", { cache: "no-store" }),
      ]);

      const pData: any = await pRes.json().catch(() => ({}));
      const sData: any = await sRes.json().catch(() => ({}));
      const p = pData?.point ?? null;
      const rawS = sData?.services ?? sData?.items ?? sData?.data ?? sData;
      const sList = Array.isArray(rawS) ? rawS : [];

      setPoint(p);
      setServices(sList);

      if (p) {
        setServiceId(p.serviceId ?? p.service?.id ?? "");
        setTitle(p.title ?? p.name ?? "");
        setMaterialKind((p.materialKind ?? "PET") as any);
        setAddress(p.address ?? "");
        setNeighborhood(p.neighborhood ?? "");
        setHours(p.hours ?? "");
        setContact(p.contact ?? "");
        setIsActive(!!p.isActive);
      }
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { load(); /* eslint-disable-next-line */ }, [id]);

  const canSave = useMemo(() => {
    return !loading && !saving && title.trim().length >= 2 && !!serviceId;
  }, [loading, saving, title, serviceId]);

  const w = waLink(contact);
  const m = mapLink(address, neighborhood);

  async function onSave() {
    if (!canSave) return;
    setSaving(true);
    setMsg("");
    try {
      const payload: any = {
        serviceId,
        title: title.trim(),
        materialKind,
        address: address.trim(),
        neighborhood: neighborhood.trim(),
        hours: hours.trim(),
        contact: contact.trim(),
        isActive,
      };

      const res = await fetch(`/api/points/${id}`, {
        method: "PATCH",
        headers: { "content-type": "application/json" },
        body: JSON.stringify(payload),
      });

      const data: any = await res.json().catch(() => ({}));
      if (!res.ok) throw new Error(data?.error ?? JSON.stringify(data) ?? "Falha");

      setPoint(data.point);
      setMsg("✅ Salvo!");
      router.refresh();
    } catch (e: any) {
      setMsg(`❌ ${e?.message ?? "Erro"}`);
    } finally {
      setSaving(false);
    }
  }

  async function onDelete() {
    if (!confirm("Excluir este ponto?")) return;
    setSaving(true);
    setMsg("");
    try {
      const res = await fetch(`/api/points/${id}`, { method: "DELETE" });
      if (!res.ok) throw new Error(await res.text());
      setMsg("✅ Excluído. Voltando…");
      router.push("/coleta");
      router.refresh();
    } catch (e: any) {
      setMsg(`❌ ${e?.message ?? "Erro"}`);
    } finally {
      setSaving(false);
    }
  }

  async function copyLink() {
    try {
      await navigator.clipboard.writeText(window.location.href);
      setMsg("✅ Link copiado!");
    } catch {
      setMsg("❌ Não consegui copiar o link.");
    }
  }

  if (loading) return <div className="card"><p>Carregando...</p></div>;
  if (!point) return <div className="card"><p>Não achei esse ponto.</p></div>;

  return (
    <div className="grid2">
      <div className="card">
        <div className="toolbar">
          <h2 style={{ margin: 0 }}>Edição</h2>
          <span className={isActive ? "badge ok" : "badge"}>{isActive ? "ATIVO" : "INATIVO"}</span>
        </div>

        <label>Serviço</label>
        <select value={serviceId} onChange={(e) => setServiceId(e.target.value)}>
          <option value="">(selecione)</option>
          {services.map((s: any) => (
            <option key={s.id} value={s.id}>
              {s.name} ({s.kind})
            </option>
          ))}
        </select>

        <label>Título do ponto</label>
        <input value={title} onChange={(e) => setTitle(e.target.value)} />

        <label>Material (principal)</label>
        <select value={materialKind} onChange={(e) => setMaterialKind(e.target.value as any)}>
          {MATERIALS.map((m) => <option key={m} value={m}>{m}</option>)}
        </select>

        <label>Endereço</label>
        <input value={address} onChange={(e) => setAddress(e.target.value)} placeholder="Rua, nº, referência" />

        <label>Bairro</label>
        <input value={neighborhood} onChange={(e) => setNeighborhood(e.target.value)} placeholder="Ex: Aterrado" />

        <label>Horários</label>
        <input value={hours} onChange={(e) => setHours(e.target.value)} placeholder="Ex: seg-sex 9h–17h" />

        <label>Contato</label>
        <input value={contact} onChange={(e) => setContact(e.target.value)} placeholder="WhatsApp/Instagram/telefone" />

        <label style={{ display: "flex", alignItems: "center", gap: 10, marginTop: 10 }}>
          <input type="checkbox" checked={isActive} onChange={(e) => setIsActive(e.target.checked)} />
          <span>Ativo</span>
        </label>

        <div className="toolbar" style={{ marginTop: 12 }}>
          <button className="primary" onClick={onSave} disabled={!canSave}>
            {saving ? "Salvando..." : "Salvar"}
          </button>
          <button className="btn" type="button" onClick={copyLink}>Copiar link</button>
          <button className="btn danger" type="button" onClick={onDelete} disabled={saving}>Excluir</button>
        </div>

        {msg ? <p>{msg}</p> : <p><small>Dica: no próximo passo a gente adiciona “Compartilhar no WhatsApp” com texto pronto.</small></p>}
      </div>

      <div className="card">
        <h2 style={{ marginTop: 0 }}>Ações rápidas</h2>
        <div className="toolbar" style={{ flexWrap: "wrap" }}>
          {w ? <a className="btn" href={w} target="_blank" rel="noreferrer">WhatsApp</a> : <span className="badge">Sem WhatsApp</span>}
          {m ? <a className="btn" href={m} target="_blank" rel="noreferrer">Abrir mapa</a> : <span className="badge">Sem endereço</span>}
          <Link className="btn" href="/coleta">Voltar pra lista</Link>
        </div>

        <hr />

        <p style={{ margin: 0 }}>
          <small><b>ID:</b> {point.id}</small><br />
          <small><b>Serviço:</b> {point.service?.name ?? point.serviceId ?? "-"}</small><br />
          <small><b>Material:</b> {point.materialKind ?? "-"}</small>
        </p>
      </div>
    </div>
  );
}