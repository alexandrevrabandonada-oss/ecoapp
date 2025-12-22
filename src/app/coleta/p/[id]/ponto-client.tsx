"use client";

import Link from "next/link";
import { useEffect, useMemo, useState } from "react";

const MATERIALS = [
  "PAPEL","PAPELAO","PET","PLASTICO_MISTO","ALUMINIO","VIDRO","FERRO","ELETRONICOS","OUTRO",
] as const;

export default function PontoClient({ id }: { id: string }) {
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [msg, setMsg] = useState("");

  const [services, setServices] = useState<any[]>([]);
  const [serviceId, setServiceId] = useState("");

  const [title, setTitle] = useState("");
  const [materialKind, setMaterialKind] = useState<(typeof MATERIALS)[number]>("PET");
  const [address, setAddress] = useState("");
  const [contact, setContact] = useState("");
  const [isActive, setIsActive] = useState(true);

  useEffect(() => {
    (async () => {
      setLoading(true);
      setMsg("");
      try {
        const [pRes, sRes] = await Promise.all([
          fetch(`/api/points/${id}`, { cache: "no-store" }),
          fetch(`/api/services`, { cache: "no-store" }),
        ]);

        const pJson: any = await pRes.json().catch(() => ({}));
        const sJson: any = await sRes.json().catch(() => ({}));

        const point = pJson?.point ?? pJson?.data ?? null;
        const rawServices = sJson?.services ?? sJson?.items ?? sJson?.data ?? sJson;
        const list = Array.isArray(rawServices) ? rawServices : [];

        setServices(list);

        if (point) {
          const t = (point?.title ?? point?.name ?? "").toString();
          setTitle(t);
          setMaterialKind((point?.materialKind ?? "PET") as any);
          setAddress((point?.address ?? "").toString());
          setContact((point?.contact ?? "").toString());
          setIsActive(!!point?.isActive);
          setServiceId((point?.serviceId ?? list?.[0]?.id ?? "") as string);
        } else {
          setMsg("❌ Não achei esse ponto (404).");
        }
      } catch (e: any) {
        setMsg(`❌ Falha ao carregar: ${e?.message ?? "erro"}`);
      } finally {
        setLoading(false);
      }
    })();
  }, [id]);

  const canSave = useMemo(() => {
    return !loading && !saving && title.trim().length >= 2 && !!serviceId;
  }, [loading, saving, title, serviceId]);

  async function onSave() {
    setMsg("");
    setSaving(true);
    try {
      const payload: any = {
        serviceId,
        title: title.trim(),
        materialKind,
        address: address.trim(),
        contact: contact.trim(),
        isActive,
      };

      const res = await fetch(`/api/points/${id}`, {
        method: "PATCH",
        headers: { "content-type": "application/json" },
        body: JSON.stringify(payload),
      });

      const text = await res.text();
      if (!res.ok) throw new Error(text || "Falha ao salvar");
      setMsg("✅ Salvo!");
    } catch (e: any) {
      setMsg(`❌ ${e?.message ?? "Erro ao salvar"}`);
    } finally {
      setSaving(false);
    }
  }

  function buildShareText() {
    const t = title.trim() || "Ponto ECO";
    const parts = [
      `🌿 ECO — ${t}`,
      isActive ? "Status: ATIVO" : "Status: INATIVO",
      serviceId ? `Serviço: ${serviceId}` : null,
      materialKind ? `Material: ${materialKind}` : null,
      address.trim() ? `Endereço: ${address.trim()}` : null,
      contact.trim() ? `Contato: ${contact.trim()}` : null,
      "",
      `Abrir: ${typeof window !== "undefined" ? window.location.href : ""}`,
      "",
      "#ECO #EscutarCuidarOrganizar",
    ].filter(Boolean);
    return parts.join("\n");
  }

  async function onCopy() {
    try {
      await navigator.clipboard.writeText(buildShareText());
      setMsg("✅ Texto copiado!");
    } catch {
      setMsg("❌ Não consegui copiar (permissão do navegador).");
    }
  }

  function onWhatsApp() {
    const url = `https://wa.me/?text=${encodeURIComponent(buildShareText())}`;
    window.open(url, "_blank", "noopener,noreferrer");
  }

  async function onWebShare() {
    const text = buildShareText();
    try {
      if (navigator.share) {
        await navigator.share({ title: "ECO", text, url: window.location.href });
      } else {
        onWhatsApp();
      }
    } catch {
      // usuário cancelou ou navegador bloqueou
    }
  }

  return (
    <div className="stack">
      <div className="toolbar">
        <h1 style={{ marginRight: 10 }}>Ponto</h1>
        <Link className="btn" href="/coleta">Voltar</Link>
      </div>

      <div className="grid2">
        <div className="card">
          <div className="toolbar">
            <h2 style={{ margin: 0 }}>Editar</h2>
            <span className={isActive ? "badge ok" : "badge"}>{isActive ? "ATIVO" : "INATIVO"}</span>
          </div>

          {loading ? <p>Carregando…</p> : (
            <>
              <label>Serviço</label>
              <select value={serviceId} onChange={(e) => setServiceId(e.target.value)}>
                {services.map((s: any) => (
                  <option key={s.id} value={s.id}>{s.name} ({s.kind})</option>
                ))}
              </select>

              <label>Título</label>
              <input value={title} onChange={(e) => setTitle(e.target.value)} />

              <label>Material</label>
              <select value={materialKind} onChange={(e) => setMaterialKind(e.target.value as any)}>
                {MATERIALS.map((m) => <option key={m} value={m}>{m}</option>)}
              </select>

              <label>Endereço</label>
              <input value={address} onChange={(e) => setAddress(e.target.value)} />

              <label>Contato</label>
              <input value={contact} onChange={(e) => setContact(e.target.value)} />

              <div className="toolbar">
                <label style={{ display: "flex", gap: 10, alignItems: "center" }}>
                  <input type="checkbox" checked={isActive} onChange={(e) => setIsActive(e.target.checked)} />
                  Ativo
                </label>
                <button className="primary" onClick={onSave} disabled={!canSave}>
                  {saving ? "Salvando…" : "Salvar"}
                </button>
              </div>

              {msg ? <p>{msg}</p> : <p><small>Dica: deixa “Ativo” ligado pra aparecer na lista do bairro.</small></p>}
            </>
          )}
        </div>

        <div className="card">
          <h2>Compartilhar</h2>
          <p><small>
            Um “share pack” simples pra chamar gente pro ponto (WhatsApp primeiro).
          </small></p>

          <div className="toolbar" style={{ justifyContent: "flex-start" }}>
            <button className="primary" onClick={onWhatsApp}>WhatsApp</button>
            <button className="btn" onClick={onCopy}>Copiar texto</button>
            <button className="btn" onClick={onWebShare}>Web Share</button>
          </div>

          <hr />

          <p><small>Preview do texto:</small></p>
          <pre style={{
            margin: 0,
            whiteSpace: "pre-wrap",
            background: "rgba(0,0,0,.25)",
            border: "1px solid var(--border)",
            padding: 12,
            borderRadius: 12
          }}>{typeof window !== "undefined" ? buildShareText() : ""}</pre>
        </div>
      </div>
    </div>
  );
}