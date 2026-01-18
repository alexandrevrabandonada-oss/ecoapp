# eco-step-150 — fix build blockers — 20260116-132045

## Patch log
~~~
[SKIP] src\app\eco\mural-acoes\MuralAcoesClient.tsx (use client na 1a linha (hard): no change)
[SKIP] src\app\api\eco\mutirao\finish\route.ts (remove token "pointId",: no change)
[SKIP] src\app\api\eco\points\confirm\route.ts (fix regex literal quebrada (confirm): no change)
[SKIP] src\app\api\eco\points\replicar\route.ts (fix regex literal quebrada (replicar): no change)
[SKIP] src\app\api\eco\points\support\route.ts (fix regex literal quebrada (support): no change)
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
Error: Turbopack build failed with 7 errors:
./src/app/api/eco/mutirao/finish/route.ts:47:24
Parsing ecmascript source code failed
  45 | }
  46 | function findLinkedPointId(mut: any): string {
> 47 |   const keys = [pointId: null,"criticalPointId","ecoPointId","ecoCriticalPointId","pontoId","pontoCriticoId"];
     |                        ^
  48 |   for (const k of keys) {
  49 |     const v = mut?.[k];
  50 |     if (typeof v === "string" && v.trim()) return v.trim();

Expected ',', got ':'


./src/app/api/eco/points/confirm/route.ts:149:51
Parsing ecmascript source code failed
  147 |
  148 |     const base: any = {};
> 149 |     if (hasField(am.name, "id")) base.id = randId("
      |                                                   ^
  150 | c
  151 | ");
  152 |     base[fk] = pointId;

Unterminated string constant


./src/app/api/eco/points/replicar/route.ts:149:51
Parsing ecmascript source code failed
  147 |
  148 |     const base: any = {};
> 149 |     if (hasField(am.name, "id")) base.id = randId("
      |                                                   ^
  150 | r
  151 | ");
  152 |     base[fk] = pointId;

Unterminated string constant


./src/app/api/eco/points/support/route.ts:149:51
Parsing ecmascript source code failed
  147 |
  148 |     const base: any = {};
> 149 |     if (hasField(am.name, "id")) base.id = randId("
      |                                                   ^
  150 | s
  151 | ");
  152 |     base[fk] = pointId;

Unterminated string constant


./src/app/eco/mural-acoes/_components/MuralTopBarClient.tsx:21:7
Parsing ecmascript source code failed
  19 |         return (<Link key={t.href} href={t.href} className={cls}>{t.label}</Link>);
  20 |       })}
> 21 |       }
     |       ^
  22 |     </div>
  23 |   );
  24 | }

Unexpected token. Did you mean `{'}'}` or `&rbrace;`?

Import trace:
  Server Component:
    ./src/app/eco/mural-acoes/_components/MuralTopBarClient.tsx
    ./src/app/eco/mural-acoes/page.tsx


./src/app/pedidos/page.tsx:52:51
Parsing ecmascript source code failed
  50 |     try { json = JSON.parse(txt); } catch { json = { raw: txt }; }
  51 |
> 52 |     if (!res.ok) throw new Error(json?.error ?? ""GET /api/pickup-requests falhou"
     |                                                   ^^^
  53 |     items = pickItems(json);
  54 |   } catch (e: any) {
  55 |     err = e?.message ?? String(e);

Expected ',', got 'GET'


./src/app/recibo/[code]/recibo-client.tsx:56:74
Parsing ecmascript source code failed
  54 |       }
  55 |
> 56 |       if (!res.ok) throw new Error(json?.error ?? GET /api/receipts?code falhou ());
     |                                                                          ^^^^^^
  57 |       setReceipt(json?.receipt ?? null);
  58 |
  59 |       if (operatorToken) saveToken(operatorToken);

Expected ':', got 'falhou'

Import trace:
  Server Component:
    ./src/app/recibo/[code]/recibo-client.tsx
    ./src/app/recibo/[code]/page.tsx


    at <unknown> (./src/app/api/eco/mutirao/finish/route.ts:47:24)
    at <unknown> (./src/app/api/eco/points/confirm/route.ts:149:51)
    at <unknown> (./src/app/api/eco/points/replicar/route.ts:149:51)
    at <unknown> (./src/app/api/eco/points/support/route.ts:149:51)
    at <unknown> (./src/app/eco/mural-acoes/_components/MuralTopBarClient.tsx:21:7)
    at <unknown> (./src/app/pedidos/page.tsx:52:51)
    at <unknown> (./src/app/recibo/[code]/recibo-client.tsx:56:74)
~~~

### eslint (scopado ECO) src/app/eco + src/app/api/eco + src/lib/eco
~~~
(node:18960) ESLintIgnoreWarning: The ".eslintignore" file is no longer supported. Switch to using the "ignores" property in "eslint.config.js": https://eslint.org/docs/latest/use/configure/migration-guide#ignoring-files


(Use `node --trace-warnings ...` to show where the warning was created)





C:\Projetos\App ECO\eluta-servicos\src\app\api\eco\critical\confirm\route.ts


  15:38  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


  15:54  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


  16:40  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


  16:56  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


  19:56  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any





C:\Projetos\App ECO\eluta-servicos\src\app\api\eco\critical\create\route.ts


  15:38  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


  15:54  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


  17:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


  42:56  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


  59:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any





C:\Projetos\App ECO\eluta-servicos\src\app\api\eco\critical\list\route.ts


   7:22  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


  12:38  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


  12:54  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


  23:18  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


  27:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any





C:\Projetos\App ECO\eluta-servicos\src\app\api\eco\day-close\card\route.tsx


  21:19  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


  33:27  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


  57:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any





C:\Projetos\App ECO\eluta-servicos\src\app\api\eco\day-close\compute\route.ts


  33:13  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


  33:29  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


  37:77  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


  48:20  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


  68:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


  69:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any





C:\Projetos\App ECO\eluta-servicos\src\app\api\eco\day-close\list\route.ts


  20:13  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


  20:29  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any





C:\Projetos\App ECO\eluta-servicos\src\app\api\eco\day-close\route.ts


   35:13  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


   35:29  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


   40:13  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


   40:29  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


   44:77  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


   55:20  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


   75:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


   76:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


  139:56  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any





C:\Projetos\App ECO\eluta-servicos\src\app\api\eco\month-close\card\route.tsx


   13:19  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


   19:27  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


   28:20  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


   54:13  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


   54:29  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


   59:13  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


   59:29  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


   63:77  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


   72:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


   73:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


   83:43  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


   84:48  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


   86:37  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


  113:13  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


  113:29  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


  128:18  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


  128:50  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


  129:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


  129:54  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any





C:\Projetos\App ECO\eluta-servicos\src\app\api\eco\month-close\list\route.ts


   7:22  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


  16:13  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


  16:29  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


  22:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any





C:\Projetos\App ECO\eluta-servicos\src\app\api\eco\month-close\route.ts


   24:13  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


   24:29  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


   29:13  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


   29:29  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


   34:13  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


   34:29  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


   38:77  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


   43:20  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


   73:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


   74:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


   85:43  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


   86:48  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


   89:37  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


  142:56  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any





C:\Projetos\App ECO\eluta-servicos\src\app\api\eco\mural\list\route.ts


   13:13   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


   13:29   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


   20:77   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


   26:13   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


   26:29   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


   33:114  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


   38:20   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


   42:25   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


   43:22   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


   43:51   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


   43:84   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


   47:40   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


   47:52   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


   47:66   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


   55:46   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


   64:34   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


   65:32   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


   77:34   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


   77:57   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


  100:16   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


  105:14   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any


  115:37   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any





C:\Projetos\App ECO\eluta-servicos\src\app\api\eco\mutirao\card\route.tsx


... (truncado)
~~~

