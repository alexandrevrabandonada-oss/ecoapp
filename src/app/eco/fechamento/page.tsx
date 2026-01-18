// ECO — Fechamento do Dia (UI) — step 55

import FechamentoClient from "./FechamentoClient";

export const dynamic = "force-dynamic";

export default function Page() {
  return (
    <main style={{ padding: 16, fontFamily: "system-ui, -apple-system, Segoe UI, Roboto, Arial" }}>
      <h1 style={{ margin: "0 0 8px 0" }}>ECO — Fechamento do Dia</h1>
      <p style={{ margin: "0 0 16px 0", opacity: 0.85 }}>
        Fecha o dia (upsert) e mostra o resumo + histórico. (Brasil -03:00)
      </p>
      <FechamentoClient />
    </main>
  );
}

