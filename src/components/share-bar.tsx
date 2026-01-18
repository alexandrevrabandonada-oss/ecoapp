"use client";

import { useMemo, useState } from "react";

export default function ShareBar({ path, label }: { path: string; label: string }) {
  const [copied, setCopied] = useState(false);

  const url = useMemo(() => {
    if (typeof window === "undefined") return path;
    return `${window.location.origin}${path}`;
  }, [path]);

  const text = useMemo(() => `${label}\n${url}`, [label, url]);

  async function onShare() {
    try {
      if (navigator.share) {
        await navigator.share({ title: label, text, url });
      } else {
        await navigator.clipboard.writeText(text);
        setCopied(true);
        setTimeout(() => setCopied(false), 1200);
      }
    } catch { void 0; }
  }

  async function onCopy() {
    try {
      await navigator.clipboard.writeText(text);
      setCopied(true);
      setTimeout(() => setCopied(false), 1200);
    } catch { void 0; }
  }

  const wa = useMemo(() => {
    const u = encodeURIComponent(text);
    return `https://wa.me/?text=${u}`;
  }, [text]);

  return (
    <div className="toolbar">
      <button className="primary" onClick={onShare}>Compartilhar</button>
      <a className="btn" href={wa} target="_blank" rel="noreferrer">WhatsApp</a>
      <button className="btn" onClick={onCopy}>{copied ? "Copiado!" : "Copiar link"}</button>
    </div>
  );
}