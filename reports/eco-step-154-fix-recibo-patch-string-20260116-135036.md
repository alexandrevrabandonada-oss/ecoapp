# eco-step-154 — fix recibo PATCH string — 20260116-135036

## Patch log
~~~
[OK]   patched: src\app\recibo\[code]\recibo-client.tsx
~~~

## VERIFY
### npm run build
~~~

> eluta-servicos@0.1.0 build
> next build

   Ôû▓ Next.js 16.0.10 (Turbopack)
   - Environments: .env

   Creating an optimized production build ...
 Ô£ô Compiled successfully in 4.4s
   Running TypeScript ...
Failed to compile.

.next/dev/types/validator.ts:837:31
Type error: Type 'typeof import("C:/Projetos/App ECO/eluta-servicos/src/app/api/pickup-requests/[id]/receipt/route")' does not satisfy the constraint 'RouteHandlerConfig<"/api/pickup-requests/[id]/receipt">'.
  Types of property 'POST' are incompatible.
    Type '(req: Request, ctx: { params: { id: string; }; }) => Promise<NextResponse<{ ok: boolean; error: string; }> | NextResponse<{ ok: boolean; receipt: any; }>>' is not assignable to type '(request: NextRequest, context: { params: Promise<{ id: string; }>; }) => void | Response | Promise<void | Response>'.
      Types of parameters 'ctx' and 'context' are incompatible.
        Type '{ params: Promise<{ id: string; }>; }' is not assignable to type '{ params: { id: string; }; }'.
          Types of property 'params' are incompatible.
            Property 'id' is missing in type 'Promise<{ id: string; }>' but required in type '{ id: string; }'.

  835 |   type __IsExpected<Specific extends RouteHandlerConfig<"/api/pickup-requests/[id]/receipt">> = Specific
  836 |   const handler = {} as typeof import("../../../src/app/api/pickup-requests/[id]/receipt/route.js")
> 837 |   type __Check = __IsExpected<typeof handler>
      |                               ^
  838 |   // @ts-ignore
  839 |   type __Unused = __Check
  840 | }
Next.js build worker exited with code: 1 and signal: null
~~~