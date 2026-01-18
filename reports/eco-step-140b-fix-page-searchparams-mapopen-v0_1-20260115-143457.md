# eco-step-140b-fix-page-searchparams-mapopen-v0_1 - 20260115-143457

## PATCH
- fixed page.tsx signature to accept searchParams (if needed)
- ensured mapOpen uses JS operator || and mapVal normalization

## VERIFY
- Ctrl+C -> npm run dev
- abrir /eco/mural?map=1 (não pode dar erro de parse)