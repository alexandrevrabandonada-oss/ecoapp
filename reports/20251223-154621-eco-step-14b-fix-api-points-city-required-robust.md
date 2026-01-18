# ECO — STEP 14b — Fix /api/points (city required) via data.city antes do cleanup

Data: 2025-12-23 15:46:21
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG
API points: src/app/api/points/route.ts
Tem city em algum lugar? True
Tem data.city? False

## PATCH
Backup API: tools/_patch_backup/20251223-154621-src_app_api_points_route.ts

- OK: injetei city antes do Object.keys(data).forEach (ponto certo).

## Como usar
- (Opcional) No .env: ECO_DEFAULT_CITY=Volta Redonda
- Se não setar, default = 'Volta Redonda' (MVP).

## Próximos passos
1) Reinicie o dev (CTRL+C): npm run dev
2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1
3) Abra /coleta/novo e crie um ponto (POST /api/points sem erro city)
