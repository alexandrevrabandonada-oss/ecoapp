# ECO — STEP 16d — Fix /api/points (rewrite seguro, sem tokens do PowerShell no TS)

Data: 2025-12-23 17:09:41
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG
API points: src/app/api/points/route.ts

## PATCH
Backup API: tools/_patch_backup/20251223-170941-src_app_api_points_route.ts

- OK: Reescrevi /api/points com defaults (city/slug), validação required e enum via Prisma.dmmf.

## Próximos passos
1) Reinicie o dev (CTRL+C): npm run dev
2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1
3) Abra /coleta/novo e crie um ponto: city default deve impedir 500.
