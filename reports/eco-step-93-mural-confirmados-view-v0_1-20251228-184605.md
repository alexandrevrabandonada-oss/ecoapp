# eco-step-93-mural-confirmados-view-v0_1

- Time: 
20251228-184605
- Backup: 
C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251228-184605-eco-step-93-mural-confirmados-view-v0_1

## Changes
- Added route: src/app/eco/mural/confirmados/page.tsx
- Patched: src/app/eco/mural/page.tsx (link Confirmados)
- Patched: src/app/eco/mural/MuralClient.tsx (base==confirmados => filtra counts.confirm > 0 antes de setItems)

## Verify
1) Ctrl+C -> npm run dev
2) /eco/mural (tem botao ✅ Confirmados)
3) /eco/mural/confirmados (lista apenas pontos com counts.confirm > 0)

## Notes
- Este tijolo nao depende de API nova: filtra no client usando counts.confirm vindo do payload.
- Se aparecer vazio, pode ser que seus pontos ainda nao tenham confirmacoes gravadas.