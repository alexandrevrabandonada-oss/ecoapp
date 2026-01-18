"use client";

import React from "react";
import { useRouter } from "next/navigation";

type AnyRec = Record<string, any>;

function num(v: any) {
  const n = Number(v);
  return Number.isFinite(n) ? n : 0;
}

function getCounts(props: AnyRec) {
  const c = props?.counts ?? props?.value ?? props?.initialCounts ?? props?.data ?? null;
  return {
    confirm: num(c?.confirm ?? c?.confirmCount ?? 0),
    support: num(c?.support ?? c?.supportCount ?? 0),
    replicar: num(c?.replicar ?? c?.replicarCount ?? c?.replicate ?? 0),
  };
}

function setCountsBack(props: AnyRec, nextCounts: AnyRec) {
  try { if (typeof props?.onCounts === "function") props.onCounts(nextCounts); } catch {}
  try { if (typeof props?.onChange === "function") props.onChange(nextCounts); } catch {}
  try { if (typeof props?.setCounts === "function") props.setCounts(nextCounts); } catch {}
}

async function postAction(pointId: string, action: string, actor: string) {
  const body = JSON.stringify({ pointId, action, actor });
  const res = await fetch("/api/eco/points/action", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body,
  });
  let json: any = null;
  try { json = await res.json(); } catch {}
  if (!res.ok || !json?.ok) {
    const msg = json?.error || json?.message || ("http_" + String(res.status));
    throw new Error(String(msg));
  }
  return json;
}

export default function MuralPointActionsClient(props: AnyRec) {
  const router = useRouter();
  const pointId = String(props?.pointId ?? props?.id ?? "").trim();
  const actor = String(props?.actor ?? "anon").trim() || "anon";

  const [busy, setBusy] = React.useState<string>("");
  const [localCounts, setLocalCounts] = React.useState(() => getCounts(props));

  React.useEffect(() => {
    // se o pai atualizar counts, sincroniza (sem piscar demais)
    try { setLocalCounts(getCounts(props)); } catch {}
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [props?.counts, props?.value, props?.initialCounts]);

  function optimistic(action: string) {
    setLocalCounts((prev) => {
      const next = { confirm: num(prev.confirm), support: num(prev.support), replicar: num(prev.replicar) };
      if (action === "confirm") next.confirm = num(prev.confirm) + 1;
      if (action === "support") next.support = num(prev.support) + 1;
      if (action === "replicar") next.replicar = num(prev.replicar) + 1;
      return next;
    });
  }

  async function doAct(action: string) {
    if (!pointId) return;
    if (busy) return;
    setBusy(action);
    const snapshot = localCounts;
    optimistic(action);
    try {
      const json = await postAction(pointId, action, actor);
      const nextCounts = {
        confirm: num(json?.counts?.confirm),
        support: num(json?.counts?.support),
        replicar: num(json?.counts?.replicar),
      };
      setLocalCounts(nextCounts);
      setCountsBack(props, nextCounts);
      try { router.refresh(); } catch {}
    } catch {
      // rollback
      setLocalCounts(snapshot);
    } finally {
      setBusy("");
    }
  }

  const mapHref = "/eco/mapa?focus=" + encodeURIComponent(pointId || "");

  return (
    <div style={{ display: "flex", gap: 8, alignItems: "center", flexWrap: "wrap" }}>
      <button type="button" onClick={() => doAct("confirm")} disabled={!pointId || !!busy}
        style={{ padding: "8px 10px", borderRadius: 12, border: "1px solid #111", background: "#fff", fontWeight: 900 }}>
        ✅ {localCounts.confirm}
      </button>
      <button type="button" onClick={() => doAct("support")} disabled={!pointId || !!busy}
        style={{ padding: "8px 10px", borderRadius: 12, border: "1px solid #111", background: "#fff", fontWeight: 900 }}>
        🤝 {localCounts.support}
      </button>
      <button type="button" onClick={() => doAct("replicar")} disabled={!pointId || !!busy}
        style={{ padding: "8px 10px", borderRadius: 12, border: "1px solid #111", background: "#fff", fontWeight: 900 }}>
        ♻️ {localCounts.replicar}
      </button>

      <a href={mapHref}
        style={{ padding: "8px 10px", borderRadius: 12, border: "1px solid #111", background: "#fff", fontWeight: 900, textDecoration: "none", color: "#111" }}>
        🗺️ Mapa
      </a>
    </div>
  );
}
