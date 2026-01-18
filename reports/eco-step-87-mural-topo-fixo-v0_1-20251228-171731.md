# eco-step-87-mural-topo-fixo-v0_1

- Time: 
20251228-171731
- Backup: 
C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251228-171731-eco-step-87-mural-topo-fixo-v0_1

## Files
- Component: src/app/eco/mural/_components/MuralTopBar.tsx
- Patched mural page: tools/_patch_backup/20251228-171731-C__Projetos_App ECO_eluta-servicos True
- Patched mural-acoes page: tools/_patch_backup/20251228-171731-C__Projetos_App ECO_eluta-servicos True

## What
- Topo fixo (sticky) com 3 caixas: Chamados ativos / Mais confirmados / Mutiroes recentes
- Best-effort: tenta endpoints conhecidos; se nao achar, mostra vazio mas sem quebrar

## Verify
1) Ctrl+C -> npm run dev
2) Abra /eco/mural
3) Veja topo fixo com 3 colunas
4) Role a pagina: topo fica grudado
5) Clique em itens: abre ponto ou mutirao