# eco-step-188 — fix r/[code] headers() async — 20260116-200146

## DIAG
- alvo: C:\Projetos\App ECO\eluta-servicos\src\app\r\[code]\page.tsx
- motivo: headers() tipado como Promise<ReadonlyHeaders> (Next 16) — precisa await

## PATCH
- ecoOriginFromHeaders() virou async + await headers()
- chamadas viraram '= await ecoOriginFromHeaders()'
- garantiu 'export default async function' se necessario
- backup: 

## VERIFY
Rode:
- npm run build