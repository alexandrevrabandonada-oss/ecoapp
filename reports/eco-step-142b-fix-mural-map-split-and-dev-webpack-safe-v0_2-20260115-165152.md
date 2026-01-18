# eco-step-142b-fix-mural-map-split-and-dev-webpack-safe-v0_2 - 20260115-165152

## PATCH
- rewrote: src/app/eco/mural/_components/MuralWideStyles.tsx
- updated: src/app/eco/mural/page.tsx (mapOpen + data-map + split + mapa direita)
- optional: package.json added dev:webpack (next dev --no-turbo)

## VERIFY
- Ctrl+C -> npm run dev
- abrir: /eco/mural
- abrir: /eco/mural?map=1 (>=1100px => 2 colunas, mapa sticky direita)
- se overlay sourcemap incomodar: npm run dev:webpack