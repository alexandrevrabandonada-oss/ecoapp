# eco-step-88-mural-topbar-client-v0_1

- Time: 
20251228-172644
- Backup: 
C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251228-172644-eco-step-88-mural-topbar-client-v0_1

## Files
- New: src/app/eco/mural/_components/MuralTopBarClient.tsx
- Patched mural page: tools/_patch_backup/20251228-172644-C__Projetos_App ECO_eluta-servicos True
- Patched mural-acoes page: tools/_patch_backup/20251228-172644-C__Projetos_App ECO_eluta-servicos True

## What
- Topo fixo do Mural agora é client-side (fetch relativo /api), sem depender de NEXT_PUBLIC_BASE_URL.
- Evita problemas de SSR com URL absoluta e deixa o topo funcionar em dev/prod.

## Verify
1) Ctrl+C -> npm run dev
2) Abrir /eco/mural
3) Topo fixo aparece e carrega itens
4) Abrir /eco/mural-acoes (se existir) e ver topo