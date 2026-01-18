# ECO — STEP 21e — Fix /api/pickup-requests (dedupe ecoWithReceipt + reinject limpo)

Data: 2025-12-24 17:19:09
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG
schema: prisma/schema.prisma
PickupRequest.receipt field: receipt
Receipt select: code: true, public: true

## PATCH
Arquivo: src/app/api/pickup-requests/route.ts
Backup : tools/_patch_backup/20251224-171909-src_app_api_pickup-requests_route.ts
- OK: removi ecoWithReceipt antigos (len 6862 -> 6082).
- OK: reinjetei UM helper ecoWithReceipt.
- WARN: não achei delegate.findMany(...) para embrulhar (talvez não use 'delegate').

## VERIFY
1) Reinicie o dev (CTRL+C): npm run dev
2) Rode: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1
3) /api/pickup-requests deve voltar 200
