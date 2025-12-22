import Link from "next/link";
import ServicesTable from "./services-table";

export default function ServicosPage() {
  return (
    <div className="stack">
      <div className="toolbar">
        <div>
          <h1 style={{ margin: 0 }}>Serviços</h1>
          <p style={{ margin: 0 }}><small>Busca + filtro por tipo (COLETA, REPARO, etc).</small></p>
        </div>
        <Link className="btn" href="/servicos/novo">+ Novo serviço</Link>
      </div>

      <ServicesTable />
    </div>
  );
}