# eco-step-158 — fix receipts public code dup — 20260116-141409

## Patch log
~~~
[OK]   src\app\api\receipts\[code]\public\route.ts (rename destructure -> codeParam; normalize code string)
       backup: tools\_patch_backup\eco-step-158\20260116-141409-src_app_api_receipts__code__public_route.ts
~~~

## VERIFY
### npm run build
~~~

> eluta-servicos@0.1.0 build
> next build

   Ôû▓ Next.js 16.0.10 (Turbopack)
   - Environments: .env

   Creating an optimized production build ...
 Ô£ô Compiled successfully in 3.2s
   Running TypeScript ...
Failed to compile.

./src/app/api/eco/points/confirm/route.ts:111:16
Type error: Property 'get' does not exist on type 'Promise<ReadonlyRequestCookies>'.

  109 | function readActorFromReq(req: Request, body: any): string {
  110 |   const c = cookies();
> 111 |   const c1 = c.get("eco_actor")?.value;
      |                ^
  112 |   const c2 = c.get("nika_email")?.value;
  113 |   const h = req.headers.get("x-actor");
  114 |   const b = body && typeof body.actor === "string" ? body.actor : null;
Next.js build worker exited with code: 1 and signal: null
~~~

