import ShareMutiraoClient from "./ShareMutiraoClient";

export default async function Page({ params }: any) {
  const p: any = await (params as any);
  const id = String(p?.id || "");
  return (
    <main style={{ padding: 16, maxWidth: 1100, margin: "0 auto" }}>
      <h1 style={{ margin: "0 0 8px 0" }}>Compartilhar mutirão: {id}</h1>
      <p style={{ margin: "0 0 14px 0", opacity: 0.85 }}>Card + legenda prontos para postar.</p>
      <ShareMutiraoClient id={id} />
    </main>
  );
}
