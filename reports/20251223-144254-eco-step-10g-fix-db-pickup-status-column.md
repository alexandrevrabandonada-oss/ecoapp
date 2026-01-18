# ECO — STEP 10g — Fix DB drift (PickupRequest.status missing)

Data: 2025-12-23 14:42:54
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG
Schema: prisma/schema.prisma
DATABASE_URL: file:./dev.db
SQLite path: C:\Projetos\App ECO\eluta-servicos\dev.db
Prisma CLI: C:\Projetos\App ECO\eluta-servicos\node_modules\.bin\prisma.cmd

## BACKUP
DB não encontrado (ainda) — seguindo assim mesmo.

## PATCH
- Rodando: prisma db push
ExitCode: 

## PATCH (fallback)
- db push falhou. Rodando: prisma db push --force-reset (APAGA o dev.db; backup já foi feito acima se existia)
ExitCode(force-reset): 
