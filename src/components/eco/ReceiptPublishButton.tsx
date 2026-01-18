'use client';

import React from 'react';

function ecoReadToken(): string | null {
  try {
    const keys = ['eco_token', 'eco_token', 'eco_operator_token', 'ECO_TOKEN', 'ECO_OPERATOR_TOKEN'];
    for (const k of keys) {
      const v = window.localStorage.getItem(k);
      if (v && v.trim()) return v.trim();
    }
    return null;
  } catch {
    return null;
  }
}

type AnyItem = any;

export function ReceiptPublishButtonFromItem({ item }: { item: AnyItem }) {
  const token = ecoReadToken();
  const receipt = (item as any)?.receipt;
  const code = receipt?.code as string | undefined;
  const initialPublic = !!receipt?.public;

  const [isPublic, setIsPublic] = React.useState<boolean>(initialPublic);
  const [busy, setBusy] = React.useState<boolean>(false);
  const [err, setErr] = React.useState<string | null>(null);

  React.useEffect(() => {
    setIsPublic(!!receipt?.public);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [receipt?.public, receipt?.code]);

  if (!code) return null;
  if (!token) return null;

  async function toggle() {
    setErr(null);
    setBusy(true);
    if (!code) { setBusy(false); return; }
    try {
      const res = await fetch('/api/receipts/' + encodeURIComponent(String(code || "")) + '/public', {
        method: 'PATCH',
        headers: {
          'content-type': 'application/json',
          ...(token ? { "x-eco-token": token } : {}),
        },
        body: JSON.stringify({ public: !isPublic }),
      });
      if (!res.ok) {
        const t = await res.text().catch(() => '');
        throw new Error('HTTP ' + res.status + (t ? ' — ' + t : ''));
      }
      const j = await res.json().catch(() => ({} as any));
      if (typeof (j as any)?.public === 'boolean') setIsPublic(!!(j as any).public);
    } catch (e: any) {
      setErr(e?.message ?? 'Falha ao atualizar');
    } finally {
      setBusy(false);
    }
  }

  return (
    <span className="inline-flex items-center gap-2">
      {isPublic ? (
        <span className="text-[11px] px-2 py-0.5 rounded border border-green-600/40 bg-green-600/10">
          Público
        </span>
      ) : (
        <span className="text-[11px] px-2 py-0.5 rounded border border-zinc-500/40 bg-zinc-500/10">
          Privado
        </span>
      )}

      <button
        type="button"
        onClick={toggle}
        disabled={busy}
        className="text-xs px-2 py-1 rounded border border-zinc-300 hover:bg-zinc-100 disabled:opacity-60"
        title="Alternar visibilidade do recibo"
      >
        {busy ? 'Salvando…' : (isPublic ? 'Tornar privado' : 'Publicar')}
      </button>

      {err ? <span className="text-xs text-red-600">{err}</span> : null}
    </span>
  );
}