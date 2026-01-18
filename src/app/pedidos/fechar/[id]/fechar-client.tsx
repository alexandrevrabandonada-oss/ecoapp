"use client";

import Link from "next/link";
import { useEffect, useMemo, useState } from "react";

type ApiGetPickup = any;
type ApiIssueReceipt = any;

function pickRequestItem(payload: ApiGetPickup) {
  return payload?.item ?? payload?.request ?? payload?.data ?? payload;
}

function prettify(v: any) {
  try { return JSON.stringify(v, null, 2); } catch { return String(v); }
}

const TOKEN_KEY = "eco_operator_token";

function readToken() {
  if (typeof window === "undefined") return "";
  try { return localStorage.getItem(TOKEN_KEY) || ""; } catch { return ""; }
}
function saveToken(v: string) {
  if (typeof window === "undefined") return;
  try {
    if (v) localStorage.setItem(TOKEN_KEY, v);
    else localStorage.removeItem(TOKEN_KEY);
  } catch {}
}

export default function FecharClient({ requestId }: { requestId: string }) {
  const [loading, setLoading] = useState(true);
  const [reqData, setReqData] = useState<any>(null);
  const [err, setErr] = useState<string | null>(null);

  const [summary, setSummary] = useState("");
  const [items, setItems] = useState("");
  const [operator, setOperator] = useState("");
  const [isPublic, setIsPublic] = useState(false);

  const [operatorToken, setOperatorToken] = useState<string>(readToken());

  const [issuing, setIssuing] = useState(false);
  const [issued, setIssued] = useState<any>(null);
  const [issueErr, setIssueErr] = useState<string | null>(null);

  const derivedCode = useMemo(() => {
    const r = issued?.receipt ?? issued;
    return r?.shareCode ?? r?.code ?? r?.id ?? null;
  }, [issued]);

  useEffect(() => {
    let alive = true;
    async function run() {
      setLoading(true);
      setErr(null);
      setReqData(null);

      try {
        const url = "/api/pickup-requests/" + encodeURIComponent(requestId);
        const res = await fetch(url, { cache: "no-store" });
        const txt = await res.text();
        let json: any = null;
        try { json = JSON.parse(txt); } catch { json = { raw: txt }; }

        if (!res.ok) throw new Error(json?.error ?? "GET pickup-requests falhou (" + res.status + ")");
        if (!alive) return;

        const item = pickRequestItem(json);
        setReqData(item);
      } catch (e: any) {
        if (!alive) return;
        setErr(e?.message ?? String(e));
      } finally {
        if (!alive) return;
        setLoading(false);
      }
    }
    if (requestId) run();
    return () => { alive = false; };
  }, [requestId]);

  async function onIssue() {
    setIssuing(true);
    setIssueErr(null);
    setIssued(null);
    try {
      const body: any = {
        requestId,
        summary: summary || null,
        items: items || null,
        operator: operator || null,
        public: !!isPublic,
        operatorToken: operatorToken || null,
      };

      const headers: any = { "content-type": "application/json" };
      if (operatorToken) headers["x-eco-token"] = operatorToken;

      const res = await fetch("/api/receipts", {
        method: "POST",
        headers,
        body: JSON.stringify(body),
      });

      const txt = await res.text();
      let json: ApiIssueReceipt = null as any;
      try { json = JSON.parse(txt); } catch { json = { raw: txt } as any; }

      if (res.status === 401) throw new Error("unauthorized (defina ECO_OPERATOR_TOKEN no .env e preencha a chave)");
      if (!res.ok) throw new Error(json?.error ?? "POST /api/receipts falhou (" + res.status + ")");

      if (operatorToken) saveToken(operatorToken);
      setIssued(json);
    } catch (e: any) {
      setIssueErr(e?.message ?? String(e));
    } finally {
      setIssuing(false);
    }
  }

  return (
    <section className="space-y-4">
      <div className="rounded border p-3">
        <h2 className="font-semibold mb-2">Pedido</h2>

        {loading && <p className="text-sm opacity-70">Carregando…</p>}
        {err && (
          <div className="text-sm">
            <p className="font-semibold text-red-600">Erro ao carregar pedido</p>
            <pre className="whitespace-pre-wrap break-words">{err}</pre>
          </div>
        )}
        {!loading && !err && (
          <pre className="text-xs whitespace-pre-wrap break-words max-h-72 overflow-auto bg-black/5 p-2 rounded">
            {prettify(reqData)}
          </pre>
        )}
      </div>

      <div className="rounded border p-3 space-y-3">
        <h2 className="font-semibold">Emitir recibo</h2>

        <label className="block space-y-1">
          <span className="text-sm opacity-80">Chave de operador (opcional)</span>
          <input
            className="w-full border rounded p-2"
            placeholder="ECO_OPERATOR_TOKEN (se existir)"
            value={operatorToken}
            onChange={(e) => setOperatorToken(e.target.value)}
            type="password"
          />
          <span className="text-xs opacity-60">
            Só é exigida se você setar <code>ECO_OPERATOR_TOKEN</code> no .env.
          </span>
        </label>

        <label className="block space-y-1">
          <span className="text-sm opacity-80">Resumo</span>
          <textarea className="w-full border rounded p-2" rows={3} value={summary} onChange={(e) => setSummary(e.target.value)} />
        </label>

        <label className="block space-y-1">
          <span className="text-sm opacity-80">Itens / Observações</span>
          <textarea className="w-full border rounded p-2" rows={4} value={items} onChange={(e) => setItems(e.target.value)} />
        </label>

        <div className="grid md:grid-cols-2 gap-3">
          <label className="block space-y-1">
            <span className="text-sm opacity-80">Operador</span>
            <input className="w-full border rounded p-2" value={operator} onChange={(e) => setOperator(e.target.value)} />
          </label>

          <label className="flex items-center gap-2 pt-6">
            <input type="checkbox" checked={isPublic} onChange={(e) => setIsPublic(e.target.checked)} />
            <span className="text-sm">Recibo público (quando suportado)</span>
          </label>
        </div>

        <button
          onClick={onIssue}
          disabled={issuing || !requestId}
          className="px-3 py-2 rounded bg-black text-white disabled:opacity-50"
        >
          {issuing ? "Emitindo…" : "Emitir recibo"}
        </button>

        {issueErr && (
          <div className="text-sm">
            <p className="font-semibold text-red-600">Falha ao emitir recibo</p>
            <pre className="whitespace-pre-wrap break-words">{issueErr}</pre>
          </div>
        )}

        {issued && (
          <div className="text-sm space-y-2">
            <p className="font-semibold text-green-700">Recibo emitido ✅</p>

            {derivedCode ? (
              <div className="flex gap-3 items-center flex-wrap">
                <Link className="underline" href={"/recibo/" + String(derivedCode)}>Ver recibo</Link>
                <span className="text-xs opacity-70">code: {String(derivedCode)}</span>
              </div>
            ) : (
              <p className="text-xs opacity-70">Emitido, mas não consegui derivar code (shareCode/code/id).</p>
            )}

            <details>
              <summary className="cursor-pointer opacity-80">Resposta completa</summary>
              <pre className="text-xs whitespace-pre-wrap break-words max-h-72 overflow-auto bg-black/5 p-2 rounded">
                {prettify(issued)}
              </pre>
            </details>
          </div>
        )}
      </div>
    </section>
  );
}