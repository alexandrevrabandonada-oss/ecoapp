# eco-step-94-mural-api-confirm-counts-v0_1

- Time: 
20251228-184924
- Backup: 
C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251228-184924-eco-step-94-mural-api-confirm-counts-v0_1

## Changes
- Added API: src/app/api/eco/mural/list/route.ts (items + counts.confirm best-effort via Prisma dynamic models)
- Patched: src/app/eco/mural/MuralClient.tsx (fetch from /api/eco/mural/list?base=...)

## Verify
1) Ctrl+C -> npm run dev
2) /eco/mural (carrega sem 500)
3) /eco/mural/confirmados (filtra por counts.confirm > 0)
4) Se tiver ponto confirmado, deve aparecer badge/contagem com consistencia.

## Notes
- A API tenta detectar automaticamente os models do Prisma (pontos + confirmacoes).
- Se meta.confirmModel vier null, seu schema ainda nao tem o model de confirmacao ou o nome e diferente (a gente ajusta candidatos).