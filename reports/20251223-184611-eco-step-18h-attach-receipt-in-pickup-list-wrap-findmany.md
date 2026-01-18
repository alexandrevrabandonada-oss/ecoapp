# ECO — STEP 18h — Anexar receipt no list de pickup-requests (wrap findMany)

Data: 2025-12-23 18:46:11
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG
schema: prisma/schema.prisma
receiptField (PickupRequest -> Receipt?): receipt

route: src/app/api/pickup-requests/route.ts

OK: helper inserido após imports.

## PATCH
Backup: tools/_patch_backup/20251223-184611-src_app_api_pickup-requests_route.ts
OK: findMany(ARG) -> findMany(ecoWithReceipt(ARG))

## Resultado esperado
- /api/pickup-requests deve incluir receipt em cada item (via include/select).
- /pedidos deve conseguir mostrar 'Ver recibo' quando existir.

## Próximos passos
1) Reinicie o dev (CTRL+C): npm run dev
2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1
3) Abra /pedidos e verifique se aparece 'Ver recibo' quando houver recibo.
