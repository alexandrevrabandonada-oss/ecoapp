# eco-step-104-stabilize-points-api-list2-counts-support-prisma-v0_1

- Time: 
20251229-142351
- Backup: 
C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251229-142351-eco-step-104-stabilize-points-api-list2-counts-support-prisma-v0_1

## Changes
- schema.prisma: ensured EcoPointSupport exists + added opposite relation supports EcoPointSupport[] on point model (
EcoCriticalPoint
)
- wrote /api/eco/points/route.ts (compat -> delegates to list2)
- rewrote /api/eco/points/list2/route.ts with robust model+groupBy field detection + counts {confirm,support,replicar}

## Verify
1) Ctrl+C -> npm run dev
2) irm http://localhost:3000/api/eco/points?limit=5 | ConvertTo-Json -Depth 30
3) abrir /eco/mural e /eco/mural/confirmados (sem 404/500)
4) conferir meta.by no JSON (campo detectado do groupBy)
