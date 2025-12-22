$ErrorActionPreference = "Stop"

function Ensure-Dir([string]$p){ if($p -and !(Test-Path $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function WriteUtf8NoBom([string]$path, [string]$content){
  $dir = Split-Path $path -Parent
  if($dir){ Ensure-Dir $dir }
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
}
function Backup-File([string]$path){
  if(!(Test-Path $path)){ return $null }
  Ensure-Dir "tools/_patch_backup"
  $ts = Get-Date -Format "yyyyMMdd-HHmmss"
  $safe = ($path -replace '[\\/:*?"<>|]', '_')
  $dst = "tools/_patch_backup/$ts-$safe"
  Copy-Item -Force $path $dst
  return $dst
}
function New-Report([string]$name){
  Ensure-Dir "reports"
  $ts = Get-Date -Format "yyyyMMdd-HHmmss"
  return "reports/$ts-$name.md"
}

Ensure-Dir "tools/_patch_backup"
Ensure-Dir "reports"

$rep = New-Report "eco-step-03c-force-chamar-coleta"
$log = @()
$log += "# ECO — Step 03C (FORCE: Chamar Coleta + Smoke)"
$log += ""
$log += "- Data: " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
$log += "- PWD : " + (Get-Location).Path
$log += "- Node: " + (node -v 2>$null)
$log += "- npm : " + (npm -v 2>$null)
$log += ""

# PATCH A — API pickup-requests
$apiPath = "src/app/api/pickup-requests/route.ts"
Ensure-Dir (Split-Path $apiPath -Parent)
if(Test-Path $apiPath){ $b = Backup-File $apiPath; if($b){ $log += "- Backup API: $b" } }

$api = @'
import { NextResponse } from "next/server";
import { PrismaClient } from "@prisma/client";

const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };
const prisma = globalForPrisma.prisma ?? new PrismaClient();
if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = prisma;

export async function GET() {
  const items = await prisma.pickupRequest.findMany({
    orderBy: { createdAt: "desc" },
    take: 200,
  });
  return NextResponse.json(items);
}

export async function POST(req: Request) {
  const body = await req.json().catch(() => ({}));

  const name = typeof body?.name === "string" ? body.name.trim() : null;
  const phone = typeof body?.phone === "string" ? body.phone.trim() : null;
  const address = typeof body?.address === "string" ? body.address.trim() : null;
  const notes = typeof body?.notes === "string" ? body.notes.trim() : null;

  const created = await prisma.pickupRequest.create({
    data: {
      name: name || undefined,
      phone: phone || undefined,
      address: address || undefined,
      notes: notes || undefined,
      status: "OPEN",
    },
  });

  return NextResponse.json(created, { status: 201 });
}
'@
WriteUtf8NoBom $apiPath $api
$log += "- OK: $apiPath"

# PATCH B — UI pages
$pageList = "src/app/chamar-coleta/page.tsx"
$pageNew  = "src/app/chamar-coleta/novo/page.tsx"
Ensure-Dir (Split-Path $pageList -Parent)
Ensure-Dir (Split-Path $pageNew  -Parent)

if(Test-Path $pageList){ $b = Backup-File $pageList; if($b){ $log += "- Backup page: $b" } }
if(Test-Path $pageNew ){ $b = Backup-File $pageNew ; if($b){ $log += "- Backup page: $b" } }

$listCode = @'
"use client";

import Link from "next/link";
import { useEffect, useState } from "react";

type Item = {
  id: string;
  createdAt: string;
  status: "OPEN" | "SCHEDULED" | "DONE" | "CANCELED";
  name?: string | null;
  phone?: string | null;
  address?: string | null;
  notes?: string | null;
};

export default function ChamarColetaPage() {
  const [items, setItems] = useState<Item[]>([]);
  const [loading, setLoading] = useState(true);

  async function load() {
    setLoading(true);
    const res = await fetch("/api/pickup-requests", { cache: "no-store" });
    const json = (await res.json()) as Item[];
    setItems(Array.isArray(json) ? json : []);
    setLoading(false);
  }

  useEffect(() => {
    load().catch(() => setLoading(false));
  }, []);

  return (
    <div className="stack">
      <div className="card">
        <div className="toolbar">
          <h1 style={{ margin: 0 }}>Chamar Coleta</h1>
          <span className="badge">v0</span>
        </div>

        <p style={{ marginTop: 8 }}>
          <small>
            Pedido rápido (MVP). Depois liga no <b>Recibo ECO</b>.
          </small>
        </p>

        <div className="toolbar" style={{ marginTop: 10 }}>
          <Link className="primary" href="/chamar-coleta/novo">+ Novo pedido</Link>
          <Link className="btn" href="/">Voltar ao HUB</Link>
          <button className="btn" onClick={() => load()}>Atualizar</button>
        </div>
      </div>

      <div className="card">
        <div className="toolbar">
          <h2 style={{ margin: 0 }}>Pedidos</h2>
          <span className="muted"><small>{items.length} itens</small></span>
        </div>

        {loading ? (
          <p><small>Carregando…</small></p>
        ) : items.length === 0 ? (
          <p><small>Nenhum pedido ainda.</small></p>
        ) : (
          <div className="stack" style={{ marginTop: 10 }}>
            {items.map((it) => (
              <div key={it.id} className="card" style={{ padding: 12 }}>
                <div className="toolbar">
                  <b>{it.name || "Sem nome"}</b>
                  <span className="badge">{it.status}</span>
                </div>
                <p style={{ marginTop: 6 }}>
                  <small className="muted">
                    {new Date(it.createdAt).toLocaleString()}
                  </small>
                </p>
                {it.phone ? <p style={{ marginTop: 6 }}><small><b>Tel:</b> {it.phone}</small></p> : null}
                {it.address ? <p style={{ marginTop: 6 }}><small><b>End:</b> {it.address}</small></p> : null}
                {it.notes ? <p style={{ marginTop: 6 }}><small><b>Obs:</b> {it.notes}</small></p> : null}
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
'@

$newCode = @'
"use client";

import Link from "next/link";
import { useState } from "react";

export default function NovoPedidoPage() {
  const [name, setName] = useState("");
  const [phone, setPhone] = useState("");
  const [address, setAddress] = useState("");
  const [notes, setNotes] = useState("");
  const [saving, setSaving] = useState(false);
  const [ok, setOk] = useState<string | null>(null);
  const [err, setErr] = useState<string | null>(null);

  async function submit() {
    setSaving(true);
    setOk(null);
    setErr(null);

    try {
      const res = await fetch("/api/pickup-requests", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ name, phone, address, notes }),
      });

      if (!res.ok) throw new Error("Falha ao salvar (" + res.status + ")");

      const json = await res.json();
      setOk("Pedido criado: " + (json?.id ?? "ok"));
      setName(""); setPhone(""); setAddress(""); setNotes("");
    } catch (e: any) {
      setErr(e?.message ?? "Erro ao salvar");
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="stack">
      <div className="card">
        <div className="toolbar">
          <h1 style={{ margin: 0 }}>Novo pedido</h1>
          <span className="badge">Chamar Coleta</span>
        </div>

        <div className="stack" style={{ marginTop: 10 }}>
          <label>
            <small><b>Nome</b></small>
            <input value={name} onChange={(e) => setName(e.target.value)} placeholder="Seu nome (opcional)" />
          </label>

          <label>
            <small><b>Telefone</b></small>
            <input value={phone} onChange={(e) => setPhone(e.target.value)} placeholder="WhatsApp (opcional)" />
          </label>

          <label>
            <small><b>Endereço</b></small>
            <input value={address} onChange={(e) => setAddress(e.target.value)} placeholder="Rua / referência (opcional)" />
          </label>

          <label>
            <small><b>Observações</b></small>
            <textarea value={notes} onChange={(e) => setNotes(e.target.value)} placeholder="Material, quantidade, horário etc (opcional)" />
          </label>

          {ok ? <p><small>✅ {ok}</small></p> : null}
          {err ? <p><small>❌ {err}</small></p> : null}

          <div className="toolbar">
            <button className="primary" disabled={saving} onClick={submit}>
              {saving ? "Salvando…" : "Criar pedido"}
            </button>
            <Link className="btn" href="/chamar-coleta">Voltar</Link>
            <Link className="btn" href="/">HUB</Link>
          </div>
        </div>
      </div>
    </div>
  );
}
'@

WriteUtf8NoBom $pageList $listCode
WriteUtf8NoBom $pageNew  $newCode
$log += "- OK: $pageList"
$log += "- OK: $pageNew"

# PATCH C — HUB link
$homePath = "src/app/page.tsx"
if(Test-Path $homePath){
  $homeContent = Get-Content $homePath -Raw
  if($homeContent -notmatch '/chamar-coleta'){
    $needle = 'href="/servicos">Ver serviços</Link>'
    if($homeContent -match [regex]::Escape($needle)){
      $homeContent = $homeContent.Replace($needle, $needle + "
" + '          <Link className="btn" href="/chamar-coleta">Chamar coleta</Link>')
      WriteUtf8NoBom $homePath $homeContent
      $log += "- HUB: link inserido"
    }
  }
}

# PATCH D — Smoke
$smokePath = "tools/eco-smoke.ps1"
$smoke = @'
Stop = "Stop"
 = "http://localhost:3000"
if(.Count -ge 1 -and [0]){  = [0] }

function Hit([string]){
   = ""
   = Invoke-WebRequest -Uri  -UseBasicParsing -TimeoutSec 10
  Write-Host "✅  -> " -ForegroundColor Green
}

Write-Host "== ECO SMOKE ==" -ForegroundColor Cyan
Hit "/"
Hit "/servicos"
Hit "/servicos/novo"
Hit "/coleta"
Hit "/coleta/novo"
Hit "/chamar-coleta"
Hit "/chamar-coleta/novo"
Hit "/api/services"
Hit "/api/points"
Hit "/api/pickup-requests"
Write-Host "✅ SMOKE OK" -ForegroundColor Green
'@
WriteUtf8NoBom $smokePath $smoke
$log += "- OK: $smokePath"

# VERIFY
$log += ""
$log += "## VERIFY"
npx prisma generate --schema=prisma/schema.prisma | Out-Host
if(!(Test-Path $pageList)){ throw "VERIFY falhou: $pageList não existe." }
if(!(Test-Path $pageNew )){ throw "VERIFY falhou: $pageNew não existe." }
if(!(Test-Path $apiPath )){ throw "VERIFY falhou: $apiPath não existe." }
$log += "- arquivos: OK"

WriteUtf8NoBom $rep ($log -join "
")
Write-Host "✅ Step 03C aplicado. Report -> $rep" -ForegroundColor Green
