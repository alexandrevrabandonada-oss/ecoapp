# eco-step-145-fix-dev-and-mural-searchparams-v0_1 - 20260115-180747

## PATCH
- package.json: scripts.dev = next dev (remove --no-turbo inválido)
- package.json: add dev:turbo / dev:webpack
- mural/page.tsx: unwrap searchParams Promise (se necessário)

## VERIFY
- Ctrl+C (se dev estiver rodando)
- npm run dev
- abrir: /eco/mural?map=1
- se ainda ficar spam de sourcemap, testar: npm run dev:webpack