# ECO — STEP 22b — Dedupe bloco de privacidade do receipt em /api/pickup-requests

Data: 2025-12-24 17:59:05
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG
schema: prisma/schema.prisma
PickupRequest receipt field: receipt
Receipt public field: public

## PATCH
Arquivo: src/app/api/pickup-requests/route.ts
Backup : tools/_patch_backup/20251224-175905-src_app_api_pickup-requests_route.ts
- OK: removi blocos marcados ECO_PICKUP_RECEIPT_PRIVACY (len 8596 -> 8596).
- OK: removi possíveis linhas órfãs 'const __eco_isOp = ecoIsOperator(...)'.
- OK: reinjetei bloco de privacidade (único) antes do return.

## VERIFY
1) Reinicie o dev (CTRL+C): npm run dev
2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1
3) /api/pickup-requests deve voltar 200
