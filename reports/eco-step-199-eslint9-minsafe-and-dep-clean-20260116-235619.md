# ECO STEP 199 — ESLint9 min-safe + limpar __DEP__

Root: C:\Projetos\App ECO\eluta-servicos
Stamp: 20260116-235619

## DIAG
- node: v22.19.0
- npm: 10.9.3

## PATCH A — eslint.config.mjs (flat config válido, ignora TS/TSX)
- backup: C:\Projetos\App ECO\eluta-servicos\eslint.config.mjs -> C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\eco-step-199\20260116-235619\eslint.config.mjs--20260116-235619
- wrote: eslint.config.mjs

## PATCH B — package.json: scripts.lint = eslint .
- backup: C:\Projetos\App ECO\eluta-servicos\package.json -> C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\eco-step-199\20260116-235619\package.json--20260116-235619
- ok: scripts.lint = eslint .

## PATCH C — remover __DEP__ do src/
- ok: sem __DEP__ em src/

## VERIFY
- npm bin: C:\Program Files\nodejs\npm.ps1
### npm run lint
~~~
Unknown command: "npmCmd"

To see a list of supported npm commands, run:
  npm help

~~~
### npm run build
~~~
Unknown command: "npmCmd"

To see a list of supported npm commands, run:
  npm help

~~~