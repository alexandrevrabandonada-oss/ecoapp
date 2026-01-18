# eco-step-59-month-close-mvp-v0_1

- Time: 
20251227-165528
- Backup: 
C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251227-165528-eco-step-59-month-close-mvp-v0_1

## Added
- Prisma model: EcoMonthClose (month unique, summary Json)
- API: /api/eco/month-close (GET/POST)
- API: /api/eco/month-close/list
- Card: /api/eco/month-close/card?format=3x4|1x1&month=YYYY-MM
- UI: /eco/transparencia (lista + atalhos)

## Verify
1) Restart dev server
2) Open /eco/transparencia
3) Click 'Compartilhar mês atual' and open cards
4) Test: /api/eco/month-close?month=2025-12

