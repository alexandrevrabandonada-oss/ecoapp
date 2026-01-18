import MutiroesClient from "./MutiroesClient";

export const dynamic = "force-dynamic";

export default function Page() {
  return (
    <main style={{ padding: 16, maxWidth: 1100, margin: "0 auto" }}>
      <h1 style={{ margin: "0 0 8px 0" }}>Mutirões (ciclo fechado)</h1>
      <p style={{ margin: "0 0 14px 0", opacity: 0.85 }}>
        Ponto crítico virou ação coletiva: data, duração, checklist e antes/depois. Recibo é lei.
      </p>
      <MutiroesClient />
    </main>
  );
}

