import Link from "next/link";
export default function Page() {
  return (
    <div className="stack">
      <div className="toolbar">
        <h1 style={{ marginRight: 10 }}>Em construção</h1>
        <Link className="btn" href="/">Home</Link>
        <Link className="btn" href="/coleta">Coleta</Link>
        <Link className="btn" href="/servicos">Serviços</Link>
      </div>
      <div className="card">
        <p><small>Essa área é o próximo passo do ECO. A gente já pode plugar aqui metas/ranking, mapa, WhatsApp e fichas completas.</small></p>
      </div>
    </div>
  );
}