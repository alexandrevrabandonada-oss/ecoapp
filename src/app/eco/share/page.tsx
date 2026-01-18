// ECO — Share Pack Hub — step 58

export const dynamic = "force-dynamic";

export default function Page() {
  return (
    <main style={{ padding: 16, fontFamily: "system-ui, -apple-system, Segoe UI, Roboto, Arial" }}>
      <h1 style={{ margin: "0 0 8px 0" }}>ECO — Share Pack</h1>
      <p style={{ margin: "0 0 16px 0", opacity: 0.85 }}>
        Cards + legenda prontos para compartilhar (WhatsApp/Instagram).
      </p>
      <ul style={{ margin: 0, paddingLeft: 18, display: "grid", gap: 8 }}>
        <li><a href="/eco/share/dia/2025-12-27">Share do Dia (exemplo)</a></li>
        <li><a href="/eco/share/mes/2025-12">Share do Mês (exemplo)</a></li>
      </ul>
      <div style={{ height: 12 }} />
      <p style={{ margin: 0, opacity: 0.75 }}>
        Dica: use os botões “Abrir Share” nas telas de Fechamento e Transparência.
      </p>
    </main>
  );
}

