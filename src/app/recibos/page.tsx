import Link from "next/link";
import { headers } from "next/headers";

export const runtime = "nodejs";

async function originFromHeaders() {
  const h = await headers();
  const proto = h.get("x-forwarded-proto") ?? "http";
  const host = h.get("x-forwarded-host") ?? h.get("host") ?? "localhost:3000";
  return proto + "://" + host;
}

function getCode(r: any) {
  return r?.shareCode ?? r?.code ?? r?.id ?? "";
}

export default async function RecibosPage() {
  const origin = await originFromHeaders();
  const res = await fetch(origin + "/api/receipts", { cache: "no-store" });
  const txt = await res.text();
  let json: any = null;
  try { json = JSON.parse(txt); } catch { json = { raw: txt }; }

  const receipts: any[] = Array.isArray(json?.items) ? json.items : [];

  return (
    <main className="p-4 max-w-4xl mx-auto space-y-4">
      <header className="space-y-2">
        <h1 className="text-2xl font-bold">Recibos</h1>
        <div className="flex gap-3 flex-wrap">
          <Link className="underline" href="/pedidos">← Pedidos</Link>
          <Link className="underline" href="/chamar">Chamar coleta</Link>
        </div>
      </header>

      {!res.ok && (
        <div className="rounded border p-3">
          <p className="font-semibold text-red-600">Falha ao listar /api/receipts</p>
          <pre className="text-xs whitespace-pre-wrap break-words">{txt}</pre>
        </div>
      )}

      {res.ok && receipts.length === 0 && (
        <p className="text-sm opacity-70">Nenhum recibo ainda.</p>
      )}

      {res.ok && receipts.length > 0 && (
        <div className="rounded border overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-black/5">
              <tr>
                <th className="text-left p-2">Code</th>
                <th className="text-left p-2">Resumo</th>
                <th className="text-left p-2">Ações</th>
              </tr>
            </thead>
            <tbody>
              {receipts.map((r, idx) => {
                const code = getCode(r);
                return (
                  <tr key={String(code || idx)} className="border-t">
                    <td className="p-2 font-mono text-xs break-all">{code || "-"}</td>
                    <td className="p-2">{r?.summary ?? ""}</td>
                    <td className="p-2">
                      {code ? (
                        <Link className="underline" href={"/recibo/" + encodeURIComponent(code)}>Ver</Link>
                      ) : (
                        <span className="opacity-60">sem code</span>
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </main>
  );
}