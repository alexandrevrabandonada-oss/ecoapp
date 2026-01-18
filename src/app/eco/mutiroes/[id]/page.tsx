import Link from "next/link";

export default function Page({ params }: { params: { id: string } }) {
  const id = String(params?.id || "");
  const hrefFinalize = "/eco/mutiroes/" + encodeURIComponent(id) + "/finalizar";
  return (
    <main className="mx-auto max-w-3xl p-6">
      <div className="text-xs opacity-70">Mutirao</div>
      <h1 className="text-2xl font-bold">{id || "Sem id"}</h1>
      <div className="mt-6 flex gap-3">
        <Link className="rounded bg-emerald-500 px-4 py-2 font-semibold text-black" href={hrefFinalize}>Finalizar</Link>
        <Link className="rounded border border-neutral-700 px-4 py-2" href="/eco/mutiroes">Voltar</Link>
      </div>
    </main>
  );
}
