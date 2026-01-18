'use client';

import Link from 'next/link';
import { useEffect, useMemo, useState } from 'react';

type AnyItem = any;

function ecoReceiptFromItem(item: AnyItem): any | null {
  return (item?.receipt ?? item?.Receipt ?? item?.recibo ?? null) as any;
}

function ecoReceiptCodeFromItem(item: AnyItem): string | null {
  const r = ecoReceiptFromItem(item);
  const code =
    r?.code ??
    r?.shareCode ??
    r?.publicCode ??
    r?.slug ??
    r?.id;
  return (typeof code === 'string' && code.trim().length > 0) ? code.trim() : null;
}

function ecoReceiptIsPublicFromItem(item: AnyItem): boolean {
  const r = ecoReceiptFromItem(item);
  return Boolean(r?.public ?? r?.isPublic);
}

function ecoTokenFromLocalStorage(): string | null {
  try {
    const keys = ['eco_token','ECO_TOKEN','ecoToken','token'];
    for (const k of keys) {
      const v = localStorage.getItem(k);
      if (v && v.trim()) return v.trim();
    }
    return null;
  } catch {
    return null;
  }
}

async function ecoCopyText(text: string) {
  try {
    await navigator.clipboard.writeText(text);
    alert('Link copiado!');
  } catch {
    // fallback
    prompt('Copie o link:', text);
  }
}

export default function ReceiptLinkFromItem(props: { item: AnyItem }) {
  const item = props?.item;

  const [token, setToken] = useState<string | null>(null);

  useEffect(() => {
    setToken(ecoTokenFromLocalStorage());
  }, []);

  const code = useMemo(() => ecoReceiptCodeFromItem(item), [item]);
  const isPublic = useMemo(() => ecoReceiptIsPublicFromItem(item), [item]);

  if (!code) return null;

  // regra: privado exige token; público não.
  if (!isPublic && !token) return null;

  const href = isPublic ? ('/r/' + code) : ('/recibos/' + code);

  const onCopy = async () => {
    const origin = (typeof window !== 'undefined' && window.location && window.location.origin) ? window.location.origin : '';
    const url = origin + '/r/' + code;
    await ecoCopyText(url);
  };

  return (
    <span className="inline-flex items-center gap-3">
      <Link href={href} className="underline">
        Ver recibo
      </Link>

      {isPublic ? (
        <button type="button" onClick={onCopy} className="underline">
          Copiar link
        </button>
      ) : null}
    </span>
  );
}