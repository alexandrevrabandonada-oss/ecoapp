# ECO — STEP 18h2 — Fix: findMany type quebrado + wrap no runtime

Data: 2025-12-23 19:07:51
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG
route: src/app/api/pickup-requests/route.ts

## PATCH
Backup: tools/_patch_backup/20251223-190751-src_app_api_pickup-requests_route.ts
- OK: tipagem findMany (AnyDelegate) corrigida (remove ecoWithReceipt da assinatura).
- OK: delegate.findMany(ARG) -> delegate.findMany(ecoWithReceipt(ARG)).

## Próximos passos
1) Reinicie o dev (CTRL+C): npm run dev
2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1
3) /api/pickup-requests deve voltar 200
