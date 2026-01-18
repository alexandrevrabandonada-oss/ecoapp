# eco-step-57-month-close-transparencia-v0_1

- Time: 
20251227-155200
- Backup: 
C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251227-155200-eco-step-57-month-close-transparencia-v0_1

## Added
- API: /api/eco/month-close?month=YYYY-MM (GET/POST, fresh=1)
- API: /api/eco/month-close/list?limit=24
- Card: /api/eco/month-close/card?month=YYYY-MM&format=3x4|1x1
- UI: /eco/transparencia

## Notes
- Este tijolo assume existência do modelo Prisma ecoMonthClose. Se der model_not_ready, faremos o STEP 57b (Prisma model + migrate).

