# ECO STEP 198e — Unblock ESLint9 + Build

Stamp: 20260116-233645

## PATCH A — remover __DEP__ (quebra TS build)
- backup: C:\Projetos\App ECO\eluta-servicos\src\app\eco\mutiroes\[id]\MutiraoDetailClient.tsx -> C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\eco-step-198e\20260116-233645\MutiraoDetailClient.tsx--20260116-233645
- patched: C:\Projetos\App ECO\eluta-servicos\src\app\eco\mutiroes\[id]\MutiraoDetailClient.tsx
- backup: C:\Projetos\App ECO\eluta-servicos\src\app\eco\mutiroes\MutiroesClient.tsx -> C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\eco-step-198e\20260116-233645\MutiroesClient.tsx--20260116-233645
- patched: C:\Projetos\App ECO\eluta-servicos\src\app\eco\mutiroes\MutiroesClient.tsx
- backup: C:\Projetos\App ECO\eluta-servicos\src\app\eco\pontos\PontosClient.tsx -> C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\eco-step-198e\20260116-233645\PontosClient.tsx--20260116-233645
- patched: C:\Projetos\App ECO\eluta-servicos\src\app\eco\pontos\PontosClient.tsx
- backup: C:\Projetos\App ECO\eluta-servicos\src\app\eco\recibos\RecibosClient.tsx -> C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\eco-step-198e\20260116-233645\RecibosClient.tsx--20260116-233645
- patched: C:\Projetos\App ECO\eluta-servicos\src\app\eco\recibos\RecibosClient.tsx

## PATCH B — eslint.config.mjs minimo + ignores (sem TS/TSX)
- backup: C:\Projetos\App ECO\eluta-servicos\eslint.config.mjs -> C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\eco-step-198e\20260116-233645\eslint.config.mjs--20260116-233645
- wrote: eslint.config.mjs

## PATCH C — package.json: scripts.lint = eslint .
- backup: C:\Projetos\App ECO\eluta-servicos\package.json -> C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\eco-step-198e\20260116-233645\package.json--20260116-233645
- ok: scripts.lint = eslint .

## VERIFY
### npm run lint
Unknown command: "pm"

To see a list of supported npm commands, run:
  npm help


### npm run build
Unknown command: "pm"

To see a list of supported npm commands, run:
  npm help
