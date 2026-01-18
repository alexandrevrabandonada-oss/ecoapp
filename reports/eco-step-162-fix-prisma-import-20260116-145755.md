# eco-step-162 — fix prisma import (points route) — 20260116-145755

## Patch log
~~~
[OK]   src\app\api\eco\points\route.ts (added prisma import)
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

./src/app/api/pickup-requests/[id]/receipt/route.ts:34:24
Type error: Cannot find name 'ctx'.

  32 |     const { id } = await params;
  33 | try {
> 34 |     const id = String((ctx as any)?.params?.id ?? "");
     |                        ^
  35 |     if (!id) return NextResponse.json({ ok: false, error: "missing_id" }, { status: 400 });
  36 |
  37 |     if (!ecoIsOperator(req)) {
Next.js build worker exited with code: 1 and signal: null
~~~

