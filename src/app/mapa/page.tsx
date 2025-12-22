import Link from "next/link";

export default function MapaPage() {
  return (
    <div className="stack">
      <div className="toolbar">
        <h1>Mapa ECO</h1>
        <Link className="btn" href="/coleta">Ver pontos</Link>
      </div>

      <div className="card">
        <h2>Em breve</h2>
        <p><small>
          Aqui vai entrar o “Mapa do Cuidado”: pontos, rotas e mutirões.
          No v0, a gente pode começar com links “ver no mapa” por endereço.
        </small></p>
        <hr />
        <Link className="primary" href="/coleta">Ir para Coleta</Link>
      </div>
    </div>
  );
}