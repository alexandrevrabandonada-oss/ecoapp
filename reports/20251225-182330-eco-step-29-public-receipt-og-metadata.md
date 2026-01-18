# ECO — STEP 29 — OpenGraph/Twitter metadata em /r/[code]

Data: 2025-12-25 18:23:30
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG
Arquivo alvo: src/app/r/[code]/page.tsx

## PATCH
Backup: tools/_patch_backup/20251225-182330-src_app_r_[code]_page.tsx
- OK: inseri generateMetadata + OpenGraph/Twitter (com metadataBase via headers).

## VERIFY
1) Reinicie o dev (CTRL+C): npm run dev
2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1
3) Teste preview: cole um link /r/[code] no WhatsApp e veja se puxa imagem/título
