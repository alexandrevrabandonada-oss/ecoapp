# eco-step-97-fix-points-list2-and-confirmados-v0_1

- Time: 
20251228-200527
- Backup: 
C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251228-200527-eco-step-97-fix-points-list2-and-confirmados-v0_1

## Changes
- Rewrote: src/app/api/eco/points/list2/route.ts (remove multiline strings; add counts.confirm; support base=confirmados/chamados)
- Added:  src/app/eco/mural/confirmados/page.tsx
- Patched (best-effort): src/app/eco/mural/page.tsx (button Confirmados)
- Patched (best-effort): src/app/eco/mural/MuralClient.tsx (send base= in fetch)

## Verify
1) Ctrl+C -> npm run dev
2) http://localhost:3000/api/eco/points/list2?limit=10  (200)
3) http://localhost:3000/api/eco/points/list2?limit=50&base=confirmados (200, items com counts.confirm > 0)
4) http://localhost:3000/eco/mural (botao Confirmados)
5) http://localhost:3000/eco/mural/confirmados
6) Network: veja /api/eco/points/list2 ... base=...