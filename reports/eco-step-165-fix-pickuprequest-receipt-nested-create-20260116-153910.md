# eco-step-165 — fix pickup-requests/[id]/receipt nested create — 20260116-153910

## Patch log
~~~
[OK]   src\app\api\pickup-requests\[id]\receipt\route.ts (remove request/connect for nested create)
       backup: tools\_patch_backup\eco-step-165\20260116-153910-src_app_api_pickup-requests__id__receipt_route.ts
~~~

## VERIFY
### npm run build
~~~

> eluta-servicos@0.1.0 build
> next build

   Ôû▓ Next.js 16.0.10 (Turbopack)
   - Environments: .env

   Creating an optimized production build ...
 Ô£ô Compiled successfully in 3.7s
   Running TypeScript ...
Failed to compile.

./src/app/api/pickup-requests/[id]/route.ts:38:23
Type error: Cannot find name 'ctx'.

  36 |     }
  37 |
> 38 |     const id = String(ctx?.params?.id ?? '').trim();
     |                       ^
  39 |     if (!id) return NextResponse.json({ ok: false, error: 'missing id' }, { status: 400 });
  40 |
  41 |     const body = await req.json().catch(() => ({} as any));
Next.js build worker exited with code: 1 and signal: null
~~~

