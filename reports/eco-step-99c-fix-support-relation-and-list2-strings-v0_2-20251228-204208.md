# eco-step-99c-fix-support-relation-and-list2-strings-v0_2

- Time: 20251228-204208
- Backup: C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251228-204208-eco-step-99c-fix-support-relation-and-list2-strings-v0_2

## Changes
- schema.prisma: added inverse field supports EcoPointSupport[] on point model (fix P1012 missing opposite relation).
- list2 route.ts: fixed broken multiline strings in pickModel(...) and pc?.["..."] accesses.

## Verify
1) Ctrl+C -> npm run dev
2) irm http://localhost:3000/api/eco/points/list2?limit=10 -Headers @{Accept="application/json"} | ConvertTo-Json -Depth 50
3) abra /eco/mural e /eco/mural/confirmados
