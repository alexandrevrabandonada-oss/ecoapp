# ECO — STEP 23b — Recibo público/privado + botão publicar + link sem token quando público

Data: 2025-12-24 19:04:01
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG
ReceiptLink: src/components/eco/ReceiptLink.tsx
Token key: eco_token
Schema: prisma/schema.prisma
Receipt code field: code
Receipt public field: public
API dyn folder: [code] (param: code)
API toggle path: src\app\api\receipts\[code]\public\route.ts

## PATCH
Backup: 
- OK: ReceiptPublishButton criado/atualizado.
Backup: 
- OK: API toggle criada/atualizada.
Backup: tools/_patch_backup/20251224-190401-src_components_eco_ReceiptLink.tsx
- OK: ReceiptLinkFromItem agora deixa link sem token quando recibo é público.
Backup: tools/_patch_backup/20251224-190401-src_app_chamar_sucesso_page.tsx
- OK: botão publicar/privado inserido ao lado do link.

## VERIFY
1) Reinicie o dev (CTRL+C): npm run dev
2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1
3) /chamar/sucesso: com token aparece botão Publicar/Tornar privado
4) Aba anônima: link Ver recibo só aparece se recibo estiver público
5) API: PATCH /api/receipts/{param}/public (somente operador)