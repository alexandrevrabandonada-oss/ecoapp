# eco-step-119-fix-muralclient-sort-syntax-v0_1

- Time: 20260114-113826
- Backup: C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20260114-113826-eco-step-119-fix-muralclient-sort-syntax-v0_1

## What/Why
- Corrige sintaxe quebrada no MuralClient (arr try + .sort).
- Corrige p. dentro do primeiro arr.sort para a. (evita 'p is not defined').
- Cria alias /api/eco/points2 -> /api/eco/points (evita 404).

## Patched
- src/app/eco/mural/MuralClient.tsx
- src/app/api/eco/points2/route.ts

## Verify
1) Ctrl+C -> npm run dev
2) abrir /eco/mural (não pode mais dar erro de parse nem 'p is not defined')
3) irm 'http://localhost:3000/api/eco/points2?limit=1' | ConvertTo-Json -Depth 30
