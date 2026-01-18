# eco-step-148b — verify + smoke (auto dev) — 20260116-212512

## VERIFY (offline)

### npm run lint
~~~

> eluta-servicos@0.1.0 lint
> eslint

(node:16000) ESLintIgnoreWarning: The ".eslintignore" file is no longer supported. Switch to using the "ignores" property in "eslint.config.js": https://eslint.org/docs/latest/use/configure/migration-guide#ignoring-files
(Use `node --trace-warnings ...` to show where the warning was created)

C:\Projetos\App ECO\eluta-servicos\src\app\api\dev\seed-eco\route.ts
   11:41  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   15:21  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   16:21  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   16:34  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   25:19  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   32:30  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   34:27  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   55:42  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   62:24  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   72:25  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   77:30  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   85:68  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   85:92  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   85:98  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   88:14  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  129:62  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  138:34  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  161:22  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  161:38  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  190:44  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  194:44  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  201:19  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  220:23  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  235:23  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  251:23  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  271:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

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
    7:21  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   14:22  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   20:13  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   20:29  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   24:79  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   28:21  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   32:23  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  117:83  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  118:37  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  118:64  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  119:37  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  119:64  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\api\eco\mutirao\create\route.ts
  15:40  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  15:56  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  16:38  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  16:54  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  19:56  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\api\eco\mutirao\finish\route.ts
   15:21   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   21:13   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   21:29   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   25:113  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   30:13   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   30:29   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   34:113  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   38:33   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   38:56   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   46:33   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   55:26   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   61:33   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   78:27   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   80:14   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   81:29   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   82:28   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   83:29   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   84:28   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   96:56   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  122:31   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  124:18   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  125:18   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  126:32   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  127:33   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  128:32   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  139:19   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\api\eco\mutirao\get\route.ts
  16:13  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  16:29  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  20:79  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\api\eco\mutirao\list\route.ts
   7:22  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  19:40  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  19:56  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  38:18  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  47:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\api\eco\mutirao\proof\route.ts
  16:13   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  16:29   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  20:113  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  24:21   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  31:56   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  46:23   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  47:42   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  48:44   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\api\eco\mutirao\update\route.ts
  16:13  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  16:29  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  20:75  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  24:22  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  31:56  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  43:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\api\eco\point\reopen\route.ts
  16:13  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  16:29  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  20:75  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  26:56  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\api\eco\points\action\route.ts
   12:30  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   17:21  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   18:21  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   18:34  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   20:23  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   24:22  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   29:33  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   33:52  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   34:31  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   36:46  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   37:31  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   41:63  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   43:27  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   57:25  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   61:36  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  101:29  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  115:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  115:31  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  152:21  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  186:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\api\eco\points\card\route.tsx
  18:24  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  35:13  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  38:14  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\api\eco\points\confirm\route.ts
   13:21  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   14:21  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   14:34  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   17:23  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   22:22  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   28:33  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   33:52  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   34:31  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   37:46  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   38:31  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   43:63  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   46:27  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   61:30  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   64:30  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   69:68  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   69:79  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   69:85  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   71:14  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   97:62  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  119:47  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  129:54  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  133:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  133:31  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  148:20  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  157:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  168:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\api\eco\points\get\route.ts
  18:13  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  18:29  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  29:79  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\api\eco\points\map\route.ts
   16:13  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   16:29  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   20:77  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   24:24  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   32:21  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   34:21  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   39:21  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   41:21  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   47:26  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   50:27  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   51:35  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   57:27  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   57:60  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   58:27  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   58:60  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   72:11  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   87:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   89:20  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  104:16  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  106:35  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  107:24  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  107:57  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  108:24  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  108:57  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  132:18  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  132:26  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\api\eco\points\react\route.ts
  20:13  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  20:29  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  31:75  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  35:24  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  44:20  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  49:24  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  53:64  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  55:36  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  57:37  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  57:75  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  62:19  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  66:14  warning  'e' is defined but never used             @typescript-eslint/no-unused-vars
  74:56  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  86:14  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  98:19  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\api\eco\points\replicar\route.ts
   13:21  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   14:21  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   14:34  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   17:23  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   22:22  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   28:33  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   33:52  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   34:31  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   37:46  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   38:31  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   43:63  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   46:27  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   61:30  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   64:30  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   69:68  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   69:79  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   69:85  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   71:14  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   97:62  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  119:47  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  129:54  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  133:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  133:31  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  148:20  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  157:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  169:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\api\eco\points\report\route.ts
   16:13   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   16:29   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   20:111  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   24:21   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   29:21   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   48:56   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   79:21   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   96:15   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   99:32   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   99:51   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  100:32   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  100:51   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  100:70   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  102:24   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  102:57   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  113:54   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  119:21   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  135:22   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  139:22   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\api\eco\points\resolve\route.ts
  18:13   error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  18:29   error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  29:113  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  34:10   warning  'normStatus' is defined but never used    @typescript-eslint/no-unused-vars
  34:24   error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  39:56   error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  55:20   error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  65:17   error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\api\eco\points\route.ts
   47:17   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   89:15   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   89:31   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  107:16   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  110:17   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  110:58   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  113:19   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  116:18   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  122:35   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  125:102  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  128:99   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  134:32   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  137:62   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  155:22   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  170:24   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  188:17   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  194:20   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  308:15   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\api\eco\points\stats\route.ts
  16:13   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  16:29   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  20:77   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  24:24   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  32:26   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  48:15   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  62:16   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  68:24   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  68:57   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  69:24   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  69:57   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  79:35   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  93:83   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  93:107  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\api\eco\points\support\route.ts
   13:21  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   14:21  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   14:34  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   17:23  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   22:22  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   28:33  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   33:52  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   34:31  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   37:46  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   38:31  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   43:63  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   46:27  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   61:30  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   64:30  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   69:68  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   69:79  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   69:85  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   71:14  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   97:62  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  119:47  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  129:54  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  133:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  133:31  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  148:20  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  157:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  168:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\api\eco\recibo\list\route.ts
  17:13  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  17:29  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  20:77  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  25:24  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  38:14  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\api\eco\upload\route.ts
   9:25  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  15:32  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  16:29  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  34:34  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  55:88  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  56:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\api\pickup-requests\[id]\receipt\route.ts
  77:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\api\pickup-requests\[id]\route.ts
  32:13  warning  'id' is assigned a value but never used   @typescript-eslint/no-unused-vars
  41:54  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  42:17  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  51:38  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  57:15  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\api\pickup-requests\bulk\route.ts
  43:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  45:62  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\api\pickup-requests\route.ts
    5:7    warning  'ECO_TOKEN_HEADER' is assigned a value but never used  @typescript-eslint/no-unused-vars
    9:10   warning  'ecoStripReceiptForAnon' is defined but never used     @typescript-eslint/no-unused-vars
    9:42   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
   14:12   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
   22:32   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
   23:13   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
   25:23   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
   53:22   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
   53:38   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
   54:20   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
   54:36   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
   88:28   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  100:22   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  105:30   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  107:34   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  108:35   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  111:25   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  111:61   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  111:114  error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  112:25   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  112:62   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  112:117  error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  114:23   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  114:74   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  114:124  error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  117:37   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  121:30   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  122:35   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  123:35   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  124:35   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  126:32   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  146:17   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  147:30   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  154:41   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  155:33   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  156:39   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  157:25   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  160:25   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  194:66   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  195:38   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  196:25   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  197:34   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  199:20   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  199:42   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  199:89   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\api\points\[id]\route.ts
  11:28  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  24:28  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  27:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  29:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\api\points\route.ts
   12:22  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   12:38  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   13:24  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   13:40  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   14:23  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   14:39  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   15:20  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   15:36  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   16:20  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   16:36  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   35:23  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   51:29  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   62:24  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   82:28  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   97:36  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   99:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  100:30  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  112:58  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  125:32  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  130:39  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  137:30  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  142:30  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  147:30  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  152:30  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  157:30  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  163:31  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  218:31  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  249:36  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\api\receipts\[code]\public\route.ts
  44:38  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  49:34  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\api\receipts\[code]\route.ts
   11:23  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   11:39  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   12:20  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   12:36  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   62:28  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   63:28  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   68:14  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   69:28  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   70:28  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   71:28  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   75:47  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  105:48  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  120:31  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\api\receipts\public\route.ts
  20:18  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  24:19  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  29:14  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  29:37  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  44:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\api\receipts\route.ts
    7:51  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   29:22  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   29:38  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   30:24  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   30:40  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   31:23  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   31:39  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   32:20  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   32:36  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   33:20  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   33:36  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   34:20  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   34:36  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  101:28  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  102:28  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  106:28  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  107:28  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  111:28  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  112:28  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  115:65  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  116:30  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  117:28  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  118:28  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  119:28  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  129:66  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  130:29  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  131:35  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  144:41  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  189:39  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  189:66  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  208:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  209:30  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  253:36  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  255:59  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  256:57  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  261:23  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  265:19  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  278:18  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  288:49  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\api\requests\[id]\route.ts
   4:46  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   5:14  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  10:48  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  11:14  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\api\services\route.ts
  13:49  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  14:27  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  15:51  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  19:19  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  20:16  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  22:14  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  33:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  58:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\api\share\receipt-card\route.tsx
   5:29  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  28:12  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\api\share\route-day-card\route.ts
  109:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\chamar\page.tsx
   14:44  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   31:21  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   52:22  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   75:19  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   94:91  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  122:34  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\coleta\novo\page.tsx
   21:44  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   38:21  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   59:22  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   82:19  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  104:31  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  122:91  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\coleta\p\[id]\page.tsx
  4:12  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  4:28  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\coleta\p\[id]\point-detail.tsx
   39:38  error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
   40:44  error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
   60:20  error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
   61:20  error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
   72:54  error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
   84:29  warning  Unused eslint-disable directive (no problems were reported)
   84:63  warning  React Hook useEffect has a missing dependency: 'load'. Either include it or remove the dependency array  react-hooks/exhaustive-deps
   98:22  error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
  115:19  error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
  121:17  error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
  138:17  error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
  168:29  error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
  179:89  error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\coleta\p\[id]\ponto-client.tsx
   15:44  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   34:22  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   35:22  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   46:61  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   54:19  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   70:22  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   88:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  157:35  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  166:95  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\coleta\points-table.tsx
   40:40  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   54:19  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   81:30  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  112:34  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  121:19  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  124:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  131:30  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  138:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  232:31  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\eco\_components\ConfirmadoBadge.tsx
   3:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   5:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  15:28  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  20:14  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  21:14  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  22:14  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  23:14  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  24:14  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  28:27  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  34:14  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  35:14  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  36:14  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  37:14  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\eco\_components\EcoPointResolutionPanel.tsx
  10:36   error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
  29:115  error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
  33:17   error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
  42:6    warning  React Hook useEffect has a missing dependency: 'load'. Either include it or remove the dependency array  react-hooks/exhaustive-deps
  57:17   error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
  85:17   error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\eco\_components\EcoPoints30dWidget.tsx
   8:36  error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
  19:98  error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
  23:17  error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
  30:37  warning  React Hook useEffect has a missing dependency: 'load'. Either include it or remove the dependency array  react-hooks/exhaustive-deps

C:\Projetos\App ECO\eluta-servicos\src\app\eco\_components\PointActionBar.tsx
  13:21  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  30:68  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  53:16  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  65:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  77:19  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  77:32  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\eco\_components\PointActionsInline.tsx
    5:15   error    Unexpected any. Specify a different type                                                                @typescript-eslint/no-explicit-any
    7:19   error    Unexpected any. Specify a different type                                                                @typescript-eslint/no-explicit-any
   14:19   error    Unexpected any. Specify a different type                                                                @typescript-eslint/no-explicit-any
   14:42   error    Unexpected any. Specify a different type                                                                @typescript-eslint/no-explicit-any
   14:60   error    Unexpected any. Specify a different type                                                                @typescript-eslint/no-explicit-any
   14:85   error    Unexpected any. Specify a different type                                                                @typescript-eslint/no-explicit-any
   14:109  error    Unexpected any. Specify a different type                                                                @typescript-eslint/no-explicit-any
   19:17   error    Unexpected any. Specify a different type                                                                @typescript-eslint/no-explicit-any
   19:39   error    Unexpected any. Specify a different type                                                                @typescript-eslint/no-explicit-any
   19:68   error    Unexpected any. Specify a different type                                                                @typescript-eslint/no-explicit-any
   19:96   error    Unexpected any. Specify a different type                                                                @typescript-eslint/no-explicit-any
   22:44   error    Unexpected any. Specify a different type                                                                @typescript-eslint/no-explicit-any
   29:22   error    Unexpected any. Specify a different type                                                                @typescript-eslint/no-explicit-any
   29:64   error    Unexpected any. Specify a different type                                                                @typescript-eslint/no-explicit-any
   43:6    warning  React Hook useMemo has a missing dependency: 'props'. Either include it or remove the dependency array  react-hooks/exhaustive-deps
   47:6    warning  React Hook useMemo has a missing dependency: 'props'. Either include it or remove the dependency array  react-hooks/exhaustive-deps
   52:37   error    Unexpected any. Specify a different type                                                                @typescript-eslint/no-explicit-any
   52:64   error    Unexpected any. Specify a different type                                                                @typescript-eslint/no-explicit-any
   52:96   error    Unexpected any. Specify a different type                                                                @typescript-eslint/no-explicit-any
   53:37   error    Unexpected any. Specify a different type                                                                @typescript-eslint/no-explicit-any
   53:64   error    Unexpected any. Specify a different type                                                                @typescript-eslint/no-explicit-any
   54:38   error    Unexpected any. Specify a different type                                                                @typescript-eslint/no-explicit-any
   54:66   error    Unexpected any. Specify a different type                                                                @typescript-eslint/no-explicit-any
   58:19   error    Unexpected any. Specify a different type                                                                @typescript-eslint/no-explicit-any
   72:20   error    Unexpected any. Specify a different type                                                                @typescript-eslint/no-explicit-any
  101:17   error    Unexpected any. Specify a different type                                                                @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\eco\_components\PointReplicarButton.tsx
  10:12  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\eco\_components\PointSupportButton.tsx
   5:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   7:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  12:27  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  17:35  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  37:51  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\eco\_ui\PointStatus.tsx
   5:31  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  12:35  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  16:31  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  20:33  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  24:31  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  28:40  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\eco\fechamento\FechamentoClient.tsx
   5:30  error    Unexpected any. Specify a different type                                                        @typescript-eslint/no-explicit-any
  59:5   warning  Unused eslint-disable directive (no problems were reported from 'react-hooks/exhaustive-deps')

C:\Projetos\App ECO\eluta-servicos\src\app\eco\mapa\MapaClient.tsx
  16:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  48:83  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  53:19  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\eco\mapa\_components\MapaClient.tsx
   6:30  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   8:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  51:19  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  63:22  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  97:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\eco\mural-acoes\MuralAcoesClient.tsx
    2:10  warning  'dt' is defined but never used                          @typescript-eslint/no-unused-vars
    2:16  error    Unexpected any. Specify a different type                @typescript-eslint/no-explicit-any
    7:17  error    Unexpected any. Specify a different type                @typescript-eslint/no-explicit-any
   12:10  warning  'score' is defined but never used                       @typescript-eslint/no-unused-vars
   12:19  error    Unexpected any. Specify a different type                @typescript-eslint/no-explicit-any
   24:7   warning  '__ECO_REF_GUARD__' is assigned a value but never used  @typescript-eslint/no-unused-vars
   25:10  error    Unexpected any. Specify a different type                @typescript-eslint/no-explicit-any
   26:7   warning  'it' is assigned a value but never used                 @typescript-eslint/no-unused-vars
   26:11  error    Unexpected any. Specify a different type                @typescript-eslint/no-explicit-any
   27:7   warning  'item' is assigned a value but never used               @typescript-eslint/no-unused-vars
   27:13  error    Unexpected any. Specify a different type                @typescript-eslint/no-explicit-any
   38:21  error    Unexpected any. Specify a different type                @typescript-eslint/no-explicit-any
   43:29  error    Unexpected any. Specify a different type                @typescript-eslint/no-explicit-any
   52:28  error    Unexpected any. Specify a different type                @typescript-eslint/no-explicit-any
   67:41  error    Unexpected any. Specify a different type                @typescript-eslint/no-explicit-any
   88:63  error    Unexpected any. Specify a different type                @typescript-eslint/no-explicit-any
   88:81  error    Unexpected any. Specify a different type                @typescript-eslint/no-explicit-any
  117:58  error    Unexpected any. Specify a different type                @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\eco\mural\MuralClient.tsx
    5:7   warning  '__ECO_REF_GUARD__' is assigned a value but never used  @typescript-eslint/no-unused-vars
    6:7   warning  'p' is assigned a value but never used                  @typescript-eslint/no-unused-vars
    6:10  error    Unexpected any. Specify a different type                @typescript-eslint/no-explicit-any
    7:7   warning  'it' is assigned a value but never used                 @typescript-eslint/no-unused-vars
    7:11  error    Unexpected any. Specify a different type                @typescript-eslint/no-explicit-any
    8:7   warning  'item' is assigned a value but never used               @typescript-eslint/no-unused-vars
    8:13  error    Unexpected any. Specify a different type                @typescript-eslint/no-explicit-any
   16:8   warning  'MuralPointActionsClient' is defined but never used     @typescript-eslint/no-unused-vars
   18:15  error    Unexpected any. Specify a different type                @typescript-eslint/no-explicit-any
   20:17  error    Unexpected any. Specify a different type                @typescript-eslint/no-explicit-any
   24:16  error    Unexpected any. Specify a different type                @typescript-eslint/no-explicit-any
   29:19  error    Unexpected any. Specify a different type                @typescript-eslint/no-explicit-any
   73:42  error    Unexpected any. Specify a different type                @typescript-eslint/no-explicit-any
  103:28  error    Unexpected any. Specify a different type                @typescript-eslint/no-explicit-any
  109:20  error    Unexpected any. Specify a different type                @typescript-eslint/no-explicit-any
  109:28  error    Unexpected any. Specify a different type                @typescript-eslint/no-explicit-any
  122:15  error    Unexpected any. Specify a different type                @typescript-eslint/no-explicit-any
  123:19  error    Unexpected any. Specify a different type                @typescript-eslint/no-explicit-any
  124:16  error    Unexpected any. Specify a different type                @typescript-eslint/no-explicit-any
  125:15  error    Unexpected any. Specify a different type                @typescript-eslint/no-explicit-any
  126:17  error    Unexpected any. Specify a different type                @typescript-eslint/no-explicit-any
  127:15  error    Unexpected any. Specify a different type                @typescript-eslint/no-explicit-any
  144:25  error    Unexpected any. Specify a different type                @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\eco\mural\_components\MuralInlineMapa.tsx
   18:17   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   24:20   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   24:38   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   27:20   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   27:38   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   89:55   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  132:32   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  132:67   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  132:108  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\eco\mural\_components\MuralNavPillsClient.tsx
  11:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  12:13  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  13:14  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\eco\mural\_components\MuralNewPointClient.tsx
   6:19  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  23:14  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  23:34  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  32:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  44:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  64:22  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  74:51  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\eco\mural\_components\MuralPointActionsClient.tsx
   6:30  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   8:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  35:13  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\eco\mural\_components\MuralTopBar.tsx
    9:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   10:19  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   12:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   17:23  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   74:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   75:14  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   84:14  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   95:14  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  101:12  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  102:12  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  103:14  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  115:32  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  135:35  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  155:32  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\eco\mural\_components\MuralTopBarClient.tsx
    6:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
    8:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   13:23  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   79:30  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  126:25  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  127:22  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  128:28  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  136:19  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  137:16  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  142:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  142:25  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  146:16  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  151:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  151:25  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  158:18  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  158:26  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  161:39  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  168:45  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  175:14  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  176:12  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  177:12  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  178:14  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  200:41  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  220:44  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  240:41  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\eco\mural\page.tsx
  11:25  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\eco\mutiroes\MutiroesClient.tsx
   5:30  error    Unexpected any. Specify a different type                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    @typescript-eslint/no-explicit-any
  37:21  error    Error: Calling setState synchronously within an effect can trigger cascading renders

Effects are intended to synchronize state between React and external systems such as manually updating the DOM, state management libraries, or other platform APIs. In general, the body of an effect should do one or both of the following:
* Update external systems with the latest state from React.
* Subscribe for updates from some external system, calling setState in a callback function when external state changes.

Calling setState synchronously within an effect body causes cascading renders that can hurt performance, and is not recommended. (https://react.dev/learn/you-might-not-need-an-effect).

C:\Projetos\App ECO\eluta-servicos\src\app\eco\mutiroes\MutiroesClient.tsx:37:21
  35 |     else { setItems([]); setStatus("erro"); }
  36 |   }
> 37 |   useEffect(() => { refresh(); }, []);
     |                     ^^^^^^^ Avoid calling setState() directly within an effect
  38 |
  39 |   return (
  40 |     <section style={{ display: "grid", gap: 10 }}>  react-hooks/set-state-in-effect
  37:35  warning  React Hook useEffect has a missing dependency: 'refresh'. Either include it or remove the dependency array                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  react-hooks/exhaustive-deps
  45:9   error    Do not use an `<a>` element to navigate to `/eco/pontos/`. Use `<Link />` from `next/link` instead. See: https://nextjs.org/docs/messages/no-html-link-for-pages                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            @next/next/no-html-link-for-pages

C:\Projetos\App ECO\eluta-servicos\src\app\eco\mutiroes\[id]\MutiraoDetailClient.tsx
    5:30   error    Unexpected any. Specify a different type                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       @typescript-eslint/no-explicit-any
   65:21   error    Error: Calling setState synchronously within an effect can trigger cascading renders

Effects are intended to synchronize state between React and external systems such as manually updating the DOM, state management libraries, or other platform APIs. In general, the body of an effect should do one or both of the following:
* Update external systems with the latest state from React.
* Subscribe for updates from some external system, calling setState in a callback function when external state changes.

Calling setState synchronously within an effect body causes cascading renders that can hurt performance, and is not recommended. (https://react.dev/learn/you-might-not-need-an-effect).

C:\Projetos\App ECO\eluta-servicos\src\app\eco\mutiroes\[id]\MutiraoDetailClient.tsx:65:21
  63 |     }
  64 |   }
> 65 |   useEffect(() => { refresh(); }, [id]);
     |                     ^^^^^^^ Avoid calling setState() directly within an effect
  66 |
  67 |   function toggle(k: string) { setCheck((prev: AnyObj) => ({ ...prev, [k]: !prev?.[k] })); }
  68 |  react-hooks/set-state-in-effect
   65:35   warning  React Hook useEffect has a missing dependency: 'refresh'. Either include it or remove the dependency array                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     react-hooks/exhaustive-deps
  106:9    error    Do not use an `<a>` element to navigate to `/eco/mutiroes/`. Use `<Link />` from `next/link` instead. See: https://nextjs.org/docs/messages/no-html-link-for-pages                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             @next/next/no-html-link-for-pages
  130:24   warning  Using `<img>` could result in slower LCP and higher bandwidth. Consider using `<Image />` from `next/image` or a custom image loader to automatically optimize images. This may incur additional usage or cost from your provider. See: https://nextjs.org/docs/messages/no-img-element                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        @next/next/no-img-element
  145:23   warning  Using `<img>` could result in slower LCP and higher bandwidth. Consider using `<Image />` from `next/image` or a custom image loader to automatically optimize images. This may incur additional usage or cost from your provider. See: https://nextjs.org/docs/messages/no-img-element                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        @next/next/no-img-element
  160:45   error    Unexpected any. Specify a different type                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       @typescript-eslint/no-explicit-any
  160:102  error    Unexpected any. Specify a different type                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\eco\mutiroes\[id]\finalizar\MutiraoFinishClient.tsx
  28:36  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\eco\mutiroes\[id]\finalizar\page.tsx
  3:48  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  4:12  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  4:35  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\eco\pontos\PontosClient.tsx
    5:30  error    Unexpected any. Specify a different type                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     @typescript-eslint/no-explicit-any
   67:21  error    Error: Calling setState synchronously within an effect can trigger cascading renders

Effects are intended to synchronize state between React and external systems such as manually updating the DOM, state management libraries, or other platform APIs. In general, the body of an effect should do one or both of the following:
* Update external systems with the latest state from React.
* Subscribe for updates from some external system, calling setState in a callback function when external state changes.

Calling setState synchronously within an effect body causes cascading renders that can hurt performance, and is not recommended. (https://react.dev/learn/you-might-not-need-an-effect).

C:\Projetos\App ECO\eluta-servicos\src\app\eco\pontos\PontosClient.tsx:67:21
  65 |     else { setItems([]); setStatus("erro"); }
  66 |   }
> 67 |   useEffect(() => { refresh(); }, [listUrl]);
     |                     ^^^^^^^ Avoid calling setState() directly within an effect
  68 |
  69 |   async function useGeo() {
  70 |     setMsg("");  react-hooks/set-state-in-effect
   67:35  warning  React Hook useEffect has a missing dependency: 'refresh'. Either include it or remove the dependency array                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   react-hooks/exhaustive-deps
  146:9   error    Do not use an `<a>` element to navigate to `/eco/mutiroes/`. Use `<Link />` from `next/link` instead. See: https://nextjs.org/docs/messages/no-html-link-for-pages                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           @next/next/no-html-link-for-pages

C:\Projetos\App ECO\eluta-servicos\src\app\eco\pontos\[id]\PointDetailClient.tsx
    5:10   warning  'PointBadge' is defined but never used                                                                   @typescript-eslint/no-unused-vars
    5:22   warning  'markerFill' is defined but never used                                                                   @typescript-eslint/no-unused-vars
    5:34   warning  'markerBorder' is defined but never used                                                                 @typescript-eslint/no-unused-vars
    6:24   error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
   13:22   error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
   17:23   error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
   18:12   error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
   58:10   warning  'ProofBlock' is defined but never used                                                                   @typescript-eslint/no-unused-vars
   58:33   error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
  101:15   error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
  150:108  error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
  154:17   error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
  161:37   warning  React Hook useEffect has a missing dependency: 'load'. Either include it or remove the dependency array  react-hooks/exhaustive-deps
  176:17   error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
  195:17   error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
  251:82   error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
  255:77   error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\eco\pontos\[id]\resolver\PointResolveClient.tsx
    5:56  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
    5:68  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
    7:24  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   14:24  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   18:23  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   33:47  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   55:36  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   79:19  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  103:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\eco\pontos\[id]\resolver\page.tsx
  8:48  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  9:30  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\eco\recibos\RecibosClient.tsx
   5:30  error    Unexpected any. Specify a different type                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            @typescript-eslint/no-explicit-any
  55:21  error    Error: Calling setState synchronously within an effect can trigger cascading renders

Effects are intended to synchronize state between React and external systems such as manually updating the DOM, state management libraries, or other platform APIs. In general, the body of an effect should do one or both of the following:
* Update external systems with the latest state from React.
* Subscribe for updates from some external system, calling setState in a callback function when external state changes.

Calling setState synchronously within an effect body causes cascading renders that can hurt performance, and is not recommended. (https://react.dev/learn/you-might-not-need-an-effect).

C:\Projetos\App ECO\eluta-servicos\src\app\eco\recibos\RecibosClient.tsx:55:21
  53 |   }
  54 |
> 55 |   useEffect(() => { refresh(); }, [url]);
     |                     ^^^^^^^ Avoid calling setState() directly within an effect
  56 |
  57 |   const dayCloses = Array.isArray(data?.dayCloses) ? data!.dayCloses : [];
  58 |   const mutiroes = Array.isArray(data?.mutiroes) ? data!.mutiroes : [];  react-hooks/set-state-in-effect
  55:35  warning  React Hook useEffect has a missing dependency: 'refresh'. Either include it or remove the dependency array                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          react-hooks/exhaustive-deps

C:\Projetos\App ECO\eluta-servicos\src\app\eco\share\dia\[day]\ShareDayClient.tsx
    5:30  error    Unexpected any. Specify a different type                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           @typescript-eslint/no-explicit-any
    7:19  error    Unexpected any. Specify a different type                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           @typescript-eslint/no-explicit-any
   13:27  error    Unexpected any. Specify a different type                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           @typescript-eslint/no-explicit-any
   61:11  error    Error: Calling setState synchronously within an effect can trigger cascading renders

Effects are intended to synchronize state between React and external systems such as manually updating the DOM, state management libraries, or other platform APIs. In general, the body of an effect should do one or both of the following:
* Update external systems with the latest state from React.
* Subscribe for updates from some external system, calling setState in a callback function when external state changes.

Calling setState synchronously within an effect body causes cascading renders that can hurt performance, and is not recommended. (https://react.dev/learn/you-might-not-need-an-effect).

C:\Projetos\App ECO\eluta-servicos\src\app\eco\share\dia\[day]\ShareDayClient.tsx:61:11
  59 |
  60 |   useEffect(() => {
> 61 |     try { setLinkHere(window.location.href); } catch {}
     |           ^^^^^^^^^^^ Avoid calling setState() directly within an effect
  62 |   }, [day]);
  63 |
  64 |   useEffect(() => {  react-hooks/set-state-in-effect
  138:13  warning  Using `<img>` could result in slower LCP and higher bandwidth. Consider using `<Image />` from `next/image` or a custom image loader to automatically optimize images. This may incur additional usage or cost from your provider. See: https://nextjs.org/docs/messages/no-img-element                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            @next/next/no-img-element
  144:13  warning  Using `<img>` could result in slower LCP and higher bandwidth. Consider using `<Image />` from `next/image` or a custom image loader to automatically optimize images. This may incur additional usage or cost from your provider. See: https://nextjs.org/docs/messages/no-img-element                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            @next/next/no-img-element

C:\Projetos\App ECO\eluta-servicos\src\app\eco\share\mes\[month]\ShareMonthClient.tsx
   5:30  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  14:19  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  20:23  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  49:45  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  50:49  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\eco\share\mes\[month]\page.tsx
  5:43  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\eco\share\mutirao\[id]\ShareMutiraoClient.tsx
  75:13  warning  Using `<img>` could result in slower LCP and higher bandwidth. Consider using `<Image />` from `next/image` or a custom image loader to automatically optimize images. This may incur additional usage or cost from your provider. See: https://nextjs.org/docs/messages/no-img-element  @next/next/no-img-element
  82:13  warning  Using `<img>` could result in slower LCP and higher bandwidth. Consider using `<Image />` from `next/image` or a custom image loader to automatically optimize images. This may incur additional usage or cost from your provider. See: https://nextjs.org/docs/messages/no-img-element  @next/next/no-img-element

C:\Projetos\App ECO\eluta-servicos\src\app\eco\share\mutirao\[id]\page.tsx
  3:48  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  4:12  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  4:35  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\eco\share\page.tsx
  13:13  error  Do not use an `<a>` element to navigate to `/eco/share/dia/2025-12-27/`. Use `<Link />` from `next/link` instead. See: https://nextjs.org/docs/messages/no-html-link-for-pages  @next/next/no-html-link-for-pages
  14:13  error  Do not use an `<a>` element to navigate to `/eco/share/mes/2025-12/`. Use `<Link />` from `next/link` instead. See: https://nextjs.org/docs/messages/no-html-link-for-pages     @next/next/no-html-link-for-pages

C:\Projetos\App ECO\eluta-servicos\src\app\eco\share\ponto\[id]\SharePointClient.tsx
   22:10  error    Unexpected any. Specify a different type                                                                                                                                                                                                                                                 @typescript-eslint/no-explicit-any
   64:21  error    Unexpected any. Specify a different type                                                                                                                                                                                                                                                 @typescript-eslint/no-explicit-any
  100:18  error    Unexpected any. Specify a different type                                                                                                                                                                                                                                                 @typescript-eslint/no-explicit-any
  105:19  error    Unexpected any. Specify a different type                                                                                                                                                                                                                                                 @typescript-eslint/no-explicit-any
  158:16  error    Unexpected any. Specify a different type                                                                                                                                                                                                                                                 @typescript-eslint/no-explicit-any
  163:17  error    Unexpected any. Specify a different type                                                                                                                                                                                                                                                 @typescript-eslint/no-explicit-any
  207:19  warning  Using `<img>` could result in slower LCP and higher bandwidth. Consider using `<Image />` from `next/image` or a custom image loader to automatically optimize images. This may incur additional usage or cost from your provider. See: https://nextjs.org/docs/messages/no-img-element  @next/next/no-img-element
  213:19  warning  Using `<img>` could result in slower LCP and higher bandwidth. Consider using `<Image />` from `next/image` or a custom image loader to automatically optimize images. This may incur additional usage or cost from your provider. See: https://nextjs.org/docs/messages/no-img-element  @next/next/no-img-element

C:\Projetos\App ECO\eluta-servicos\src\app\eco\share\ponto\[id]\page.tsx
  8:48  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  9:30  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\eco\transparencia\TransparenciaClient.tsx
   5:30  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  60:45  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  61:48  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\entrega\entrega-form.tsx
  40:83  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\formacao\cursos\page.tsx
  1:42  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\operador\triagem\DayCloseShortcut.tsx
  72:9  error  Do not use an `<a>` element to navigate to `/s/dia/`. Use `<Link />` from `next/link` instead. See: https://nextjs.org/docs/messages/no-html-link-for-pages  @next/next/no-html-link-for-pages

C:\Projetos\App ECO\eluta-servicos\src\app\operador\triagem\OperatorTriageV2.tsx
    5:16  error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
   15:21  error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
   73:94  error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
   81:15  error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
   88:32  warning  React Hook useEffect has a missing dependency: 'load'. Either include it or remove the dependency array  react-hooks/exhaustive-deps
  103:40  error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
  104:14  error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
  105:27  error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
  114:14  error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
  114:32  error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
  249:34  error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
  266:15  error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\operador\triagem\page.tsx
  5:8  warning  'DayCloseShortcut' is defined but never used  @typescript-eslint/no-unused-vars

C:\Projetos\App ECO\eluta-servicos\src\app\painel\page.tsx
  25:41  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\pedidos\fechar\[id]\fechar-client.tsx
    6:21  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
    7:24  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   13:22  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   33:42  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   44:40  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   63:19  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   71:19  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   88:19  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   97:22  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  107:43  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  108:70  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  115:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\pedidos\fechar\[id]\page.tsx
  6:70  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\pedidos\page.tsx
   5:26  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   5:32  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  17:19  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  23:21  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  31:34  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  43:14  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  49:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  53:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  96:30  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\r\[code]\page.tsx
  46:8   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  62:16  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  64:36  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  69:32  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  74:48  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  74:73  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\recibo\[code]\page.tsx
  6:64  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\recibo\[code]\recibo-client.tsx
   24:42  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   45:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   59:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   88:20  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   89:23  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   90:33  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  100:38  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  100:66  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  113:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  123:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  130:35  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  130:63  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\recibos\page.tsx
  13:21  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  21:13  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  24:19  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\s\dia\[day]\DayClosePanel.tsx
  35:5   error  Error: Calling setState synchronously within an effect can trigger cascading renders

Effects are intended to synchronize state between React and external systems such as manually updating the DOM, state management libraries, or other platform APIs. In general, the body of an effect should do one or both of the following:
* Update external systems with the latest state from React.
* Subscribe for updates from some external system, calling setState in a callback function when external state changes.

Calling setState synchronously within an effect body causes cascading renders that can hurt performance, and is not recommended. (https://react.dev/learn/you-might-not-need-an-effect).

C:\Projetos\App ECO\eluta-servicos\src\app\s\dia\[day]\DayClosePanel.tsx:35:5
  33 |
  34 |   useEffect(() => {
> 35 |     setDraft(initialDraft);
     |     ^^^^^^^^ Avoid calling setState() directly within an effect
  36 |     setSaved(null);
  37 |     setErr(null);
  38 |     setLoading(true);  react-hooks/set-state-in-effect
  65:57  error  Unexpected any. Specify a different type                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       @typescript-eslint/no-explicit-any
  72:17  error  Unexpected any. Specify a different type                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\s\dia\[day]\page.tsx
  70:11  warning  Using `<img>` could result in slower LCP and higher bandwidth. Consider using `<Image />` from `next/image` or a custom image loader to automatically optimize images. This may incur additional usage or cost from your provider. See: https://nextjs.org/docs/messages/no-img-element  @next/next/no-img-element
  75:11  warning  Using `<img>` could result in slower LCP and higher bandwidth. Consider using `<Image />` from `next/image` or a custom image loader to automatically optimize images. This may incur additional usage or cost from your provider. See: https://nextjs.org/docs/messages/no-img-element  @next/next/no-img-element

C:\Projetos\App ECO\eluta-servicos\src\app\servicos\services-table.tsx
  11:44  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  20:19  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  34:32  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  90:31  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\components\eco\IssueReceiptButton.tsx
  66:59  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  67:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\components\eco\OperatorPanel.tsx
    5:30  error    Unexpected any. Specify a different type   @typescript-eslint/no-explicit-any
   10:6   warning  'EcoCardFormat' is defined but never used  @typescript-eslint/no-unused-vars
   12:22  error    Unexpected any. Specify a different type   @typescript-eslint/no-explicit-any
  122:17  error    Unexpected any. Specify a different type   @typescript-eslint/no-explicit-any
  144:17  error    Unexpected any. Specify a different type   @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\components\eco\OperatorTriageBoard.tsx
    7:30  error    Unexpected any. Specify a different type                                                                                                                                                                     @typescript-eslint/no-explicit-any
   10:7   warning  'STATUS_OPTIONS' is assigned a value but never used                                                                                                                                                          @typescript-eslint/no-unused-vars
   17:6   warning  'ShareNav' is defined but never used                                                                                                                                                                         @typescript-eslint/no-unused-vars
   19:22  error    Unexpected any. Specify a different type                                                                                                                                                                     @typescript-eslint/no-explicit-any
   49:16  error    Unexpected any. Specify a different type                                                                                                                                                                     @typescript-eslint/no-explicit-any
   49:35  error    Unexpected any. Specify a different type                                                                                                                                                                     @typescript-eslint/no-explicit-any
   67:19  error    Unexpected any. Specify a different type                                                                                                                                                                     @typescript-eslint/no-explicit-any
  202:17  error    Unexpected any. Specify a different type                                                                                                                                                                     @typescript-eslint/no-explicit-any
  222:17  error    Unexpected any. Specify a different type                                                                                                                                                                     @typescript-eslint/no-explicit-any
  312:6   warning  React Hook useMemo has missing dependencies: 'onCopyRoute', 'onWhatsAppRoute', 'routeBairro', 'routeCandidates.length', 'routeOnlyNew', and 'routeText'. Either include them or remove the dependency array  react-hooks/exhaustive-deps

C:\Projetos\App ECO\eluta-servicos\src\components\eco\ReceiptLink.tsx
   6:16  error  Unexpected any. Specify a different type                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    @typescript-eslint/no-explicit-any
   8:45  error  Unexpected any. Specify a different type                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    @typescript-eslint/no-explicit-any
   9:70  error  Unexpected any. Specify a different type                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    @typescript-eslint/no-explicit-any
  57:5   error  Error: Calling setState synchronously within an effect can trigger cascading renders

Effects are intended to synchronize state between React and external systems such as manually updating the DOM, state management libraries, or other platform APIs. In general, the body of an effect should do one or both of the following:
* Update external systems with the latest state from React.
* Subscribe for updates from some external system, calling setState in a callback function when external state changes.

Calling setState synchronously within an effect body causes cascading renders that can hurt performance, and is not recommended. (https://react.dev/learn/you-might-not-need-an-effect).

C:\Projetos\App ECO\eluta-servicos\src\components\eco\ReceiptLink.tsx:57:5
  55 |
  56 |   useEffect(() => {
> 57 |     setToken(ecoTokenFromLocalStorage());
     |     ^^^^^^^^ Avoid calling setState() directly within an effect
  58 |   }, []);
  59 |
  60 |   const code = useMemo(() => ecoReceiptCodeFromItem(item), [item]);  react-hooks/set-state-in-effect

C:\Projetos\App ECO\eluta-servicos\src\components\eco\ReceiptPublishButton.tsx
  18:16  error    Unexpected any. Specify a different type                                                        @typescript-eslint/no-explicit-any
  22:28  error    Unexpected any. Specify a different type                                                        @typescript-eslint/no-explicit-any
  32:5   warning  Unused eslint-disable directive (no problems were reported from 'react-hooks/exhaustive-deps')
  55:53  error    Unexpected any. Specify a different type                                                        @typescript-eslint/no-explicit-any
  56:24  error    Unexpected any. Specify a different type                                                        @typescript-eslint/no-explicit-any
  56:72  error    Unexpected any. Specify a different type                                                        @typescript-eslint/no-explicit-any
  57:17  error    Unexpected any. Specify a different type                                                        @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\components\eco\ReceiptShareBar.tsx
   17:7   warning  'ecoReceiptCopyText' is assigned a value but never used      @typescript-eslint/no-unused-vars
   38:7   warning  'ecoReceiptOpenWhatsApp' is assigned a value but never used  @typescript-eslint/no-unused-vars
  213:16  error    Unexpected any. Specify a different type                     @typescript-eslint/no-explicit-any
  213:73  error    Unexpected any. Specify a different type                     @typescript-eslint/no-explicit-any
  252:9   warning  'eco31_copyShort' is assigned a value but never used         @typescript-eslint/no-unused-vars
  256:9   warning  'eco31_copyLong' is assigned a value but never used          @typescript-eslint/no-unused-vars
  260:9   warning  'eco31_copyZap' is assigned a value but never used           @typescript-eslint/no-unused-vars
  264:9   warning  'eco31_shareText' is assigned a value but never used         @typescript-eslint/no-unused-vars
  288:9   warning  'eco32_shareLink' is assigned a value but never used         @typescript-eslint/no-unused-vars
  290:16  error    Unexpected any. Specify a different type                     @typescript-eslint/no-explicit-any
  290:35  error    Unexpected any. Specify a different type                     @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\lib\eco\muralActions.ts
  13:53  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

Ô£û 981 problems (926 errors, 55 warnings)
  0 errors and 3 warnings potentially fixable with the `--fix` option.
~~~

### npm run build
~~~

> eluta-servicos@0.1.0 build
> next build

   Ôû▓ Next.js 16.0.10 (Turbopack)
   - Environments: .env

   Creating an optimized production build ...
 Ô£ô Compiled successfully in 4.1s
   Running TypeScript ...
   Collecting page data using 11 workers ...
 ÔÜá Using edge runtime on a page currently disables static generation for that page
   Generating static pages using 11 workers (0/44) ...
   Generating static pages using 11 workers (11/44) 
   Generating static pages using 11 workers (22/44) 
   Generating static pages using 11 workers (33/44) 
 Ô£ô Generating static pages using 11 workers (44/44) in 1339.0ms
   Finalizing page optimization ...

Route (app)
Ôöî Ôùï /
Ôö£ Ôùï /_not-found
Ôö£ ãÆ /api/admin/weighing
Ôö£ ãÆ /api/delivery
Ôö£ ãÆ /api/dev/seed-eco
Ôö£ ãÆ /api/eco/critical/confirm
Ôö£ ãÆ /api/eco/critical/create
Ôö£ ãÆ /api/eco/critical/list
Ôö£ ãÆ /api/eco/day-close
Ôö£ ãÆ /api/eco/day-close/card
Ôö£ ãÆ /api/eco/day-close/compute
Ôö£ ãÆ /api/eco/day-close/list
Ôö£ ãÆ /api/eco/month-close
Ôö£ ãÆ /api/eco/month-close/card
Ôö£ ãÆ /api/eco/month-close/list
Ôö£ ãÆ /api/eco/mural/list
Ôö£ ãÆ /api/eco/mutirao/card
Ôö£ ãÆ /api/eco/mutirao/create
Ôö£ ãÆ /api/eco/mutirao/finish
Ôö£ ãÆ /api/eco/mutirao/get
Ôö£ ãÆ /api/eco/mutirao/list
Ôö£ ãÆ /api/eco/mutirao/proof
Ôö£ ãÆ /api/eco/mutirao/update
Ôö£ ãÆ /api/eco/point/detail
Ôö£ ãÆ /api/eco/point/reopen
Ôö£ ãÆ /api/eco/points
Ôö£ ãÆ /api/eco/points/action
Ôö£ ãÆ /api/eco/points/card
Ôö£ ãÆ /api/eco/points/confirm
Ôö£ ãÆ /api/eco/points/get
Ôö£ ãÆ /api/eco/points/list
Ôö£ ãÆ /api/eco/points/list2
Ôö£ ãÆ /api/eco/points/map
Ôö£ ãÆ /api/eco/points/react
Ôö£ ãÆ /api/eco/points/replicar
Ôö£ ãÆ /api/eco/points/report
Ôö£ ãÆ /api/eco/points/resolve
Ôö£ ãÆ /api/eco/points/stats
Ôö£ ãÆ /api/eco/points/support
Ôö£ ãÆ /api/eco/points2
Ôö£ ãÆ /api/eco/recibo/list
Ôö£ ãÆ /api/eco/upload
Ôö£ ãÆ /api/pickup-requests
Ôö£ ãÆ /api/pickup-requests/[id]
Ôö£ ãÆ /api/pickup-requests/[id]/receipt
Ôö£ ãÆ /api/pickup-requests/bulk
Ôö£ ãÆ /api/pickup-requests/triage
Ôö£ ãÆ /api/points
Ôö£ ãÆ /api/points/[id]
Ôö£ ãÆ /api/receipts
Ôö£ ãÆ /api/receipts/[code]
Ôö£ ãÆ /api/receipts/[code]/public
Ôö£ ãÆ /api/receipts/public
Ôö£ ãÆ /api/requests
Ôö£ ãÆ /api/requests/[id]
Ôö£ ãÆ /api/seed
Ôö£ ãÆ /api/services
Ôö£ ãÆ /api/share/receipt-card
Ôö£ ãÆ /api/share/receipt-pack
Ôö£ ãÆ /api/share/route-day-card
Ôö£ ãÆ /api/stats
Ôö£ Ôùï /chamar
Ôö£ Ôùï /chamar-coleta
Ôö£ Ôùï /chamar-coleta/novo
Ôö£ Ôùï /chamar/sucesso
Ôö£ Ôùï /coleta
Ôö£ Ôùï /coleta/novo
Ôö£ ãÆ /coleta/p/[id]
Ôö£ Ôùï /doacao
Ôö£ ãÆ /eco/fechamento
Ôö£ ãÆ /eco/mapa
Ôö£ ãÆ /eco/mural
Ôö£ ãÆ /eco/mural-acoes
Ôö£ Ôùï /eco/mural/chamados
Ôö£ ãÆ /eco/mural/confirmados
Ôö£ ãÆ /eco/mutiroes
Ôö£ ãÆ /eco/mutiroes/[id]
Ôö£ ãÆ /eco/mutiroes/[id]/finalizar
Ôö£ ãÆ /eco/pontos
Ôö£ ãÆ /eco/pontos/[id]
Ôö£ ãÆ /eco/pontos/[id]/resolver
Ôö£ Ôùï /eco/recibos
Ôö£ ãÆ /eco/share
Ôö£ ãÆ /eco/share/dia/[day]
Ôö£ ãÆ /eco/share/mes/[month]
Ôö£ ãÆ /eco/share/mutirao/[id]
Ôö£ ãÆ /eco/share/ponto/[id]
Ôö£ ãÆ /eco/transparencia
Ôö£ ãÆ /entrega
Ôö£ Ôùï /feira
Ôö£ Ôùï /formacao
Ôö£ Ôùï /formacao/cursos
Ôö£ Ôùï /impacto
Ôö£ Ôùï /mapa
Ôö£ Ôùï /operador
Ôö£ ãÆ /operador/triagem
Ôö£ ãÆ /painel
Ôö£ ãÆ /pedidos
Ôö£ Ôùï /pedidos/fechar
Ôö£ ãÆ /pedidos/fechar/[id]
Ôö£ ãÆ /r/[code]
Ôö£ ãÆ /recibo/[code]
Ôö£ ãÆ /recibos
Ôö£ Ôùï /reparo
Ôö£ ãÆ /s/dia/[day]
Ôö£ Ôùï /servicos
Ôöö Ôùï /servicos/novo


Ôùï  (Static)   prerendered as static content
ãÆ  (Dynamic)  server-rendered on demand
~~~

## DEV (auto)
- started: True
- port_ready: False

## SMOKE

### points_list
- error: The request was canceled due to the configured HttpClient.Timeout of 10 seconds elapsing.

### points_list2
- error: The request was canceled due to the configured HttpClient.Timeout of 10 seconds elapsing.

### points2
- error: The request was canceled due to the configured HttpClient.Timeout of 10 seconds elapsing.

### points_get_noid
- error: Response status code does not indicate success: 400 (Bad Request).

### point_detail_noid
- error: Response status code does not indicate success: 400 (Bad Request).

### points_map
- error: Response status code does not indicate success: 503 (Service Unavailable).

### points_stats
- error: Response status code does not indicate success: 503 (Service Unavailable).

### mural_list
- error: Response status code does not indicate success: 503 (Service Unavailable).

## DEV stop
- stopped: False (A parameter cannot be found that matches parameter name 'Force'.)