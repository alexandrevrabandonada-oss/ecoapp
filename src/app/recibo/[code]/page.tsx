import Link from "next/link";
import ReciboClient from "./recibo-client";

export const runtime = "nodejs";

export default async function ReciboPage({ params }: { params: any }) {
  const p = await Promise.resolve(params);
  const code = p?.code as string;

  return (
    <main className="p-4 max-w-3xl mx-auto space-y-4">
      <header className="space-y-2">
        <div className="flex items-center justify-between gap-3 flex-wrap">
          <h1 className="text-2xl font-bold">Recibo ECO</h1>
          <Link className="underline text-sm" href="/recibos">← Voltar</Link>
        </div>
        <p className="text-xs opacity-70 break-all">code: {code}</p>
      </header>

      <ReciboClient code={code} />
    </main>
  );
}