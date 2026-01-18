# ECO — STEP 16c — Fix syntax do guard de recibo (route.ts)

Data: 2025-12-23 16:58:42
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG
API receipts: src/app/api/receipts/route.ts
Has guard marker? True

## PATCH
Backup API: tools/_patch_backup/20251223-165842-src_app_api_receipts_route.ts

- OK: Bloco ECO_RECEIPTS_PUBLIC_GUARD_V1 reescrito com TypeScript válido.

## Próximos passos
1) Reinicie o dev (CTRL+C): npm run dev
2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1
3) /api/services deve voltar 200 (compile OK)
4) Teste recibo privado com ECO_OPERATOR_TOKEN: em aba anônima deve dar 404
