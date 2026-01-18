# eco-step-78-points-list-map-status-markers-v0_1

- Time: 
20251228-133912
- Backup: 
C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251228-133912-eco-step-78-points-list-map-status-markers-v0_1

## Added
- src/app/eco/_ui/PointStatus.tsx (PointBadge + markerFill/markerBorder)

## Patched (best-effort)
- src\app\eco\mapa\MapaClient.tsx
- src\app\eco\pontos\[id]\PointDetailClient.tsx

## Verify
1) Ctrl+C -> npm run dev
2) Abra a LISTA de pontos (onde aparece cards) e confira o carimbo ABERTO/RESOLVIDO
3) Abra o MAPA (se usa MapLibre markers) e confira: pinos verdes para RESOLVIDO, amarelos para ABERTO