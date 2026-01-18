# eco-step-144e-fix-mural-searchparams-promise-v0_1 - 20260115-174932

## PATCH
- src/app/eco/mural/page.tsx: Page async + unwrap searchParams Promise + mapOpen
- src/app/eco/mural/page.tsx: ensure data-map on <main>
- package.json (best-effort): scripts.dev -> next dev --no-turbo

## VERIFY
- Ctrl+C (if dev running)
- npm run dev
- open: /eco/mural and /eco/mural?map=1 (no searchParams Promise error)