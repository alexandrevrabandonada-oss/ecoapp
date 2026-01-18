// ECO — resolver ponto manualmente — v0.1

import { PointResolveClient } from "./PointResolveClient";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export default async function Page({ params }: any) {
  const p = await (params as any);
  const id = String(p?.id || "");
  return (
    <main style={{ padding: 16, maxWidth: 980, margin: "0 auto" }}>
      <h1 style={{ margin: "0 0 8px 0" }}>Resolver ponto (prova)</h1>
      <p style={{ margin: "0 0 14px 0", opacity: 0.85 }}>
        Use isso quando o ponto foi resolvido sem mutirão. Salva prova (foto) + nota e marca como RESOLVIDO.
      </p>
      <PointResolveClient id={id} />
    </main>
  );
}
