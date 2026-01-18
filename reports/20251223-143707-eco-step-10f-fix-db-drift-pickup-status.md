# ECO — STEP 10f — Fix drift DB (PickupRequest.status missing)

Data: 2025-12-23 14:37:07
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG
Schema: prisma/schema.prisma
DB (backup): tools/_patch_backup/20251223-143707-C__Projetos_App ECO_eluta-servicos_prisma_dev.db

## PATCH
- Tentando: npx prisma db push (sync schema->DB)


## VERIFY
- Rodando: npx prisma generate

## Próximos passos
1) Reinicie o dev (CTRL+C): npm run dev
2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1
3) Confirme /api/pickup-requests = 200
