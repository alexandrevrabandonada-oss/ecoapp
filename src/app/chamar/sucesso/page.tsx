import Link from "next/link";

export default function Page({ searchParams }: { searchParams?: Record<string, string | string[] | undefined> }) {
  const codeRaw = searchParams?.code;
  const code = Array.isArray(codeRaw) ? codeRaw[0] : codeRaw;
  return (
    <main className="mx-auto max-w-2xl p-6">
      <h1 className="text-2xl font-bold">Pedido enviado</h1>
      <p className="mt-2 text-sm opacity-80">Se precisar, voce pode acompanhar na lista de pedidos.</p>
      {code ? (
        <div className="mt-4 rounded border border-neutral-800 bg-neutral-950 p-3">
          <div className="text-xs opacity-70">Codigo</div>
          <div className="font-mono">{code}</div>
        </div>
      ) : null}
      <div className="mt-6 flex gap-3">
        <Link className="rounded bg-emerald-500 px-4 py-2 font-semibold text-black" href="/pedidos">Ver pedidos</Link>
        <Link className="rounded border border-neutral-700 px-4 py-2" href="/eco">Voltar ao ECO</Link>
      </div>
    </main>
  );
}
