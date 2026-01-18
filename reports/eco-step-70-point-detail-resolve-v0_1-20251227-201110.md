# eco-step-70-point-detail-resolve-v0_1

- Time: 
20251227-201110
- Backup: 
C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251227-201110-eco-step-70-point-detail-resolve-v0_1

## Added
- GET /api/eco/points/get?id=...
- POST /api/eco/points/resolve { id, proofNote, proofUrl? }
- Page /eco/pontos/[id] + PointDetailClient

## Verify
1) Ctrl+C -> npm run dev
2) Abra /eco/mapa, clique 'Ver detalhe' em um item
3) Clique 'Eu vi tambem' e ver se aumenta contador
4) Escreva nota >= 6 chars e clique 'Marcar RESOLVIDO' (status deve mudar)

## Notes
- Resolve tenta varios campos (status/proofNote/resolvedAt/meta/description) para aguentar variações do schema.