import PontosClient from "./PontosClient";
import EcoPoints30dWidget from "@/app/eco/_components/EcoPoints30dWidget";

export const dynamic = "force-dynamic";

export default function Page() {
  return (
    <main style={{ padding: 16, maxWidth: 1100, margin: "0 auto" }}>
      <EcoPoints30dWidget />

      <h1 style={{ margin: "0 0 8px 0" }}>Pontos críticos (Mapa da Vergonha)</h1>
      <p style={{ margin: "0 0 14px 0", opacity: 0.85 }}>
        Marque pontos de abandono (lixo, entulho, fumaça, vazamento). Sem caça às bruxas: prova leve + confirmação coletiva.
      </p>
      <PontosClient />
    </main>
  );
}

