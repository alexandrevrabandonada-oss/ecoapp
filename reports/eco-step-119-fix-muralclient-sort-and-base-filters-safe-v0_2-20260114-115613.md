# eco-step-119-fix-muralclient-sort-and-base-filters-safe-v0_2

- Time: 20260114-115613
- Backup: C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20260114-115613-eco-step-119-fix-muralclient-sort-and-base-filters-safe-v0_2

## Results
- C:\Projetos\App ECO\eluta-servicos\src\app\eco\mural\MuralClient.tsx :: patched
- C:\Projetos\App ECO\eluta-servicos\src\app\eco\mural-acoes\MuralAcoesClient.tsx :: patched

## What/Why
- Corrige sort quebrado (arr try / p is not defined).
- Sort por score(confirm+support+replicar) + desempate por createdAt.
- Filtros por base: confirmados (confirm>0) e acoes (score>0).

## Verify
1) Ctrl+C -> npm run dev
2) abrir /eco/mural
3) abrir /eco/mural/confirmados
4) (opcional) abrir /eco/mural-acoes
5) testar API actions:
   $pid = (irm 'http://localhost:3000/api/eco/points?limit=1').items[0].id
   $b = @{ pointId = $pid; action = 'confirm'; actor = 'dev' } | ConvertTo-Json -Compress
   irm 'http://localhost:3000/api/eco/points/action' -Method Post -ContentType 'application/json' -Body $b | ConvertTo-Json -Depth 60