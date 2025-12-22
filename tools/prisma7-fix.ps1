$ErrorActionPreference = "Stop"

function Backup-File {
  param([string]$p)
  if (Test-Path $p) {
    $ts = Get-Date -Format "yyyyMMdd-HHmmss"
    Copy-Item $p "$p.bak-$ts" -Force
  }
}

Write-Host "== Prisma 7 repair ==" -ForegroundColor Cyan
Write-Host ("node  : " + (node -v))
Write-Host ("npm   : " + (npm -v))

$schemaPath = "prisma/schema.prisma"
if (!(Test-Path $schemaPath)) { throw "Não achei $schemaPath" }

Backup-File $schemaPath
$txt = Get-Content $schemaPath -Raw

function Expand-OneLineEnum {
  param([string]$t, [string]$name)
  $pattern = "(?ms)enum\s+$name\s*\{\s*([^}]+?)\s*\}"
  return [regex]::Replace($t, $pattern, {
    param($m)
    $vals = ($m.Groups[1].Value -replace "\s+", " ").Trim().Split(" ", [System.StringSplitOptions]::RemoveEmptyEntries)
    $body = ($vals | ForEach-Object { "  $_" }) -join "`n"
    return "enum $name {`n$body`n}"
  })
}

# Corrige enums em 1 linha (o seu erro P1012)
$txt = Expand-OneLineEnum $txt "ServiceKind"
$txt = Expand-OneLineEnum $txt "MaterialKind"

# Prisma 7: datasource.url sai do schema (vai pro prisma.config.ts) 
$provider = "sqlite"
if ($txt -match "(?ms)datasource\s+db\s*\{.*?provider\s*=\s*""([^""]+)""") { $provider = $Matches[1] }

$dsNew = "datasource db {`n  provider = ""$provider""`n}`n"
if ($txt -match "(?ms)datasource\s+db\s*\{.*?\}") {
  $txt = [regex]::Replace($txt, "(?ms)datasource\s+db\s*\{.*?\}", $dsNew)
} else {
  $txt = $dsNew + "`n" + $txt
}

# Garante generator client com prisma-client-js + driverAdapters (adapter do SQLite) 
$genPattern = "(?ms)generator\s+client\s*\{.*?\}"
if ($txt -match $genPattern) {
  $txt = [regex]::Replace($txt, $genPattern, {
    param($m)
    $b = $m.Value

    if ($b -match 'provider\s*=') {
      $b = [regex]::Replace($b, 'provider\s*=\s*""[^""]+""', 'provider = "prisma-client-js"')
    } else {
      $b = $b -replace '\{', "{`n  provider = ""prisma-client-js"""
    }

    if ($b -match 'previewFeatures\s*=') {
      if ($b -notmatch 'driverAdapters') {
        $b = [regex]::Replace($b, 'previewFeatures\s*=\s*\[([^\]]*)\]', {
          param($mm)
          $inside = $mm.Groups[1].Value.Trim()
          if ([string]::IsNullOrWhiteSpace($inside)) { return 'previewFeatures = ["driverAdapters"]' }
          return "previewFeatures = [$inside, ""driverAdapters""]"
        })
      }
    } else {
      $b = $b -replace '(provider\s*=\s*"prisma-client-js".*)', '$1' + "`n  previewFeatures = [""driverAdapters""]"
    }

    return $b
  })
} else {
  $txt = "generator client {`n  provider = ""prisma-client-js""`n  previewFeatures = [""driverAdapters""]`n}`n`n" + $txt
}

Set-Content -Encoding UTF8 -Path $schemaPath -Value $txt
Write-Host "✅ schema.prisma atualizado" -ForegroundColor Green

# Prisma 7: config file define schema + datasource.url + carregar dotenv manualmente 
$configPath = "prisma.config.ts"
Backup-File $configPath
@"
import 'dotenv/config'
import { defineConfig, env } from 'prisma/config'

export default defineConfig({
  schema: 'prisma/schema.prisma',
  datasource: {
    url: env('DATABASE_URL'),
  },
})
"@ | Set-Content -Encoding UTF8 -Path $configPath
Write-Host "✅ prisma.config.ts atualizado" -ForegroundColor Green

Write-Host ">> Instalando adapter SQLite (Prisma 7)..." -ForegroundColor Cyan
npm i @prisma/adapter-better-sqlite3 better-sqlite3 dotenv

# Prisma singleton (evita múltiplas instâncias em dev) + adapter do SQLite 
$libDir = "src/lib"
New-Item -ItemType Directory -Force $libDir | Out-Null
$prismaLib = "src/lib/prisma.ts"
Backup-File $prismaLib
@"
import { PrismaClient } from '@prisma/client'
import { PrismaBetterSqlite3 } from '@prisma/adapter-better-sqlite3'

const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient }

export const prisma =
  globalForPrisma.prisma ??
  new PrismaClient({
    adapter: new PrismaBetterSqlite3({
      url: process.env.DATABASE_URL || 'file:./prisma/dev.db',
    }),
  })

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma
"@ | Set-Content -Encoding UTF8 -Path $prismaLib
Write-Host "✅ src/lib/prisma.ts criado/atualizado" -ForegroundColor Green

# Patch do endpoint que está quebrando no log: src/app/api/points/route.ts
$route = "src/app/api/points/route.ts"
if (Test-Path $route) {
  Backup-File $route
  $r = Get-Content $route -Raw

  # remove import PrismaClient e instancia local
  $r = [regex]::Replace($r,'(?m)^\s*import\s+\{\s*PrismaClient\s*\}\s+from\s+["'']@prisma\/client["'']\s*;?\s*$','')
  $r = [regex]::Replace($r,'(?m)^\s*import\s+PrismaClient\s+from\s+["'']@prisma\/client["'']\s*;?\s*$','')
  $r = [regex]::Replace($r,'(?m)^\s*(const|let|var)\s+prisma\s*=\s*new\s+PrismaClient\([^;]*\)\s*;?\s*$','')

  if ($r -notmatch "from\s+['""]\.\.\/\.\.\/\.\.\/lib\/prisma['""]") {
    $r = "import { prisma } from '../../../lib/prisma'`n" + $r
  }

  Set-Content -Encoding UTF8 -Path $route -Value $r
  Write-Host "✅ points/route.ts ajustado pra usar singleton" -ForegroundColor Green
} else {
  Write-Host "(!) Não achei $route (pulei patch da rota)." -ForegroundColor Yellow
}

Write-Host ">> Rodando prisma generate (agora é explícito no Prisma 7)..." -ForegroundColor Cyan
npx prisma generate

Write-Host ">> Sanity check: require('@prisma/client')" -ForegroundColor Cyan
node -e "require('@prisma/client'); console.log('OK: @prisma/client carregou');"

Write-Host ""
Write-Host "✅ Pronto. Agora suba assim (por enquanto):" -ForegroundColor Green
Write-Host "   npm run dev -- --webpack"
