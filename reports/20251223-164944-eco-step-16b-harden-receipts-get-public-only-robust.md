# ECO — STEP 16b — Harden Recibos (GET por code respeita público/privado) — robust

Data: 2025-12-23 16:49:44
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG
API receipts : src/app/api/receipts/route.ts
Recibo client: src/app/recibo/[code]/recibo-client.tsx

## PATCH
Backup API    : tools/_patch_backup/20251223-164944-src_app_api_receipts_route.ts
Backup Client : tools/_patch_backup/20251223-164944-src_app_recibo_[code]_recibo-client.tsx

- OK: Guard inserido no GET por code (ECO_OPERATOR_TOKEN opcional, privado não vaza).
- WARN: Não achei a URL padrão do GET no recibo-client. Não alterei o client.

## Próximos passos
1) Reinicie o dev (CTRL+C): npm run dev
2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1
3) Com ECO_OPERATOR_TOKEN no .env: recibo privado deve virar 404 sem token (aba anônima).
4) Preencha a chave no /recibo/[code] para conseguir ver/toggle se for operador.
