# ECO — STEP 13c — Chave opcional de operador (emitir + toggle recibo)

Data: 2025-12-23 15:26:37
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG
API receipts : src/app/api/receipts/route.ts
Recibo client: src/app/recibo/[code]/recibo-client.tsx
Fechar client: src/app/pedidos/fechar/[id]/fechar-client.tsx

## PATCH
Backup API    : tools/_patch_backup/20251223-152637-src_app_api_receipts_route.ts
Backup Recibo : tools/_patch_backup/20251223-152637-src_app_recibo_[code]_recibo-client.tsx
Backup Fechar : tools/_patch_backup/20251223-152637-src_app_pedidos_fechar_[id]_fechar-client.tsx

- OK: /api/receipts POST/PATCH agora respeitam ECO_OPERATOR_TOKEN (opcional).
- OK: /pedidos/fechar/[id] agora envia token opcional no POST /api/receipts

- OK: /recibo/[code] toggle agora envia token opcional no PATCH /api/receipts

## Como usar
- (Opcional) Crie no .env: ECO_OPERATOR_TOKEN=uma-chave-forte
- Sem essa env: tudo continua funcionando aberto (MVP).
- Com essa env: POST/PATCH /api/receipts exigem token (campo nas telas).

## Próximos passos
1) npm run dev
2) pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1
3) /pedidos -> Fechar -> emitir recibo (com/sem token)
4) /recibo/[code] -> toggle público/privado (com/sem token)
