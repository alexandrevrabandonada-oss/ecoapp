# ECO — STEP 22c — Fix rápido: __eco_isOp duplicado (const/let -> var) em /api/pickup-requests

Data: 2025-12-24 18:04:41
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG
Arquivo: src/app/api/pickup-requests/route.ts
Antes: const=3 | let=0 | var=0

## PATCH
Backup: tools/_patch_backup/20251224-180441-src_app_api_pickup-requests_route.ts
- OK: converti const/let __eco_isOp -> var __eco_isOp.
Depois: const=0 | let=0 | var=3

## VERIFY
1) Reinicie o dev (CTRL+C): npm run dev
2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1
3) /api/pickup-requests deve voltar 200
