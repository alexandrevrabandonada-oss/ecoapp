# eco-step-106c-fix-seed-eco-pragma-string-v0_2

- Time: 
20251229-172255
- Backup: 
C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251229-172255-eco-step-106c-fix-seed-eco-pragma-string-v0_2
- Patched: src/app/api/dev/seed-eco/route.ts

## Why
- Fix TS parse error caused by bad escaping in PRAGMA string.
- Uses PRAGMA table_info("TABLE") built with TS single-quoted string (no backslash-quote escapes).

## Verify
1) Ctrl+C (stop dev) and run: npm run dev
2) irm 'http://localhost:3000/api/dev/seed-eco?n=3&confirm=1&support=1' | ConvertTo-Json -Depth 60
3) irm 'http://localhost:3000/api/eco/points?limit=5' | ConvertTo-Json -Depth 80
4) Open /eco/mural and /eco/mural/confirmados