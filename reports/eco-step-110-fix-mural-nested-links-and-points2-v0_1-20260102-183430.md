# eco-step-110-fix-mural-nested-links-and-points2-v0_1

- Time: 20260102-183430
- Backup: C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20260102-183430-eco-step-110-fix-mural-nested-links-and-points2-v0_1

## What/Why
- Corrige hydration error: remove <a> aninhado dentro de <a> em src/app/eco/mural/page.tsx.
- Troca chamadas antigas /api/eco/points2 -> /api/eco/points para parar 404 no dev log.

## Patched
- src/app/eco/mural/page.tsx
- Files updated (/api/eco/points2 -> /api/eco/points):
  - C:\Projetos\App ECO\eluta-servicos\src\app\eco\mural\MuralClient.tsx

## Verify
1) Ctrl+C -> npm run dev
2) abrir /eco/mural (não pode aparecer 'In HTML, <a> cannot be a descendant of <a>')
3) conferir que sumiu GET /api/eco/points2 404
