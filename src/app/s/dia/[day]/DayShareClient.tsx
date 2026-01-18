"use client";

type ShareNav = Navigator & { share?: (data: ShareData) => Promise<void>; canShare?: (data: ShareData) => boolean };

function buildCaption(day: string) {
  // Instagram: 5 hashtags (pack ECO)
  return [
    `ECO — Fechamento do dia ${day}`,
    `Recibo é lei. Cuidado é coletivo. Trabalho digno é o centro.`,
    ``,
    `#ECO #ReciboECO #Reciclagem #VoltaRedonda #EconomiaSolidaria`,
  ].join("\\n");
}

export default function DayShareClient(props: { day: string }) {
  const day = props.day;

  const url3x4 = `/api/share/route-day-card?day=${encodeURIComponent(day)}&format=3x4`;
  const url1x1 = `/api/share/route-day-card?day=${encodeURIComponent(day)}&format=1x1`;
  const caption = buildCaption(day);

  const onCopyText = async (text: string, okMsg: string) => {
    try {
      await navigator.clipboard.writeText(text);
      alert(okMsg);
    } catch {
      prompt("Copie:", text);
    }
  };

  const onCopyLink = async () => {
    const link = window.location.href;
    await onCopyText(link, "Link copiado!");
  };

  const onCopyCaption = async () => {
    await onCopyText(caption, "Legenda copiada!");
  };

  const onWhatsApp = () => {
    const link = window.location.href;
    const text = `ECO — Fechamento do dia ${day}\\n${link}`;
    const wa = `https://wa.me/?text=${encodeURIComponent(text)}`;
    window.open(wa, "_blank", "noopener,noreferrer");
  };

  const onShareLink = async () => {
    const link = window.location.href;
    const nav = navigator as ShareNav;
    const data: ShareData = {
      title: `ECO — Fechamento do dia ${day}`,
      text: `ECO — Fechamento do dia ${day}`,
      url: link,
    };
    if (nav.share && (!nav.canShare || nav.canShare(data))) {
      await nav.share(data);
      return;
    }
    await onCopyLink();
  };

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 12, marginTop: 14 }}>
      <div style={{ display: "flex", flexWrap: "wrap", gap: 10 }}>
        <a href={url3x4} target="_blank" rel="noreferrer" style={{ padding: "8px 10px", border: "1px solid #333", borderRadius: 10 }}>
          Baixar card 3:4
        </a>
        <a href={url1x1} target="_blank" rel="noreferrer" style={{ padding: "8px 10px", border: "1px solid #333", borderRadius: 10 }}>
          Baixar card 1:1
        </a>
      </div>

      <div style={{ display: "flex", flexWrap: "wrap", gap: 10 }}>
        <button type="button" onClick={onCopyLink} style={{ padding: "8px 10px", border: "1px solid #333", borderRadius: 10 }}>
          Copiar link
        </button>
        <button type="button" onClick={onCopyCaption} style={{ padding: "8px 10px", border: "1px solid #333", borderRadius: 10 }}>
          Copiar legenda (Instagram)
        </button>
        <button type="button" onClick={onWhatsApp} style={{ padding: "8px 10px", border: "1px solid #333", borderRadius: 10 }}>
          WhatsApp
        </button>
        <button type="button" onClick={onShareLink} style={{ padding: "8px 10px", border: "1px solid #333", borderRadius: 10 }}>
          Compartilhar (Share Sheet)
        </button>
      </div>

      <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
        <div style={{ fontWeight: 700, opacity: 0.9 }}>Legenda pronta</div>
        <textarea
          value={caption}
          readOnly
          rows={5}
          style={{ width: "100%", maxWidth: 680, padding: 10, borderRadius: 10, border: "1px solid #333" }}
        />
      </div>
    </div>
  );
}