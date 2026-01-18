# ECO — STEP 25 — ReceiptLink: público sem token + copiar link

Data: 2025-12-24 19:36:57
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG
ReceiptLink: src/components/eco/ReceiptLink.tsx

## PATCH
Backup: tools/_patch_backup/20251224-193657-src_components_eco_ReceiptLink.tsx
- OK: ReceiptLink.tsx reescrito com suporte a recibo público (/r/[code]) + copiar link.

## VERIFY
1) Reinicie o dev (CTRL+C): npm run dev
2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1
3) Teste /pedidos:
   - aba anônima (sem token): 'Ver recibo' só aparece se receipt.public=true
   - aba normal (com token): 'Ver recibo' aparece mesmo se privado
   - se público: aparece 'Copiar link'