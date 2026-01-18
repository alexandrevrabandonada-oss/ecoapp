# ECO — STEP 21d — Recover /api/pickup-requests + ReceiptLink client com token

Data: 2025-12-24 17:11:37
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG
route: src/app/api/pickup-requests/route.ts
backup escolhido: C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251224-163550-src_app_api_pickup-requests_route.ts

## PATCH — route.ts
Backup do estado atual: tools/_patch_backup/20251224-171137-src_app_api_pickup-requests_route.ts
OK: route.ts restaurado a partir de: C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251224-163550-src_app_api_pickup-requests_route.ts

## PATCH — componente
OK: criado src/components/eco/ReceiptLink.tsx

## PATCH — página
arquivo: src/app/chamar/sucesso/page.tsx
backup : tools/_patch_backup/20251224-171137-src_app_chamar_sucesso_page.tsx
- OK: import ReceiptLinkFromItem inserido.
- OK: 'Ver recibo' agora só aparece com token (ReceiptLinkFromItem) | map var: item

## VERIFY
1) Reinicie o dev (CTRL+C): npm run dev
2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1
3) /api/pickup-requests deve voltar 200
4) Página do STEP 19: 'Ver recibo' só aparece se houver token no localStorage (aba anônima deve sumir)
