# ECO — STEP 07d — Hotfix POST /api/pickup-requests (address compat)

Data: 2025-12-22 22:19:52
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG (model PickupRequest via Prisma.dmmf)
fields: id,createdAt,updatedAt,receipt

Backup: tools/_patch_backup/20251222-221952-src_app_api_pickup-requests_route.ts

## PATCH
- OK: reescrito src/app/api/pickup-requests/route.ts com compat de address

## VERIFY (rápido, se server estiver no ar)
- VERIFY skip/falhou (server off?): Nenhuma conexão pôde ser feita porque a máquina de destino as recusou ativamente. (localhost:3000)
