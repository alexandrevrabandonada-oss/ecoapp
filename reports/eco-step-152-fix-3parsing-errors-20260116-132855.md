# eco-step-152 — fix 3 parsing errors — 20260116-132855

## Patch log
~~~
[OK]   src\app\api\eco\mutirao\finish\route.ts (fix tryUpdate arg (pointId: null))
       backup: tools\_patch_backup\eco-step-152\20260116-132855-src_app_api_eco_mutirao_finish_route.ts
[OK]   src\app\pedidos\page.tsx (fecha throw Error (pickup-requests))
       backup: tools\_patch_backup\eco-step-152\20260116-132855-src_app_pedidos_page.tsx
[OK]   src\app\recibo\[code]\recibo-client.tsx (remove ) extra (recibo-client))
       backup: tools\_patch_backup\eco-step-152\20260116-132855-src_app_recibo__code__recibo-client.tsx
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
Error: Turbopack build failed with 3 errors:
./src/app/api/eco/mutirao/finish/route.ts:141:48
Parsing ecmascript source code failed
  139 |     let pointRes: any = { ok: false, skipped: true };
  140 |     if (pointId && pm?.model) {
> 141 |       pointRes = await resolvePoint(pm, pointId: null,proofNote, proofUrl, beforeUrl, afterUrl, nowIso);
      |                                                ^
  142 |     }
  143 |
  144 |     return NextResponse.json({

Expected ',', got ':'


./src/app/pedidos/page.tsx:103:41
Parsing ecmascript source code failed
  101 |                 const receiptCode = deriveReceiptCode(it);
  102 |
> 103 |                 const fecharHref = id ? /pedidos/fechar/ : null;
      |                                         ^^^^^^^^^^^^^^^
  104 |                 const reciboHref = receiptCode ? /recibo/ : null;
  105 |
  106 |                 return (

Unknown regular expression flags.


./src/app/recibo/[code]/recibo-client.tsx:83:25
Parsing ecmascript source code failed
  81 |   function waLink() {
  82 |     const link = window.location.href;
> 83 |     const text = Recibo ECO: ;
     |                         ^^^
  84 |     return https://wa.me/?text=;
  85 |   }
  86 |

Expected a semicolon

Import trace:
  Server Component:
    ./src/app/recibo/[code]/recibo-client.tsx
    ./src/app/recibo/[code]/page.tsx


    at <unknown> (./src/app/api/eco/mutirao/finish/route.ts:141:48)
    at <unknown> (./src/app/pedidos/page.tsx:103:41)
    at <unknown> (./src/app/recibo/[code]/recibo-client.tsx:83:25)
~~~

