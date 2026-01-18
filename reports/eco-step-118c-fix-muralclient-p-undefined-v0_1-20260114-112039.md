# eco-step-118c-fix-muralclient-p-undefined-v0_1

- Time: 20260114-112039
- Backup: C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20260114-112039-eco-step-118c-fix-muralclient-p-undefined-v0_1

## What/Why
- Corrige Runtime ReferenceError: p is not defined (p usado dentro do .sort(...) sem existir no escopo).
- Substitui p. pelo nome do 1º parâmetro do comparator (geralmente a.).
- Envolve sort em try/catch para não derrubar o mural em caso de erro.

## Patched
- C:\Projetos\App ECO\eluta-servicos\src\app\eco\mural\MuralClient.tsx (sorts patched=1)
- C:\Projetos\App ECO\eluta-servicos\src\app\eco\mural-acoes\MuralAcoesClient.tsx (no change)

## Verify
1) Ctrl+C -> npm run dev
2) abrir /eco/mural (não pode mais dar 'p is not defined')
3) abrir /eco/mural-acoes (se existir no menu)
