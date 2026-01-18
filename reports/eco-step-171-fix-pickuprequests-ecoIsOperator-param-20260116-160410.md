# eco-step-171 — normalize ecoIsOperator(param) — 20260116-160410

## DIAG
alvo: src\app\api\pickup-requests\route.ts
GET param detectado: req
calls ecoIsOperator(...): 1

## PATCH LOG
~~~
[OK]   normalized ecoIsOperator(...) -> ecoIsOperator(req)
       backup: C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\eco-step-171\20260116-160410-C__Projetos_App_ECO_eluta-servicos_src_app_api_pickup-requests_route.ts
~~~

## VERIFY
### npm run build
~~~

> eluta-servicos@0.1.0 build
> next build

   Ôû▓ Next.js 16.0.10 (Turbopack)
   - Environments: .env

   Creating an optimized production build ...
 Ô£ô Compiled successfully in 4.1s
   Running TypeScript ...
Failed to compile.

./src/app/api/pickup-requests/route.ts:140:35
Type error: Cannot find name 'req'.

  138 |
  139 |  // ECO_PICKUP_RECEIPT_PRIVACY_START
> 140 |  const __eco_isOp = ecoIsOperator(req);
      |                                   ^
  141 |  if (!__eco_isOp) {
  142 |    const __rf = "receipt";
  143 |    const __pf = "public";
Next.js build worker exited with code: 1 and signal: null
~~~

