$ErrorActionPreference = "Stop"

function EnsureDir([string]$p){
  if($p -and !(Test-Path -LiteralPath $p)){
    New-Item -ItemType Directory -Force -Path $p | Out-Null
  }
}
function WriteUtf8NoBom([string]$path, [string]$content){
  $dir = Split-Path -Parent $path
  if($dir){ EnsureDir $dir }
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
}
function BackupFile([string]$path){
  if(!(Test-Path -LiteralPath $path)){ return $null }
  EnsureDir "tools/_patch_backup"
  $ts = Get-Date -Format "yyyyMMdd-HHmmss"
  $safe = ($path -replace '[\\/:*?"<>|]', '_')
  $dst = "tools/_patch_backup/$ts-$safe"
  Copy-Item -Force -LiteralPath $path $dst
  return $dst
}
function NewReport([string]$name){
  EnsureDir "reports"
  $ts = Get-Date -Format "yyyyMMdd-HHmmss"
  return "reports/$ts-$name.md"
}
function FindFirst([string]$root, [string]$pattern){
  $f = Get-ChildItem -Recurse -File -Path $root -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -match $pattern } |
    Select-Object -First 1
  if($f){ return $f.FullName }
  return $null
}

$rep = NewReport "eco-step-13c-optional-operator-token-safe"
$log = @()
$log += "# ECO — STEP 13c — Chave opcional de operador (emitir + toggle recibo)"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

# =========
# DIAG
# =========
$apiReceipts = "src/app/api/receipts/route.ts"
if(!(Test-Path -LiteralPath $apiReceipts)){
  $apiReceipts = FindFirst "src/app" "\\api\\receipts\\route\.ts$"
}
if(-not $apiReceipts){ throw "Não achei /api/receipts/route.ts" }

$reciboClient = "src/app/recibo/[code]/recibo-client.tsx"
if(!(Test-Path -LiteralPath $reciboClient)){
  $reciboClient = FindFirst "src/app" "\\recibo\\\[code\]\\recibo-client\.tsx$"
}
if(-not $reciboClient){ throw "Não achei recibo-client.tsx em /recibo/[code]" }

$fecharClient = "src/app/pedidos/fechar/[id]/fechar-client.tsx"
if(!(Test-Path -LiteralPath $fecharClient)){
  $fecharClient = FindFirst "src/app" "\\pedidos\\fechar\\\[id\]\\fechar-client\.tsx$"
}
if(-not $fecharClient){ throw "Não achei fechar-client.tsx em /pedidos/fechar/[id]" }

$log += "## DIAG"
$log += ("API receipts : {0}" -f $apiReceipts)
$log += ("Recibo client: {0}" -f $reciboClient)
$log += ("Fechar client: {0}" -f $fecharClient)
$log += ""

# =========
# PATCH (backup)
# =========
$log += "## PATCH"
$log += ("Backup API    : {0}" -f (BackupFile $apiReceipts))
$log += ("Backup Recibo : {0}" -f (BackupFile $reciboClient))
$log += ("Backup Fechar : {0}" -f (BackupFile $fecharClient))
$log += ""

# =========
# PATCH: API /api/receipts — guard opcional por ENV (ECO_OPERATOR_TOKEN)
# =========
$apiTxt = Get-Content -LiteralPath $apiReceipts -Raw

if($apiTxt -match "ECO_OPERATOR_TOKEN" -or $apiTxt -match "requireOperatorToken"){
  $log += "- INFO: API já possui guard de operador (skip patch API)."
} else {
  $needle = 'export const runtime = "nodejs";'
  if($apiTxt -notlike "*$needle*"){
    throw "Não encontrei runtime nodejs em /api/receipts para injetar guard."
  }

  $helper = @"
function requireOperatorToken(req: Request, body: any) {
  const required = process.env.ECO_OPERATOR_TOKEN;
  if (!required) return { ok: true as const };

  const headerToken = req.headers.get("x-eco-token");
  const token =
    (typeof body?.operatorToken === "string" && body.operatorToken.trim())
      ? body.operatorToken.trim()
      : (headerToken || "");

  if (!token || token !== required) {
    return { ok: false as const, res: NextResponse.json({ error: "unauthorized" }, { status: 401 }) };
  }
  return { ok: true as const };
}
"@

  $apiTxt2 = $apiTxt.Replace($needle, ($needle + "`n`n" + $helper.TrimEnd() + "`n"))

  # injeta check logo após ler body no POST/PATCH (bem específico do nosso arquivo)
  $apiTxt2 = $apiTxt2.Replace(
    'const body = (await req.json()) as IssueBody;',
    'const body = (await req.json()) as IssueBody;' + "`n" +
    '    const auth = requireOperatorToken(req, body);' + "`n" +
    '    if (!auth.ok) return auth.res;'
  )

  $apiTxt2 = $apiTxt2.Replace(
    'const body = (await req.json()) as PatchBody;',
    'const body = (await req.json()) as PatchBody;' + "`n" +
    '    const auth = requireOperatorToken(req, body);' + "`n" +
    '    if (!auth.ok) return auth.res;'
  )

  WriteUtf8NoBom $apiReceipts $apiTxt2
  $log += "- OK: /api/receipts POST/PATCH agora respeitam ECO_OPERATOR_TOKEN (opcional)."
}

# =========
# PATCH: fechar-client.tsx — campo opcional de token + enviar no POST /api/receipts
# (sem template literal `${}` pra não brigar com PowerShell)
# =========
$fecharTs = @"
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
"@

WriteUtf8NoBom $fecharClient $fecharTs
$log += "- OK: /pedidos/fechar/[id] agora envia token opcional no POST /api/receipts"
$log += ""

# =========
# PATCH: recibo-client.tsx — campo opcional de token + enviar no PATCH /api/receipts
# =========
$reciboTs = @"
"use client";

import { useEffect, useState } from "react";

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

export default function ReciboClient({ code }: { code: string }) {
  const [loading, setLoading] = useState(true);
  const [receipt, setReceipt] = useState<any>(null);
  const [err, setErr] = useState<string | null>(null);

  const [operatorToken, setOperatorToken] = useState<string>(readToken());

  const [toggling, setToggling] = useState(false);
  const [toggleErr, setToggleErr] = useState<string | null>(null);

  async function load() {
    setLoading(true);
    setErr(null);
    try {
      const url = "/api/receipts?code=" + encodeURIComponent(code);
      const res = await fetch(url, { cache: "no-store" });
      const txt = await res.text();
      let json: any = null;
      try { json = JSON.parse(txt); } catch { json = { raw: txt }; }

      if (!res.ok) throw new Error(json?.error ?? ("GET /api/receipts?code falhou (" + res.status + ")"));
      setReceipt(json?.receipt ?? null);
    } catch (e: any) {
      setErr(e?.message ?? String(e));
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    if (code) load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [code]);

  async function copyLink() {
    try {
      await navigator.clipboard.writeText(window.location.href);
      alert("Link copiado ✅");
    } catch {
      alert("Não consegui copiar automaticamente. Copie manualmente da barra do navegador.");
    }
  }

  function waLink() {
    const link = window.location.href;
    const text = "Recibo ECO: " + link;
    return "https://wa.me/?text=" + encodeURIComponent(text);
  }

  async function share() {
    const link = window.location.href;
    const payload: any = { title: "Recibo ECO", text: "Recibo ECO", url: link };
    if ((navigator as any).share) {
      try { await (navigator as any).share(payload); return; } catch {}
    }
    await copyLink();
  }

  async function togglePublic() {
    setToggling(true);
    setToggleErr(null);
    try {
      const current = !!(receipt?.public ?? receipt?.isPublic);
      const next = !current;

      const headers: any = { "content-type": "application/json" };
      if (operatorToken) headers["x-eco-token"] = operatorToken;

      const res = await fetch("/api/receipts", {
        method: "PATCH",
        headers,
        body: JSON.stringify({ code, public: next, operatorToken: operatorToken || null }),
      });

      const txt = await res.text();
      let json: any = null;
      try { json = JSON.parse(txt); } catch { json = { raw: txt }; }

      if (res.status === 401) throw new Error("unauthorized (defina ECO_OPERATOR_TOKEN no .env e preencha a chave aqui)");
      if (!res.ok) throw new Error(json?.error ?? ("PATCH /api/receipts falhou (" + res.status + ")"));

      if (operatorToken) saveToken(operatorToken);
      await load();
    } catch (e: any) {
      setToggleErr(e?.message ?? String(e));
    } finally {
      setToggling(false);
    }
  }

  const isPublic = !!(receipt?.public ?? receipt?.isPublic);

  return (
    <section className="space-y-4">
      <div className="rounded border p-3 space-y-2">
        <div className="flex items-center justify-between gap-2 flex-wrap">
          <h2 className="font-semibold">Status</h2>
          <span className={"text-xs px-2 py-1 rounded border " + (isPublic ? "bg-green-50" : "bg-yellow-50")}>
            {isPublic ? "Público" : "Privado"}
          </span>
        </div>

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

        <div className="flex flex-wrap gap-2">
          <button className="px-3 py-2 rounded border" onClick={copyLink}>Copiar link</button>
          <a className="px-3 py-2 rounded border" href={waLink()} target="_blank" rel="noreferrer">WhatsApp</a>
          <button className="px-3 py-2 rounded border" onClick={share}>Compartilhar</button>

          <button
            className="px-3 py-2 rounded bg-black text-white disabled:opacity-50"
            onClick={togglePublic}
            disabled={toggling || loading || !receipt}
            title="MVP: trava opcional via ECO_OPERATOR_TOKEN"
          >
            {toggling ? "Atualizando…" : (isPublic ? "Tornar privado" : "Tornar público")}
          </button>
        </div>

        {toggleErr && (
          <div className="text-sm">
            <p className="font-semibold text-red-600">Erro ao alternar público/privado</p>
            <pre className="whitespace-pre-wrap break-words">{toggleErr}</pre>
          </div>
        )}
      </div>

      <div className="rounded border p-3">
        <h2 className="font-semibold mb-2">Recibo</h2>

        {loading && <p className="text-sm opacity-70">Carregando…</p>}
        {err && (
          <div className="text-sm">
            <p className="font-semibold text-red-600">Erro ao carregar recibo</p>
            <pre className="whitespace-pre-wrap break-words">{err}</pre>
          </div>
        )}

        {!loading && !err && receipt && (
          <pre className="text-xs whitespace-pre-wrap break-words max-h-96 overflow-auto bg-black/5 p-2 rounded">
            {prettify(receipt)}
          </pre>
        )}

        {!loading && !err && !receipt && (
          <p className="text-sm opacity-70">Não encontrei recibo para esse code.</p>
        )}
      </div>
    </section>
  );
}
"@

WriteUtf8NoBom $reciboClient $reciboTs
$log += "- OK: /recibo/[code] toggle agora envia token opcional no PATCH /api/receipts"
$log += ""

# =========
# REGISTRO
# =========
$log += "## Como usar"
$log += "- (Opcional) Crie no .env: ECO_OPERATOR_TOKEN=uma-chave-forte"
$log += "- Sem essa env: tudo continua funcionando aberto (MVP)."
$log += "- Com essa env: POST/PATCH /api/receipts exigem token (campo nas telas)."
$log += ""
$log += "## Próximos passos"
$log += "1) npm run dev"
$log += "2) pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1"
$log += "3) /pedidos -> Fechar -> emitir recibo (com/sem token)"
$log += "4) /recibo/[code] -> toggle público/privado (com/sem token)"
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 13c aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) npm run dev" -ForegroundColor Yellow
Write-Host "2) pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) /pedidos -> Fechar -> emitir recibo (com/sem token)" -ForegroundColor Yellow
Write-Host "4) /recibo/[code] -> toggle público/privado (com/sem token)" -ForegroundColor Yellow
Write-Host "5) (opcional) .env: ECO_OPERATOR_TOKEN=..." -ForegroundColor Yellow