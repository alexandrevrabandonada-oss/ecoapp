import Link from "next/link";
import { headers } from "next/headers";

async function getOrigin() {
  const h = await headers();
  const proto = h.get("x-forwarded-proto") ?? "http";
  const host = h.get("x-forwarded-host") ?? h.get("host") ?? "localhost:3000";
  return `${proto}://${host}`;
}

export default async function PedidosPage() {
  const origin = await getOrigin();
  const res = await fetch(`${origin}/api/requests`, { cache: "no-store" });
  const data: any = await res.json().catch(() => ({}));
  const requests = Array.isArray(data?.requests) ? data.requests : [];

  const updateStatus = async (id: string, status: string) => {
    const res = await fetch(`/api/requests/${id}`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ status }),
    });
    const data = await res.json();
    if (!res.ok) {
      alert(`Erro ao atualizar status: ${data?.error || "Erro desconhecido"}`);
    }
  };

  return (
    <div className="stack">
      <div className="toolbar">
        <h1>Pedidos</h1>
        <Link className="btn" href="/chamar">+ Novo pedido</Link>
      </div>

      {requests.length === 0 ? (
        <div className="card"><p><small>Nenhum pedido ainda.</small></p></div>
      ) : (
        <div className="grid2">
          {requests.map((r: any) => (
            <div key={r.id} className="card">
              <div className="toolbar" style={{ justifyContent: "space-between" }}>
                <strong>{r.materialKind}</strong>
                <span className="pill">{r.status}</span>
              </div>
              <p><small><strong>Endereço:</strong> {r.address}</small></p>
              {r.quantity ? <p><small><strong>Qtd:</strong> {r.quantity}</small></p> : null}
              {r.contact ? <p><small><strong>Contato:</strong> {r.contact}</small></p> : null}
              {r.notes ? <p><small><strong>Obs:</strong> {r.notes}</small></p> : null}
              <p><small style={{ opacity: .7 }}>ID: {r.id}</small></p>

              <div className="toolbar">
                {r.status !== "DONE" && (
                  <button onClick={() => updateStatus(r.id, "TRIAGED")}>Triar</button>
                )}
                {r.status !== "SCHEDULED" && (
                  <button onClick={() => updateStatus(r.id, "SCHEDULED")}>Agendar</button>
                )}
                {r.status !== "DONE" && (
                  <button onClick={() => updateStatus(r.id, "DONE")}>Concluir</button>
                )}
              </div>
            </div>
          ))}
        </div>
      )}

      <div className="card">
        <p><small>
          Próximo passo: integração com o Recibo ECO e transparência do bairro.
        </small></p>
        <div className="toolbar">
          <Link className="btn" href="/coleta">Ver pontos</Link>
          <Link className="btn" href="/">Início</Link>
        </div>
      </div>
    </div>
  );
}