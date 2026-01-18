# eco-step-164 — fix pickup-requests/[id]/receipt link — 20260116-152726

## Patch log
~~~
[DIAG] Receipt relation type: PickupRequest
[DIAG] Receipt relation field: request
[DIAG] Receipt fk scalar (fields:[..]): requestId
[OK] backup: C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\eco-step-164\20260116-152726-C__Projetos_App_ECO_eluta-servicos_src_app_api_pickup-requests__id__receipt_route.ts
[OK] replace requestId:"MVP" ->     request: { connect: { id } },
~~~

## VERIFY
### npm run build
~~~

> eluta-servicos@0.1.0 build
> next build

   Ôû▓ Next.js 16.0.10 (Turbopack)
   - Environments: .env

   Creating an optimized production build ...
 Ô£ô Compiled successfully in 5.4s
   Running TypeScript ...
Failed to compile.

./src/app/api/pickup-requests/[id]/receipt/route.ts:64:5
Type error: Object literal may only specify known properties, and 'request' does not exist in type '(Without<ReceiptCreateWithoutRequestInput, ReceiptUncheckedCreateWithoutRequestInput> & ReceiptUncheckedCreateWithoutRequestInput) | (Without<...> & ReceiptCreateWithoutRequestInput)'.

  62 |     code: ecoGenCode(),
  63 |     public: false,
> 64 |     request: { connect: { id } },
     |     ^
  65 |           },
  66 |         },
  67 |       },
Next.js build worker exited with code: 1 and signal: null
~~~

