# eco-step-155 — fix routehandler params Promise — 20260116-135431

## Patch log
~~~
[OK]   src\app\api\pickup-requests\[id]\receipt\route.ts (route handler POST params Promise (pickup-requests/[id]/receipt))
       backup: tools\_patch_backup\eco-step-155\20260116-135431-src_app_api_pickup-requests__id__receipt_route.ts
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

.next/dev/types/validator.ts:846:31
Type error: Type 'typeof import("C:/Projetos/App ECO/eluta-servicos/src/app/api/pickup-requests/[id]/route")' does not satisfy the constraint 'RouteHandlerConfig<"/api/pickup-requests/[id]">'.
  Types of property 'PATCH' are incompatible.
    Type '(req: Request, ctx: { params: { id: string; }; }) => Promise<NextResponse<{ ok: boolean; error: string; }> | NextResponse<{ ok: boolean; item: any; }>>' is not assignable to type '(request: NextRequest, context: { params: Promise<{ id: string; }>; }) => void | Response | Promise<void | Response>'.
      Types of parameters 'ctx' and 'context' are incompatible.
        Type '{ params: Promise<{ id: string; }>; }' is not assignable to type '{ params: { id: string; }; }'.
          Types of property 'params' are incompatible.
            Property 'id' is missing in type 'Promise<{ id: string; }>' but required in type '{ id: string; }'.

  844 |   type __IsExpected<Specific extends RouteHandlerConfig<"/api/pickup-requests/[id]">> = Specific
  845 |   const handler = {} as typeof import("../../../src/app/api/pickup-requests/[id]/route.js")
> 846 |   type __Check = __IsExpected<typeof handler>
      |                               ^
  847 |   // @ts-ignore
  848 |   type __Unused = __Check
  849 | }
Next.js build worker exited with code: 1 and signal: null
~~~

