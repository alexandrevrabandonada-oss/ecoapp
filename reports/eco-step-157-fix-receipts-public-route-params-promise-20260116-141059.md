# eco-step-157 — fix receipts/[code]/public params Promise — 20260116-141059

## Patch log
~~~
[OK]   src\app\api\receipts\[code]\public\route.ts (Next 16 handler signatures + params Promise (receipts/[code]/public))
       backup: tools\_patch_backup\eco-step-157\20260116-141059-src_app_api_receipts__code__public_route.ts
~~~

## VERIFY
### npm run build
~~~

> eluta-servicos@0.1.0 build
> next build

   Ôû▓ Next.js 16.0.10 (Turbopack)
   - Environments: .env

   Creating an optimized production build ...

> Build error occurred
Error: Turbopack build failed with 1 errors:
./src/app/api/receipts/[code]/public/route.ts:26:9
Ecmascript file had an error
  24 |   }
  25 |
> 26 |   const code = params?.code ? String(code) : '';
     |         ^^^^
  27 |   if (!code) return NextResponse.json({ error: 'missing_code' }, { status: 400 });
  28 |
  29 |   let desired: boolean | null = null;

the name `code` is defined multiple times


    at <unknown> (./src/app/api/receipts/[code]/public/route.ts:26:9)
~~~

