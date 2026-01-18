# eco-step-140-mural-splitview-map-sticky-v0_1 - 20260115-141852

## PATCH
- rewrote: src/app/eco/mural/_components/MuralWideStyles.tsx
- updated: src/app/eco/mural/page.tsx (data-map + split columns)

## VERIFY
- Ctrl+C -> npm run dev
- abrir: /eco/mural (map fechado => 1 coluna)
- abrir: /eco/mural?map=1 (desktop => 2 colunas, mapa sticky à direita)
- testar foco: /eco/mural?map=1&focus=<id>