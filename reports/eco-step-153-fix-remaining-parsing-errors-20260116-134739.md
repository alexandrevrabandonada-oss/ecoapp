# eco-step-153 — fix remaining parsing errors — 20260116-134739

## Patch log
~~~
[OK]   src\app\api\eco\mutirao\finish\route.ts (fix resolvePoint arg (pointId: null))
       backup: tools\_patch_backup\eco-step-153\20260116-134739-src_app_api_eco_mutirao_finish_route.ts
[OK]   src\app\pedidos\page.tsx (fix href strings (pedidos))
       backup: tools\_patch_backup\eco-step-153\20260116-134739-src_app_pedidos_page.tsx
[OK]   src\app\recibo\[code]\recibo-client.tsx (fix waLink + use client (recibo-client))
       backup: tools\_patch_backup\eco-step-153\20260116-134739-src_app_recibo__code__recibo-client.tsx
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
./src/app/recibo/[code]/recibo-client.tsx:119:71
Parsing ecmascript source code failed
  117 |         throw new Error("unauthorized (defina ECO_OPERATOR_TOKEN no .env e preencha a chave aqui)");
  118 |       }
> 119 |       if (!res.ok) throw new Error(json?.error ?? PATCH /api/receipts falhou ());
      |                                                                       ^^^^^^
  120 |
  121 |       if (operatorToken) saveToken(operatorToken);
  122 |       await load();

Expected ',', got 'falhou'

Import trace:
  Server Component:
    ./src/app/recibo/[code]/recibo-client.tsx
    ./src/app/recibo/[code]/page.tsx


    at <unknown> (./src/app/recibo/[code]/recibo-client.tsx:119:71)
~~~

