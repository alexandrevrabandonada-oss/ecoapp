# eco-step-87b-fix-mural-page-p-div-nesting-v0_1

- Time: 
20251228-172010
- Backup: 
C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251228-172010-eco-step-87b-fix-mural-page-p-div-nesting-v0_1
- File: src/app/eco/mural/page.tsx

## What
- Corrige HTML invalido: <div> dentro de <p> (insere </p> antes do bloco).

## Verify
1) Ctrl+C -> npm run dev
2) Abra /eco/mural
3) Nao deve mais aparecer erro: "div cannot be a descendant of p"