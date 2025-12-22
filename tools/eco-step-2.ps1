$ErrorActionPreference = "Stop"

function Backup-File([string]$p) {
  if (Test-Path $p) {
    $ts = Get-Date -Format "yyyyMMdd-HHmmss"
    Copy-Item $p "$p.bak-$ts" -Force
  }
}
function Ensure-Dir([string]$p) {
  $dir = Split-Path $p -Parent
  if ($dir -and !(Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
}

Write-Host "== ECO: passo 2 (Serviços + stubs + seed) ==" -ForegroundColor Cyan

# 0) DB OK
Write-Host ">> prisma db push + generate" -ForegroundColor Yellow
npx prisma db push --schema=prisma/schema.prisma
npx prisma generate --schema=prisma/schema.prisma

# 1) STUBS pra parar 404
$stubs = @(
  @{ path="src/app/formacao/cursos/page.tsx"; title="Formação"; msg="Em construção (Formação v0 vem já já)." },
  @{ path="src/app/formacao/cursos/[slug]/page.tsx"; title="Curso"; msg="Em construção (detalhe do curso)." },
  @{ path="src/app/s/missao/[id]/page.tsx"; title="Missão compartilhada"; msg="Em construção (Share pack Missão)." },
  @{ path="src/app/s/progresso/[code]/page.tsx"; title="Progresso compartilhado"; msg="Em construção (Share pack Progresso)." },
  @{ path="src/app/s/cert/[code]/page.tsx"; title="Certificado"; msg="Em construção (Share pack Certificado)." }
)

foreach ($s in $stubs) {
  Ensure-Dir $s.path
  if (!(Test-Path $s.path)) {
@"
export default function Page({ params }: any) {
  return (
    <main style={{ padding: 24 }}>
      <h1 style={{ marginTop: 0 }}>${($s.title)}</h1>
      <p>${($s.msg)}</p>
      <pre style={{ opacity: 0.8 }}>params: {JSON.stringify(params, null, 2)}</pre>
    </main>
  );
}
"@ | Set-Content -Encoding UTF8 $s.path
  }
}

# 2) Tela /servicos (lista)
$servicesList = "src/app/servicos/page.tsx"
Ensure-Dir $servicesList
Backup-File $servicesList
@"
import Link from "next/link";
import { prisma } from "../../lib/prisma";

export default async function ServicosPage() {
  const services = await prisma.service.findMany({ orderBy: { createdAt: "desc" } });

  return (
    <main style={{ padding: 24 }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", gap: 12 }}>
        <h1 style={{ margin: 0 }}>Serviços</h1>
        <Link href="/servicos/novo">Cadastrar serviço</Link>
      </div>

      {services.length === 0 ? (
        <p style={{ marginTop: 16 }}>Nenhum serviço ainda. Crie o primeiro.</p>
      ) : (
        <ul style={{ marginTop: 16, paddingLeft: 18 }}>
          {services.map((s: any) => (
            <li key={s.id}>
              <strong>{s.name}</strong> — <code>{s.slug}</code> • {s.kind}
            </li>
          ))}
        </ul>
      )}

      <p style={{ marginTop: 18 }}>
        Ir para <Link href="/coleta">/coleta</Link>
      </p>
    </main>
  );
}
"@ | Set-Content -Encoding UTF8 $servicesList

# 3) Tela /servicos/novo (client)
$servicesNew = "src/app/servicos/novo/page.tsx"
Ensure-Dir $servicesNew
Backup-File $servicesNew
@"
"use client";

import { useMemo, useState } from "react";

const KINDS = ["COLETA","REPARO","FEIRA","FORMACAO","DOACAO","OUTRO"];

export default function NovoServicoPage() {
  const [name, setName] = useState("");
  const [kind, setKind] = useState("COLETA");
  const [msg, setMsg] = useState("");

  const canSave = useMemo(() => name.trim().length > 0, [name]);

  async function onSave() {
    setMsg("");
    const res = await fetch("/api/services", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name, kind }),
    });
    const j = await res.json().catch(() => ({}));
    if (!res.ok) return setMsg("Erro: " + String(j?.message ?? j?.error ?? "unknown"));
    setMsg("✅ Serviço criado. Volte para /servicos.");
    setName("");
  }

  return (
    <main style={{ padding: 24, maxWidth: 720 }}>
      <h1 style={{ marginTop: 0 }}>Cadastrar serviço</h1>

      <label style={{ display: "block", marginTop: 12 }}>
        Nome
        <input value={name} onChange={(e) => setName(e.target.value)} style={{ width: "100%", padding: 8 }} />
      </label>

      <label style={{ display: "block", marginTop: 12 }}>
        Tipo
        <select value={kind} onChange={(e) => setKind(e.target.value)} style={{ width: "100%", padding: 8 }}>
          {KINDS.map((k) => <option key={k} value={k}>{k}</option>)}
        </select>
      </label>

      <div style={{ display: "flex", gap: 12, marginTop: 16 }}>
        <button disabled={!canSave} onClick={onSave} type="button">Salvar</button>
        <a href="/servicos">Voltar</a>
      </div>

      {msg ? <p style={{ marginTop: 12 }}>{msg}</p> : null}
    </main>
  );
}
"@ | Set-Content -Encoding UTF8 $servicesNew

# 4) Seed simples (somente serviços) — roda via node tools/seed-eco.mjs
New-Item -ItemType Directory -Force tools | Out-Null
$seed = @"
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

const defaults = [
  { name: "Coleta Solidária", kind: "COLETA", slug: "coleta-solidaria" },
  { name: "Reparo & Reuso", kind: "REPARO", slug: "reparo-reuso" },
  { name: "Feira Comunitária", kind: "FEIRA", slug: "feira-comunitaria" },
  { name: "Formação Popular", kind: "FORMACAO", slug: "formacao-popular" },
  { name: "Doação", kind: "DOACAO", slug: "doacao" },
];

async function main() {
  const count = await prisma.service.count();
  if (count > 0) {
    console.log("Seed: serviços já existem (count =", count, ")");
    return;
  }

  for (const s of defaults) {
    await prisma.service.create({ data: s as any });
  }
  console.log("Seed: OK (", defaults.length, "serviços criados )");
}

main()
  .catch((e) => {
    console.error("Seed error:", e?.message ?? e);
    process.exitCode = 1;
  })
  .finally(async () => prisma.$disconnect());
"@
$seed | Set-Content -Encoding UTF8 tools/seed-eco.mjs

Write-Host ">> Rodando seed (se não tiver serviços ainda)..." -ForegroundColor Yellow
node tools/seed-eco.mjs

Write-Host "✅ Passo 2 aplicado. Suba:" -ForegroundColor Green
Write-Host "   npm run dev -- --webpack"
