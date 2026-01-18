# eco-step-87c-rewrite-mural-page-safe-v0_1

- Time: 
20251228-172318
- Backup: 
C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251228-172318-eco-step-87c-rewrite-mural-page-safe-v0_1
- File: src/app/eco/mural/page.tsx

## What
- Reconstrói o page.tsx com JSX válido (remove nesting p>div e corrige parser).
- Mantém imports existentes (incluindo MuralClient) e garante import do MuralTopBar.
- Se a página estiver como "use client", não renderiza MuralTopBar (evita erro server->client).

## Verify
1) Ctrl+C -> npm run dev
2) Abrir /eco/mural
3) Não deve mais ter "Parsing ecmascript source code failed"
4) Se não aparecer topo fixo, verificar se tinha "use client" (aí fazemos TopBar client-side)