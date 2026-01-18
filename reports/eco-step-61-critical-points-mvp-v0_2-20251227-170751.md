# eco-step-61-critical-points-mvp-v0_2

- Time: 
20251227-170751
- Backup: 
C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251227-170751-eco-step-61-critical-points-mvp-v0_2

## Added
- Prisma: EcoCriticalKind + EcoCriticalPoint + EcoCriticalPointConfirm
- API: POST /api/eco/critical/create (dedupe)
- API: GET  /api/eco/critical/list
- API: POST /api/eco/critical/confirm
- UI: /eco/pontos (form + list + confirm)

## Verify
1) Restart dev server
2) Open /eco/pontos
3) Use geo, create point, confirm point
4) Check /api/eco/critical/list

