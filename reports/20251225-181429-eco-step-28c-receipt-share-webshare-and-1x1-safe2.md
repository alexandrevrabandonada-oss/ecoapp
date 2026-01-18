# ECO — STEP 28c — Web Share (PNG) + Baixar 1:1 (ReceiptShareBar) — SAFE v2

Data: 2025-12-25 18:14:29
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG
Arquivo: src/components/eco/ReceiptShareBar.tsx
Backup : tools/_patch_backup/20251225-181429-src_components_eco_ReceiptShareBar.tsx

Endpoint card: /api/share/receipt-card

## PATCH
- INFO: nenhum bloco STEP28 antigo encontrado.
- len: 1456 -> 1456
- OK: helpers WebShare/1:1 inseridos.
- OK: botões 1:1 + compartilhar inseridos.

## VERIFY
1) Reinicie o dev (CTRL+C): npm run dev
2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1
3) Abra /r/[code] e teste:
   - Baixar card 3:4 / 1:1
   - Compartilhar 3:4 / 1:1 (celular/PWA abre share sheet; desktop baixa)