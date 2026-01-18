import Link from "next/link";

export const runtime = "nodejs";

function pickItems(json: any): any[] {
  const items =
    json?.items ??
    json?.data ??
    json?.requests ??
    json?.pickupRequests ??
    json?.result ??
    json;

  return Array.isArray(items) ? items : [];
}

function asStr(v: any) {
  if (v == null) return "";
  if (typeof v === "string") return v;
  try { return String(v); } catch { return ""; }
}

function fmtDate(v: any) {
  if (!v) return "";
  const s = asStr(v);
  const d = new Date(s);
  if (isNaN(d.getTime())) return s;
  return d.toLocaleString("pt-BR");
}

function deriveReceiptCode(item: any) {
  return (
    item?.receipt?.shareCode ??
    item?.receipt?.code ??
    item?.receipt?.id ??
    item?.receiptCode ??
    item?.receiptId ??
    null
  );
}

export default async function PedidosPage() {
  let items: any[] = [];
  let err: string | null = null;

  try {
    const res = await fetch("http://localhost:3000/api/pickup-requests", { cache: "no-store" });
    const txt = await res.text();
    let json: any = null;
    try { json = JSON.parse(txt); } catch { json = { raw: txt }; }

    if (!res.ok) throw new Error(json?.error ?? "GET /api/pickup-requests falhou");items = pickItems(json);
  } catch (e: any) {
    err = e?.message ?? String(e);
  }

  return (
    <main className="p-4 max-w-5xl mx-auto space-y-4">
<div className="mb-3 flex flex-wrap items-center gap-3 rounded-xl border px-3 py-2 text-sm">
  <a className="underline" href="/operador">Modo Operador</a>
  <span className="opacity-70">Salvar/limpar token e voltar pros pedidos.</span>
</div>

      <header className="flex items-center justify-between gap-3 flex-wrap">
        <h1 className="text-2xl font-bold">Pedidos</h1>
        <div className="flex gap-2 flex-wrap">
          <Link className="px-3 py-2 rounded border" href="/chamar">Novo pedido</Link>
          <Link className="px-3 py-2 rounded border" href="/recibos">Recibos</Link>
        </div>
      </header>

      {err && (
        <div className="rounded border p-3">
          <p className="font-semibold text-red-600">Erro ao carregar</p>
          <pre className="text-xs whitespace-pre-wrap break-words">{err}</pre>
        </div>
      )}

      <div className="rounded border overflow-auto">
        <table className="min-w-[900px] w-full text-sm">
          <thead className="bg-black/5">
            <tr>
              <th className="text-left p-2">Criado</th>
              <th className="text-left p-2">Status</th>
              <th className="text-left p-2">Endereço/Local</th>
              <th className="text-left p-2">Obs</th>
              <th className="text-left p-2">Ações</th>
            </tr>
          </thead>
          <tbody>
            {items.length === 0 ? (
              <tr>
                <td className="p-3 opacity-70" colSpan={5}>Nenhum item (ou formato inesperado).</td>
              </tr>
            ) : (
              items.map((it: any) => {
                const id = asStr(it?.id);
                const status = asStr(it?.status) || "—";
                const address = asStr(it?.address) || asStr(it?.place) || asStr(it?.location) || "—";
                const notes = asStr(it?.notes) || asStr(it?.items) || asStr(it?.summary) || "—";
                const receiptCode = deriveReceiptCode(it);

                const fecharHref = id ? ("/pedidos/fechar/" + encodeURIComponent(String(id))) : null;
                const reciboHref = receiptCode ? ("/recibo/" + encodeURIComponent(String(receiptCode))) : null;

                return (
                  <tr key={id || Math.random()} className="border-t">
                    <td className="p-2 whitespace-nowrap">{fmtDate(it?.createdAt)}</td>
                    <td className="p-2">
                      <span className="inline-block px-2 py-1 rounded border text-xs">{status}</span>
                    </td>
                    <td className="p-2 min-w-[260px]">{address}</td>
                    <td className="p-2 max-w-[320px] truncate" title={notes}>{notes}</td>
                    <td className="p-2">
                      <div className="flex gap-2 flex-wrap">
                        {fecharHref ? (
                          <Link className="px-3 py-2 rounded bg-black text-white" href={fecharHref}>
                            Fechar / Emitir recibo
                          </Link>
                        ) : (
                          <span className="text-xs opacity-60">sem id</span>
                        )}

                        {reciboHref && (
                          <Link className="px-3 py-2 rounded border" href={reciboHref}>
                            Ver recibo
                          </Link>
                        )}
                      </div>
                      <div className="text-[11px] opacity-60 mt-1 break-all">id: {id || "—"}</div>
                    </td>
                  </tr>
                );
              })
            )}
          </tbody>
        </table>
      </div>

      <p className="text-xs opacity-60">
        Nota: se “Ver recibo” não aparecer, é porque o backend ainda não está incluindo a relação/campo do recibo na listagem.
        Mas “Fechar / Emitir recibo” sempre aparece (com id).
      </p>
    </main>
  );
}