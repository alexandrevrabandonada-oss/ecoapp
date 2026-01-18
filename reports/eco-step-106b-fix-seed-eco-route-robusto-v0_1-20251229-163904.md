# eco-step-106b-fix-seed-eco-route-robusto-v0_1

- Time: 20251229-163904
- Backup: C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251229-163904-eco-step-106b-fix-seed-eco-route-robusto-v0_1
- Patched: src/app/api/dev/seed-eco/route.ts

## Why
- O seed antigo quebrava com model_block_not_found (parser fragil de schema).
- Este seed detecta models via Prisma + descobre colunas via PRAGMA table_info (SQLite).

## Verify
1) npm run dev
2) irm 'http://localhost:3000/api/dev/seed-eco?n=3&confirm=1&support=1' | ConvertTo-Json -Depth 50
3) irm 'http://localhost:3000/api/eco/points?limit=5' | ConvertTo-Json -Depth 80
4) /eco/mural e /eco/mural/confirmados