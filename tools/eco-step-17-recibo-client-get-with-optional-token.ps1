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

$rep = NewReport "eco-step-17-recibo-client-get-with-optional-token"
$log = @()
$log += "# ECO — STEP 17 — /recibo/[code] (GET com token opcional para operador)"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

# =========
# DIAG
# =========
$reciboClient = "src/app/recibo/[code]/recibo-client.tsx"
if(!(Test-Path -LiteralPath $reciboClient)){
  $reciboClient = FindFirst "src/app" "\\recibo\\\[code\]\\recibo-client\.tsx$"
}
if(-not $reciboClient){ throw "Não achei recibo-client.tsx em /recibo/[code]" }

$log += "## DIAG"
$log += ("Recibo client: {0}" -f $reciboClient)
$log += ""

# =========
# PATCH (backup)
# =========
$log += "## PATCH"
$log += ("Backup Recibo: {0}" -f (BackupFile $reciboClient))
$log += ""

# =========
# PATCH (rewrite seguro)
# =========
$tsx = @"
"use client";

import { useEffect, useState } from "react";

function prettify(v: unknown) {
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
      const url =
        `/api/receipts?code=${encodeURIComponent(code)}` +
        (operatorToken ? `&token=${encodeURIComponent(operatorToken)}` : "");

      const res = await fetch(url, {
        cache: "no-store",
        headers: operatorToken ? { "x-eco-token": operatorToken } : undefined,
      });

      const txt = await res.text();
      let json: any = null;
      try { json = JSON.parse(txt); } catch { json = { raw: txt }; }

      if (res.status === 404) {
        // pode ser "não existe" OU "privado sem token"
        setReceipt(null);
        setErr("Não encontrei esse recibo (ou ele está PRIVADO). Se você é operador, preencha a chave e clique em Recarregar.");
        return;
      }

      if (!res.ok) throw new Error(json?.error ?? `GET /api/receipts?code falhou (${res.status})`);
      setReceipt(json?.receipt ?? null);

      if (operatorToken) saveToken(operatorToken);
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
    const text = `Recibo ECO: ${link}`;
    return `https://wa.me/?text=${encodeURIComponent(text)}`;
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
      const current = !!((receipt as any)?.public ?? (receipt as any)?.isPublic);
      const next = !current;

      const res = await fetch("/api/receipts", {
        method: "PATCH",
        headers: {
          "content-type": "application/json",
          ...(operatorToken ? { "x-eco-token": operatorToken } : {}),
        },
        body: JSON.stringify({ code, public: next, operatorToken: operatorToken || null }),
      });

      const txt = await res.text();
      let json: any = null;
      try { json = JSON.parse(txt); } catch { json = { raw: txt }; }

      if (res.status === 401) {
        throw new Error("unauthorized (defina ECO_OPERATOR_TOKEN no .env e preencha a chave aqui)");
      }
      if (!res.ok) throw new Error(json?.error ?? `PATCH /api/receipts falhou (${res.status})`);

      if (operatorToken) saveToken(operatorToken);
      await load();
    } catch (e: any) {
      setToggleErr(e?.message ?? String(e));
    } finally {
      setToggling(false);
    }
  }

  const isPublic = !!((receipt as any)?.public ?? (receipt as any)?.isPublic);

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

          <button className="px-3 py-2 rounded border" onClick={load} disabled={loading}>
            {loading ? "Carregando…" : "Recarregar"}
          </button>

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
            <p className="font-semibold text-red-600">Aviso</p>
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

WriteUtf8NoBom $reciboClient $tsx
$log += "- OK: /recibo/[code]/recibo-client.tsx agora envia token opcional no GET (/api/receipts?code) via header e query."
$log += ""

# =========
# REGISTRO
# =========
$log += "## Como testar"
$log += "1) (Opcional) .env: ECO_OPERATOR_TOKEN=uma-chave-forte"
$log += "2) Emita um recibo PRIVADO"
$log += "3) /recibo/[code] (operador): preencher chave -> Recarregar -> deve mostrar"
$log += "4) Aba anônima (sem chave): deve 404/privado"
$log += ""

WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 17 aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow
Write-Host "3) Teste /recibo/[code] privado: operador (com chave) vê; anônimo não." -ForegroundColor Yellow