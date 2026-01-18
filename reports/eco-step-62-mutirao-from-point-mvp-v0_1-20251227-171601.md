# eco-step-62-mutirao-from-point-mvp-v0_1

- Time: 
20251227-171601
- Backup: 
C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251227-171601-eco-step-62-mutirao-from-point-mvp-v0_1

## Added
- Prisma: model EcoMutirao (+ relation field EcoCriticalPoint.mutirao)
- API: POST /api/eco/mutirao/create (upsert + set point.status=MUTIRAO)
- API: GET  /api/eco/mutirao/list (include point)
- UI: /eco/mutiroes
- UI: /eco/pontos updated (filter OPEN/MUTIRAO + quick mutirao form)

## Verify
1) Restart dev server
2) Open /eco/pontos
3) Create a point, confirm it, then click "Virar mutirão" and create
4) Switch filter to "Viraram mutirão"
5) Open /eco/mutiroes
6) Check /api/eco/mutirao/list

