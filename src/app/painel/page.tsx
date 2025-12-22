import { getBaseUrl } from "@/lib/baseUrl";

async function getStats() {
  const base = await getBaseUrl();
  const res = await fetch(`${base}/api/stats`, { cache: "no-store" });
  return res.json();
}

export default async function PainelPage() {
  const s = await getStats();
  const totalKg = s?.totalKg ?? 0;
  const by = s?.byMaterial ?? {};

  return (
    <main className="min-h-screen bg-neutral-950 text-emerald-300 p-6">
      <h1 className="text-2xl font-black">Painel público</h1>
      <div className="mt-6 rounded border border-emerald-300/20 p-4">
        <div className="text-sm text-emerald-200/70">Total (pesagens registradas)</div>
        <div className="text-4xl font-black">{Number(totalKg).toFixed(1)} kg</div>
      </div>

      <h2 className="mt-8 font-semibold">Por material</h2>
      <ul className="mt-3 space-y-2">
        {Object.keys(by).length === 0 && <li className="text-emerald-200/70">Ainda sem pesagens.</li>}
        {Object.entries(by).map(([k,v]: any) => (
          <li key={k} className="rounded border border-emerald-300/20 p-3 flex justify-between">
            <span>{k}</span><span className="font-semibold">{Number(v).toFixed(1)} kg</span>
          </li>
        ))}
      </ul>
    </main>
  );
}
