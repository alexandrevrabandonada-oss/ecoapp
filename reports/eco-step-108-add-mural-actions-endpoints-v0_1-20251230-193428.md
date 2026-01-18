# eco-step-108-add-mural-actions-endpoints-v0_1

- Time: 20251230-193428
- Backup: C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251230-193428-eco-step-108-add-mural-actions-endpoints-v0_1

## What/Why
- Criou endpoints POST de ações do Mural: confirmar/support/replicar.
- Implementação 'ensure' (1 por actor por ponto) quando existir campo actor.
- Usa Prisma.dmmf para preencher campos obrigatórios sem default com valores seguros.

## Patched
- src/app/api/eco/points/confirm/route.ts
- src/app/api/eco/points/support/route.ts
- src/app/api/eco/points/replicar/route.ts

## Verify
1) Ctrl+C -> npm run dev
2) pegar um id:  (irm 'http://localhost:3000/api/eco/points?limit=1').items[0].id
3) POST confirm/support/replicar:
   - irm -Method Post 'http://localhost:3000/api/eco/points/confirm'  -ContentType 'application/json' -Body (@{ pointId = '<ID>'; actor='dev-1' } | ConvertTo-Json)
   - irm -Method Post 'http://localhost:3000/api/eco/points/support'  -ContentType 'application/json' -Body (@{ pointId = '<ID>'; actor='dev-1' } | ConvertTo-Json)
   - irm -Method Post 'http://localhost:3000/api/eco/points/replicar' -ContentType 'application/json' -Body (@{ pointId = '<ID>'; actor='dev-1' } | ConvertTo-Json)
4) conferir contadores em /api/eco/points?limit=1 (counts.confirm/support/replicar)
