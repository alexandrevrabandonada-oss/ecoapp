# eco-step-141-mural-split-wrapper-safe-v0_1 - 20260115-162852

## PATCH
- rewrote: src/app/eco/mural/_components/MuralWideStyles.tsx
- updated: src/app/eco/mural/page.tsx (mapOpen + data-map + split wrapper)

## VERIFY
- Ctrl+C -> npm run dev
- abrir: /eco/mural (map fechado => 1 coluna)
- abrir: /eco/mural?map=1 (>=1100px => 2 colunas, mapa sticky à direita)