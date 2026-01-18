import Link from "next/link";

export const runtime = "nodejs";

export default function FecharIndex() {
  return (
    <main className="p-4 max-w-2xl mx-auto space-y-3">
      <h1 className="text-2xl font-bold">Fechar pedido</h1>
      <p className="text-sm opacity-80">
        Faltou o ID do pedido na URL. Volte para a lista de pedidos e clique em “Fechar/Emitir recibo”.
      </p>
      <Link className="underline" href="/pedidos">← Ir para /pedidos</Link>
    </main>
  );
}