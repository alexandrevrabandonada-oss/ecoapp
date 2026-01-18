# ECO — STEP 37c — Fix Next 16 async params + async headers() em /s/dia/[day]

Data: 2025-12-26 15:43:18
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG
Arquivo: src/app/s/dia/[day]/page.tsx
Backup : tools/_patch_backup/20251226-154318-src_app_s_dia_[day]_page.tsx

## PATCH
- OK: page.tsx reescrito com async params + async headers() (Next 16).

## VERIFY
1) Reinicie o dev: CTRL+C ; npm run dev
2) Abra /s/dia/2025-12-26
3) Confirme que previews chamam day=2025-12-26 (não 2025-01-01)
4) Cole o link no WhatsApp e veja se puxa OG