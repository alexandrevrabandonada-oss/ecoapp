# eco-step-96-points-alias-route-v0_1

- Time: 
20251228-192425
- Backup: 
C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251228-192425-eco-step-96-points-alias-route-v0_1

## Changes
- Added/Updated: src/app/api/eco/points/route.ts
- Behavior: /api/eco/points (GET) delega para /api/eco/points/list2

## Verify
1) Ctrl+C -> npm run dev
2) http://localhost:3000/api/eco/points?limit=10 (200)
3) http://localhost:3000/api/eco/points/list2?limit=10 (200)
4) /eco/mural e /eco/mural/confirmados (se existir) nao devem mais chamar /api/eco/points 404