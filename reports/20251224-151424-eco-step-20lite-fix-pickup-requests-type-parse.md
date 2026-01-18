# ECO — STEP 20LITE — Fix TS parse em /api/pickup-requests (type AnyDelegate)

Data: 2025-12-24 15:14:24
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG
route.ts: src/app/api/pickup-requests/route.ts

## PATCH
Backup: tools/_patch_backup/20251224-151424-src_app_api_pickup-requests_route.ts

- WARN: não achei a linha exata. Vou aplicar um fallback mais amplo.
- OK: type AnyDelegate corrigido (TS parse).

## Próximos passos
1) Reinicie o dev (CTRL+C): npm run dev
2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1
3) /api/pickup-requests deve voltar 200 (sem parsing error)
