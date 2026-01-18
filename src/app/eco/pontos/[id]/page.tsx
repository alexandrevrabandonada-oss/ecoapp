import PointDetailClient from "./PointDetailClient";

export default async function Page({ params }: { params: { id: string } }) {
  return (
    <main style={{ padding: 16, maxWidth: 980, margin: "0 auto" }}>
      <h1 style={{ margin: "0 0 8px 0" }}>Ponto</h1>
      <div style={{ display: "flex", gap: 10, flexWrap: "wrap", margin: "10px 0" }}>
        <a
          href="./resolver"
          style={{
            padding: "10px 12px",
            borderRadius: 12,
            border: "1px solid #111",
            textDecoration: "none",
            color: "#111",
            background: "#FFDD00",
            fontWeight: 900,
          }}
        >
          Resolver ponto (prova)

      <div style={{ display: "flex", gap: 10, flexWrap: "wrap", margin: "10px 0" }}>
        <a
          href={"/eco/share/ponto/" + encodeURIComponent(String(params?.id || ""))}
          style={{
            padding: "10px 12px",
            borderRadius: 12,
            border: "1px solid #111",
            textDecoration: "none",
            color: "#111",
            background: "#fff",
            fontWeight: 900,
          }}
        >
          Compartilhar ponto
        </a>
      </div>
        </a>
      </div>
      <p style={{ margin: "0 0 14px 0", opacity: 0.85 }}>
        Abandono x Cuidado. Confirmacao comunitaria e prova. Recibo e lei.
      </p>
      <PointDetailClient id={params.id} />
    </main>
  );
}
