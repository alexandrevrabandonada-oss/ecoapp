# ECO — STEP 23a — /operador (token) + ReceiptLink busca code via API

Data: 2025-12-24 18:28:48
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG
ReceiptLink.tsx: src/components/eco/ReceiptLink.tsx
Token localStorage key (detectado): eco_operator_token
Operador page: src/app/operador/page.tsx
API receipt endpoint: src/app/api/pickup-requests/[id]/receipt/route.ts

## PATCH
- Backup /operador: (novo)
- OK: /operador criado/atualizado.
- Backup API receipt: (novo)
- OK: endpoint /api/pickup-requests/[id]/receipt criado.
- Backup ReceiptLink: tools/_patch_backup/20251224-182848-src_components_eco_ReceiptLink.tsx
- OK: ReceiptLink.tsx atualizado (busca code via API + token).

## VERIFY
1) Reinicie o dev (CTRL+C): npm run dev
2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1
3) Abra /operador -> salve token -> abra /pedidos e veja 'Ver recibo'.
4) Aba anônima: /pedidos não deve mostrar 'Ver recibo'.
5) Teste rápido do endpoint:
   - Com token: GET /api/pickup-requests/<id>/receipt -> 200 {code}
   - Sem token: se receipt não for public -> 404