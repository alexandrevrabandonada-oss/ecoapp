# ECO — STEP 05 — Emitir Recibo por Pedido

Data: 2025-12-22 20:59:17
PWD : C:\Projetos\App ECO\eluta-servicos
Node: v22.19.0
npm : 10.9.3

## DIAG
- schema tem Receipt? **True**
- schema tem EcoReceipt? **True**

- Backup src/app/api/receipts/route.ts: tools/_patch_backup/20251222-205918-src_app_api_receipts_route.ts
## PATCH
- OK: src/app/api/receipts/route.ts atualizado (GET + POST emitir)

- OK: criada página /pedidos/fechar/[id]

## VERIFY
- Arquivos existem? apiReceipts=True | fecharPage=True | fecharClient=True

## Próximos passos
1) Reinicie o dev: npm run dev
2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1
3) Teste: abra /pedidos e pegue um id, ou acesse direto /pedidos/fechar/SEU_ID