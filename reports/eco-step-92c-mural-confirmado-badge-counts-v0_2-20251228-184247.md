# eco-step-92c-mural-confirmado-badge-counts-v0_2

- Time: 
20251228-184247
- Backup: 
C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251228-184247-eco-step-92c-mural-confirmado-badge-counts-v0_2

## Changes
- Added: src/app/eco/_components/ConfirmadoBadge.tsx
- Ensured default export: PointActionsInline
- Added: /api/eco/points/list2 (returns items with counts.confirm)
- Patched: MuralClient to use list2 and (if detected) render ConfirmadoBadge near actions

## Verify
1) Ctrl+C -> npm run dev
2) Abra /eco/mural (sem 500).
3) Em pontos com confirmações, badge ✅ CONFIRMADO + numero aparece (se houver confirmacoes na base).
4) /eco/mural/chamados idem.

## Notes
- list2 tenta inferir pointKey/confirmKey lendo seus route.ts existentes; se falhar, usa fallbacks.
- Se badge nao aparecer, pode ser que ainda nao existam confirmacoes registradas para os pontos testados.