$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

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
function FindFirstByName([string]$root, [string]$fileName){
  if(!(Test-Path -LiteralPath $root)){ return $null }
  $f = Get-ChildItem -Path $root -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -ieq $fileName } |
    Select-Object -First 1
  if($f){ return $f.FullName }
  return $null
}

$rep = NewReport "eco-step-44-day-close-store-safe"
$log = @()
$log += "# ECO — STEP 44 (SAFE v2) — Day Close (persistência + UI)"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

try {
  # GUARD: isso é do ECO (depende de /s/dia existir)
  if(!(Test-Path -LiteralPath "src/app/s/dia")){
    throw "GUARD: não achei src/app/s/dia. Você está no repo errado. Rode no ECO: C:\Projetos\App ECO\eluta-servicos"
  }

  # Prisma schema?
  $schema = "prisma/schema.prisma"
  if(!(Test-Path -LiteralPath $schema)){
    $schema = FindFirstByName "." "schema.prisma"
  }
  $log += "## DIAG — Prisma"
  $log += ("schema.prisma: {0}" -f ($(if($schema){$schema}else{"(não encontrado)"})))
  $log += ""

  # garantir src/lib/prisma.ts
  $prismaLib = "src/lib/prisma.ts"
  if(!(Test-Path -LiteralPath $prismaLib)){
    EnsureDir (Split-Path -Parent $prismaLib)
    $prismaLibTxt = @"
import { PrismaClient } from "@prisma/client";

const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };

export const prisma =
  globalForPrisma.prisma ??
  new PrismaClient({
    log: process.env.NODE_ENV === "development" ? ["error", "warn"] : ["error"],
  });

if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = prisma;
"@
    WriteUtf8NoBom $prismaLib $prismaLibTxt
    $log += "## PATCH — src/lib/prisma.ts"
    $log += "- OK: criado singleton PrismaClient."
    $log += ""
  } else {
    $log += "## PATCH — src/lib/prisma.ts"
    $log += "- INFO: já existe; não mexi."
    $log += ""
  }

  # model EcoDayClose (se schema existir)
  if($schema){
    $schemaRaw = Get-Content -LiteralPath $schema -Raw
    if($schemaRaw -and $schemaRaw.Contains("model EcoDayClose")){
      $log += "## PATCH — Prisma schema"
      $log += "- INFO: EcoDayClose já existe; skip."
      $log += ""
    } else {
      $bk = BackupFile $schema
      $modelBlock = @"

model EcoDayClose {
  id        String   @id @default(cuid())
  day       String   @unique
  summary   Json
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}
"@
      $schemaNew = $schemaRaw.TrimEnd() + "`n" + $modelBlock.TrimStart()
      WriteUtf8NoBom $schema $schemaNew
      $log += "## PATCH — Prisma schema"
      $log += ("Backup: {0}" -f $bk)
      $log += "- OK: adicionado model EcoDayClose."
      $log += ""
    }
  }

  # API /api/eco/day-close
  $api = "src/app/api/eco/day-close/route.ts"
  EnsureDir (Split-Path -Parent $api)
  $bkApi = BackupFile $api

  $apiTxt = @"
import { NextResponse } from "next/server";
import { prisma } from "../../../../lib/prisma";

export const runtime = "nodejs";

function safeDay(input: string | null): string | null {
  const s = String(input || "").trim();
  if (/^\d{4}-\d{2}-\d{2}$/.test(s)) return s;
  return null;
}

export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const day = safeDay(searchParams.get("day"));
  if (!day) return NextResponse.json({ ok: false, error: "bad_day" }, { status: 400 });

  const row = await prisma.ecoDayClose.findUnique({ where: { day } });
  if (!row) return NextResponse.json({ ok: false, error: "not_found" }, { status: 404 });

  return NextResponse.json({ ok: true, item: row });
}

export async function POST(req: Request) {
  const body = (await req.json().catch(() => null)) as { day?: string; summary?: unknown } | null;
  const day = safeDay(body?.day ?? null);
  if (!day) return NextResponse.json({ ok: false, error: "bad_day" }, { status: 400 });

  const summary = body?.summary ?? {};
  const item = await prisma.ecoDayClose.upsert({
    where: { day },
    update: { summary },
    create: { day, summary },
  });

  return NextResponse.json({ ok: true, item });
}
"@
  WriteUtf8NoBom $api $apiTxt
  $log += "## PATCH — API"
  $log += ("Backup: {0}" -f ($(if($bkApi){$bkApi}else{"(novo)"})))
  $log += "- OK: /api/eco/day-close criado."
  $log += ""

  # UI panel
  $panel = "src/app/s/dia/[day]/DayClosePanel.tsx"
  EnsureDir (Split-Path -Parent $panel)
  $bkPanel = BackupFile $panel

  $panelTxt = @"
"use client";

import { useEffect, useMemo, useState } from "react";

type ApiResp =
  | { ok: true; item: { day: string; summary: unknown; updatedAt?: string } }
  | { ok: false; error: string };

function template(day: string) {
  return {
    day,
    totals: {
      "Papel/Papelão": {},
      "Plástico": {},
      "Metal": {},
      "Vidro": {},
      "Óleo": { litros: 0 },
      "E-lixo": { unidades: 0 },
      "Rejeito": {},
    },
    notes: "",
    meta: { unitsV0: true },
  };
}

export default function DayClosePanel({ day }: { day: string }) {
  const [loading, setLoading] = useState(true);
  const [saved, setSaved] = useState<unknown>(null);
  const [err, setErr] = useState<string | null>(null);

  const initialDraft = useMemo(() => JSON.stringify(template(day), null, 2), [day]);
  const [draft, setDraft] = useState<string>(initialDraft);

  useEffect(() => {
    setDraft(initialDraft);
    setSaved(null);
    setErr(null);
    setLoading(true);

    fetch("/api/eco/day-close?day=" + encodeURIComponent(day))
      .then(async (r) => {
        const j = (await r.json().catch(() => null)) as ApiResp | null;
        if (!j) throw new Error("Resposta inválida");
        if (j.ok) {
          setSaved(j.item.summary);
          setDraft(JSON.stringify(j.item.summary ?? template(day), null, 2));
        } else {
          if (j.error !== "not_found") throw new Error(j.error);
        }
      })
      .catch((e: unknown) => {
        const msg = e instanceof Error ? e.message : "Erro ao carregar";
        setErr(msg);
      })
      .finally(() => setLoading(false));
  }, [day, initialDraft]);

  const onSave = async () => {
    setErr(null);
    let parsed: unknown = null;
    try {
      parsed = JSON.parse(draft);
    } catch {
      setErr("JSON inválido (não consegui dar parse).");
      return;
    }

    const res = await fetch("/api/eco/day-close", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ day, summary: parsed }),
    });

    const j = (await res.json().catch(() => null)) as ApiResp | null;
    if (!j || !("ok" in j)) {
      setErr("Falha ao salvar (resposta inválida).");
      return;
    }
    if (!j.ok) {
      setErr("Falha ao salvar: " + j.error);
      return;
    }
    setSaved(j.item.summary);
    alert("Fechamento salvo ✅");
  };

  return (
    <section style={{ marginTop: 18, border: "1px solid #222", borderRadius: 14, padding: 14 }}>
      <div style={{ display: "flex", flexWrap: "wrap", gap: 10, alignItems: "baseline", justifyContent: "space-between" }}>
        <h2 style={{ fontSize: 16, fontWeight: 900, margin: 0 }}>Fechamento do dia (salvo)</h2>
        <div style={{ fontSize: 12, opacity: 0.75 }}>
          {loading ? "carregando…" : saved ? "existe fechamento salvo" : "ainda não salvo"}
        </div>
      </div>

      {err ? <p style={{ color: "#ff3b30", marginTop: 10 }}>Erro: {err}</p> : null}

      <p style={{ marginTop: 10, fontSize: 13, opacity: 0.85 }}>
        Por enquanto esse painel salva um <strong>JSON</strong> do resumo do dia (v0).
      </p>

      <textarea
        value={draft}
        onChange={(e) => setDraft(e.target.value)}
        spellCheck={false}
        style={{ width: "100%", minHeight: 220, marginTop: 10, padding: 10, borderRadius: 10, border: "1px solid #333", fontFamily: "ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace" }}
      />

      <div style={{ display: "flex", flexWrap: "wrap", gap: 10, marginTop: 10 }}>
        <button type="button" onClick={onSave} style={{ padding: "8px 10px", border: "1px solid #333", borderRadius: 10 }}>
          Salvar fechamento
        </button>
        <button type="button" onClick={() => setDraft(JSON.stringify(template(day), null, 2))} style={{ padding: "8px 10px", border: "1px solid #333", borderRadius: 10 }}>
          Reset template
        </button>
      </div>

      {saved ? (
        <details style={{ marginTop: 12 }}>
          <summary style={{ cursor: "pointer" }}>Ver JSON salvo</summary>
          <pre style={{ whiteSpace: "pre-wrap", marginTop: 10, fontSize: 12, opacity: 0.9 }}>
            {JSON.stringify(saved, null, 2)}
          </pre>
        </details>
      ) : null}
    </section>
  );
}
"@
  WriteUtf8NoBom $panel $panelTxt
  $log += "## PATCH — UI"
  $log += ("Backup: {0}" -f ($(if($bkPanel){$bkPanel}else{"(novo)"})))
  $log += "- OK: DayClosePanel criado."
  $log += ""

  # injeta no /s/dia/[day]/page.tsx (best effort)
  $dayPage = "src/app/s/dia/[day]/page.tsx"
  if(Test-Path -LiteralPath $dayPage){
    $raw = Get-Content -LiteralPath $dayPage -Raw
    $bk = BackupFile $dayPage
    if($raw -and !$raw.Contains('DayClosePanel')){
      if(!$raw.Contains('import DayClosePanel')){
        $pos = $raw.IndexOf("export default")
        if($pos -gt 0){
          $raw = $raw.Insert($pos, 'import DayClosePanel from "./DayClosePanel";' + "`n")
        } else {
          $raw = 'import DayClosePanel from "./DayClosePanel";' + "`n" + $raw
        }
      }
      if($raw.Contains("<DayShareClient") -and !$raw.Contains("<DayClosePanel")){
        $raw = $raw.Replace("<DayShareClient day={day} />", "<DayShareClient day={day} />`n`n      <DayClosePanel day={day} />")
      } elseif($raw.Contains("</main>") -and !$raw.Contains("<DayClosePanel")){
        $raw = $raw.Replace("</main>", "      <DayClosePanel day={day} />`n    </main>")
      }
      WriteUtf8NoBom $dayPage $raw
      $log += "## PATCH — /s/dia/[day]/page.tsx"
      $log += ("Backup: {0}" -f $bk)
      $log += "- OK: painel inserido (best effort)."
      $log += ""
    }
  }

  WriteUtf8NoBom $rep ($log -join "`n")
  Write-Host ("✅ STEP 44 (SAFE v2) aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
  Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
  Write-Host "1) (Se Prisma) npx prisma migrate dev --name eco_day_close" -ForegroundColor Yellow
  Write-Host "2) npm run dev" -ForegroundColor Yellow
  Write-Host "3) Abra /s/dia/AAAA-MM-DD e use o painel 'Fechamento do dia (salvo)'" -ForegroundColor Yellow

} catch {
  try { WriteUtf8NoBom $rep ($log -join "`n") } catch {}
  throw
}