# eco-step-66c-patch-mutirao-client-proofnote-literalpath-v0_1

- Time: 
20251227-180833
- Backup: 
C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251227-180833-eco-step-66c-patch-mutirao-client-proofnote-literalpath-v0_1
- Patched: 
C:\Projetos\App ECO\eluta-servicos\src\app\eco\mutiroes\[id]\MutiraoDetailClient.tsx
- Score: 
35

## Verify
1) restart dev
2) abrir /eco/mutiroes/[id]
3) procurar textarea "Justificativa (se faltar foto)" no checklist
4) finalizar sem antes/depois e sem justificativa => deve dar missing_proof (se UI chama finish)
