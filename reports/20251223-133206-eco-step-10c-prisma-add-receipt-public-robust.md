# ECO — STEP 10c — Prisma: adicionar public Boolean @default(false) no Receipt (parser robusto)

Data: 2025-12-23 13:32:06
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG (antes)
Schema: prisma/schema.prisma
Backup: tools/_patch_backup/20251223-133206-prisma_schema.prisma

Models detectados: PickupRequest, Service, Point, Delivery, Weighing, Receipt, EcoReceipt

Models alvo: Receipt, EcoReceipt

- OK Receipt: field public inserido
- SKIP EcoReceipt: já tem field public

## PATCH
Alterações aplicadas: 1

## FORMAT

## MIGRATE/GENERATE
- npx prisma migrate dev --name eco_receipt_public
- npx prisma generate

## Próximos passos
1) Reinicie o dev (CTRL+C): npm run dev
2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1
3) Abra /recibo/[code] e teste o toggle Público/Privado (STEP 10)
