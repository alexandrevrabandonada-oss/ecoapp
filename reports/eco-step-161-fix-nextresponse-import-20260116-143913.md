# eco-step-161 — fix NextResponse import — 20260116-143913

## Patch log
~~~
[OK]   src\app\api\eco\points\route.ts (add NextResponse import (and NextRequest if used))
       backup: tools\_patch_backup\eco-step-161\20260116-143913-src_app_api_eco_points_route.ts
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

./src/app/api/eco/points/route.ts:30:21
Type error: Cannot find name 'prisma'.

  28 |     const photoUrl = (typeof body.photoUrl === 'string' && body.photoUrl.trim().length) ? body.photoUrl.trim().slice(0, 500) : null;
  29 |
> 30 |     const pc: any = prisma as any;
     |                     ^
  31 |     const keys = Object.keys(pc);
  32 |     const pointKey = (pc.ecoCriticalPoint ? 'ecoCriticalPoint' : (keys.find((k) => /point/i.test(k) && /eco/i.test(k)) || null));
  33 |     if (!pointKey) return NextResponse.json({ ok: false, error: 'point_model_not_found' }, { status: 500 });
Next.js build worker exited with code: 1 and signal: null
~~~

