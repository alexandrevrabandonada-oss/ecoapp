$ErrorActionPreference = "Stop"

function Backup-File([string]$p) {
  if (Test-Path $p) {
    $ts = Get-Date -Format "yyyyMMdd-HHmmss"
    Copy-Item $p "$p.bak-$ts" -Force
  }
}

Write-Host "== DB INIT + PATCH /api/points ==" -ForegroundColor Cyan

# 1) aplica schema no SQLite (cria as tabelas)
Write-Host ">> prisma db push (criar tabelas no dev.db)" -ForegroundColor Yellow
npx prisma db push --schema=prisma/schema.prisma

# 2) garante client atualizado
Write-Host ">> prisma generate" -ForegroundColor Yellow
npx prisma generate --schema=prisma/schema.prisma

# 3) patch da rota /api/points (remove crash e garante JSON)
$route = "src/app/api/points/route.ts"
if (!(Test-Path $route)) { throw "Não achei $route" }
Backup-File $route

@"
import { NextResponse } from "next/server";
import { prisma } from "../../../lib/prisma";

export async function GET() {
  try {
    const points = await prisma.point.findMany({
      where: { isActive: true },
      include: { service: true },
      orderBy: { createdAt: "desc" },
    });

    return NextResponse.json({ points });
  } catch (err: any) {
    // evita que o frontend receba HTML e quebre JSON.parse
    return NextResponse.json(
      { points: [], error: "DB_ERROR", message: err?.message ?? String(err) },
      { status: 500 }
    );
  }
}
"@ | Set-Content -Encoding UTF8 $route

Write-Host "✅ OK. Agora rode:" -ForegroundColor Green
Write-Host "   npm run dev -- --webpack"
