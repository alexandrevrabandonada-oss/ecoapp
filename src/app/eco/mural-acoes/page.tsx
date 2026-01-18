import { MuralAcoesClient } from "./MuralAcoesClient";
import MuralTopBarClient from "./_components/MuralTopBarClient";

export const dynamic = "force-dynamic";

export default function Page() {
  return (
    <main style={{ padding: 16, maxWidth: 1100, margin: "0 auto" }}>
      <div className="eco-mural-inner">
      <MuralTopBarClient />

      <h1 style={{ margin: "0 0 8px 0" }}>Mural do Cuidado (v0) — Acoes</h1>
      <p style={{ margin: "0 0 14px 0", opacity: 0.85 }}>
        Aqui as reacoes viram acoes (Confirmar, Apoiar, Chamado, Gratidao, Replicar).
      </p>
      <MuralAcoesClient />
    
      </div>
</main>
  );
}
