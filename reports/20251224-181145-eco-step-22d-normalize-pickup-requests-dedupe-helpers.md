# ECO — STEP 22d — Normalizar /api/pickup-requests (dedupe helpers/blocks repetidos)

Data: 2025-12-24 18:11:45
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG (antes)
Arquivo: src/app/api/pickup-requests/route.ts
Backup : tools/_patch_backup/20251224-181145-src_app_api_pickup-requests_route.ts
- count function ecoGetToken : 2
- count function ecoIsOperator: 3
- count function ecoWithReceipt: 1
- count marker OP start      : 2
- count marker RECEIPT start : 1
- count marker PRIVACY start : 3

## PATCH
- dedupe block ECO_HELPER_OPERATOR_* removidos: 1
- dedupe block ECO_HELPER_WITH_RECEIPT_* removidos: 0
- dedupe block ECO_PICKUP_RECEIPT_PRIVACY_* removidos: 2
- dedupe function ecoGetToken removidos: 0
- dedupe function ecoIsOperator removidos: 1
- dedupe function ecoWithReceipt removidos: 0

## DIAG (depois)
- count function ecoGetToken : 1
- count function ecoIsOperator: 1
- count function ecoWithReceipt: 1
- count marker OP start      : 1
- count marker RECEIPT start : 1
- count marker PRIVACY start : 1

## VERIFY
1) Reinicie o dev (CTRL+C): npm run dev
2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1
3) /api/pickup-requests deve voltar 200
