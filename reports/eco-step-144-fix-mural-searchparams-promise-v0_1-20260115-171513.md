# eco-step-144-fix-mural-searchparams-promise-v0_1 - 20260115-171513

## PATCH
- page.tsx: Page() async + await searchParams; trocou searchParams.* -> sp.*
- (opcional) package.json: adiciona dev:webpack = next dev --no-turbo

## VERIFY
- Ctrl+C -> npm run dev:webpack (recomendado p/ evitar overlay de sourcemap)
- abrir: /eco/mural
- abrir: /eco/mural?map=1 (>=1100px: 2 colunas, mapa aparece e fica sticky)