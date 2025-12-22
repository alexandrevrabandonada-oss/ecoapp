import Link from "next/link";

export default function ImpactoPage() {
  return (
    <div className="stack">
      <div className="toolbar">
        <h1>Impacto</h1>
        <Link className="btn" href="/">Início</Link>
      </div>

      <div className="card">
        <h2>Transparência (v0)</h2>
        <p><small>
          Aqui entra: contador do mês, metas do bairro e o “Recibo ECO”.
          Primeiro a gente fecha o fluxo de coleta. Depois liga a transparência.
        </small></p>
      </div>
    </div>
  );
}