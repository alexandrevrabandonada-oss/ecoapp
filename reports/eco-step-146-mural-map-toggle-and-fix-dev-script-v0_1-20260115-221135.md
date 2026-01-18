# eco-step-146-mural-map-toggle-and-fix-dev-script-v0_1 - 20260115-221135

## PATCH
- wrote: src/app/eco/mural/_components/MapToggleLink.tsx
- updated: src/app/eco/mural/page.tsx (import + render toggle após MuralWideStyles)
- updated: package.json (remove --no-turbo, dev usa NEXT_DISABLE_TURBOPACK=1; adiciona dev:webpack/dev:turbo)

## VERIFY
- Ctrl+C -> npm run dev
- abrir: /eco/mural (botão deve mostrar Abrir mapa)
- clicar Abrir mapa -> vira /eco/mural?map=1 (2 colunas + mapa à direita)
- clicar Fechar mapa -> volta /eco/mural (preserva outros params se tiver)