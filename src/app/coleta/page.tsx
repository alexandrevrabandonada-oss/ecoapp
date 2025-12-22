import Link from "next/link";
import PointsTable from "./points-table";

export default function ColetaPage() {
  return (
    <div className="stack">
      <div className="toolbar">
        <div>
          <h1 style={{ margin: 0 }}>Coleta</h1>
          <p style={{ margin: 0 }}><small>Busca rápida + filtros por bairro e material.</small></p>
        </div>
        <Link className="btn" href="/coleta/novo">+ Novo ponto</Link>
      </div>

      <PointsTable />
    </div>
  );
}