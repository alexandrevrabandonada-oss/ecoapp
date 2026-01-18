# ECO — STEP 10d — Prisma CLI + migrate/generate (sem npx)

Data: 2025-12-23 13:59:34
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG
Schema: prisma/schema.prisma
Receipt/Recibo tem field public? True
Prisma bin exists? True

## RUN
Usando bin: C:\Projetos\App ECO\eluta-servicos\node_modules\.bin\prisma.cmd

### prisma format
Prisma schema loaded from prisma\schema.prisma
Formatted prisma\schema.prisma in 17ms ­ƒÜÇ

### prisma migrate dev --name eco_receipt_public
Prisma schema loaded from prisma\schema.prisma
Datasource "db": SQLite database "dev.db" at "file:./dev.db"

Drift detected: Your database schema is not in sync with your migration history.

The following is a summary of the differences between the expected database schema given your migrations files, and the actual schema of the database.

It should be understood as the set of changes to get from the expected schema to the actual schema.

If you are running this the first time on an existing database, please make sure to read this documentation page:
https://www.prisma.io/docs/guides/database/developing-with-prisma-migrate/troubleshooting-development

[+] Added tables
  - Delivery
  - PickupRequest
  - Point
  - Receipt
  - Service
  - Weighing

[*] Changed the `Point` table
  [+] Added unique index on columns (slug)

[*] Changed the `Receipt` table
  [+] Added unique index on columns (requestId)
  [+] Added unique index on columns (code)

[*] Changed the `Service` table
  [+] Added unique index on columns (slug)

We need to reset the SQLite database "dev.db" at "file:./dev.db"

You may use prisma migrate reset to drop the development database.
All data will be lost.

### prisma generate
Prisma schema loaded from prisma\schema.prisma

Ô£ö Generated Prisma Client (v6.19.1) to .\node_modules\@prisma\client in 67ms

Start by importing your Prisma Client (See: https://pris.ly/d/importing-client)

Tip: Want to turn off tips and other hints? https://pris.ly/tip-4-nohints


## Próximos passos
1) Reinicie o dev (CTRL+C): npm run dev
2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1
3) Abra /recibo/[code] (STEP 10: toggle público/privado vem já já)
