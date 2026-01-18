# ECO — STEP 28c — ReceiptShareBar: 1:1 + Web Share PNG (safe markers)

Data: 2025-12-25 21:42:04
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG
Arquivo: src/components/eco/ReceiptShareBar.tsx
Backup: tools/_patch_backup/20251225-214204-src_components_eco_ReceiptShareBar.tsx

## PATCH
- OK: removi blocos antigos do STEP 28 (markers).
- OK: helpers inseridos após onCard3x4.
- OK: botões 1:1 + compartilhar inseridos após 'Baixar card 3:4'.

## VERIFY
1) Reinicie o dev (CTRL+C): npm run dev
2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1
3) Abra /r/[code] e teste:
   - Baixar card 3:4 / 1:1
   - Compartilhar 3:4 / 1:1 (no celular/PWA deve abrir share sheet; no desktop cai em download)
