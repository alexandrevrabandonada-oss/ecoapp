# ECO — STEP 21c3 — Dedupe ecoWithReceipt no /api/pickup-requests

Data: 2025-12-24 16:35:50
PWD : C:\Projetos\App ECO\eluta-servicos

route: src/app/api/pickup-requests/route.ts
backup: tools/_patch_backup/20251224-163550-src_app_api_pickup-requests_route.ts

## DIAG
ocorrências de ecoWithReceipt: 2

## PATCH
- removidas duplicatas: 1
- mantida apenas 1 definição de ecoWithReceipt()

## VERIFY
1) Reinicie o dev (CTRL+C): npm run dev
2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1
3) /api/pickup-requests deve voltar 200 (sem erro de 'defined multiple times')
