import Link from "next/link";

export default function HomePage() {
  return (
    <div className="stack">
      <div className="card">
        <div className="toolbar">
          <h1 style={{ margin: 0 }}>ECO</h1>
          <span className="badge">MVP v0</span>
        </div>

        <p style={{ marginTop: 8 }}>
          <small>
            <b>Escutar • Cuidar • Organizar</b> — do bairro pro bairro.
            Aqui é a entrada do app: atalhos rápidos + módulos.
          </small>
        </p>

        <div className="toolbar" style={{ marginTop: 10 }}>
          <Link className="primary" href="/coleta/novo">+ Novo ponto</Link>
          <Link className="btn" href="/servicos/novo">+ Novo serviço</Link>
          <Link className="btn" href="/coleta">Ver pontos</Link>
          <Link className="btn" href="/servicos">Ver serviços</Link>
          <Link className="btn" href="/chamar-coleta">Chamar coleta</Link>
        </div>
      </div>

      <div className="grid2">
        <div className="card">
          <h2 style={{ marginTop: 0 }}>Serviços</h2>
          <p><small>Catálogo do que existe no território (coleta, feiras, reparos, doações…).</small></p>
          <div className="toolbar">
            <Link className="primary" href="/servicos">Abrir lista</Link>
            <Link className="btn" href="/servicos/novo">Criar serviço</Link>
          </div>
        </div>

        <div className="card">
          <h2 style={{ marginTop: 0 }}>Pontos de coleta</h2>
          <p><small>Onde levar / quem recebe / como participar. Depois entra mapa e horários.</small></p>
          <div className="toolbar">
            <Link className="primary" href="/coleta">Abrir lista</Link>
            <Link className="btn" href="/coleta/novo">Cadastrar ponto</Link>
          </div>
        </div>

        <div className="card">
          <h2 style={{ marginTop: 0 }}>Próximos módulos</h2>
          <ul style={{ marginTop: 6 }}>
            <li><small><b>Chamar Coleta</b> (Pedido rápido → recibo ECO)</small></li>
            <li><small><b>Ponto crítico</b> (denúncia + dedupe + “eu vi também”)</small></li>
            <li><small><b>Mutirão</b> (antes/depois + recibo de mutirão)</small></li>
          </ul>
          <p><small className="muted">*Vamos subir isso por tijolos, sem quebrar o que já existe.*</small></p>
        </div>

        <div className="card">
          <h2 style={{ marginTop: 0 }}>Status do bairro</h2>
          <p><small>
            Placeholder pro painel de transparência (mensal/semana): total de pontos, coletas, mutirões, parceiros.
          </small></p>
          <div className="toolbar">
            <button className="btn" disabled>Em breve</button>
          </div>
        </div>
      </div>
    </div>
  );
}