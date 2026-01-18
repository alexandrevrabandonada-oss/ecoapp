# ECO — STEP 23 — Dedupe TOTAL helpers em /api/pickup-requests (ecoWithReceipt + operador + privacy)

Data: 2025-12-24 18:20:49
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG
schema: prisma/schema.prisma
PickupRequest.receipt relation field: receipt
Receipt code field: code
Receipt public flag field: public
Receipt select: code: true, public: true

### Antes (contagens)
- ecoWithReceipt(): 1
- ecoGetToken(): 1
- ecoIsOperator(): 1
- bloco privacy: 1

## PATCH
Arquivo: src/app/api/pickup-requests/route.ts
Backup : tools/_patch_backup/20251224-182049-src_app_api_pickup-requests_route.ts
- OK: reinjetei helpers limpos (ecoWithReceipt + operador) uma única vez.
- INFO: não achei findMany(VAR) simples para embrulhar (talvez já use objeto literal).
- OK: reinjetei bloco privacy (1x) antes do return NextResponse.json.

### Depois (contagens)
- ecoWithReceipt(): 1
- ecoGetToken(): 1
- ecoIsOperator(): 1
- bloco privacy: 1

## VERIFY
1) Reinicie o dev (CTRL+C): npm run dev
2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1
3) /api/pickup-requests deve voltar 200
4) (Opcional) setar token do operador no .env: ECO_OPERATOR_TOKEN=... (e reiniciar dev)
