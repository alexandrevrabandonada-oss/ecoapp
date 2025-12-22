$ErrorActionPreference = "Stop"

function Backup-File([string]$p) {
  if (Test-Path $p) {
    $ts = Get-Date -Format "yyyyMMdd-HHmmss"
    Copy-Item $p "$p.bak-$ts" -Force
  }
}

Write-Host "== Prisma RESET (pin v6 + fix schema) ==" -ForegroundColor Cyan
Write-Host ("node: " + (node -v))
Write-Host ("npm : " + (npm -v))

# --- 0) backups
Backup-File "package.json"
Backup-File "prisma/schema.prisma"
if (Test-Path "prisma.config.ts") { Backup-File "prisma.config.ts" }

# --- 1) schema: remove datasource/generator quebrados + escreve header padrão (Prisma 6)
$schemaPath = "prisma/schema.prisma"
if (!(Test-Path $schemaPath)) { throw "Não achei prisma/schema.prisma" }

$txt = Get-Content $schemaPath -Raw

# remove generator/datasource existentes (qualquer formato)
$txt = [regex]::Replace($txt, '(?ms)^\s*generator\s+client\s*\{.*?\}\s*', '')
$txt = [regex]::Replace($txt, '(?ms)^\s*datasource\s+db\s*\{.*?\}\s*', '')

# força enums em múltiplas linhas (os valores são os que você postou)
$txt = [regex]::Replace($txt, '(?ms)enum\s+ServiceKind\s*\{.*?\}', @"
enum ServiceKind {
  COLETA
  REPARO
  FEIRA
  FORMACAO
  DOACAO
  OUTRO
}
"@)

$txt = [regex]::Replace($txt, '(?ms)enum\s+MaterialKind\s*\{.*?\}', @"
enum MaterialKind {
  PAPEL
  PAPELAO
  PET
  PLASTICO_MISTO
  ALUMINIO
  VIDRO
  FERRO
  ELETRONICOS
  OUTRO
}
"@)

$header = @"
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "sqlite"
  url      = env("DATABASE_URL")
}

"@

$txt = $header + ($txt.TrimStart())
Set-Content -Encoding UTF8 -Path $schemaPath -Value $txt
Write-Host "✅ schema.prisma ajustado (Prisma 6)" -ForegroundColor Green

# --- 2) garante DATABASE_URL no .env
if (!(Test-Path ".env")) { "" | Set-Content -Encoding UTF8 ".env" }
$envTxt = Get-Content ".env" -Raw
if ($envTxt -notmatch '(?m)^\s*DATABASE_URL\s*=') {
  Add-Content -Encoding UTF8 ".env" "`nDATABASE_URL=`"file:./prisma/dev.db`"`n"
  Write-Host "✅ .env: DATABASE_URL criado" -ForegroundColor Green
} else {
  Write-Host "ℹ️ .env já tem DATABASE_URL" -ForegroundColor DarkGray
}

# --- 3) pin Prisma v6 no package.json
node -e "const fs=require('fs'); const p=require('./package.json'); p.dependencies=p.dependencies||{}; p.devDependencies=p.devDependencies||{}; p.dependencies['@prisma/client']='^6.0.0'; p.devDependencies['prisma']='^6.0.0'; fs.writeFileSync('package.json', JSON.stringify(p,null,2));"
Write-Host "✅ package.json: Prisma fixado em v6" -ForegroundColor Green

# --- 4) remove prisma.config.ts (Prisma 7) pra não confundir
if (Test-Path "prisma.config.ts") {
  $ts = Get-Date -Format "yyyyMMdd-HHmmss"
  Rename-Item "prisma.config.ts" "prisma.config.ts.prisma7.bak-$ts"
  Write-Host "✅ prisma.config.ts renomeado (backup)" -ForegroundColor Green
}

# --- 5) limpeza pesada (porque já mexeram em node_modules/.prisma antes)
if (Test-Path ".next") { Remove-Item -Recurse -Force ".next" -ErrorAction SilentlyContinue }
if (Test-Path "node_modules") { Remove-Item -Recurse -Force "node_modules" -ErrorAction SilentlyContinue }
if (Test-Path "package-lock.json") { Remove-Item -Force "package-lock.json" -ErrorAction SilentlyContinue }

Write-Host ">> npm install..." -ForegroundColor Cyan
npm install

Write-Host ">> prisma generate..." -ForegroundColor Cyan
npx prisma -v
npx prisma generate --schema=prisma/schema.prisma

Write-Host ">> sanity require('@prisma/client')..." -ForegroundColor Cyan
node -e "const m=require('@prisma/client'); console.log('OK keys:', Object.keys(m)); console.log('PrismaClient typeof:', typeof m.PrismaClient);"

# --- 6) cria singleton prisma (sem adapter)
$libDir = "src/lib"
New-Item -ItemType Directory -Force $libDir | Out-Null
$prismaLib = "src/lib/prisma.ts"
Backup-File $prismaLib
@"
import { PrismaClient } from '@prisma/client'

const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient }

export const prisma =
  globalForPrisma.prisma ??
  new PrismaClient()

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma
"@ | Set-Content -Encoding UTF8 -Path $prismaLib
Write-Host "✅ src/lib/prisma.ts criado/atualizado" -ForegroundColor Green

# --- 7) patch na rota /api/points pra usar singleton (se existir)
$route = "src/app/api/points/route.ts"
if (Test-Path $route) {
  Backup-File $route
  $r = Get-Content $route -Raw

  # remove PrismaClient import/instância local
  $r = [regex]::Replace($r,'(?m)^\s*import\s+\{\s*PrismaClient\s*\}\s+from\s+["'']@prisma\/client["'']\s*;?\s*$','')
  $r = [regex]::Replace($r,'(?m)^\s*(const|let|var)\s+prisma\s*=\s*new\s+PrismaClient\([^;]*\)\s*;?\s*$','')

  if ($r -notmatch "from\s+['""]\.\.\/\.\.\/\.\.\/lib\/prisma['""]") {
    $r = "import { prisma } from '../../../lib/prisma'`n" + $r
  }

  Set-Content -Encoding UTF8 -Path $route -Value $r
  Write-Host "✅ route.ts (points) usando singleton" -ForegroundColor Green
} else {
  Write-Host "ℹ️ Não achei src/app/api/points/route.ts (pulei patch)" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "✅ Prisma voltou a funcionar. Agora rode:" -ForegroundColor Green
Write-Host "   npm run dev -- --webpack"
