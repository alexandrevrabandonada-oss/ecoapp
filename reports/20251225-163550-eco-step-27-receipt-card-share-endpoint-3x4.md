# ECO — STEP 27 — Card PNG do Recibo (3:4) + API pública sanitizada

Data: 2025-12-25 16:35:50
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG
schema: prisma/schema.prisma
Receipt code field  : code
Receipt public field: public
Receipt date field  : createdAt

## PATCH
- Node route: src/app/api/receipts/public/route.ts
  Backup: (novo)
  - OK: route escrita.

- Edge route: src/app/api/share/receipt-card/route.ts
  Backup: (novo)
  - OK: route escrita.

- Update: src/components/eco/ReceiptShareBar.tsx
  Backup: tools/_patch_backup/20251225-163551-src_components_eco_ReceiptShareBar.tsx
  - OK: botão inserido.

## VERIFY
1) Reinicie o dev (CTRL+C): npm run dev
2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1
3) Pegue um receipt code público e teste:
   - GET /api/receipts/public?code=SEU_CODE (200)
   - Abrir /api/share/receipt-card?code=SEU_CODE&format=3x4 (gera PNG)
   - Em /r/[code], clique 'Baixar card 3:4'