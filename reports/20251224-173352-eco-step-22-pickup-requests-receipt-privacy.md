# ECO — STEP 22 — Privacidade do receipt em /api/pickup-requests

Data: 2025-12-24 17:33:52
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG
schema: prisma/schema.prisma
PickupRequest receipt field: receipt
Receipt public field: public

## PATCH
Arquivo: src/app/api/pickup-requests/route.ts
Backup : tools/_patch_backup/20251224-173352-src_app_api_pickup-requests_route.ts
- OK: helper ecoIsOperator inserido (idempotente).
- OK: bloco de privacidade inserido antes do return de items.

## VERIFY
1) Reinicie o dev (CTRL+C): npm run dev
2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1
3) Teste /pedidos: operador vê recibo privado; anônimo só vê recibo public.
