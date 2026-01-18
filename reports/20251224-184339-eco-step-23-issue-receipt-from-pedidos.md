# ECO — STEP 23 — Emitir recibo a partir do /pedidos

Data: 2025-12-24 18:43:39
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG
schema: prisma/schema.prisma
Receipt.code field: code
Receipt.public field: public
Receipt required fields (sem default): 2
- code : String
- requestId : String

## PATCH — API
arquivo: src\app\api\pickup-requests\[id]\receipt\route.ts
backup : tools/_patch_backup/20251224-184339-src_app_api_pickup-requests_[id]_receipt_route.ts
- OK: criado endpoint POST /api/pickup-requests/[id]/receipt.

## PATCH — UI (client component)
arquivo: src/components/eco/IssueReceiptButton.tsx
- OK: criado IssueReceiptButton.tsx (client) com token + POST endpoint.

## PATCH — Página (/pedidos)
arquivo: src/app/chamar/sucesso/page.tsx
backup : tools/_patch_backup/20251224-184339-src_app_chamar_sucesso_page.tsx
- OK: inseri <IssueReceiptButtonFromItem item={item} /> antes do ReceiptLinkFromItem.

## VERIFY
1) Reinicie o dev (CTRL+C): npm run dev
2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1
3) Abra /pedidos (ou /chamar/sucesso): em pedido SEM recibo, deve aparecer 'Emitir recibo' (apenas com token).
4) Clique 'Emitir recibo' -> página recarrega e aparece 'Ver recibo'.
5) Link abre /recibos/[code] normalmente.

## REGISTRO
- Endpoints adicionados:
  - POST /api/pickup-requests/[id]/receipt
- UI adicionada:
  - src/components/eco/IssueReceiptButton.tsx
  - botão injetado em src/app/chamar/sucesso/page.tsx (perto do ReceiptLink)
