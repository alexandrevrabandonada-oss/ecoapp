# eco-step-191 — fix ReceiptPublishButton token header — 20260116-205358

## DIAG
alvo: src\components\eco\ReceiptPublishButton.tsx
matches antes: 1

## PATCH
[OK]  trocou header x-eco-token para spread condicional (token ? ... : {}); backup: C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\eco-step-191\20260116-205358\20260116-205358-C__Projetos_App_ECO_eluta-servicos_src_components_eco_ReceiptPublishButton.tsx

## POS
matches depois: 0

## VERIFY
- npm run build
