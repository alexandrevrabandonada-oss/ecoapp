# eco-step-146b-dev-scripts-and-allowedDevOrigins-v0_1 - 20260115-195345

## PATCH
- package.json: scripts.dev=next dev; add dev:turbo, dev:webpack
- next.config: allowedDevOrigins (silencia warning cross-origin no dev)

## VERIFY
- Ctrl+C -> npm run dev
- abrir /eco/mural e /eco/mural?map=1
- se quiser testar: npm run dev:webpack