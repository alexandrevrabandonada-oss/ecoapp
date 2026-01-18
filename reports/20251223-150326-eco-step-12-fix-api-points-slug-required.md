# ECO — STEP 12 — Fix /api/points: slug obrigatório (gerar automaticamente)

Data: 2025-12-23 15:03:26
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG
API points: src/app/api/points/route.ts
Backup: tools/_patch_backup/20251223-150326-src_app_api_points_route.ts

## PATCH
- OK: /api/points POST agora gera slug automaticamente (e tenta unicidade)
- OK: mantém include service e lista via GET
