# ECO — STEP 50C — Prisma drift (SQLite) reset seguro

Data: 2025-12-27 11:00:34
PWD : C:\Projetos\App ECO\eluta-servicos

## BACKUP
Backup dev.db -> tools/_db_backup/20251227-110034-dev.db

## RESET + MIGRATE
- Rodando: prisma migrate reset --force
Prisma schema loaded from prisma\schema.prisma
Datasource "db": SQLite database "dev.db" at "file:./dev.db"

Database reset successful


Running generate... (Use --skip-generate to skip the generators)
[2K[1A[2K[GRunning generate... - Prisma Client
[2K[1A[2K[GÔ£ö Generated Prisma Client (v6.19.1) to .\node_modules\@prisma\client in 73ms


- Rodando: prisma migrate dev (aplica migrations)
Prisma schema loaded from prisma\schema.prisma
Datasource "db": SQLite database "dev.db" at "file:./dev.db"

[2K[1G[36m?[39m [1mEnter a name for the new migration:[22m [90m┬╗[39m 78[2K[1G[2K[1G[32mÔêÜ[39m [1mEnter a name for the new migration:[22m [90m...[39m 78
[?25hApplying migration `20251227140551`

The following migration(s) have been created and applied from new schema changes:

prisma\migrations/
  ÔööÔöÇ 20251227140551/
    ÔööÔöÇ migration.sql

Your database is now in sync with your schema.

Running generate... (Use --skip-generate to skip the generators)
[2K[1A[2K[GRunning generate... - Prisma Client
[2K[1A[2K[GÔ£ö Generated Prisma Client (v6.19.1) to .\node_modules\@prisma\client in 93ms



- Rodando: prisma generate
Prisma schema loaded from prisma\schema.prisma

Ô£ö Generated Prisma Client (v6.19.1) to .\node_modules\@prisma\client in 75ms

Start by importing your Prisma Client (See: https://pris.ly/d/importing-client)

Tip: Want to turn off tips and other hints? https://pris.ly/tip-4-nohints


✅ OK: reset + migrate + generate concluídos.
