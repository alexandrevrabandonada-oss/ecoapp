# ECO — STEP 33 — Share Pack (ZIP) do Recibo (3x4 + 1x1 + textos)

Data: 2025-12-25 21:26:12
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG
ReceiptShareBar: src/components/eco/ReceiptShareBar.tsx
package.json   : package.json

## PATCH
- INFO: jszip não encontrado no package.json -> npm i jszip
- OK: npm i jszip
- OK: criado/atualizado src\app\api\share\receipt-pack\route.ts
- Backup ReceiptShareBar: tools/_patch_backup/20251225-212615-src_components_eco_ReceiptShareBar.tsx
- OK: helpers STEP33 inseridos após STEP32_LINK_HELPERS_END.
- OK: inseri botão 'Baixar pack (ZIP)'.

## VERIFY
1) Reinicie o dev (CTRL+C): npm run dev
2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1
3) Teste manual:
   - Abra /r/[code]
   - Clique 'Baixar pack (ZIP)' e confira o zip (2 PNG + textos)
   - (Opcional) abra /api/share/receipt-pack?code=[code] direto e veja se baixa
