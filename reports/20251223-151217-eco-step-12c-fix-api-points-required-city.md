# ECO — STEP 12c — Fix /api/points: city obrigatório

Data: 2025-12-23 15:12:17
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG
API points: src/app/api/points/route.ts
Backup: tools/_patch_backup/20251223-151217-src_app_api_points_route.ts

## PATCH
- OK: /api/points POST agora sempre envia city (body.city ou ECO_DEFAULT_CITY ou 'Volta Redonda')
- OK: mantém slug auto + include service

## Próximos passos
1) (opcional) setar .env: ECO_DEFAULT_CITY=Volta Redonda
2) npm run dev
3) pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1
4) /coleta/novo -> criar ponto (não pode mais dar 'Argument city is missing')
