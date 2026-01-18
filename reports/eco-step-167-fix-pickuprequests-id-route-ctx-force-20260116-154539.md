# eco-step-167 — fix pickup-requests/[id] ctx (force) — 20260116-154539

## Patch log
~~~
[OK]   src\app\api\pickup-requests\[id]\route.ts (force remove ctx; normalize id via params)
       backup: tools\_patch_backup\eco-step-167\20260116-154539-src_app_api_pickup-requests__id__route.ts
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

