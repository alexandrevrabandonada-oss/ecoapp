# ECO — STEP 08b — Fix /api/requests (alias para /api/pickup-requests)

Data: 2025-12-23 12:17:01
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG (antes)
Exists src/app/api/requests/route.ts? True
Exists src/app/api/pickup-requests/route.ts? True

## PATCH
Backup: tools/_patch_backup/20251223-121701-src_app_api_requests_route.ts
- Reescrevendo /api/requests para reexportar GET/POST do /api/pickup-requests

## VERIFY
Now exists src/app/api/requests/route.ts? True

## Próximos passos
1) Reinicie o dev (CTRL+C): npm run dev
2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1
3) Abra /chamar e envie um pedido (POST /api/requests não pode mais reclamar de address).
