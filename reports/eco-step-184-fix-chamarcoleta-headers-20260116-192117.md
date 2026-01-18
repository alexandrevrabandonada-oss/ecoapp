# eco-step-184 — fix chamar-coleta headers (ecoAuthHeaders) — 20260116-192117
## DIAG
- alvo: src\app\chamar-coleta\page.tsx
- contains ecoAuthHeaders(): True
- contains headers: ecoAuthHeaders(): True

## PATCH
- backup: C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\eco-step-184\20260116-192117-C__Projetos_App ECO_eluta-servicos_src_app_chamar-coleta_page.tsx
- inseriu bloco ECO_HEADERS_CLEAN_* antes do fetch
- trocou headers: ecoAuthHeaders() -> headers: __ecoHeaders
## VERIFY
Rode:
- npm run build