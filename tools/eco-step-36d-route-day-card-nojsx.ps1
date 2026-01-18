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

$rep = NewReport "eco-step-36d-route-day-card-nojsx"
$log = @()
$log += "# ECO — STEP 36d — route-day-card sem JSX (React.createElement) p/ Turbopack"
$log += ""
$log += ("Data: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
$log += ("PWD : {0}" -f (Get-Location).Path)
$log += ""

$routeFile = "src/app/api/share/route-day-card/route.ts"
if(!(Test-Path -LiteralPath $routeFile)){
  $log += "## ERRO"
  $log += "Não achei: $routeFile"
  WriteUtf8NoBom $rep ($log -join "`n")
  throw "Não achei route-day-card/route.ts"
}

$log += "## DIAG"
$log += ("Arquivo: {0}" -f $routeFile)
$log += ""

$bk = BackupFile $routeFile

# Reescreve o arquivo inteiro (mais seguro) sem JSX
$ts = @"
import React from "react";
import { NextRequest } from "next/server";
import { ImageResponse } from "next/og";
import { PrismaClient } from "@prisma/client";

/** ECO_STEP36D_NOJSX */
export const runtime = "nodejs";
export const dynamic = "force-dynamic";

const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };
const prisma = globalForPrisma.prisma ?? new PrismaClient();
if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = prisma;

function pickSize(fmt: string | null) {
  if (fmt === "1x1") return { width: 1080, height: 1080 };
  return { width: 1080, height: 1350 }; // 3:4
}

function safeStr(v: any) {
  return (v ?? "").toString();
}

// helper p/ evitar JSX em .ts
function E(tag: any, props: any, ...children: any[]) {
  return React.createElement(tag, props, ...children);
}

export async function GET(req: NextRequest) {
  const u = new URL(req.url);
  const day = (u.searchParams.get("day") || "").trim();
  const format = (u.searchParams.get("format") || "3x4").trim();

  if (!day) return new Response("missing day", { status: 400 });

  // esses nomes já estavam “resolvidos” pelo STEP 36c; mantemos como no arquivo atual (seu script anterior)
  // Se você alterou o model/fields, rode o STEP 36c de novo depois.
  const MODEL = "__PICKUP_DELEGATE__";
  const ROUTE_FIELD = "__ROUTE_FIELD__";
  const STATUS_FIELD = "__STATUS_FIELD__";

  const where: any = {};
  where[ROUTE_FIELD] = day;

  const select: any = {};
  select[STATUS_FIELD] = true;

  const items: any[] = await (prisma as any)[MODEL].findMany({ where, select });

  const stats: any = { total: items.length, NEW: 0, IN_ROUTE: 0, DONE: 0, CANCELED: 0, OTHER: 0 };
  for (const it of items) {
    const st = safeStr(it?.[STATUS_FIELD]) || "NEW";
    if (st === "NEW" || st === "IN_ROUTE" || st === "DONE" || st === "CANCELED") stats[st] = (stats[st] || 0) + 1;
    else stats.OTHER = (stats.OTHER || 0) + 1;
  }

  const { width, height } = pickSize(format);

  const pill = (label: string, value: any, bg: string) =>
    E("div", { style: { padding: "10px 14px", background: bg, borderRadius: 14 } },
      label, ": ", E("b", null, String(value))
    );

  const root =
    E("div", {
      style: {
        width: "100%",
        height: "100%",
        display: "flex",
        flexDirection: "column",
        background: "#0b0b0b",
        color: "#fff",
        padding: 56,
        fontFamily: "system-ui, -apple-system, Segoe UI, Roboto, Arial",
        justifyContent: "space-between",
      }
    },
      E("div", { style: { display: "flex", flexDirection: "column", gap: 12 } },
        E("div", { style: { display: "flex", alignItems: "center", gap: 14 } },
          E("div", { style: { width: 56, height: 56, borderRadius: 999, border: "6px solid #22c55e", boxSizing: "border-box" } }),
          E("div", { style: { display: "flex", flexDirection: "column" } },
            E("div", { style: { fontSize: 42, fontWeight: 900, letterSpacing: 1 } }, "ECO"),
            E("div", { style: { fontSize: 20, opacity: 0.85 } }, "Recibo é lei • Cuidado é coletivo")
          )
        ),
        E("div", { style: { marginTop: 20, fontSize: 34, fontWeight: 900 } }, "Fechamento do dia"),
        E("div", { style: { fontSize: 26, opacity: 0.9 } }, day)
      ),

      E("div", {
        style: {
          display: "flex",
          flexDirection: "column",
          gap: 16,
          background: "rgba(255,255,255,0.06)",
          border: "1px solid rgba(255,255,255,0.12)",
          borderRadius: 18,
          padding: 26,
        }
      },
        E("div", { style: { fontSize: 30, fontWeight: 900 } }, "Resumo"),
        E("div", { style: { display: "flex", flexWrap: "wrap", gap: 14, fontSize: 24 } },
          pill("Total", stats.total, "rgba(34,197,94,0.15)"),
          pill("NEW", stats.NEW, "rgba(255,255,255,0.08)"),
          pill("IN_ROUTE", stats.IN_ROUTE, "rgba(255,255,255,0.08)"),
          pill("DONE", stats.DONE, "rgba(34,197,94,0.22)"),
          pill("CANCELED", stats.CANCELED, "rgba(239,68,68,0.22)"),
          stats.OTHER ? pill("OUTROS", stats.OTHER, "rgba(255,255,255,0.08)") : null
        )
      ),

      E("div", { style: { fontSize: 18, opacity: 0.8 } }, "#ECO — Escutar • Cuidar • Organizar")
    );

  return new ImageResponse(root as any, { width, height });
}
"@

# tenta preservar os placeholders do arquivo existente (se vieram do STEP 36c)
$curr = Get-Content -LiteralPath $routeFile -Raw
function ExtractPlaceholder([string]$name, [string]$fallback){
  if($curr -match ("const\s+" + [regex]::Escape($name) + "\s*=\s*`"([^`"]+)`";")){
    return $Matches[1]
  }
  return $fallback
}

# se o arquivo atual tiver as strings já “resolvidas”, reaproveita; senão mantém defaults
$MODEL = ExtractPlaceholder "MODEL" "pickupRequest"
$ROUTE_FIELD = ExtractPlaceholder "ROUTE_FIELD" "routeDay"
$STATUS_FIELD = ExtractPlaceholder "STATUS_FIELD" "status"

$ts = $ts.Replace("__PICKUP_DELEGATE__", $MODEL)
$ts = $ts.Replace("__ROUTE_FIELD__", $ROUTE_FIELD)
$ts = $ts.Replace("__STATUS_FIELD__", $STATUS_FIELD)

WriteUtf8NoBom $routeFile $ts

$log += "## PATCH"
$log += ("Backup: {0}" -f ($bk ? $bk : "(nenhum)"))
$log += "- OK: route-day-card reescrito sem JSX (React.createElement)."
$log += ""
$log += "## VERIFY"
$log += "1) Reinicie o dev (CTRL+C): npm run dev"
$log += "2) Teste:"
$log += "   - /api/share/route-day-card?day=2025-12-26&format=3x4"
$log += "   - /api/share/route-day-card?day=2025-12-26&format=1x1"
$log += "3) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1"

WriteUtf8NoBom $rep ($log -join "`n")

Write-Host ("✅ STEP 36d aplicado. Report -> {0}" -f $rep) -ForegroundColor Green
Write-Host "PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "1) Reinicie o dev (CTRL+C): npm run dev" -ForegroundColor Yellow
Write-Host "2) Abra /api/share/route-day-card?day=2025-12-26&format=3x4" -ForegroundColor Yellow
Write-Host "3) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1" -ForegroundColor Yellow