# eco-step-72d-rewrite-finalizar-page-params-await-v0_1

- Time: 
20251227-203212
- Backup: 
C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251227-203212-eco-step-72d-rewrite-finalizar-page-params-await-v0_1
- File: src/app/eco/mutiroes/[id]/finalizar/page.tsx

## O que mudou
- Page virou async e faz await(params) pra suportar Next 16
- Passa id seguro pro MutiraoFinishClient

## Verify
1) Ctrl+C -> npm run dev
2) Abrir /eco/mutiroes/<id>/finalizar (sem overlay de erro em params.id)