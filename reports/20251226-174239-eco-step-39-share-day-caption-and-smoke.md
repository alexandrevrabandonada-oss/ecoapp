# ECO — STEP 39 — Share do Dia v1 (legenda pronta + smoke dedicado)

Data: 2025-12-26 17:42:39
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG
Client: src/app/s/dia/[day]/DayShareClient.tsx
Smoke : tools/eco-smoke-share-day.ps1

## PATCH — DayShareClient.tsx
Arquivo: src/app/s/dia/[day]/DayShareClient.tsx
Backup : tools/_patch_backup/20251226-174239-src_app_s_dia_[day]_DayShareClient.tsx

- OK: DayShareClient.tsx atualizado (legenda + copiar).

## PATCH — tools/eco-smoke-share-day.ps1
Arquivo: tools/eco-smoke-share-day.ps1
Backup : (novo)

- OK: eco-smoke-share-day.ps1 criado/atualizado.

## VERIFY
1) Reinicie o dev (CTRL+C): npm run dev
2) Abra: /s/dia/2025-12-26 e teste: copiar legenda + baixar 3:4/1:1
3) Rode: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke-share-day.ps1
