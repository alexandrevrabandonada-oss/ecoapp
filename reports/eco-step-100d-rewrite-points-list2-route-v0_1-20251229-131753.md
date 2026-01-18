# eco-step-100d-rewrite-points-list2-route-v0_1

- Time: 20251229-131753
- Backup: C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251229-131753-eco-step-100d-rewrite-points-list2-route-v0_1

## Why
- list2 estava quebrando com groupBy(by: ["criticalPointId"]) porque o campo real varia conforme o schema.
- Tambem tivemos strings quebradas em multiplas linhas em patches anteriores.

## What changed
- Reescreveu src/app/api/eco/points/list2/route.ts com:
  - pickModel dinamico (ecoCriticalPoint / ecoCriticalPointConfirm / ecoPointSupport etc)
  - groupCountBy tenta pointId / criticalPointId / ecoCriticalPointId / ecoPointId e usa o primeiro que funcionar
  - injeta counts.confirm e counts.support em cada item

## Verify
1) Ctrl+C -> npm run dev
2) GET http://localhost:3000/api/eco/points/list2?limit=10 (status 200, meta.confirmBy nao vazio se existir confirm model)
3) Abrir /eco/mural e /eco/mural/confirmados (sem 500)