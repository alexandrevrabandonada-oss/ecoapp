# eco-step-89-mural-topbar-transparencia-v0_1

- Time: 
20251228-173212
- Backup: 
C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251228-173212-eco-step-89-mural-topbar-transparencia-v0_1

## What
- Reescreve MuralTopBarClient com 4 caixas: Chamados, Confirmados, Mutirões, Transparência.
- Transparência usa /api/eco/day-close/list e computa: últimos 7 dias + mês atual (kg).
- Links: /eco/share/mes/[YYYY-MM], /eco/share/dia/[YYYY-MM-DD], /eco/fechamento.

## Verify
1) Ctrl+C -> npm run dev
2) Abrir /eco/mural
3) Caixa "Transparência" aparece com valores (ou 0 se sem dados)
4) Clicar "Compartilhar mês" e "Compartilhar dia" abre as páginas