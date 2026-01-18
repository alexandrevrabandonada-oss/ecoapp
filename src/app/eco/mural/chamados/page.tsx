import MuralClient from "../MuralClient";

export default function Page() {
  return (
    <main style={{ padding: 16, maxWidth: 1100, margin: "0 auto" }}>
      <h1 style={{ margin: "0 0 8px 0" }}>Chamados ativos</h1>
      <p style={{ margin: "0 0 14px 0", opacity: 0.85 }}>Somente pontos OPEN, ordenados por chamado (📣).</p>
      <div style={{ margin: "0 0 14px 0", display: "flex", gap: 8, flexWrap: "wrap" }}>
        <a href="/eco/mural" style={{ padding: "9px 10px", borderRadius: 12, border: "1px solid #111", textDecoration: "none", color: "#111", fontWeight: 900, background: "#fff" }}>Voltar ao mural</a>
      </div>
      <MuralClient base="pontos" mode="chamados" />
    </main>
  );
}
