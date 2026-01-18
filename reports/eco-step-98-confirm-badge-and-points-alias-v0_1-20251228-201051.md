# eco-step-98-confirm-badge-and-points-alias-v0_1

- Time: 
20251228-201051
- Backup: 
C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251228-201051-eco-step-98-confirm-badge-and-points-alias-v0_1

## Changes
- Added/ensured: src/app/api/eco/points/route.ts (alias -> list2) para evitar 404 legado
- Patched: src/app/eco/_components/PointActionsInline.tsx (badge ✅ CONFIRMADO + numero via counts.confirm)

## Verify
1) Ctrl+C -> npm run dev
2) http://localhost:3000/api/eco/points?limit=10  (200; alias)
3) Abra /eco/mural e /eco/mural/confirmados: cards com confirmacao devem mostrar ✅ CONFIRMADO (N)
4) DevTools/Network: confirme que /api/eco/points ou /api/eco/points/list2 responde 200