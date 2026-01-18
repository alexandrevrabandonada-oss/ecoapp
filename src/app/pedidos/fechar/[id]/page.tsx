import Link from "next/link";
import FecharClient from "./fechar-client";

export const runtime = "nodejs";

export default async function FecharPedidoPage({ params }: { params: any }) {
  const p = await Promise.resolve(params);
  const id = p?.id as string;

  return (
    <main className="p-4 max-w-3xl mx-auto space-y-4">
      <header className="space-y-2">
        <h1 className="text-2xl font-bold">Fechar pedido</h1>
        <p className="text-sm opacity-80">
          Emite um recibo e (quando suportado) marca o pedido como concluído.
        </p>
        <div className="flex gap-3">
          <Link className="underline" href="/pedidos">← Voltar</Link>
          <span className="text-sm opacity-70">ID: {id}</span>
        </div>
      </header>

      <FecharClient requestId={id} />
    </main>
  );
}