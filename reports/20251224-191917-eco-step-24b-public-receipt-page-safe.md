# ECO — STEP 24b — Página pública do Recibo (/r/[code]) (safe)

Data: 2025-12-24 19:19:17
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG
schema: prisma/schema.prisma
Receipt code field  : code
Receipt public field: public

## PATCH
- OK: criado src\app\r\[code]\page.tsx
- OK: criado src\app\r\[code]\not-found.tsx

## VERIFY
1) Reinicie o dev (CTRL+C): npm run dev
2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1
3) Teste: http://localhost:3000/r/<CODE> (só abre se public=true)
4) Aba anônima também deve abrir (sem token).
