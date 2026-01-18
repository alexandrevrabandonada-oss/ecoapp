'use client';// ECO_STEP29_SHAREPACK_HELPERS_START
const ecoReceiptShareText = () => {
  const code = (typeof window !== "undefined") ? (window.location.pathname.split("/").filter(Boolean).pop() ?? "") : "";
  const link = (typeof window !== "undefined") ? window.location.href : "";
  const c = decodeURIComponent(String(code || "").trim());
  const l = String(link || "").trim();

  // texto curtinho e militante/convocatório, sem exagero
  const line1 = "Bora de recibo? 🌱♻️";
  const line2 = c ? ("Meu Recibo ECO: " + c) : "Meu Recibo ECO";
  const line3 = l ? ("Veja aqui: " + l) : "";
  const line4 = "#ECO #ReciboECO";

  return [line1, line2, line3, line4].filter(Boolean).join("\n");
};

const _ecoReceiptCopyText = async () => {
  const t = ecoReceiptShareText();
  if (!t) return;
  try {
    await navigator.clipboard.writeText(t);
    return;
  } catch {
    try {
      const ta = document.createElement("textarea");
      ta.value = t;
      ta.setAttribute("readonly", "true");
      ta.style.position = "absolute";
      ta.style.left = "-9999px";
      document.body.appendChild(ta);
      ta.select();
      document.execCommand("copy");
      ta.remove();
    } catch { void 0; }
  }
};

const _ecoReceiptOpenWhatsApp = () => {
  const t = ecoReceiptShareText();
  const url = "https://wa.me/?text=" + encodeURIComponent(t);
  window.open(url, "_blank", "noopener,noreferrer");
};
// ECO_STEP29_SHAREPACK_HELPERS_END
import { useEffect, useMemo, useState } from "react";

// ECO_STEP30_CAPTIONS_HELPERS_START
type Eco30ShareNav = Navigator & { share?: (data: ShareData) => Promise<void>; canShare?: (data: ShareData) => boolean };

function eco30_publicUrl(code: string) {
  return window.location.origin + "/r/" + encodeURIComponent(String(code));
}

function eco30_captionShort(code: string) {
  return "Bora de recibo? ✅ Recibo ECO confirmado — código: " + String(code);
}

function eco30_captionLong(code: string) {
  return (
    "✅ Recibo ECO confirmado\n" +
    "Código: " + String(code) + "\n" +
    "Isso é cuidado que vira prova: menos discurso, mais recibo.\n" +
    "ECO — Escutar • Cuidar • Organizar"
  );
}

function eco30_captionZap(code: string) {
  const url = eco30_publicUrl(code);
  return eco30_captionShort(code) + "\n" + url;
}

async function eco30_copyText(text: string) {
  try {
    if (navigator.clipboard && navigator.clipboard.writeText) {
      await navigator.clipboard.writeText(text);
      return true;
    }
  } catch { void 0; }
  try {
    const ta = document.createElement("textarea");
    ta.value = text;
    ta.style.position = "fixed";
    ta.style.left = "-9999px";
    ta.style.top = "-9999px";
    document.body.appendChild(ta);
    ta.focus();
    ta.select();
    const ok = document.execCommand("copy");
    ta.remove();
    return ok;
  } catch {
    return false;
  }
}

async function eco30_copyCaptionShort(code: string) {
  await eco30_copyText(eco30_captionShort(code));
}
async function eco30_copyCaptionLong(code: string) {
  await eco30_copyText(eco30_captionLong(code));
}
async function eco30_copyZap(code: string) {
  await eco30_copyText(eco30_captionZap(code));
}

async function eco30_shareText(code: string) {
  const url = eco30_publicUrl(code);
  const text = eco30_captionShort(code);
  const nav = navigator as Eco30ShareNav;
  const data: ShareData = { title: "Recibo ECO", text, url };
  if (nav.share && (!nav.canShare || nav.canShare(data))) {
    await nav.share(data);
    return;
  }
  await eco30_copyText(text + "\n" + url);
}
// ECO_STEP30_CAPTIONS_HELPERS_END

// ECO_STEP29_LINK_HELPERS_START
type Eco29ShareNav = Navigator & { share?: (data: ShareData) => Promise<void>; canShare?: (data: ShareData) => boolean };

function eco29_publicUrl(code: string) {
  // padrão: página pública do recibo
  return window.location.origin + "/r/" + encodeURIComponent(String(code));
}

function eco29_caption(code: string) {
  // texto curto, pronto pra zap / share
  return "Recibo ECO — bora de recibo? Código: " + String(code);
}

async function eco29_copyText(text: string) {
  try {
    if (navigator.clipboard && navigator.clipboard.writeText) {
      await navigator.clipboard.writeText(text);
      return true;
    }
  } catch { void 0; }
  try {
    const ta = document.createElement("textarea");
    ta.value = text;
    ta.style.position = "fixed";
    ta.style.left = "-9999px";
    ta.style.top = "-9999px";
    document.body.appendChild(ta);
    ta.focus();
    ta.select();
    const ok = document.execCommand("copy");
    ta.remove();
    return ok;
  } catch {
    return false;
  }
}

async function eco29_copyLink(code: string) {
  const url = eco29_publicUrl(code);
  await eco29_copyText(url);
}

async function eco29_copyTextAndLink(code: string) {
  const url = eco29_publicUrl(code);
  const text = eco29_caption(code) + "\n" + url;
  await eco29_copyText(text);
}

async function eco29_shareLink(code: string) {
  const url = eco29_publicUrl(code);
  const text = eco29_caption(code);
  const nav = navigator as Eco29ShareNav;

  const data: ShareData = { title: "Recibo ECO", text, url };

  if (nav.share && (!nav.canShare || nav.canShare(data))) {
    await nav.share(data);
    return;
  }

  // fallback: copiar tudo
  await eco29_copyText(text + "\n" + url);
}

function eco29_whatsApp(code: string) {
  const url = eco29_publicUrl(code);
  const text = eco29_caption(code) + "\n" + url;
  const wa = "https://wa.me/?text=" + encodeURIComponent(text);
  window.open(wa, "_blank", "noopener,noreferrer");
}
// ECO_STEP29_LINK_HELPERS_END


async function ecoCopy(text: string) {
  try {
    await navigator.clipboard.writeText(text);
    alert('Link copiado!');
  } catch {
    prompt('Copie o link:', text);
  }
}


// ECO_STEP28_HELPER_SHARECARD_START
async function eco28_shareCard(code?: string, format: "3x4" | "1x1" = "3x4"): Promise<boolean> { 
  if (typeof window === "undefined") return false;
  const c = String(code || "");
  if (!c) return false;
  const url = "/api/share/receipt-card?code=" + encodeURIComponent(c) + "&format=" + format;
  try {
    const res = await fetch(url, { cache: "no-store" });
    if (!res.ok) throw new Error("fetch_failed");
    const blob = await res.blob();
    const ext = (blob.type && blob.type.indexOf("png") >= 0) ? "png" : "bin";
    const file = new File([blob], "eco-recibo-" + c + "-" + format + "." + ext, { type: blob.type || "application/octet-stream" });
    const nav: any = (typeof navigator !== "undefined") ? (navigator as any) : null;
    if (nav && typeof nav.share === "function") {
      const can = (typeof nav.canShare === "function") ? nav.canShare({ files: [file] }) : true;
      if (can) {
        await nav.share({ files: [file], title: "Recibo ECO", text: "Recibo ECO " + c });
        return true;
      }
    }
    const obj = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = obj;
    a.download = file.name;
    document.body.appendChild(a);
    a.click();
    a.remove();
    setTimeout(() => URL.revokeObjectURL(obj), 5000);
    return true;
  } catch (e) {
    console.error(e);
    try { alert("Nao foi possivel compartilhar agora. Tente baixar o card."); } catch { void 0; }
    return false;
  }
}
// ECO_STEP28_HELPER_SHARECARD_END

export default function ReceiptShareBar(props: { code: string }) {
// ECO_STEP31_TOAST_STATE_START
  const [ecoToastMsg, setEcoToastMsg] = useState<string | null>(null);

  useEffect(() => {
    if (!ecoToastMsg) return;
    const t = setTimeout(() => setEcoToastMsg(null), 1200);
    return () => clearTimeout(t);
  }, [ecoToastMsg]);

  const ecoToast = (msg: string) => {
    setEcoToastMsg(msg);
  };

  const _eco31_copyShort = async () => {
    await eco30_copyCaptionShort(code);
    ecoToast("Legenda copiada!");
  };
  const _eco31_copyLong = async () => {
    await eco30_copyCaptionLong(code);
    ecoToast("Legenda longa copiada!");
  };
  const _eco31_copyZap = async () => {
    await eco30_copyZap(code);
    ecoToast("Mensagem do WhatsApp copiada!");
  };
  const _eco31_shareText = async () => {
    await eco30_shareText(code);
    ecoToast("Pronto!");
  };
// ECO_STEP31_TOAST_STATE_END

// ECO_STEP32_LINK_HELPERS_START
  const ecoReceiptUrl = () => {
    const c = encodeURIComponent(String(code));
    return window.location.origin + "/r/" + c;
  };

  const eco32_copyLink = async () => {
    const u = ecoReceiptUrl();
    try {
      await navigator.clipboard.writeText(u);
      if (typeof ecoToast === "function") ecoToast("Link copiado!");
    } catch {
      // fallback bem simples
      window.prompt("Copie o link do recibo:", u);
      if (typeof ecoToast === "function") ecoToast("Link pronto!");
    }
  };

  const _eco32_shareLink = async () => {
    const u = ecoReceiptUrl();
    const nav: any = navigator as any;
    const data: ShareData = { title: "Recibo ECO", text: "Recibo ECO: " + String(code), url: u };
    if (nav.share && (!nav.canShare || nav.canShare(data))) {
      await nav.share(data);
      if (typeof ecoToast === "function") ecoToast("Compartilhado!");
      return;
    }
    await eco32_copyLink();
  };
// ECO_STEP32_LINK_HELPERS_END

// ECO_STEP33_PACK_HELPERS_START
  const eco33_packUrl = () => {
    const c = encodeURIComponent(String(code));
    return "/api/share/receipt-pack?code=" + c;
  };

  const eco33_downloadPack = async () => {
    const u = eco33_packUrl();
    let res: Response | null = null;
    try {
      res = await fetch(u, { cache: "no-store" });
    } catch {
      res = null;
    }

    if (!res || !res.ok) {
      // fallback: abre em nova aba
      window.open(u, "_blank", "noopener,noreferrer");
      return;
    }

    const blob = await res.blob();
    const fileName = "eco-share-pack-" + String(code) + ".zip";

    const a = document.createElement("a");
    const obj = URL.createObjectURL(blob);
    a.href = obj;
    a.download = fileName;
    document.body.appendChild(a);
    a.click();
    a.remove();
    setTimeout(() => URL.revokeObjectURL(obj), 1200);

    if (typeof ecoToast === "function") ecoToast("Pack baixado!");
  };
// ECO_STEP33_PACK_HELPERS_END

  const code = (props?.code ?? '').trim();

  const url = useMemo(() => {
    if (typeof window === 'undefined') return '';
    const origin = window.location?.origin ?? '';
    return origin + '/r/' + code;
  }, [code]);

  if (!code) return null;

  const onCopy = async () => {
    if (!url) return;
    await ecoCopy(url);
  };

  const onWhatsApp = () => {
    if (!url) return;
    const text = 'Recibo ECO: ' + url;
    const wa = 'https://wa.me/?text=' + encodeURIComponent(text);
    window.open(wa, '_blank', 'noopener,noreferrer');
  };

  
  const onCard3x4 = () => {
    if (!url) return;
    const c = encodeURIComponent(code);
    const card = '/api/share/receipt-card?code=' + c + '&format=3x4';
    window.open(card, '_blank', 'noopener,noreferrer');
  };

// ECO_STEP28_SHARE_HELPERS_START
type EcoCardFormat = "3x4" | "1x1";
type ShareNav = Navigator & { share?: (data: ShareData) => Promise<void>; canShare?: (data: ShareData) => boolean };

const ecoCardUrl = (fmt: EcoCardFormat) => {
  const c = encodeURIComponent(String(code));
  return "/api/share/receipt-card?code=" + c + "&format=" + fmt;
};

const onCard1x1 = () => {
  const card = ecoCardUrl("1x1");
  window.open(card, "_blank", "noopener,noreferrer");
};

const ecoShareCard = async (fmt: EcoCardFormat) => {
  const card = ecoCardUrl(fmt);

  let res: Response | null = null;
  try { res = await fetch(card, { cache: "no-store" }); } catch { res = null; }

  if(!res || !res.ok){
    window.open(card, "_blank", "noopener,noreferrer");
    return;
  }

  const blob = await res.blob();
  const fileName = "recibo-eco-" + String(code) + "-" + fmt + ".png";
  const file = new File([blob], fileName, { type: "image/png" });

  const nav = navigator as ShareNav;
  const data: ShareData = {
    title: "Recibo ECO",
    text: "Recibo ECO: " + String(code),
    files: [file],
  };

  if(nav.share && (!nav.canShare || nav.canShare(data))){
    await nav.share(data);
    return;
  }

  const a = document.createElement("a");
  const obj = URL.createObjectURL(blob);
  a.href = obj;
  a.download = fileName;
  document.body.appendChild(a);
  a.click();
  a.remove();
  setTimeout(() => URL.revokeObjectURL(obj), 1200);
};

const onShare3x4 = () => ecoShareCard("3x4");
const onShare1x1 = () => ecoShareCard("1x1");
// ECO_STEP28_SHARE_HELPERS_END


  
return (
    <div className="my-4 flex flex-wrap items-center gap-3">
      <button type="button" onClick={onCopy} className="underline">
        Copiar link
      </button>
      <button type="button" onClick={onWhatsApp} className="underline">
        WhatsApp
      </button>
      <button type="button" onClick={onCard3x4} className="underline">Baixar card 3:4</button>
{/* ECO_STEP28_SHARE_BUTTONS_START */}
<button type="button" onClick={onCard1x1} className="underline">Baixar card 1:1</button>
<button type="button" onClick={onShare3x4} className="underline">Compartilhar 3:4</button>
<button type="button" onClick={onShare1x1} className="underline">Compartilhar 1:1</button>
{/* ECO_STEP28_SHARE_BUTTONS_END */}
      {/* ECO_STEP28_BUTTONS_START */}
      <button type="button" onClick={() => eco28_downloadCard(code, "1x1")} className="underline">Baixar card 1:1</button>
      <button type="button" onClick={() => eco28_shareCard(code, "3x4")} className="underline">Compartilhar 3:4</button>
      <button type="button" onClick={() => eco28_shareCard(code, "1x1")} className="underline">Compartilhar 1:1</button>
      {/* ECO_STEP28_BUTTONS_END */}

      {/* ECO_STEP29_LINK_BUTTONS_START */}
      <button type="button" onClick={() => eco29_copyLink(code)} className="underline">Copiar link</button>
      <button type="button" onClick={() => eco29_copyTextAndLink(code)} className="underline">Copiar texto + link</button>
      <button type="button" onClick={() => eco29_whatsApp(code)} className="underline">WhatsApp</button>
      <button type="button" onClick={() => eco29_shareLink(code)} className="underline">Compartilhar link</button>
      <button type="button" onClick={eco33_downloadPack} className="underline">Baixar pack (ZIP)</button>
      {/* ECO_STEP29_LINK_BUTTONS_END */}          </div>
  );
}

function eco28_downloadCard(code: string, format: "1x1" | "3x4" = "3x4") {
  const c = encodeURIComponent(String(code || ""));
  const f = encodeURIComponent(String(format || "3x4"));
  const url = "/api/share/receipt-card?code=" + c + "&format=" + f;
  const a = document.createElement("a");
  a.href = url;
  a.download = "eco-recibo-" + c + "-" + String(format || "3x4") + ".png";
  document.body.appendChild(a);
  a.click();
  a.remove();
}
