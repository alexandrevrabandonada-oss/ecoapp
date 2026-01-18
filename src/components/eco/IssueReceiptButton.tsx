"use client";
import React from "react";

function ecoReadToken(): string {
  try {
    return (
      localStorage.getItem("eco_token") ??
      localStorage.getItem("ECO_TOKEN") ??
      localStorage.getItem("token") ??
      ""
    ).trim();
  } catch {
    return "";
  }
}

export function IssueReceiptButton(props: { pickupId: string; label?: string; onIssued?: () => void }) {
  const [hasToken, setHasToken] = React.useState(false);
  const [busy, setBusy] = React.useState(false);

  React.useEffect(() => {
    setHasToken(!!ecoReadToken());
  }, []);

  if (!hasToken) return null;

  const onClick = async () => {
    try {
      if (busy) return;
      setBusy(true);
      const t = ecoReadToken();
      const headers: Record<string, string> = { "content-type": "application/json" };
      if (t) headers["x-eco-token"] = t;

      const r = await fetch(`/api/pickup-requests/${props.pickupId}/receipt`, { method: "POST", headers });
      if (!r.ok) {
        const txt = await r.text().catch(() => "");
        console.error("emitir recibo falhou", r.status, txt);
        alert(`Falhou ao emitir recibo (${r.status}). Veja o console.`);
        return;
      }

      if (props.onIssued) props.onIssued();
      else window.location.reload();
    } catch (e) {
      console.error(e);
      alert("Erro ao emitir recibo. Veja o console.");
    } finally {
      setBusy(false);
    }
  };

  return (
    <button
      type="button"
      onClick={onClick}
      disabled={busy}
      className="text-sm underline disabled:opacity-50"
      title="Emite e cola um Recibo ECO nesse pedido"
    >
      {busy ? "Emitindo..." : props.label ?? "Emitir recibo"}
    </button>
  );
}

export function IssueReceiptButtonFromItem(props: { item: any }) {
  const item: any = props.item;
  const id = String(item?.id ?? "");
  const code = item?.receipt?.code;
  if (!id) return null;
  if (code) return null;
  return <IssueReceiptButton pickupId={id} />;
}