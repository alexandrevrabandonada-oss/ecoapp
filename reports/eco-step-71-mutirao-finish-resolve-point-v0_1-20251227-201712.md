# eco-step-71-mutirao-finish-resolve-point-v0_1

- Time: 
20251227-201712
- Backup: 
C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251227-201712-eco-step-71-mutirao-finish-resolve-point-v0_1

## Added/Updated
- GET /api/eco/mutirao/get?id=...
- POST /api/eco/mutirao/finish { id, proofNote, proofUrl? } (best-effort resolves linked point)
- POST /api/eco/points/confirm { id } (bonus)
- Page /eco/mutiroes/[id]/finalizar

## Verify
1) Ctrl+C -> npm run dev
2) Abra /eco/mutiroes/<id>/finalizar
3) Nota >= 6 chars -> Finalizar mutirao
4) Se houver ponto vinculado, abrir /eco/pontos/<pointId> e ver status RESOLVED

## Notes
- Tudo com fallbacks para aguentar variações de schema (status/fields/meta).