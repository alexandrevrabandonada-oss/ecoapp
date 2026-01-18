# eco-step-196b — eslint9 ignores + any policy — 20260116-224346

## DIAG
- root: C:\Projetos\App ECO\eluta-servicos
- eslint.config.mjs: C:\Projetos\App ECO\eluta-servicos\eslint.config.mjs
- tamanho: 465 chars

### pistas (export default / const)
- export default eslintConfig;

## PATCH
- backup: C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\eslint.config.mjs--20260116-224346
- WARN: achei export default eslintConfig, mas nao achei declaracao eslintConfig = [
- inseriu any policy antes do fechamento do array
- escreveu eslint.config.mjs

## VERIFY
- rodando: npm run lint (primeiras 120 linhas)
- exit: 0

---

> eluta-servicos@0.1.0 lint
> eslint


C:\Projetos\App ECO\eluta-servicos\src\app\api\eco\points\react\route.ts
  66:14  warning  'e' is defined but never used  @typescript-eslint/no-unused-vars

C:\Projetos\App ECO\eluta-servicos\src\app\api\eco\points\resolve\route.ts
  34:10  warning  'normStatus' is defined but never used  @typescript-eslint/no-unused-vars

C:\Projetos\App ECO\eluta-servicos\src\app\api\pickup-requests\[id]\route.ts
  32:13  warning  'id' is assigned a value but never used  @typescript-eslint/no-unused-vars

C:\Projetos\App ECO\eluta-servicos\src\app\api\pickup-requests\route.ts
  5:7   warning  'ECO_TOKEN_HEADER' is assigned a value but never used  @typescript-eslint/no-unused-vars
  9:10  warning  'ecoStripReceiptForAnon' is defined but never used     @typescript-eslint/no-unused-vars

C:\Projetos\App ECO\eluta-servicos\src\app\chamar\page.tsx
   14:44  warning  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   31:21  warning  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   52:22  warning  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   75:19  warning  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   94:91  warning  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  122:34  warning  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\coleta\novo\page.tsx
   21:44  warning  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   38:21  warning  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   59:22  warning  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   82:19  warning  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  104:31  warning  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  122:91  warning  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\coleta\p\[id]\page.tsx
  4:12  warning  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  4:28  warning  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\coleta\p\[id]\point-detail.tsx
   39:38  warning  Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
   40:44  warning  Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
   60:20  warning  Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
   61:20  warning  Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
   72:54  warning  Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
   84:29  warning  Unused eslint-disable directive (no problems were reported)
   84:63  warning  React Hook useEffect has a missing dependency: 'load'. Either include it or remove the dependency array  react-hooks/exhaustive-deps
   98:22  warning  Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
  115:19  warning  Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
  121:17  warning  Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
  138:17  warning  Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
  168:29  warning  Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
  179:89  warning  Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\coleta\p\[id]\ponto-client.tsx
   15:44  warning  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   34:22  warning  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   35:22  warning  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   46:61  warning  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   54:19  warning  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   70:22  warning  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   88:17  warning  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  157:35  warning  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  166:95  warning  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\coleta\points-table.tsx
   40:40  warning  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   54:19  warning  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   81:30  warning  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  112:34  warning  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  121:19  warning  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  124:17  warning  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  131:30  warning  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  138:17  warning  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  232:31  warning  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\eco\_components\ConfirmadoBadge.tsx
   3:15  warning  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   5:17  warning  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  15:28  warning  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  20:14  warning  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  21:14  warning  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  22:14  warning  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  23:14  warning  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  24:14  warning  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  28:27  warning  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  34:14  warning  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  35:14  warning  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  36:14  warning  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  37:14  warning  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\eco\_components\EcoPointResolutionPanel.tsx
  10:36   warning  Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
  29:115  warning  Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
  33:17   warning  Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
  42:6    warning  React Hook useEffect has a missing dependency: 'load'. Either include it or remove the dependency array  react-hooks/exhaustive-deps
  57:17   warning  Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
  85:17   warning  Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\eco\_components\EcoPoints30dWidget.tsx
   8:36  warning  Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
  19:98  warning  Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
  23:17  warning  Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
  30:37  warning  React Hook useEffect has a missing dependency: 'load'. Either include it or remove the dependency array  react-hooks/exhaustive-deps

C:\Projetos\App ECO\eluta-servicos\src\app\eco\_components\PointActionBar.tsx
  13:21  warning  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  30:68  warning  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  53:16  warning  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  65:17  warning  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  77:19  warning  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  77:32  warning  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\eco\_components\PointActionsInline.tsx
    5:15   warning  Unexpected any. Specify a different type                                                                @typescript-eslint/no-explicit-any
    7:19   warning  Unexpected any. Specify a different type                                                                @typescript-eslint/no-explicit-any
   14:19   warning  Unexpected any. Specify a different type                                                                @typescript-eslint/no-explicit-any
   14:42   warning  Unexpected any. Specify a different type                                                                @typescript-eslint/no-explicit-any
   14:60   warning  Unexpected any. Specify a different type                                                                @typescript-eslint/no-explicit-any
   14:85   warning  Unexpected any. Specify a different type                                                                @typescript-eslint/no-explicit-any
   14:109  warning  Unexpected any. Specify a different type                                                                @typescript-eslint/no-explicit-any