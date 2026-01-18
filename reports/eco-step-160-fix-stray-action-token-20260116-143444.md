# eco-step-160 — fix stray action token — 20260116-143444

## Patch log
~~~
[OK]   src\app\api\eco\points\confirm\route.ts (remove stray action token line)
       backup: tools\_patch_backup\eco-step-160\20260116-143444-src_app_api_eco_points_confirm_route.ts
[OK]   src\app\api\eco\points\replicar\route.ts (remove stray action token line)
       backup: tools\_patch_backup\eco-step-160\20260116-143444-src_app_api_eco_points_replicar_route.ts
[OK]   src\app\api\eco\points\support\route.ts (remove stray action token line)
       backup: tools\_patch_backup\eco-step-160\20260116-143444-src_app_api_eco_points_support_route.ts
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

./src/app/api/eco/points/route.ts:19:14
Type error: Cannot find name 'NextResponse'. Did you mean 'Response'?

  17 |     const lng = Number(body.lng);
  18 |     if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
> 19 |       return NextResponse.json({ ok: false, error: 'bad_latlng' }, { status: 400 });
     |              ^
  20 |     }
  21 |     if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
  22 |       return NextResponse.json({ ok: false, error: 'latlng_out_of_range' }, { status: 400 });
Next.js build worker exited with code: 1 and signal: null
~~~

