"use client";

type ShareNav = Navigator & {
  share?: (data: ShareData) => Promise<void>;
  canShare?: (data: ShareData) => boolean;
};

function todaySP(): string {
  try {
    const fmt = new Intl.DateTimeFormat("en-CA", {
      timeZone: "America/Sao_Paulo",
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
    });
    return fmt.format(new Date());
  } catch {
    const d = new Date();
    const yyyy = d.getFullYear();
    const mm = String(d.getMonth() + 1).padStart(2, "0");
    const dd = String(d.getDate()).padStart(2, "0");
    return yyyy + "-" + mm + "-" + dd;
  }
}

function linkFor(day: string) {
  const v = String(day || "").trim() || todaySP();
  return window.location.origin + "/s/dia/" + encodeURIComponent(v);
}

export default function DayCloseShortcut() {
  const day = todaySP();

  const open = () => {
    window.location.href = "/s/dia/" + encodeURIComponent(day);
  };

  const copy = async () => {
    const link = linkFor(day);
    try {
      await navigator.clipboard.writeText(link);
      alert("Link do fechamento copiado!");
    } catch {
      prompt("Copie o link:", link);
    }
  };

  const wa = () => {
    const link = linkFor(day);
    const text = "ECO — Fechamento do dia " + day + "\n" + link;
    window.open("https://wa.me/?text=" + encodeURIComponent(text), "_blank", "noopener,noreferrer");
  };

  const share = async () => {
    const nav = navigator as ShareNav;
    const url = linkFor(day);
    const data: ShareData = { title: "ECO — Fechamento do dia " + day, text: "ECO — Fechamento do dia " + day, url };
    if (nav.share && (!nav.canShare || nav.canShare(data))) {
      await nav.share(data);
      return;
    }
    await copy();
  };

  return (
    <section style={{ marginTop: 12, border: "1px solid #222", borderRadius: 14, padding: 12 }}>
      <div style={{ display: "flex", flexWrap: "wrap", gap: 10, justifyContent: "space-between", alignItems: "baseline" }}>
        <div>
          <div style={{ fontWeight: 900 }}>Fechamento do dia</div>
          <div style={{ fontSize: 12, opacity: 0.75 }}>{day} • /s/dia/{day}</div>
        </div>
        <a href="/s/dia" style={{ fontSize: 12, opacity: 0.85, textDecoration: "underline" }}>
          Índice /s/dia
        </a>
      </div>

      <div style={{ display: "flex", flexWrap: "wrap", gap: 10, marginTop: 10 }}>
        <button type="button" onClick={open} style={{ padding: "8px 10px", border: "1px solid #333", borderRadius: 10 }}>
          Abrir hoje
        </button>
        <button type="button" onClick={copy} style={{ padding: "8px 10px", border: "1px solid #333", borderRadius: 10 }}>
          Copiar link
        </button>
        <button type="button" onClick={wa} style={{ padding: "8px 10px", border: "1px solid #333", borderRadius: 10 }}>
          WhatsApp
        </button>
        <button type="button" onClick={share} style={{ padding: "8px 10px", border: "1px solid #333", borderRadius: 10 }}>
          Share Sheet
        </button>
      </div>

      <div style={{ marginTop: 10, fontSize: 12, opacity: 0.75 }}>
        Recibo é lei. Cuidado é coletivo. Trabalho digno é o centro.
      </div>
    </section>
  );
}