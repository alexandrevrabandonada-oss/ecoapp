# eco-step-163 — fix pickup-requests/[id]/receipt ctx — 20260116-150932

## Patch log
~~~
[OK]   src\app\api\pickup-requests\[id]\receipt\route.ts (remove ctx; normalize id from params)
       backup: tools\_patch_backup\eco-step-163\20260116-150932-src_app_api_pickup-requests__id__receipt_route.ts
~~~

## VERIFY
### npm run build
~~~

> eluta-servicos@0.1.0 build
> next build

   Ôû▓ Next.js 16.0.10 (Turbopack)
   - Environments: .env

   Creating an optimized production build ...
 Ô£ô Compiled successfully in 3.5s
   Running TypeScript ...
Failed to compile.

./src/app/api/pickup-requests/[id]/receipt/route.ts:64:5
Type error: Object literal may only specify known properties, and 'requestId' does not exist in type '(Without<ReceiptCreateWithoutRequestInput, ReceiptUncheckedCreateWithoutRequestInput> & ReceiptUncheckedCreateWithoutRequestInput) | (Without<...> & ReceiptCreateWithoutRequestInput)'.

  62 |     code: ecoGenCode(),
  63 |     public: false,
> 64 |     requestId: "MVP",
     |     ^
  65 |           },
  66 |         },
  67 |       },
Next.js build worker exited with code: 1 and signal: null
~~~

