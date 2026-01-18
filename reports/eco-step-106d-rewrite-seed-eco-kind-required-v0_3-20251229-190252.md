# eco-step-106d-rewrite-seed-eco-kind-required-v0_3

- Time: 
20251229-190252
- Backup: 
C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251229-190252-eco-step-106d-v0_3
- Patched: src/app/api/dev/seed-eco/route.ts
- Model in schema: 
EcoCriticalPoint
- Default kind: 
LIXO_ACUMULADO
- Default status: 
OPEN

## Verify
1) Ctrl+C -> npm run dev
2) irm 'http://localhost:3000/api/dev/seed-eco?n=3&confirm=1&support=1' | ConvertTo-Json -Depth 80
3) irm 'http://localhost:3000/api/eco/points?limit=5' | ConvertTo-Json -Depth 120
4) Abra /eco/mural e /eco/mural/confirmados