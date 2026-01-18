# eco-step-172 — fix pickup-requests privacy block placement — 20260116-175739

## DIAG
- alvo: src/app/api/pickup-requests/route.ts
- bloco encontrado: sim (START/END)
- handler GET encontrado: sim
- param detectado: 

## PATCH
- moveu o bloco ECO_PICKUP_RECEIPT_PRIVACY_* para dentro do handler GET (logo apos '{').
- backup: C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\eco-step-172\20260116-175739\C__Projetos_App ECO_eluta-servicos_src_app_api_pickup-requests_route.ts

## VERIFY
Rode:
- npm run build
- (se passar) pwsh -NoProfile -ExecutionPolicy Bypass -File tools\\eco-step-148b-verify-smoke-autodev-v0_1.ps1 -OpenReport
