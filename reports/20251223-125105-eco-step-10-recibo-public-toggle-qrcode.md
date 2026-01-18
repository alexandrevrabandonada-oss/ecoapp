# ECO — STEP 10 — Toggle público no recibo + QR Code

Data: 2025-12-23 12:51:05
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG (antes)
api exists?  True
page exists? True

## BACKUPS
Backup api : tools/_patch_backup/20251223-125105-src_app_api_receipts_[code]_route.ts
Backup page: tools/_patch_backup/20251223-125105-src_app_recibo_[code]_page.tsx

- OK: src/app/api/receipts/[code]/route.ts reescrito com GET+PATCH (toggle public)
- OK: src/app/recibo/[code]/page.tsx atualizado (badge público/privado + QR + toggle)

## VERIFY
api exists?  True
page exists? True

## Próximos passos
1) Reinicie o dev (CTRL+C): npm run dev
2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1
3) Abra /recibo/[code] e clique Tornar público/privado
4) Verifique se o badge muda e se o QR abre o recibo
