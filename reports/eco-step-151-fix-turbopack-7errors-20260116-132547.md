# eco-step-151 — fix Turbopack 7 errors — 20260116-132547

## Patch log
~~~
[OK]   src\app\api\eco\mutirao\finish\route.ts (fix keys array (strings))
       backup: tools\_patch_backup\eco-step-151\20260116-132547-src_app_api_eco_mutirao_finish_route.ts
[OK]   src\app\api\eco\points\confirm\route.ts (fix randId string (confirm))
       backup: tools\_patch_backup\eco-step-151\20260116-132547-src_app_api_eco_points_confirm_route.ts
[OK]   src\app\api\eco\points\replicar\route.ts (fix randId string (replicar))
       backup: tools\_patch_backup\eco-step-151\20260116-132547-src_app_api_eco_points_replicar_route.ts
[OK]   src\app\api\eco\points\support\route.ts (fix randId string (support))
       backup: tools\_patch_backup\eco-step-151\20260116-132547-src_app_api_eco_points_support_route.ts
[OK]   reescrito: src\app\eco\mural-acoes\_components\MuralTopBarClient.tsx (remove } sobrando)
[OK]   src\app\pedidos\page.tsx (fix string aspas duplas (pedidos))
       backup: tools\_patch_backup\eco-step-151\20260116-132547-src_app_pedidos_page.tsx
[OK]   src\app\recibo\[code]\recibo-client.tsx (fix throw message (recibo-client))
       backup: tools\_patch_backup\eco-step-151\20260116-132547-src_app_recibo__code__recibo-client.tsx
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
./src/app/api/eco/mutirao/finish/route.ts:67:44
Parsing ecmascript source code failed
  65 |
  66 |   // try: status + proof fields (if schema has them)
> 67 |   let r = await tryUpdate(pm.model, pointId: null,{ status: "RESOLVED", proofNote, resolvedAt: nowIso, proofUrl, beforeUrl, afterUrl });
     |                                            ^
  68 |   if (r.ok) return { ok: true, item: r.item, mode: "full:" + r.mode };
  69 |
  70 |   const desc = proofNote ? ("[RESOLVIDO] " + proofNote) : "[RESOLVIDO]";

Expected ',', got ':'


./src/app/pedidos/page.tsx:53:5
Parsing ecmascript source code failed
  51 |
  52 |     if (!res.ok) throw new Error(json?.error ?? "GET /api/pickup-requests falhou"
> 53 |     items = pickItems(json);
     |     ^^^^^
  54 |   } catch (e: any) {
  55 |     err = e?.message ?? String(e);
  56 |   }

Expected ',', got 'items'


./src/app/recibo/[code]/recibo-client.tsx:56:78
Parsing ecmascript source code failed
  54 |       }
  55 |
> 56 |       if (!res.ok) throw new Error(json?.error ?? "GET /api/receipts falhou"));
     |                                                                              ^
  57 |       setReceipt(json?.receipt ?? null);
  58 |
  59 |       if (operatorToken) saveToken(operatorToken);

Expected ';', got ')'

Import trace:
  Server Component:
    ./src/app/recibo/[code]/recibo-client.tsx
    ./src/app/recibo/[code]/page.tsx


    at <unknown> (./src/app/api/eco/mutirao/finish/route.ts:67:44)
    at <unknown> (./src/app/pedidos/page.tsx:53:5)
    at <unknown> (./src/app/recibo/[code]/recibo-client.tsx:56:78)
~~~

