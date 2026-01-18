# eco-step-111-fix-mural-nav-and-points2-alias-v0_1

- Time: 20260102-205847
- Backup: C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20260102-205847-eco-step-111-fix-mural-nav-and-points2-alias-v0_1

## What/Why
- Evita hydration error de vez: nav do mural vira componente client com next/link (sem <a> aninhado) + destaque da aba ativa.
- Cria alias /api/eco/points2 -> /api/eco/points para compat e parar 404 no log.

## Patched
- src/app/api/eco/points2/route.ts (alias)
- src/app/eco/mural/_components/MuralNavPillsClient.tsx (novo)
- src/app/eco/mural/page.tsx (nav trocado) ✅
- Files updated (/api/eco/points2): none

## Verify
1) Ctrl+C -> npm run dev
2) abrir /eco/mural (não pode aparecer erro de <a> dentro de <a>)
3) irm 'http://localhost:3000/api/eco/points2?limit=5' | ConvertTo-Json -Depth 40  (tem que dar 200)
4) log não pode ter GET /api/eco/points2 404
