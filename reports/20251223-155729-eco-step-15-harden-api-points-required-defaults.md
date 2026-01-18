# ECO — STEP 15 — Harden /api/points (defaults + validação de required)

Data: 2025-12-23 15:57:29
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG
API points: src/app/api/points/route.ts
Sentinel já existe? False
Tem Object.keys(data).forEach? True
Tem prisma.point.create(? True

## PATCH
Backup API: tools/_patch_backup/20251223-155729-src_app_api_points_route.ts

- OK: import PrismaClient -> PrismaClient, Prisma
- OK: injetei defaults/required-check (city/uf/state/country condicionais via Prisma.dmmf).

## VERIFY
Sentinel presente? True
Usa Prisma.dmmf?  True

## Como usar
- (Opcional) .env:
  - ECO_DEFAULT_CITY=Volta Redonda
  - ECO_DEFAULT_UF=RJ
  - ECO_DEFAULT_STATE=RJ
  - ECO_DEFAULT_COUNTRY=Brasil
- Se não setar: defaults acima (MVP).

## Próximos passos
1) Reinicie o dev (CTRL+C): npm run dev
2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1
3) Abra /coleta/novo e crie um ponto (não pode mais quebrar em city).
4) Se der 400 missing_required_fields, a API agora te diz exatamente quais campos faltam.
