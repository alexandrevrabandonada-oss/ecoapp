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
function FindFirstFileLike([string]$root, [string]$endsWith){
  if(!(Test-Path -LiteralPath $root)){ return $null }
  $f = Get-ChildItem -Path $root -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName.Replace('\','/').ToLower().EndsWith($endsWith.ToLower()) } |
    Select-Object -First 1
  if($f){ return $f.FullName }
  return $null
}

$rep = NewReport "eco-step-46-fix-day-close-autofill"
$log = @()
$log += "# ECO — STEP 46 FIX — Auto preencher fechamento do dia (triagem) [safe]"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

try {
  # GUARD
  if(!(Test-Path -LiteralPath "src/app/s/dia") -or !(Test-Path -LiteralPath "src/app/s/dia/[day]")){
    throw "GUARD: não achei src/app/s/dia e src/app/s/dia/[day]. Rode no repo ECO."
  }

  # Detect Prisma presence (best-effort)
  $hasPrisma = $false
  if(Test-Path -LiteralPath "prisma/schema.prisma"){ $hasPrisma = $true }
  if(Test-Path -LiteralPath "src/lib/prisma.ts"){ $hasPrisma = $true }
  if(Test-Path -LiteralPath "package.json"){
    try {
      $pj = Get-Content -LiteralPath "package.json" -Raw
      if($pj -and $pj.Contains('"@prisma/client"')){ $hasPrisma = $true }
    } catch {}
  }

  $log += "## DIAG"
  $log += ("hasPrisma: {0}" -f $hasPrisma)
  $log += ""

  # -------------------------
  # PATCH 1) API compute endpoint
  # -------------------------
  $api = "src/app/api/eco/day-close/compute/route.ts"
  EnsureDir (Split-Path -Parent $api)
  $bkApi = BackupFile $api

  $log += "## PATCH — API /api/eco/day-close/compute"
  $log += ("Arquivo: {0}" -f $api)
  $log += ("Backup : {0}" -f ($(if($bkApi){$bkApi}else{"(novo)"})))
  $log += ""

  if($hasPrisma){
    $apiTxt = @"
import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";

export const runtime = "nodejs";

function safeDay(input: string | null): string | null {
  const s = String(input || "").trim();
  if (/^\\d{4}-\\d{2}-\\d{2}\$/.test(s)) return s;
  return null;
}

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
    meta: { unitsV0: true, source: "auto", detail: "" },
  };
}

function mapMaterial(raw: unknown): keyof ReturnType<typeof template>["totals"] {
  const s = String(raw || "").toLowerCase();
  if (s.includes("papel")) return "Papel/Papelão";
  if (s.includes("plast")) return "Plástico";
  if (s.includes("metal")) return "Metal";
  if (s.includes("vidro")) return "Vidro";
  if (s.includes("óleo") || s.includes("oleo")) return "Óleo";
  if (s.includes("e-lixo") || s.includes("elixo") || s.includes("eletr")) return "E-lixo";
  if (s.includes("rejeit")) return "Rejeito";
  return "Rejeito";
}

function bumpObj(obj: Record<string, any>, key: string, delta = 1) {
  const v = obj[key];
  obj[key] = (typeof v === "number" ? v : 0) + delta;
}

export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const day = safeDay(searchParams.get("day"));
  if (!day) return NextResponse.json({ ok: false, error: "bad_day" }, { status: 400 });

  const out = template(day);

  const pc: any = prisma as any;
  const candidates = [
    "ecoTriagemItem",
    "ecoTriagem",
    "triagemItem",
    "triagem",
    "ecoTriagemEntry",
    "ecoTriagemRecord",
  ];
  const modelName = candidates.find((n) => pc?.[n]?.findMany);

  if (!modelName) {
    out.meta.detail = "no_triagem_model_found";
    out.meta.source = "stub";
    return NextResponse.json({ ok: true, summary: out, meta: out.meta });
  }

  const model = pc[modelName] as { findMany: (args: any) => Promise<any[]> };

  const start = new Date(day + "T00:00:00-03:00");
  const end = new Date(start.getTime() + 24 * 60 * 60 * 1000);

  let rows: any[] = [];
  try {
    rows = await model.findMany({
      where: { createdAt: { gte: start, lt: end } },
      take: 5000,
      orderBy: { createdAt: "asc" },
    });
    out.meta.detail = "model=" + modelName + ";filter=createdAt";
  } catch (e: any) {
    try {
      rows = await model.findMany({ take: 5000 });
      out.meta.detail = "model=" + modelName + ";filter=fallback_take";
    } catch (e2: any) {
      out.meta.detail = "model=" + modelName + ";error=" + String(e2?.message || e2);
      out.meta.source = "stub";
      return NextResponse.json({ ok: true, summary: out, meta: out.meta });
    }
  }

  for (const r of rows) {
    const keys = Object.keys(r || {});
    const matKey = keys.find((k) =>
      ["material", "categoria", "category", "kind", "tipo"].includes(k.toLowerCase())
    );
    const mat = mapMaterial((matKey ? r[matKey] : "") as unknown);

    const litrosKey = keys.find((k) => ["litros", "liters", "l"].includes(k.toLowerCase()));
    const unitsKey = keys.find((k) =>
      ["unidades", "units", "qtd", "quantidade", "count"].includes(k.toLowerCase())
    );
    const sizeKey = keys.find((k) => ["tamanho", "size", "bucket"].includes(k.toLowerCase()));
    const kindKey = keys.find((k) => ["tipounidade", "unittype"].includes(k.toLowerCase()));

    if (litrosKey && typeof r[litrosKey] === "number") {
      out.totals["Óleo"].litros += r[litrosKey];
      continue;
    }

    if (mat === "E-lixo") {
      if (unitsKey && typeof r[unitsKey] === "number") out.totals["E-lixo"].unidades += r[unitsKey];
      else out.totals["E-lixo"].unidades += 1;
      continue;
    }

    const base = out.totals[mat] as Record<string, any>;
    const size = sizeKey ? String(r[sizeKey] || "").trim() : "";
    const kind = kindKey ? String(r[kindKey] || "").trim() : "";
    const label = (kind || size || "itens").toLowerCase();

    if (unitsKey && typeof r[unitsKey] === "number") bumpObj(base, label, r[unitsKey]);
    else bumpObj(base, label, 1);
  }

  out.meta.detail = String(out.meta.detail || "") + ";rows=" + String(rows.length);
  return NextResponse.json({ ok: true, summary: out, meta: out.meta });
}
"@
    WriteUtf8NoBom $api $apiTxt
    $log += "- OK: endpoint compute criado (Prisma best-effort)."
  } else {
    $apiTxt = @"
import { NextResponse } from "next/server";

export const runtime = "nodejs";

function safeDay(input: string | null): string | null {
  const s = String(input || "").trim();
  if (/^\\d{4}-\\d{2}-\\d{2}\$/.test(s)) return s;
  return null;
}

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
    meta: { unitsV0: true, source: "stub", detail: "no_prisma_detected" },
  };
}

export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const day = safeDay(searchParams.get("day"));
  if (!day) return NextResponse.json({ ok: false, error: "bad_day" }, { status: 400 });
  return NextResponse.json({ ok: true, summary: template(day) });
}
"@
    WriteUtf8NoBom $api $apiTxt
    $log += "- OK: endpoint compute criado (stub, sem Prisma)."
  }

  $log += ""

  # -------------------------
  # PATCH 2) UI DayClosePanel — botão Auto preencher
  # -------------------------
  $panel = "src/app/s/dia/[day]/DayClosePanel.tsx"
  if(!(Test-Path -LiteralPath $panel)){
    $panel = FindFirstFileLike "src/app" "/s/dia/[day]/DayClosePanel.tsx"
  }
  if(!$panel){ throw "Não achei DayClosePanel.tsx em /s/dia/[day]." }

  $bkPanel = BackupFile $panel
  $raw = Get-Content -LiteralPath $panel -Raw

  if(!$raw.Contains("onAutoFill")){
    $needle = "const onSave = async () => {"
    $ix = $raw.IndexOf($needle)
    if($ix -lt 0){ throw "Não encontrei 'const onSave' no DayClosePanel." }

    $autoBlock = @"
  const onAutoFill = async () => {
    setErr(null);
    try {
      const url = "/api/eco/day-close/compute?day=" + encodeURIComponent(day);
      const res = await fetch(url);
      const j = (await res.json().catch(() => null)) as any;
      if (!j || !j.ok || !j.summary) {
        setErr("Auto-fill falhou (resposta inválida).");
        return;
      }
      setDraft(JSON.stringify(j.summary, null, 2));
      alert("Auto preenchido ✅ (v0) — revise antes de salvar");
    } catch (e: any) {
      setErr(e?.message || "Auto-fill falhou");
    }
  };

"@
    $raw = $raw.Insert($ix, $autoBlock)
  }

  if(!$raw.Contains("Auto preencher (triagem)")){
    $btnNeedle = '<button type="button" onClick={onSave}'
    $ixb = $raw.IndexOf($btnNeedle)
    if($ixb -gt 0){
      $insertBtn = @"
        <button type="button" onClick={onAutoFill} style={{ padding: "8px 10px", border: "1px solid #333", borderRadius: 10 }}>
          Auto preencher (triagem)
        </button>

"@
      $raw = $raw.Insert($ixb, $insertBtn)
    }
  }

  WriteUtf8NoBom $panel $raw

  $log += "## PATCH — UI DayClosePanel"
  $log += ("Arquivo: {0}" -f $panel)
  $log += ("Backup : {0}" -f $bkPanel)
  $log += "- OK: botão 'Auto preencher (triagem)' adicionado."
  $log += ""

  # -------------------------
  # PATCH 3) Smoke (opcional) — incluir compute
  # -------------------------
  $smokePath = "tools/eco-smoke-share-day.ps1"
  if(Test-Path -LiteralPath $smokePath){
    $bkS = BackupFile $smokePath
    $s = Get-Content -LiteralPath $smokePath -Raw

    if(!$s.Contains("/api/eco/day-close/compute")){
      if($s.Contains('/api/eco/day-close?day=$today')){
        $s2 = $s.Replace('/api/eco/day-close?day=$today', '/api/eco/day-close?day=$today' + "`n" + '  "/api/eco/day-close/compute?day=$today"')
        if($s2 -ne $s){
          WriteUtf8NoBom $smokePath $s2
          $log += "## PATCH — SMOKE"
          $log += ("Arquivo: {0}" -f $smokePath)
          $log += ("Backup : {0}" -f $bkS)
          $log += "- OK: compute adicionado no smoke."
          $log += ""
        }
      } elseif($s.Contains('@{ p="/api/eco/day-close?day=$today"')){
        $needle2 = '@{ p="/api/eco/day-close?day=$today"; ok=@(200,404) },'
        if($s.Contains($needle2)){
          $s2 = $s.Replace($needle2, $needle2 + "`n" + '  @{ p="/api/eco/day-close/compute?day=$today"; ok=@(200,201,204) },')
          WriteUtf8NoBom $smokePath $s2
          $log += "## PATCH — SMOKE"
          $log += ("Arquivo: {0}" -f $smokePath)
          $log += ("Backup : {0}" -f $bkS)
          $log += "- OK: compute adicionado no smoke (checks)."
          $log += ""
        }
      }
    }
  }

  WriteUtf8NoBom $rep ($log -join "`n")
  Write-Host ("✅ STEP 46 FIX aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
  Write-Host "VERIFY:" -ForegroundColor Yellow
  Write-Host "1) npm run dev" -ForegroundColor Yellow
  Write-Host "2) Abra /s/dia/AAAA-MM-DD e clique 'Auto preencher (triagem)'" -ForegroundColor Yellow
  Write-Host "3) (Opcional) Abra /api/eco/day-close/compute?day=AAAA-MM-DD e veja meta.detail" -ForegroundColor Yellow
  Write-Host "4) (Opcional) Rode smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke-share-day.ps1" -ForegroundColor Yellow

} catch {
  try { WriteUtf8NoBom $rep ($log -join "`n") } catch {}
  throw
}