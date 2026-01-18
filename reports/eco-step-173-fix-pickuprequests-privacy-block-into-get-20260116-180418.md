# eco-step-173 — fix pickup-requests privacy block into GET — 20260116-180418

## DIAG
- alvo: src/app/api/pickup-requests/route.ts
- bloco encontrado: sim (START/END)
- modo GET detectado: function
- param detectado: req
- backup: C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\eco-step-173\20260116-180418\route.ts

## PATCH
- removeu o bloco do top-level e reinseriu dentro do handler GET (no inicio do corpo).

## VERIFY
Rode:
- npm run build
- (se existir) pwsh -NoProfile -ExecutionPolicy Bypass -File tools\eco-step-148b-verify-smoke-autodev-v0_1.ps1 -OpenReport
