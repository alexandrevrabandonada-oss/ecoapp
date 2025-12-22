import Link from "next/link";

export default async function SucessoPage({ searchParams }: any) {
  const sp = (await searchParams) ?? searchParams ?? {};
  const id = sp?.id ? String(sp.id) : "";

  return (
    <div className="stack">
      <div className="toolbar">
        <h1>Pedido enviado</h1>
        <Link className="btn" href="/">Início</Link>
      </div>

      <div className="card">
        <h2>✅ Registrado</h2>
        <p><small>Se precisar, guarde esse código:</small></p>
        <p style={{ fontFamily:"ui-monospace, SFMono-Regular, Menlo, monospace" }}>{id || "(sem id)"}</p>

        <div className="toolbar">
          <Link className="primary" href="/chamar">Fazer outro</Link>
          <Link className="btn" href="/pedidos">Ver pedidos</Link>
        </div>

        <p><small>
          Próximo: Recibo ECO (QR/código curto + card 3:4 compartilhável).
        </small></p>
      </div>
    </div>
  );
}