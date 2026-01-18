# eco-step-143-disable-turbopack-fix-invalid-sourcemap-v0_1 - 20260115-170200

## Contexto
- Erro em dev: Invalid source map / sourceMapURL could not be parsed (chunks SSR node_modules... turbopack).

## Patch
- package.json: scripts.dev -> set NEXT_DISABLE_TURBOPACK=1 && next dev
- package.json: scripts.dev:turbo -> next dev (para voltar ao turbopack quando quiser)
- limpeza: .next removido (a menos que -NoClean)

## Verify
- Ctrl+C (se o dev estiver rodando)
- npm run dev  (agora em webpack/dev, sem turbopack)
- abrir /eco/mural e /eco/mural?map=1 e conferir se sumiu o overlay/console do sourcemap