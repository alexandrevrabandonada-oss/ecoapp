import RecibosClient from "./RecibosClient";

export default function Page() {
  return (
    <main style={{ padding: 16, maxWidth: 1100, margin: "0 auto" }}>
      <h1 style={{ margin: "0 0 8px 0" }}>Recibos ECO</h1>
      <p style={{ margin: "0 0 14px 0", opacity: 0.85 }}>
        Provas fortes: fechamento do dia e mutirões concluídos (antes/depois).
      </p>
      <RecibosClient />
    </main>
  );
}
