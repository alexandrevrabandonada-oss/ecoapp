# eco-step-106-seed-eco-pontos-dev-v0_1

- Time: 
20251229-152123
- Backup: 
C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251229-152123-eco-step-106-seed-eco-pontos-dev-v0_1

## Changes
- Added dev seed route: src/app/api/dev/seed-eco/route.ts
  - cria 3 pontos no model detectado (default ecoCriticalPoint)
  - cria 1 confirm no ponto #1 e 1 support no ponto #2

## Verify
1) npm run dev
2) GET 
http://localhost:3000
/api/dev/seed-eco?n=3&confirm=1&support=1
3) GET 
http://localhost:3000
/api/eco/points?limit=5
4) /eco/mural e /eco/mural/confirmados
