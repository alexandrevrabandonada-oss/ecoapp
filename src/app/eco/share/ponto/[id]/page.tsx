// ECO — Share Ponto — v0.1

import { SharePointClient } from "./SharePointClient";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export default async function Page({ params }: any) {
  const p = await (params as any);
  const id = String(p?.id || "");
  return (
    <main style={{ padding: 16, maxWidth: 1100, margin: "0 auto" }}>
      <h1 style={{ margin: "0 0 8px 0" }}>Compartilhar ponto</h1>
      <p style={{ margin: "0 0 14px 0", opacity: 0.85 }}>Card + legenda prontos para postar.</p>
      <SharePointClient id={id} />
    </main>
  );
}
