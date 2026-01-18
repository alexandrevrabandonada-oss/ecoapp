# eco-step-187b — fix id undefined (eco/pontos/[id]) — 20260116-194543

## DIAG
- alvo: C:\Projetos\App ECO\eluta-servicos\src\app\eco\pontos\[id]\page.tsx

## PATCH
- backup: C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\eco-step-187b\20260116-194543-C__Projetos_App ECO_eluta-servicos_src_app_eco_pontos_[id]_page.tsx
- removeu referencia a id inexistente no href do share (usa so params?.id)

## VERIFY
Rode:
- npm run build