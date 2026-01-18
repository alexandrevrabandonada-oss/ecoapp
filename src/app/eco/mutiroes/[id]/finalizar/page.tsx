import MutiraoFinishClient from "./MutiraoFinishClient";

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export default async function Page({ params }: any) {
// eslint-disable-next-line @typescript-eslint/no-explicit-any
  const p: any = await (params as any);
  const id = String(p?.id || "");
  return (
    <main style={{ padding: 16, maxWidth: 1100, margin: "0 auto" }}>
      <h1 style={{ margin: "0 0 8px 0" }}>Finalizar mutirão</h1>
      <div style={{ display: "flex", gap: 10, flexWrap: "wrap", margin: "10px 0 14px 0" }}>
        <a
          href={"/eco/share/mutirao/" + encodeURIComponent(id)}
          target="_blank"
          rel="noreferrer"
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
          Compartilhar (card)
        </a>
      </div>
      <p style={{ margin: "0 0 14px 0", opacity: 0.85 }}>
        Fecha o mutirão e (se tiver ponto vinculado) marca como RESOLVIDO com prova.
      </p>
      <MutiraoFinishClient id={id} />
    </main>
  );
}