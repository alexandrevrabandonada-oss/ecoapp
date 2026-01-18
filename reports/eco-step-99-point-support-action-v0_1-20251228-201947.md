# eco-step-99-point-support-action-v0_1

- Time: 
20251228-201947
- Backup: 
C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251228-201947-eco-step-99-point-support-action-v0_1

## Changes
- Prisma: model EcoPointSupport (pointId, note, createdAt) + migrate dev (best-effort) + generate
- API: POST /api/eco/points/support
- UI: PointSupportButton + inject in PointActionsInline
- list2: counts.support via groupBy(pointId) (best-effort) + inclui em counts

## Verify
1) Ctrl+C -> npm run dev
2) /eco/mural: clique 🤝 Apoiar em um ponto
3) Recarregue: deve aparecer (N) no botão
4) Network: POST /api/eco/points/support -> { ok: true }