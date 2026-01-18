# eco-step-106e-rewrite-seed-eco-route-stable-v0_1

- Time: 
20251229-191518
- Backup: 
C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251229-191518-eco-step-106e-seed-eco
- Patched: src/app/api/dev/seed-eco/route.ts

## What/Why
- Reescreve a rota de seed para NAO gerar valores invalidos (ex.: actor: String).
- Usa PRAGMA table_info + defaults seguros (actor='dev', status='OPEN', kind='LIXO_ACUMULADO').

## Verify
1) Ctrl+C -> npm run dev
2) irm 'http://localhost:3000/api/dev/seed-eco?n=3&confirm=1&support=1' | ConvertTo-Json -Depth 80
3) irm 'http://localhost:3000/api/eco/points?limit=5' | ConvertTo-Json -Depth 100
4) abrir /eco/mural e /eco/mural/confirmados