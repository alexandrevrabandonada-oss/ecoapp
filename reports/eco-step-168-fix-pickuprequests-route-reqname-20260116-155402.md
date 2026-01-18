# eco-step-168 — fix pickup-requests route req/request — 20260116-155402

## DIAG
alvo: src\app\api\pickup-requests\route.ts
matches ecoIsOperator(req): 1

## PATCH LOG
~~~
[OK]   src\app\api\pickup-requests\route.ts (req->request in ecoIsOperator())
       backup: C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\eco-step-168\20260116-155402\20260116-155402-C__Projetos_App_ECO_eluta-servicos_src_app_api_pickup-requests_route.ts
~~~

## VERIFY
### npm run build
~~~

> eluta-servicos@0.1.0 build
> next build

   Ôû▓ Next.js 16.0.10 (Turbopack)
   - Environments: .env

   Creating an optimized production build ...
 Ô£ô Compiled successfully in 3.4s
   Running TypeScript ...
Failed to compile.

./src/app/api/pickup-requests/route.ts:140:35
Type error: Cannot find name 'request'. Did you mean 'Request'?

  138 |
  139 |  // ECO_PICKUP_RECEIPT_PRIVACY_START
> 140 |  const __eco_isOp = ecoIsOperator(request);
      |                                   ^
  141 |  if (!__eco_isOp) {
  142 |    const __rf = "receipt";
  143 |    const __pf = "public";
Next.js build worker exited with code: 1 and signal: null
~~~

