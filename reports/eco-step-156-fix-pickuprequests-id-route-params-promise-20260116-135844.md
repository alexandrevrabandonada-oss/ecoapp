# eco-step-156 — fix pickup-requests/[id] params Promise — 20260116-135844

## Patch log
~~~
[OK]   src\app\api\pickup-requests\[id]\route.ts (Next 16 handler signatures (GET/PATCH/DELETE/POST) + params Promise)
       backup: tools\_patch_backup\eco-step-156\20260116-135844-src_app_api_pickup-requests__id__route.ts
~~~

## VERIFY
### npm run build
~~~

> eluta-servicos@0.1.0 build
> next build

   Ôû▓ Next.js 16.0.10 (Turbopack)
   - Environments: .env

   Creating an optimized production build ...
 Ô£ô Compiled successfully in 5.3s
   Running TypeScript ...
Failed to compile.

.next/dev/types/validator.ts:900:31
Type error: Type 'typeof import("C:/Projetos/App ECO/eluta-servicos/src/app/api/receipts/[code]/public/route")' does not satisfy the constraint 'RouteHandlerConfig<"/api/receipts/[code]/public">'.
  Types of property 'PATCH' are incompatible.
    Type '(req: Request, { params }: { params: { code: string; }; }) => Promise<NextResponse<{ error: string; }> | NextResponse<{ code: string; public: boolean; }>>' is not assignable to type '(request: NextRequest, context: { params: Promise<{ code: string; }>; }) => void | Response | Promise<void | Response>'.
      Types of parameters '__1' and 'context' are incompatible.
        Type '{ params: Promise<{ code: string; }>; }' is not assignable to type '{ params: { code: string; }; }'.
          Types of property 'params' are incompatible.
            Property 'code' is missing in type 'Promise<{ code: string; }>' but required in type '{ code: string; }'.

  898 |   type __IsExpected<Specific extends RouteHandlerConfig<"/api/receipts/[code]/public">> = Specific
  899 |   const handler = {} as typeof import("../../../src/app/api/receipts/[code]/public/route.js")
> 900 |   type __Check = __IsExpected<typeof handler>
      |                               ^
  901 |   // @ts-ignore
  902 |   type __Unused = __Check
  903 | }
Next.js build worker exited with code: 1 and signal: null
~~~

