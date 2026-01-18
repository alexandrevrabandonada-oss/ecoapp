# eco-step-148b — verify + smoke (auto dev) — 20260116-000329

## VERIFY (offline)

### npm run lint
~~~

> eluta-servicos@0.1.0 lint
> eslint


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
  148:81  error  Parsing error: ':' expected

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
  128:24  error  Parsing error: Unterminated regular expression literal

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
  128:24  error  Parsing error: Unterminated regular expression literal

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
   15:17   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   29:15   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   29:31   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   35:16   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   36:17   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   36:58   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   37:19   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   38:18   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   40:35   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   41:102  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   42:99   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   44:32   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   45:62   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   51:22   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   56:24   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   62:17   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   64:20   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  102:15   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

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
  128:24  error  Parsing error: Unterminated regular expression literal

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
  33:31  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  77:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\api\pickup-requests\[id]\route.ts
  40:54  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  41:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  50:38  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  56:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\api\pickup-requests\bulk\route.ts
  43:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  45:62  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\api\pickup-requests\route.ts
    3:7    warning  'ECO_TOKEN_HEADER' is assigned a value but never used  @typescript-eslint/no-unused-vars
    7:10   warning  'ecoStripReceiptForAnon' is defined but never used     @typescript-eslint/no-unused-vars
    7:42   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
   12:12   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
   20:32   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
   21:13   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
   23:23   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
   51:22   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
   51:38   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
   52:20   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
   52:36   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
   98:22   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  103:30   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  105:34   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  106:35   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  109:25   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  109:105  error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  110:25   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  110:108  error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  112:23   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  112:115  error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  144:31   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  145:23   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  146:29   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  147:15   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  150:15   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  159:17   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  189:66   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  190:38   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  191:25   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  194:20   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  194:42   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  194:89   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any

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
   97:36  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   99:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  112:58  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  125:32  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  130:39  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  163:31  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  218:31  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  249:36  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\api\receipts\[code]\public\route.ts
  43:38  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  48:34  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\api\receipts\[code]\route.ts
   11:23  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   11:39  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   12:20  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   12:36  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   68:14  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   75:47  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  105:48  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

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
  115:65  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  116:30  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  129:66  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  131:35  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  144:41  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  189:39  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  189:66  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  208:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  253:36  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  256:57  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  261:23  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  265:19  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  278:18  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

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

C:\Projetos\App ECO\eluta-servicos\src\app\api\share\receipt-card\route.ts
  38:9  error  Parsing error: '>' expected

C:\Projetos\App ECO\eluta-servicos\src\app\api\share\route-day-card\route.ts
  109:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\chamar\page.tsx
   14:44  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   31:21  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   52:22  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   75:19  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   94:91  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  122:34  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\app\chamar\sucesso\page.tsx
  60:0  error  Parsing error: ')' expected

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
    2:10  warning  'dt' is defined but never used                                         @typescript-eslint/no-unused-vars
    2:16  error    Unexpected any. Specify a different type                               @typescript-eslint/no-explicit-any
    7:10  warning  'score' is defined but never used                                      @typescript-eslint/no-unused-vars
    7:19  error    Unexpected any. Specify a different type                               @typescript-eslint/no-explicit-any
   17:1   warning  Expected an assignment or function call and instead saw an expression  @typescript-eslint/no-unused-expressions
   21:7   warning  '__ECO_REF_GUARD__' is assigned a value but never used                 @typescript-eslint/no-unused-vars
   22:10  error    Unexpected any. Specify a different type                               @typescript-eslint/no-explicit-any
   23:7   warning  'it' is assigned a value but never used                                @typescript-eslint/no-unused-vars
   23:11  error    Unexpected any. Specify a different type                               @typescript-eslint/no-explicit-any
   24:7   warning  'item' is assigned a value but never used                              @typescript-eslint/no-unused-vars
   24:13  error    Unexpected any. Specify a different type                               @typescript-eslint/no-explicit-any
   35:21  error    Unexpected any. Specify a different type                               @typescript-eslint/no-explicit-any
   40:29  error    Unexpected any. Specify a different type                               @typescript-eslint/no-explicit-any
   49:28  error    Unexpected any. Specify a different type                               @typescript-eslint/no-explicit-any
   64:41  error    Unexpected any. Specify a different type                               @typescript-eslint/no-explicit-any
   85:63  error    Unexpected any. Specify a different type                               @typescript-eslint/no-explicit-any
   85:81  error    Unexpected any. Specify a different type                               @typescript-eslint/no-explicit-any
  114:58  error    Unexpected any. Specify a different type                               @typescript-eslint/no-explicit-any

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

C:\Projetos\App ECO\eluta-servicos\src\app\eco\mutiroes\[id]\page.tsx
  7:8  error  Parsing error: ':' expected

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
  52:73  error  Parsing error: ',' expected

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
  39:25  error  Parsing error: Expression expected

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
  307:1  error  Parsing error: Expression expected

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
  54:53  error    Unexpected any. Specify a different type                                                        @typescript-eslint/no-explicit-any
  55:24  error    Unexpected any. Specify a different type                                                        @typescript-eslint/no-explicit-any
  55:72  error    Unexpected any. Specify a different type                                                        @typescript-eslint/no-explicit-any
  56:17  error    Unexpected any. Specify a different type                                                        @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\components\eco\ReceiptShareBar.tsx
   17:7   warning  'ecoReceiptCopyText' is assigned a value but never used      @typescript-eslint/no-unused-vars
   38:7   warning  'ecoReceiptOpenWhatsApp' is assigned a value but never used  @typescript-eslint/no-unused-vars
  214:9   warning  'eco31_copyShort' is assigned a value but never used         @typescript-eslint/no-unused-vars
  218:9   warning  'eco31_copyLong' is assigned a value but never used          @typescript-eslint/no-unused-vars
  222:9   warning  'eco31_copyZap' is assigned a value but never used           @typescript-eslint/no-unused-vars
  226:9   warning  'eco31_shareText' is assigned a value but never used         @typescript-eslint/no-unused-vars
  250:9   warning  'eco32_shareLink' is assigned a value but never used         @typescript-eslint/no-unused-vars
  252:16  error    Unexpected any. Specify a different type                     @typescript-eslint/no-explicit-any
  252:35  error    Unexpected any. Specify a different type                     @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\src\lib\eco\muralActions.ts
  13:53  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251222-173259-src_app_page.tsx
  1:2  error  Parsing error: Invalid character

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251222-184636-src_app_page.tsx
  1:2  error  Parsing error: Invalid character

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251222-195609-src_app_chamar-coleta_novo_page.tsx
  32:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251222-195609-src_app_chamar-coleta_page.tsx
  29:5  error  Error: Calling setState synchronously within an effect can trigger cascading renders

Effects are intended to synchronize state between React and external systems such as manually updating the DOM, state management libraries, or other platform APIs. In general, the body of an effect should do one or both of the following:
* Update external systems with the latest state from React.
* Subscribe for updates from some external system, calling setState in a callback function when external state changes.

Calling setState synchronously within an effect body causes cascading renders that can hurt performance, and is not recommended. (https://react.dev/learn/you-might-not-need-an-effect).

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251222-195609-src_app_chamar-coleta_page.tsx:29:5
  27 |
  28 |   useEffect(() => {
> 29 |     load().catch(() => setLoading(false));
     |     ^^^^ Avoid calling setState() directly within an effect
  30 |   }, []);
  31 |
  32 |   return (  react-hooks/set-state-in-effect

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251222-195609-src_app_recibos_page.tsx
  26:29  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251222-201613-src_app_recibos_page.tsx
  27:21  error  Error: Calling setState synchronously within an effect can trigger cascading renders

Effects are intended to synchronize state between React and external systems such as manually updating the DOM, state management libraries, or other platform APIs. In general, the body of an effect should do one or both of the following:
* Update external systems with the latest state from React.
* Subscribe for updates from some external system, calling setState in a callback function when external state changes.

Calling setState synchronously within an effect body causes cascading renders that can hurt performance, and is not recommended. (https://react.dev/learn/you-might-not-need-an-effect).

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251222-201613-src_app_recibos_page.tsx:27:21
  25 |   }
  26 |
> 27 |   useEffect(() => { load().catch(() => setLoading(false)); }, []);
     |                     ^^^^ Avoid calling setState() directly within an effect
  28 |
  29 |   return (
  30 |     <div className="stack">  react-hooks/set-state-in-effect

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251222-205918-src_app_api_receipts_route.ts
  15:57  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  44:59  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251222-211426-src_app_api_receipts_route.ts
  51:16  error  Parsing error: ',' expected

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251222-220912-src_app_pedidos_fechar_[id]_page.tsx
  1:33  error  Parsing error: ';' expected

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251222-220913-src_app_pedidos_fechar_[id]_fechar-client.tsx
  1:2  error  Parsing error: ';' expected

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251222-221418-src_app_api_requests_[id]_route.ts
  12:53  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  14:52  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  33:16  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251222-221952-src_app_api_pickup-requests_route.ts
  22:18  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  29:57  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  58:59  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  82:58  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  83:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  91:59  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251222-222921-src_app_chamar_sucesso_page.tsx
  3:61  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251223-121701-src_app_api_requests_route.ts
   5:14  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  11:14  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251223-124723-src_app_api_receipts_[code]_route.ts
  15:57  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  48:59  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251223-124723-src_app_recibos_page.tsx
  23:29  error  Unexpected any. Specify a different type                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             @typescript-eslint/no-explicit-any
  29:21  error  Error: Calling setState synchronously within an effect can trigger cascading renders

Effects are intended to synchronize state between React and external systems such as manually updating the DOM, state management libraries, or other platform APIs. In general, the body of an effect should do one or both of the following:
* Update external systems with the latest state from React.
* Subscribe for updates from some external system, calling setState in a callback function when external state changes.

Calling setState synchronously within an effect body causes cascading renders that can hurt performance, and is not recommended. (https://react.dev/learn/you-might-not-need-an-effect).

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251223-124723-src_app_recibos_page.tsx:29:21
  27 |   }
  28 |
> 29 |   useEffect(() => { load().catch(() => setLoading(false)); }, []);
     |                     ^^^^ Avoid calling setState() directly within an effect
  30 |
  31 |   return (
  32 |     <div className="stack">  react-hooks/set-state-in-effect

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251223-125105-src_app_api_receipts_[code]_route.ts
  11:23  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  11:39  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  66:47  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  79:16  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251223-125105-src_app_recibo_[code]_page.tsx
  14:22  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  18:64  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  25:13  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251223-141949-C__Projetos_App ECO_eluta-servicos_src_app_recibo_[code]_page.tsx
  14:22  error    Unexpected any. Specify a different type                                                                                                                                                                                                                                                 @typescript-eslint/no-explicit-any
  18:32  error    Unexpected any. Specify a different type                                                                                                                                                                                                                                                 @typescript-eslint/no-explicit-any
  22:64  error    Unexpected any. Specify a different type                                                                                                                                                                                                                                                 @typescript-eslint/no-explicit-any
  30:13  error    Unexpected any. Specify a different type                                                                                                                                                                                                                                                 @typescript-eslint/no-explicit-any
  87:13  warning  Using `<img>` could result in slower LCP and higher bandwidth. Consider using `<Image />` from `next/image` or a custom image loader to automatically optimize images. This may incur additional usage or cost from your provider. See: https://nextjs.org/docs/messages/no-img-element  @next/next/no-img-element

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251223-141949-C__Projetos_App ECO_eluta-servicos_src_app_recibo_[code]_recibo-client.tsx
  29:5  error  Use "@ts-expect-error" instead of "@ts-ignore", as "@ts-ignore" will do nothing if the following line is error-free  @typescript-eslint/ban-ts-comment
  31:7  error  Use "@ts-expect-error" instead of "@ts-ignore", as "@ts-ignore" will do nothing if the following line is error-free  @typescript-eslint/ban-ts-comment

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251223-141949-src_app_api_receipts_route.ts
   33:57  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   54:59  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   76:59  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   89:18  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  112:59  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  159:59  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  169:36  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  172:57  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  175:21  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  184:23  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  189:19  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  206:18  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251223-145537-C__Projetos_App ECO_eluta-servicos_src_app_pedidos_page.tsx
  14:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  40:29  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251223-150326-src_app_api_points_route.ts
  20:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251223-151217-src_app_api_points_route.ts
  39:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  41:20  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  52:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  64:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251223-152637-src_app_api_receipts_route.ts
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
   17:20  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   17:36  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   98:65  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   99:30  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  112:66  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  114:35  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  127:41  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  171:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  214:36  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  217:57  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  222:23  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  226:19  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  239:18  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251223-152637-src_app_pedidos_fechar_[id]_fechar-client.tsx
   6:21  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   7:24  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  13:22  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  19:42  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  28:40  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  46:19  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  54:19  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  86:43  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  87:70  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  91:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251223-152637-src_app_recibo_[code]_recibo-client.tsx
   6:22  error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
  12:42  error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
  24:17  error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
  29:17  error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
  36:42  warning  React Hook useEffect has a missing dependency: 'load'. Either include it or remove the dependency array  react-hooks/exhaustive-deps
  55:20  error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
  56:23  error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
  57:33  error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
  76:17  error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
  82:17  error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251223-154227-src_app_api_points_route.ts
  39:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  40:20  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  51:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  69:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251223-154621-src_app_api_points_route.ts
  39:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  40:20  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  51:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  69:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251223-155729-src_app_api_points_route.ts
  84:30  error  Parsing error: ')' expected

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251223-160350-src_app_api_receipts_route.ts
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
  115:65  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  116:30  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  129:66  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  131:35  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  144:41  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  188:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  233:36  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  236:57  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  241:23  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  245:19  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  258:18  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251223-160350-src_app_recibo_[code]_recibo-client.tsx
    5:22  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   25:42  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   40:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   45:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   74:20  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   75:23  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   76:33  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   88:22  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   98:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  106:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251223-164944-src_app_api_receipts_route.ts
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
  115:65  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  116:30  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  129:66  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  131:35  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  144:41  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  188:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  233:36  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  236:57  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  241:23  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  245:19  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  258:18  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251223-164944-src_app_recibo_[code]_recibo-client.tsx
    5:22  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   25:42  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   40:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   45:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   74:20  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   75:23  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   76:33  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   88:22  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   98:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  106:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251223-165842-src_app_api_receipts_route.ts
  189:7  error  Parsing error: Declaration or statement expected

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251223-170941-src_app_api_points_route.ts
  84:30  error  Parsing error: ')' expected

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251223-171340-src_app_recibo_[code]_recibo-client.tsx
    5:22  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   25:42  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   40:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   45:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   74:20  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   75:23  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   76:33  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   88:22  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   98:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  106:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251223-173132-src_app_api_pickup-requests_route.ts
   11:22   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   11:38   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   12:20   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   12:36   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   58:22   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   63:30   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   65:34   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   66:35   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   69:25   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   69:105  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   70:25   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   70:108  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   72:23   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   72:115  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  102:17   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  132:66   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  133:38   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  134:25   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  137:20   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  137:42   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  137:89   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251223-173132-src_app_pedidos_page.tsx
  52:73  error  Parsing error: ',' expected

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251223-173852-src_app_api_pickup-requests_route.ts
   11:22   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   11:38   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   12:20   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   12:36   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   58:22   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   63:30   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   65:34   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   66:35   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   69:25   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   69:105  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   70:25   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   70:108  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   72:23   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   72:115  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  102:17   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  132:66   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  133:38   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  134:25   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  137:20   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  137:42   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  137:89   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251223-181151-src_app_api_pickup-requests_route.ts
   11:22   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   11:38   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   12:20   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   12:36   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   58:22   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   63:30   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   65:34   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   66:35   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   69:25   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   69:105  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   70:25   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   70:108  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   72:23   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   72:115  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  102:17   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  132:66   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  133:38   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  134:25   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  137:20   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  137:42   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  137:89   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251223-184611-src_app_api_pickup-requests_route.ts
   11:22   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   11:38   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   12:20   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   12:36   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   58:22   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   63:30   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   65:34   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   66:35   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   69:25   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   69:105  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   70:25   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   70:108  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   72:23   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   72:115  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  102:17   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  132:66   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  133:38   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  134:25   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  137:20   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  137:42   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  137:89   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251223-190751-src_app_api_pickup-requests_route.ts
  19:28  error  Parsing error: ')' expected

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251224-144704-C__Projetos_App ECO_eluta-servicos_src_app_chamar_sucesso_page.tsx
  5:83  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251224-151424-src_app_api_pickup-requests_route.ts
    5:31   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
    6:12   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
    8:13   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
    8:45   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   19:22   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   19:38   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   20:20   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   20:36   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   66:22   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   71:30   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   73:34   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   74:35   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   77:25   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   77:105  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   78:25   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   78:108  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   80:23   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   80:115  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  110:17   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  140:66   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  141:38   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  142:25   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  145:20   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  145:42   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  145:89   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251224-162419-src_app_api_pickup-requests_route.ts
    5:31   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
    6:12   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
    8:13   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
    8:45   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   19:22   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   19:38   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   20:20   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   20:36   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   66:22   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   71:30   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   73:34   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   74:35   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   77:25   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   77:105  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   78:25   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   78:108  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   80:23   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   80:115  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  110:17   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  140:66   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  141:38   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  142:25   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  145:20   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  145:42   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  145:89   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251224-163550-src_app_api_pickup-requests_route.ts
    7:10   warning  'ecoIsOperator' is defined but never used           @typescript-eslint/no-unused-vars
   15:31   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   16:12   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   25:10   warning  'ecoStripReceiptForAnon' is defined but never used  @typescript-eslint/no-unused-vars
   25:42   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   30:12   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   37:31   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   38:12   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   40:13   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   40:45   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   51:22   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   51:38   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   52:20   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   52:36   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   98:22   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  103:30   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  105:34   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  106:35   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  109:25   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  109:105  error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  110:25   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  110:108  error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  112:23   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  112:115  error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  142:17   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  172:66   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  173:38   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  174:25   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  177:20   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  177:42   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  177:89   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251224-171137-src_app_api_pickup-requests_route.ts
  22:66  error  Parsing error: ',' expected

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251224-171137-src_app_chamar_sucesso_page.tsx
  54:0  error  Parsing error: ')' expected

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251224-171909-src_app_api_pickup-requests_route.ts
    7:10   warning  'ecoIsOperator' is defined but never used           @typescript-eslint/no-unused-vars
   15:31   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   16:12   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   25:10   warning  'ecoStripReceiptForAnon' is defined but never used  @typescript-eslint/no-unused-vars
   25:42   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   30:12   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   37:31   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   38:12   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   40:13   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   40:45   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   51:22   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   51:38   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   52:20   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   52:36   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   98:22   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  103:30   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  105:34   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  106:35   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  109:25   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  109:105  error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  110:25   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  110:108  error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  112:23   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  112:115  error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  142:17   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  172:66   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  173:38   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  174:25   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  177:20   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  177:42   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  177:89   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251224-173352-src_app_api_pickup-requests_route.ts
    4:31   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
    5:12   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
    7:22   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   16:10   warning  'ecoIsOperator' is defined but never used           @typescript-eslint/no-unused-vars
   25:10   warning  'ecoStripReceiptForAnon' is defined but never used  @typescript-eslint/no-unused-vars
   25:42   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   30:12   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   42:22   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   42:38   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   43:20   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   43:36   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   89:22   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   94:30   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   96:34   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   97:35   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  100:25   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  100:105  error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  101:25   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  101:108  error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  103:23   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  103:115  error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  133:17   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  163:66   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  164:38   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  165:25   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  168:20   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  168:42   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  168:89   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251224-175503-src_app_api_pickup-requests_route.ts
   27:31   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   28:12   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   30:22   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   48:10   warning  'ecoStripReceiptForAnon' is defined but never used  @typescript-eslint/no-unused-vars
   48:42   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   53:12   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   65:22   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   65:38   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   66:20   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   66:36   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  112:22   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  117:30   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  119:34   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  120:35   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  123:25   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  123:105  error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  124:25   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  124:108  error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  126:23   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  126:115  error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  157:30   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  158:22   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  159:21   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  160:14   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  170:17   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  200:66   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  201:38   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  202:25   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  205:20   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  205:42   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  205:89   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251224-175905-src_app_api_pickup-requests_route.ts
   50:31   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   51:12   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   53:22   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   71:10   warning  'ecoStripReceiptForAnon' is defined but never used  @typescript-eslint/no-unused-vars
   71:42   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   76:12   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   88:22   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   88:38   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   89:20   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   89:36   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  135:22   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  140:30   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  142:34   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  143:35   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  146:25   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  146:105  error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  147:25   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  147:108  error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  149:23   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  149:115  error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  180:30   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  181:22   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  182:21   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  183:14   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  194:30   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  195:22   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  196:21   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  197:14   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  207:17   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  237:66   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  238:38   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  239:25   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  242:20   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  242:42   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  242:89   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251224-180441-src_app_api_pickup-requests_route.ts
   50:31   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   51:12   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   53:22   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   71:10   warning  'ecoStripReceiptForAnon' is defined but never used  @typescript-eslint/no-unused-vars
   71:42   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   76:12   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   88:22   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   88:38   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   89:20   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   89:36   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  135:22   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  140:30   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  142:34   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  143:35   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  146:25   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  146:105  error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  147:25   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  147:108  error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  149:23   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  149:115  error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  180:30   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  181:22   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  182:21   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  183:14   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  194:30   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  195:22   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  196:21   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  197:14   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  209:32   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  210:24   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  211:23   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  212:16   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  223:17   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  253:66   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  254:38   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  255:25   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  258:20   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  258:42   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  258:89   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251224-181145-src_app_api_pickup-requests_route.ts
   50:31   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   51:12   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   53:22   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   71:10   warning  'ecoStripReceiptForAnon' is defined but never used  @typescript-eslint/no-unused-vars
   71:42   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   76:12   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   88:22   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   88:38   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   89:20   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
   89:36   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  135:22   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  140:30   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  142:34   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  143:35   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  146:25   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  146:105  error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  147:25   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  147:108  error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  149:23   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  149:115  error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  176:1    error    Unexpected var, use let or const instead            no-var
  180:30   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  181:22   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  182:21   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  183:14   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  190:1    error    Unexpected var, use let or const instead            no-var
  194:30   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  195:22   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  196:21   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  197:14   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  205:3    error    Unexpected var, use let or const instead            no-var
  209:32   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  210:24   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  211:23   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  212:16   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  223:17   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  253:66   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  254:38   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  255:25   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  258:20   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  258:42   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any
  258:89   error    Unexpected any. Specify a different type            @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251224-182049-src_app_api_pickup-requests_route.ts
   25:31   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
   26:12   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
   28:22   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
   35:7    warning  'ECO_TOKEN_HEADER' is assigned a value but never used  @typescript-eslint/no-unused-vars
   39:10   warning  'ecoStripReceiptForAnon' is defined but never used     @typescript-eslint/no-unused-vars
   39:42   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
   44:12   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
   56:22   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
   56:38   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
   57:20   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
   57:36   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  103:22   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  108:30   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  110:34   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  111:35   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  114:25   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  114:105  error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  115:25   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  115:108  error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  117:23   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  117:115  error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  144:1    error    Unexpected var, use let or const instead               no-var
  148:30   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  149:22   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  150:21   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  151:14   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  160:17   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  190:66   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  191:38   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  192:25   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  195:20   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  195:42   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any
  195:89   error    Unexpected any. Specify a different type               @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251224-182848-src_components_eco_ReceiptLink.tsx
  18:35  error  Unexpected any. Specify a different type                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                @typescript-eslint/no-explicit-any
  20:22  error  Unexpected any. Specify a different type                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                @typescript-eslint/no-explicit-any
  23:14  error  Unexpected any. Specify a different type                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                @typescript-eslint/no-explicit-any
  24:14  error  Unexpected any. Specify a different type                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                @typescript-eslint/no-explicit-any
  33:5   error  Error: Calling setState synchronously within an effect can trigger cascading renders

Effects are intended to synchronize state between React and external systems such as manually updating the DOM, state management libraries, or other platform APIs. In general, the body of an effect should do one or both of the following:
* Update external systems with the latest state from React.
* Subscribe for updates from some external system, calling setState in a callback function when external state changes.

Calling setState synchronously within an effect body causes cascading renders that can hurt performance, and is not recommended. (https://react.dev/learn/you-might-not-need-an-effect).

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251224-182848-src_components_eco_ReceiptLink.tsx:33:5
  31 |   const [token, setToken] = useState<string>('');
  32 |   useEffect(() => {
> 33 |     setToken(getTokenFromStorage());
     |     ^^^^^^^^ Avoid calling setState() directly within an effect
  34 |   }, []);
  35 |
  36 |   const href = useMemo(() => {  react-hooks/set-state-in-effect
  52:55  error  Unexpected any. Specify a different type                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251224-183445-src_app_pedidos_page.tsx
  52:73  error  Parsing error: ',' expected

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251224-184339-src_app_api_pickup-requests_[id]_receipt_route.ts
  31:16  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  31:39  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  46:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251224-184339-src_app_chamar_sucesso_page.tsx
  55:0  error  Parsing error: ')' expected

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251224-190401-src_app_chamar_sucesso_page.tsx
  59:0  error  Parsing error: ')' expected

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251224-190401-src_components_eco_ReceiptLink.tsx
  19:17  error  Unexpected any. Specify a different type                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       @typescript-eslint/no-explicit-any
  27:52  error  Unexpected any. Specify a different type                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       @typescript-eslint/no-explicit-any
  35:5   error  Error: Calling setState synchronously within an effect can trigger cascading renders

Effects are intended to synchronize state between React and external systems such as manually updating the DOM, state management libraries, or other platform APIs. In general, the body of an effect should do one or both of the following:
* Update external systems with the latest state from React.
* Subscribe for updates from some external system, calling setState in a callback function when external state changes.

Calling setState synchronously within an effect body causes cascading renders that can hurt performance, and is not recommended. (https://react.dev/learn/you-might-not-need-an-effect).

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251224-190401-src_components_eco_ReceiptLink.tsx:35:5
  33 |
  34 |   useEffect(() => {
> 35 |     setToken(safeGet());
     |     ^^^^^^^^ Avoid calling setState() directly within an effect
  36 |   }, []);
  37 |
  38 |   useEffect(() => {  react-hooks/set-state-in-effect

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251224-193657-src_components_eco_ReceiptLink.tsx
  19:17  error  Unexpected any. Specify a different type                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       @typescript-eslint/no-explicit-any
  27:52  error  Unexpected any. Specify a different type                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       @typescript-eslint/no-explicit-any
  35:5   error  Error: Calling setState synchronously within an effect can trigger cascading renders

Effects are intended to synchronize state between React and external systems such as manually updating the DOM, state management libraries, or other platform APIs. In general, the body of an effect should do one or both of the following:
* Update external systems with the latest state from React.
* Subscribe for updates from some external system, calling setState in a callback function when external state changes.

Calling setState synchronously within an effect body causes cascading renders that can hurt performance, and is not recommended. (https://react.dev/learn/you-might-not-need-an-effect).

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251224-193657-src_components_eco_ReceiptLink.tsx:35:5
  33 |
  34 |   useEffect(() => {
> 35 |     setToken(safeGet());
     |     ^^^^^^^^ Avoid calling setState() directly within an effect
  36 |   }, []);
  37 |
  38 |   useEffect(() => {  react-hooks/set-state-in-effect
  51:35  error  Unexpected any. Specify a different type                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251225-162322-src_app_r_[code]_page.tsx
  16:16  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  18:36  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  23:32  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251225-182330-src_app_r_[code]_page.tsx
  17:16  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  19:36  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  24:32  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  29:48  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  29:73  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251225-183544-src_components_eco_ReceiptShareBar.tsx
  47:55  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  47:96  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  75:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251225-184636-src_components_eco_ReceiptShareBar.tsx
  18:7  warning  'ecoReceiptDownloadCard' is assigned a value but never used  @typescript-eslint/no-unused-vars
  45:7  warning  'ecoReceiptShareLink' is assigned a value but never used     @typescript-eslint/no-unused-vars
  57:7  warning  'ecoReceiptShareCard' is assigned a value but never used     @typescript-eslint/no-unused-vars

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251225-192412-src_components_eco_ReceiptShareBar.tsx
   18:7  warning  'ecoReceiptDownloadCard' is assigned a value but never used  @typescript-eslint/no-unused-vars
   45:7  warning  'ecoReceiptShareLink' is assigned a value but never used     @typescript-eslint/no-unused-vars
   57:7  warning  'ecoReceiptShareCard' is assigned a value but never used     @typescript-eslint/no-unused-vars
  112:7  warning  'ecoReceiptCopyText' is assigned a value but never used      @typescript-eslint/no-unused-vars
  133:7  warning  'ecoReceiptOpenWhatsApp' is assigned a value but never used  @typescript-eslint/no-unused-vars

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251225-193906-src_components_eco_ReceiptShareBar.tsx
  17:7  warning  'ecoReceiptCopyText' is assigned a value but never used      @typescript-eslint/no-unused-vars
  38:7  warning  'ecoReceiptOpenWhatsApp' is assigned a value but never used  @typescript-eslint/no-unused-vars

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251225-202954-src_components_eco_ReceiptShareBar.tsx
  17:7  warning  'ecoReceiptCopyText' is assigned a value but never used      @typescript-eslint/no-unused-vars
  38:7  warning  'ecoReceiptOpenWhatsApp' is assigned a value but never used  @typescript-eslint/no-unused-vars

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251225-203504-src_components_eco_ReceiptShareBar.tsx
  17:7  warning  'ecoReceiptCopyText' is assigned a value but never used      @typescript-eslint/no-unused-vars
  38:7  warning  'ecoReceiptOpenWhatsApp' is assigned a value but never used  @typescript-eslint/no-unused-vars

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251225-210035-src_components_eco_ReceiptShareBar.tsx
  17:7  warning  'ecoReceiptCopyText' is assigned a value but never used      @typescript-eslint/no-unused-vars
  38:7  warning  'ecoReceiptOpenWhatsApp' is assigned a value but never used  @typescript-eslint/no-unused-vars

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251225-212615-src_components_eco_ReceiptShareBar.tsx
   17:7   warning  'ecoReceiptCopyText' is assigned a value but never used      @typescript-eslint/no-unused-vars
   38:7   warning  'ecoReceiptOpenWhatsApp' is assigned a value but never used  @typescript-eslint/no-unused-vars
  318:9   warning  'eco32_shareLink' is assigned a value but never used         @typescript-eslint/no-unused-vars
  320:16  error    Unexpected any. Specify a different type                     @typescript-eslint/no-explicit-any
  320:35  error    Unexpected any. Specify a different type                     @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251225-214204-src_components_eco_ReceiptShareBar.tsx
   17:7   warning  'ecoReceiptCopyText' is assigned a value but never used      @typescript-eslint/no-unused-vars
   38:7   warning  'ecoReceiptOpenWhatsApp' is assigned a value but never used  @typescript-eslint/no-unused-vars
  318:9   warning  'eco32_shareLink' is assigned a value but never used         @typescript-eslint/no-unused-vars
  320:16  error    Unexpected any. Specify a different type                     @typescript-eslint/no-explicit-any
  320:35  error    Unexpected any. Specify a different type                     @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251225-215259-src_app_api_pickup-requests_[id]_route.ts
  22:18  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  29:57  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  57:59  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  83:58  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  84:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  92:59  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251225-215259-src_app_operador_page.tsx
  23:5  error  Error: Calling setState synchronously within an effect can trigger cascading renders

Effects are intended to synchronize state between React and external systems such as manually updating the DOM, state management libraries, or other platform APIs. In general, the body of an effect should do one or both of the following:
* Update external systems with the latest state from React.
* Subscribe for updates from some external system, calling setState in a callback function when external state changes.

Calling setState synchronously within an effect body causes cascading renders that can hurt performance, and is not recommended. (https://react.dev/learn/you-might-not-need-an-effect).

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251225-215259-src_app_operador_page.tsx:23:5
  21 |   useEffect(() => {
  22 |     const t = safeGet();
> 23 |     setCurrent(t);
     |     ^^^^^^^^^^ Avoid calling setState() directly within an effect
  24 |     setValue(t ?? '');
  25 |   }, []);
  26 |  react-hooks/set-state-in-effect

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251225-221040-src_components_eco_OperatorPanel.tsx
   5:30  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  58:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  80:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251225-230136-src_components_eco_OperatorTriageBoard.tsx
    7:30  error    Unexpected any. Specify a different type             @typescript-eslint/no-explicit-any
   10:7   warning  'STATUS_OPTIONS' is assigned a value but never used  @typescript-eslint/no-unused-vars
   17:6   warning  'ShareNav' is defined but never used                 @typescript-eslint/no-unused-vars
   19:22  error    Unexpected any. Specify a different type             @typescript-eslint/no-explicit-any
  123:17  error    Unexpected any. Specify a different type             @typescript-eslint/no-explicit-any
  143:17  error    Unexpected any. Specify a different type             @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251226-140346-src_app_operador_triagem_OperatorTriageV2.tsx
    5:16  error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
   15:21  error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
   73:94  error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
   81:15  error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
   88:32  warning  React Hook useEffect has a missing dependency: 'load'. Either include it or remove the dependency array  react-hooks/exhaustive-deps
  122:34  error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
  139:15  error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251226-142221-src_app_operador_triagem_OperatorTriageV2.tsx
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
  165:34  error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
  182:15  error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251226-143812-src_app_api_share_route-day-card_route.ts
  51:11  error  Parsing error: '>' expected

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251226-144225-src_app_api_share_route-day-card_route.ts
   19:21  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   24:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   24:29  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   24:47  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   41:16  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   44:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   47:16  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   47:41  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   49:16  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   58:39  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  114:36  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251226-145427-src_app_operador_triagem_OperatorTriageV2.tsx
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
  217:34  error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
  234:15  error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251226-154318-src_app_s_dia_[day]_page.tsx
  57:11  warning  Using `<img>` could result in slower LCP and higher bandwidth. Consider using `<Image />` from `next/image` or a custom image loader to automatically optimize images. This may incur additional usage or cost from your provider. See: https://nextjs.org/docs/messages/no-img-element  @next/next/no-img-element
  62:11  warning  Using `<img>` could result in slower LCP and higher bandwidth. Consider using `<Image />` from `next/image` or a custom image loader to automatically optimize images. This may incur additional usage or cost from your provider. See: https://nextjs.org/docs/messages/no-img-element  @next/next/no-img-element

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251226-160620-src_app_operador_triagem_OperatorTriageV2.tsx
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
  217:34  error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any
  234:15  error    Unexpected any. Specify a different type                                                                 @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251226-160620-src_app_s_dia_[day]_page.tsx
  61:11  warning  Using `<img>` could result in slower LCP and higher bandwidth. Consider using `<Image />` from `next/image` or a custom image loader to automatically optimize images. This may incur additional usage or cost from your provider. See: https://nextjs.org/docs/messages/no-img-element  @next/next/no-img-element
  66:11  warning  Using `<img>` could result in slower LCP and higher bandwidth. Consider using `<Image />` from `next/image` or a custom image loader to automatically optimize images. This may incur additional usage or cost from your provider. See: https://nextjs.org/docs/messages/no-img-element  @next/next/no-img-element

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251226-162119-src_app_operador_triagem_OperatorTriageV2.tsx
  170:19  error  Parsing error: Invalid character

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251226-162119-src_app_s_dia_[day]_page.tsx
  61:11  warning  Using `<img>` could result in slower LCP and higher bandwidth. Consider using `<Image />` from `next/image` or a custom image loader to automatically optimize images. This may incur additional usage or cost from your provider. See: https://nextjs.org/docs/messages/no-img-element  @next/next/no-img-element
  66:11  warning  Using `<img>` could result in slower LCP and higher bandwidth. Consider using `<Image />` from `next/image` or a custom image loader to automatically optimize images. This may incur additional usage or cost from your provider. See: https://nextjs.org/docs/messages/no-img-element  @next/next/no-img-element

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251226-165326-src_app_operador_triagem_OperatorTriageV2.tsx
  170:19  error  Parsing error: Invalid character

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251226-165326-src_app_s_dia_[day]_page.tsx
  61:11  warning  Using `<img>` could result in slower LCP and higher bandwidth. Consider using `<Image />` from `next/image` or a custom image loader to automatically optimize images. This may incur additional usage or cost from your provider. See: https://nextjs.org/docs/messages/no-img-element  @next/next/no-img-element
  66:11  warning  Using `<img>` could result in slower LCP and higher bandwidth. Consider using `<Image />` from `next/image` or a custom image loader to automatically optimize images. This may incur additional usage or cost from your provider. See: https://nextjs.org/docs/messages/no-img-element  @next/next/no-img-element

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251226-172156-src_app_api_share_route-day-card_route.ts
   19:21  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   24:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   24:29  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   24:47  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   41:16  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   44:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   47:16  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   47:41  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   49:16  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   58:39  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  114:36  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251226-172156-src_app_operador_triagem_OperatorTriageV2.tsx
  170:19  error  Parsing error: Invalid character

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251226-181942-src_app_operador_triagem_OperatorTriageV2.tsx
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

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251226-194041-C__Projetos_App ECO_eluta-servicos_tools__patch_backup_20251226-162119-src_app_operador_triagem_OperatorTriageV2.tsx
  144:43  error  Parsing error: Expression expected

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251226-194041-C__Projetos_App ECO_eluta-servicos_tools__patch_backup_20251226-165326-src_app_operador_triagem_OperatorTriageV2.tsx
  144:43  error  Parsing error: Expression expected

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251226-194041-C__Projetos_App ECO_eluta-servicos_tools__patch_backup_20251226-172156-src_app_operador_triagem_OperatorTriageV2.tsx
  144:43  error  Parsing error: Expression expected

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251226-194041-src_app_api_share_route-day-card_route.ts
   19:21  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   24:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   24:29  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   24:47  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   41:16  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   44:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   47:16  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   47:41  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   49:16  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   58:39  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  114:36  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251226-201118-src_app_s_dia_[day]_page.tsx
  65:11  warning  Using `<img>` could result in slower LCP and higher bandwidth. Consider using `<Image />` from `next/image` or a custom image loader to automatically optimize images. This may incur additional usage or cost from your provider. See: https://nextjs.org/docs/messages/no-img-element  @next/next/no-img-element
  70:11  warning  Using `<img>` could result in slower LCP and higher bandwidth. Consider using `<Image />` from `next/image` or a custom image loader to automatically optimize images. This may incur additional usage or cost from your provider. See: https://nextjs.org/docs/messages/no-img-element  @next/next/no-img-element

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251226-201851-src_app_s_dia_[day]_page.tsx
  68:11  warning  Using `<img>` could result in slower LCP and higher bandwidth. Consider using `<Image />` from `next/image` or a custom image loader to automatically optimize images. This may incur additional usage or cost from your provider. See: https://nextjs.org/docs/messages/no-img-element  @next/next/no-img-element
  73:11  warning  Using `<img>` could result in slower LCP and higher bandwidth. Consider using `<Image />` from `next/image` or a custom image loader to automatically optimize images. This may incur additional usage or cost from your provider. See: https://nextjs.org/docs/messages/no-img-element  @next/next/no-img-element

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251226-203816-src_app_s_dia_[day]_DayClosePanel.tsx
  35:5  error  Error: Calling setState synchronously within an effect can trigger cascading renders

Effects are intended to synchronize state between React and external systems such as manually updating the DOM, state management libraries, or other platform APIs. In general, the body of an effect should do one or both of the following:
* Update external systems with the latest state from React.
* Subscribe for updates from some external system, calling setState in a callback function when external state changes.

Calling setState synchronously within an effect body causes cascading renders that can hurt performance, and is not recommended. (https://react.dev/learn/you-might-not-need-an-effect).

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251226-203816-src_app_s_dia_[day]_DayClosePanel.tsx:35:5
  33 |
  34 |   useEffect(() => {
> 35 |     setDraft(initialDraft);
     |     ^^^^^^^^ Avoid calling setState() directly within an effect
  36 |     setSaved(null);
  37 |     setErr(null);
  38 |     setLoading(true);  react-hooks/set-state-in-effect

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251226-235054-src_app_api_share_route-day-card_route.ts
  31:13  error  Parsing error: '>' expected

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251226-235054-src_app_s_dia_[day]_DayClosePanel.tsx
  35:5   error  Error: Calling setState synchronously within an effect can trigger cascading renders

Effects are intended to synchronize state between React and external systems such as manually updating the DOM, state management libraries, or other platform APIs. In general, the body of an effect should do one or both of the following:
* Update external systems with the latest state from React.
* Subscribe for updates from some external system, calling setState in a callback function when external state changes.

Calling setState synchronously within an effect body causes cascading renders that can hurt performance, and is not recommended. (https://react.dev/learn/you-might-not-need-an-effect).

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251226-235054-src_app_s_dia_[day]_DayClosePanel.tsx:35:5
  33 |
  34 |   useEffect(() => {
> 35 |     setDraft(initialDraft);
     |     ^^^^^^^^ Avoid calling setState() directly within an effect
  36 |     setSaved(null);
  37 |     setErr(null);
  38 |     setLoading(true);  react-hooks/set-state-in-effect
  63:57  error  Unexpected any. Specify a different type                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           @typescript-eslint/no-explicit-any
  70:17  error  Unexpected any. Specify a different type                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251227-100854-src_app_api_share_route-day-card_route.ts
  131:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251227-125556-src_app_api_eco_day-close_route.ts
  23:13  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  23:29  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251227-132259-src_app_api_eco_day-close_route.ts
   23:13  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   23:29  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   28:13  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   28:29  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   32:77  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   44:20  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   64:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   65:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  127:56  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251227-143805-src_app_api_eco_day-close_compute_route.ts
   41:38  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   53:13  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   53:29  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   70:53  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   70:69  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   75:13  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   83:12  warning  'e' is defined but never used             @typescript-eslint/no-unused-vars
   83:15  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   87:18  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  119:52  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251227-143805-src_app_api_eco_day-close_route.ts
   23:13  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   23:29  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   28:13  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   28:29  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   32:77  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   44:20  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   64:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   65:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  127:56  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251227-143914-src_app_api_eco_day-close_compute_route.ts
  1:1178  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  1:1608  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  1:1624  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  1:2071  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  1:2087  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  1:2225  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  1:2472  warning  'e' is defined but never used             @typescript-eslint/no-unused-vars
  1:2475  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  1:2632  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  1:3896  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251227-143914-src_app_api_eco_day-close_route.ts
  1:4718  error  Parsing error: '}' expected

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251227-144605-eco-fix-day-close-parse-v0_1\route.ts
  1:1179  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  1:1609  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  1:1625  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  1:2072  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  1:2088  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  1:2226  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  1:2473  warning  'e' is defined but never used             @typescript-eslint/no-unused-vars
  1:2476  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  1:2633  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  1:3897  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251227-145118-eco-step-54b-day-close-debug-v0_1\route.ts
  26:13  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  26:29  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  30:77  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  41:20  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  61:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  62:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251227-153452-eco-step-56-day-close-card-v0_1\src__app__eco__fechamento__FechamentoClient.tsx
   5:30  error    Unexpected any. Specify a different type                                                        @typescript-eslint/no-explicit-any
  60:5   warning  Unused eslint-disable directive (no problems were reported from 'react-hooks/exhaustive-deps')

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251227-154625-eco-step-56c-fix-card-og-display-v0_1\src__app__api__eco__day-close__card__route.tsx
  21:19  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  34:27  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  63:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251227-163714-eco-step-58-share-pack-v0_1\src__app__eco__fechamento__FechamentoClient.tsx
   5:30  error    Unexpected any. Specify a different type                                                        @typescript-eslint/no-explicit-any
  58:5   warning  Unused eslint-disable directive (no problems were reported from 'react-hooks/exhaustive-deps')

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251227-163714-eco-step-58-share-pack-v0_1\src__app__eco__transparencia__TransparenciaClient.tsx
   5:30  error    Unexpected any. Specify a different type                                                        @typescript-eslint/no-explicit-any
  56:5   warning  Unused eslint-disable directive (no problems were reported from 'react-hooks/exhaustive-deps')

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251227-165528-eco-step-59-month-close-mvp-v0_1\src__app__api__eco__month-close__card__route.tsx
  19:19  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  31:27  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  56:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251227-165528-eco-step-59-month-close-mvp-v0_1\src__app__api__eco__month-close__list__route.ts
  20:13  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  20:29  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251227-165528-eco-step-59-month-close-mvp-v0_1\src__app__api__eco__month-close__route.ts
   20:13  error    Unexpected any. Specify a different type           @typescript-eslint/no-explicit-any
   20:29  error    Unexpected any. Specify a different type           @typescript-eslint/no-explicit-any
   25:13  error    Unexpected any. Specify a different type           @typescript-eslint/no-explicit-any
   25:29  error    Unexpected any. Specify a different type           @typescript-eslint/no-explicit-any
   40:20  error    Unexpected any. Specify a different type           @typescript-eslint/no-explicit-any
   57:11  warning  'start' is assigned a value but never used         @typescript-eslint/no-unused-vars
   57:18  warning  'endExclusive' is assigned a value but never used  @typescript-eslint/no-unused-vars
   59:17  error    Unexpected any. Specify a different type           @typescript-eslint/no-explicit-any
   60:15  error    Unexpected any. Specify a different type           @typescript-eslint/no-explicit-any
   78:21  error    Unexpected any. Specify a different type           @typescript-eslint/no-explicit-any
  126:56  error    Unexpected any. Specify a different type           @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251227-165528-eco-step-59-month-close-mvp-v0_1\src__app__eco__transparencia__TransparenciaClient.tsx
   5:30  error    Unexpected any. Specify a different type                                                        @typescript-eslint/no-explicit-any
  57:5   warning  Unused eslint-disable directive (no problems were reported from 'react-hooks/exhaustive-deps')

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251227-171601-eco-step-62-mutirao-from-point-mvp-v0_1\src__app__eco__pontos__PontosClient.tsx
   5:30  error    Unexpected any. Specify a different type                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              @typescript-eslint/no-explicit-any
  60:21  error    Error: Calling setState synchronously within an effect can trigger cascading renders

Effects are intended to synchronize state between React and external systems such as manually updating the DOM, state management libraries, or other platform APIs. In general, the body of an effect should do one or both of the following:
* Update external systems with the latest state from React.
* Subscribe for updates from some external system, calling setState in a callback function when external state changes.

Calling setState synchronously within an effect body causes cascading renders that can hurt performance, and is not recommended. (https://react.dev/learn/you-might-not-need-an-effect).

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251227-171601-eco-step-62-mutirao-from-point-mvp-v0_1\src__app__eco__pontos__PontosClient.tsx:60:21
  58 |     else { setItems([]); setStatus("erro"); }
  59 |   }
> 60 |   useEffect(() => { refresh(); }, []);
     |                     ^^^^^^^ Avoid calling setState() directly within an effect
  61 |
  62 |   async function useGeo() {
  63 |     setMsg("");  react-hooks/set-state-in-effect
  60:35  warning  React Hook useEffect has a missing dependency: 'refresh'. Either include it or remove the dependency array                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            react-hooks/exhaustive-deps

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251227-172126-eco-step-63-mutirao-finish-share-card-v0_1\src__app__eco__mutiroes__MutiroesClient.tsx
   5:30  error    Unexpected any. Specify a different type                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       @typescript-eslint/no-explicit-any
  37:21  error    Error: Calling setState synchronously within an effect can trigger cascading renders

Effects are intended to synchronize state between React and external systems such as manually updating the DOM, state management libraries, or other platform APIs. In general, the body of an effect should do one or both of the following:
* Update external systems with the latest state from React.
* Subscribe for updates from some external system, calling setState in a callback function when external state changes.

Calling setState synchronously within an effect body causes cascading renders that can hurt performance, and is not recommended. (https://react.dev/learn/you-might-not-need-an-effect).

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251227-172126-eco-step-63-mutirao-finish-share-card-v0_1\src__app__eco__mutiroes__MutiroesClient.tsx:37:21
  35 |     else { setItems([]); setStatus("erro"); }
  36 |   }
> 37 |   useEffect(() => { refresh(); }, []);
     |                     ^^^^^^^ Avoid calling setState() directly within an effect
  38 |
  39 |   return (
  40 |     <section style={{ display: "grid", gap: 10 }}>  react-hooks/set-state-in-effect
  37:35  warning  React Hook useEffect has a missing dependency: 'refresh'. Either include it or remove the dependency array                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     react-hooks/exhaustive-deps
  45:9   error    Do not use an `<a>` element to navigate to `/eco/pontos/`. Use `<Link />` from `next/link` instead. See: https://nextjs.org/docs/messages/no-html-link-for-pages                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               @next/next/no-html-link-for-pages

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251228-183154-eco-step-92b-confirmado-badge-actionsinline-v0_1\src__app__eco___components__PointActionsInline.tsx
   5:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   7:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  35:44  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  45:67  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  73:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  74:14  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  75:20  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251229-000238-eco-step-100-fix-list2-confirm-groupby-field-v0_3\src__app__api__eco__points__list2__route.ts
   14:24   error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   25:41   error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   33:12   error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   34:31   error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   35:26   error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   36:32   error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   40:14   warning  'e' is defined but never used             @typescript-eslint/no-unused-vars
   47:36   error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   47:48   error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   49:88   error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   49:103  warning  'e1' is defined but never used            @typescript-eslint/no-unused-vars
   50:88   error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   50:103  warning  'e2' is defined but never used            @typescript-eslint/no-unused-vars
   51:56   error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   51:71   warning  'e3' is defined but never used            @typescript-eslint/no-unused-vars
   52:49   error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   52:64   warning  'e4' is defined but never used            @typescript-eslint/no-unused-vars
   64:15   error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   64:31   error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   70:18   error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   85:28   error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   85:43   error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  102:32   error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  115:15   error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251230-125954-eco-step-106f2-fix-seed-eco-dmmf-required-v0_2\route.ts
    7:83  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   13:43  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   14:25  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   21:23  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   72:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  111:13  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  111:29  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251230-163513-eco-step-107g-fix-points-list-alias-and-front-safe-v0_1\src\app\api\eco\points\list\route.ts
   18:13  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   18:29  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   29:77  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   33:24  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   34:24  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   42:23  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   43:30  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   47:22  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   51:21  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   57:21  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   63:27  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   67:27  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   88:15  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   95:30  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  110:19  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  113:55  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  114:64  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  115:37  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  117:42  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  118:37  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  121:27  error    Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  121:45  warning  'raw' is assigned a value but never used  @typescript-eslint/no-unused-vars

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251230-163513-eco-step-107g-fix-points-list-alias-and-front-safe-v0_1\src\app\eco\mural-acoes\MuralAcoesClient.tsx
  15:10  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  16:10  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  17:11  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  20:28  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  42:14  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  45:54  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  49:66  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  51:45  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  69:48  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  83:19  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251230-163513-eco-step-107g-fix-points-list-alias-and-front-safe-v0_1\src\app\eco\mural\MuralClient.tsx
    8:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   10:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   50:42  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   80:28  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   85:18  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   85:26  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   98:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   99:19  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  100:16  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  101:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  102:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  103:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  120:25  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251230-163513-eco-step-107g-fix-points-list-alias-and-front-safe-v0_1\src\app\eco\mural\_components\MuralTopBar.tsx
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

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251230-163513-eco-step-107g-fix-points-list-alias-and-front-safe-v0_1\src\app\eco\mural\_components\MuralTopBarClient.tsx
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

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251230-193430-C__Projetos_App ECO_eluta-servicos_src_app_api_eco_points_confirm_route.ts
  16:13   error  Unexpected any. Specify a different type      @typescript-eslint/no-explicit-any
  16:29   error  Unexpected any. Specify a different type      @typescript-eslint/no-explicit-any
  20:113  error  Unexpected any. Specify a different type      @typescript-eslint/no-explicit-any
  24:33   error  Unexpected any. Specify a different type      @typescript-eslint/no-explicit-any
  24:56   error  Unexpected any. Specify a different type      @typescript-eslint/no-explicit-any
  34:56   error  Unexpected any. Specify a different type      @typescript-eslint/no-explicit-any
  46:9    error  'r' is never reassigned. Use 'const' instead  prefer-const
  51:29   error  Unexpected any. Specify a different type      @typescript-eslint/no-explicit-any
  53:36   error  Unexpected any. Specify a different type      @typescript-eslint/no-explicit-any
  54:16   error  Unexpected any. Specify a different type      @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251230-193431-C__Projetos_App ECO_eluta-servicos_src_app_api_eco_points_replicar_route.ts
  59:50  error  Parsing error: ':' expected

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251230-193431-C__Projetos_App ECO_eluta-servicos_src_app_api_eco_points_support_route.ts
   7:24  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  17:54  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  18:37  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  19:30  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  24:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  24:31  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  30:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251230-233241-C__Projetos_App ECO_eluta-servicos_src_app_api_eco_points_confirm_route.ts
  128:24  error  Parsing error: Unterminated regular expression literal

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251230-233241-C__Projetos_App ECO_eluta-servicos_src_app_api_eco_points_replicar_route.ts
  128:24  error  Parsing error: Unterminated regular expression literal

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20251230-233241-C__Projetos_App ECO_eluta-servicos_src_app_api_eco_points_support_route.ts
  128:24  error  Parsing error: Unterminated regular expression literal

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20260102-130401-C__Projetos_App ECO_eluta-servicos_src_app_api_eco_points_confirm_route.ts
  128:24  error  Parsing error: Unterminated regular expression literal

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20260102-130401-C__Projetos_App ECO_eluta-servicos_src_app_api_eco_points_replicar_route.ts
  128:24  error  Parsing error: Unterminated regular expression literal

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20260102-130401-C__Projetos_App ECO_eluta-servicos_src_app_api_eco_points_support_route.ts
  128:24  error  Parsing error: Unterminated regular expression literal

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20260102-164956-C__Projetos_App ECO_eluta-servicos_src_app_api_eco_points_confirm_route.ts
  128:24  error  Parsing error: Unterminated regular expression literal

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20260102-164956-C__Projetos_App ECO_eluta-servicos_src_app_api_eco_points_replicar_route.ts
  128:24  error  Parsing error: Unterminated regular expression literal

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20260102-164956-C__Projetos_App ECO_eluta-servicos_src_app_api_eco_points_support_route.ts
  128:24  error  Parsing error: Unterminated regular expression literal

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20260102-165017-C__Projetos_App ECO_eluta-servicos_src_app_eco_mural-acoes_MuralAcoesClient.tsx
  15:10  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  16:10  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  17:11  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  20:28  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  42:14  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  45:54  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  49:66  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  51:45  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  69:48  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  83:19  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20260102-183432-C__Projetos_App ECO_eluta-servicos_src_app_eco_mural_MuralClient.tsx
    8:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   10:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   50:42  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   80:28  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   85:18  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   85:26  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   98:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   99:19  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  100:16  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  101:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  102:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  103:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  120:25  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20260103-182504-C__Projetos_App ECO_eluta-servicos_src_app_api_eco_points_route.ts
   15:17   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   29:15   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   29:31   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   35:16   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   36:17   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   36:58   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   37:19   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   38:18   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   40:35   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   41:102  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   42:99   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   44:32   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   45:62   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   51:22   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   56:24   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   62:17   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   64:20   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  102:15   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20260103-184128-C__Projetos_App ECO_eluta-servicos_src_app_eco_mural-acoes_MuralAcoesClient.tsx
  12:21  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  17:29  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  26:28  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  41:41  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  61:63  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  61:81  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  90:58  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20260103-184128-C__Projetos_App ECO_eluta-servicos_src_app_eco_mural_MuralClient.tsx
    8:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   10:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   50:42  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   80:28  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   85:18  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   85:26  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   98:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   99:19  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  100:16  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  101:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  102:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  103:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  120:25  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20260114-103305-eco-step-115h-rewrite-points-action-dmmf-safe-v0_1\C__Projetos_App ECO_eluta-servicos_src_app_api_eco_points_action_route.ts
   13:21   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   13:45   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   13:58   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   14:23   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   15:22   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   16:85   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   17:52   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   17:93   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   18:46   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   18:87   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   19:166  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   20:27   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   28:25   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   32:36   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   36:68   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   36:79   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   36:85   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   38:14   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   62:62   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   69:30   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   73:16   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   80:17   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   92:15   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   92:31   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  118:17   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  140:15   error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20260114-105608-eco-step-117-fix-mural-links-and-actions-v0_1\C__Projetos_App ECO_eluta-servicos_src_app_api_eco_points_action_route.ts
   12:30  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   18:21  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   19:21  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   19:34  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   22:23  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   27:22  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   33:33  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   38:52  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   39:31  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   42:46  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   43:31  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   48:63  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   51:27  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   68:25  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   73:36  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  122:29  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  139:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  139:31  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  188:21  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  212:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20260114-112039-eco-step-118c-fix-muralclient-p-undefined-v0_1\C_Projetos_App ECO_eluta-servicos_src_app_eco_mural-acoes_MuralAcoesClient.tsx
  13:21  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  18:29  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  27:28  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  42:41  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  63:63  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  63:81  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  92:58  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20260114-112039-eco-step-118c-fix-muralclient-p-undefined-v0_1\C_Projetos_App ECO_eluta-servicos_src_app_eco_mural_MuralClient.tsx
    9:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   11:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   51:42  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   81:28  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   86:18  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   86:26  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  100:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  101:19  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  102:16  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  103:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  104:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  105:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  122:25  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20260114-113826-eco-step-119-fix-muralclient-sort-syntax-v0_1\src_app_eco_mural_MuralClient.tsx
  86:4  error  Parsing error: Unexpected keyword or identifier

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20260114-115613-eco-step-119-fix-muralclient-sort-and-base-filters-safe-v0_2\C__Projetos_App ECO_eluta-servicos_src_app_eco_mural-acoes_MuralAcoesClient.tsx
  13:21  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  18:29  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  27:28  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  42:41  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  63:63  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  63:81  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  92:58  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20260114-115613-eco-step-119-fix-muralclient-sort-and-base-filters-safe-v0_2\C__Projetos_App ECO_eluta-servicos_src_app_eco_mural_MuralClient.tsx
    9:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   11:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   51:42  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   81:28  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   87:20  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   87:28  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  102:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  103:19  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  104:16  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  105:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  106:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  107:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  124:25  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20260114-122124-eco-step-120j-upgrade-newpoint-geolocate-safe-v0_3\C__Projetos_App_ECO_eluta-servicos_src_app_eco_mural__components_MuralNewPointClient.tsx
  39:22  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20260114-123530-eco-step-121b-fix-mural-readable-styles-v0_1\C__Projetos_App_ECO_eluta-servicos_src_app_eco_mural__components_MuralReadableStyles.tsx
  8:6  error  Parsing error: Expression expected

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\20260114-123959-eco-step-121c-fix-mural-readable-styles-template-v0_1\C__Projetos_App_ECO_eluta-servicos_src_app_eco_mural__components_MuralReadableStyles.tsx
  13:28  error  Parsing error: ',' expected

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\eco-step-148-20260116-000117\src\app\api\eco\mural\list\route.ts
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

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\eco-step-148-20260116-000117\src\app\api\eco\point\detail\route.ts
  16:13  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  16:29  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  20:79  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  25:13  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  25:29  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  29:78  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  47:28  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\eco-step-148-20260116-000117\src\app\api\eco\points\list2\route.ts
    7:15  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   10:24  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   13:22  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   16:37  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   40:22  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   47:37  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   56:36  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   60:31  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   61:34  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   63:32  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   67:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   81:13  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   81:29  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
   95:14  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  103:38  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  105:38  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  107:17  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any
  113:36  error  Unexpected any. Specify a different type  @typescript-eslint/no-explicit-any

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\eco-step-148-20260116-000117\src\app\api\eco\points\map\route.ts
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

C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\eco-step-148-20260116-000117\src\app\api\eco\points\stats\route.ts
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

Ô£û 2078 problems (1954 errors, 124 warnings)
  2 errors and 7 warnings potentially fixable with the `--fix` option.
~~~

### npm run build
~~~

> eluta-servicos@0.1.0 build
> next build

   Ôû▓ Next.js 16.0.10 (Turbopack)
   - Environments: .env

   Creating an optimized production build ...

> Build error occurred
Error: Turbopack build failed with 14 errors:
./src/app/eco/mural-acoes/MuralAcoesClient.tsx:17:1
Ecmascript file had an error
  15 | // Robust client actions bar for ECO mural items (works with different prop shapes).
  16 |
> 17 | "use client";
     | ^^^^^^^^^^^^^
  18 | // ===== ECO REF GUARD (auto) =====
  19 | // Safety-net for accidental leftover identifiers (p/it/item) that cause ReferenceError during SSR/module eval.
  20 | // Remove after we fully clean this file.

The "use client" directive must be placed before other expressions. Move it to the top of the file to resolve this issue.

Import trace:
  Server Component:
    ./src/app/eco/mural-acoes/MuralAcoesClient.tsx
    ./src/app/eco/mural-acoes/page.tsx


./src/app/eco/mural-acoes/MuralAcoesClient.tsx:29:10
Ecmascript file had an error
  27 |
  28 | import * as React from "react";
> 29 | import { useRouter } from "next/navigation";
     |          ^^^^^^^^^
  30 | import { postMuralAction, type MuralAction } from "@/lib/eco/muralActions";
  31 | import MuralPointActionsClient from "../mural/_components/MuralPointActionsClient";
  32 |

You're importing a component that needs `useRouter`. This React Hook only works in a Client Component. To fix, mark the file (or its parent) with the `"use client"` directive.

 Learn more: https://nextjs.org/docs/app/api-reference/directives/use-client



Import trace:
  Server Component:
    ./src/app/eco/mural-acoes/MuralAcoesClient.tsx
    ./src/app/eco/mural-acoes/page.tsx


./src/app/api/eco/mutirao/finish/route.ts:148:82
Parsing ecmascript source code failed
  146 |       mutirao: mutiraoItem,
  147 |       point: pointRes?.ok ? pointRes.item : null,
> 148 |       meta: { mutiraoModel: mm.key, mutiraoMode: upd.mode || "unknown", "pointId", pointMode: pointRes?.mode || "skip" }
      |                                                                                  ^
  149 |     });
  150 |   } catch (e) {
  151 |     const msg = asMsg(e);

Unexpected token `,`. Expected identifier


./src/app/api/eco/points/confirm/route.ts:128:25
Parsing ecmascript source code failed
  126 |     const actionKey = pickDelegate(pc, [
  127 | "ecoCriticalPointConfirm", "ecoPointConfirm", "ecoCriticalConfirm"
> 128 | ]) || (keys.find((k) => /
      |                         ^
  129 | confirm
  130 | /i.test(k) && /eco/i.test(k)) || null);
  131 |     if (!actionKey) return NextResponse.json({ ok: false, error: "action_model_not_found" }, { status: 500 });

Unterminated regexp literal


./src/app/api/eco/points/replicar/route.ts:128:25
Parsing ecmascript source code failed
  126 |     const actionKey = pickDelegate(pc, [
  127 | "ecoPointReplicate", "ecoPointReplicar", "ecoCriticalPointReplicate"
> 128 | ]) || (keys.find((k) => /
      |                         ^
  129 | replicar
  130 | /i.test(k) && /eco/i.test(k)) || null);
  131 |     if (!actionKey) return NextResponse.json({ ok: false, error: "action_model_not_found" }, { status: 500 });

Unterminated regexp literal


./src/app/api/eco/points/support/route.ts:128:25
Parsing ecmascript source code failed
  126 |     const actionKey = pickDelegate(pc, [
  127 | "ecoPointSupport", "ecoCriticalPointSupport"
> 128 | ]) || (keys.find((k) => /
      |                         ^
  129 | support
  130 | /i.test(k) && /eco/i.test(k)) || null);
  131 |     if (!actionKey) return NextResponse.json({ ok: false, error: "action_model_not_found" }, { status: 500 });

Unterminated regexp literal


./src/app/api/share/receipt-card/route.ts:38:10
Parsing ecmascript source code failed
  36 |
  37 |   return new ImageResponse((
> 38 |     <div style={{ width: "100%", height: "100%", background: bg, display: "flex", flexDirection: "column", padding: 72, color: ink, fontFamily: "ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Arial" }}>
     |          ^^^^^
  39 |       <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
  40 |         <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
  41 |           <div style={{ fontSize: 28, letterSpacing: 2, color: green, fontWeight: 700 }}>RECIBO ECO</div>

Expected '>', got 'style'


./src/app/chamar/sucesso/page.tsx:60:1
Parsing ecmascript source code failed
  58 |               Fechar / Emitir recibo
  59 |             </Link>
> 60 | {(() => {
     | ^
  61 |   const __c = receiptCodeFromItem(item);
  62 |   return __c ? (
  63 |     <>

Expected '</', got '{'


./src/app/eco/mutiroes/[id]/page.tsx:7:9
Parsing ecmascript source code failed
   5 |
   6 | export default async function Page({
>  7 |   const p: any = await (params as any);
     |         ^
   8 |   const id = String(p?.id || "");
   9 |  params }: { params: Promise<{ id: string }> }) {
  10 |   const p = await params;

Expected ',', got 'p'


./src/app/pedidos/page.tsx:52:74
Parsing ecmascript source code failed
  50 |     try { json = JSON.parse(txt); } catch { json = { raw: txt }; }
  51 |
> 52 |     if (!res.ok) throw new Error(json?.error ?? GET /api/pickup-requests falhou (\));
     |                                                                          ^^^^^^
  53 |     items = pickItems(json);
  54 |   } catch (e: any) {
  55 |     err = e?.message ?? String(e);

Expected ',', got 'falhou'


./src/app/recibo/[code]/recibo-client.tsx:39:32
Parsing ecmascript source code failed
  37 |       const url =
  38 |         /api/receipts?code= +
> 39 |         (operatorToken ? &token= : "");
     |                                ^
  40 |
  41 |       const res = await fetch(url, {
  42 |         cache: "no-store",

Expected ':', got '='

Import trace:
  Server Component:
    ./src/app/recibo/[code]/recibo-client.tsx
    ./src/app/recibo/[code]/page.tsx


./src/app/recibo/[code]/recibo-client.tsx:39:26
Parsing ecmascript source code failed
  37 |       const url =
  38 |         /api/receipts?code= +
> 39 |         (operatorToken ? &token= : "");
     |                          ^
  40 |
  41 |       const res = await fetch(url, {
  42 |         cache: "no-store",

Expression expected

Import trace:
  Server Component:
    ./src/app/recibo/[code]/recibo-client.tsx
    ./src/app/recibo/[code]/page.tsx


./src/app/recibo/[code]/recibo-client.tsx:38:9
Parsing ecmascript source code failed
  36 |     try {
  37 |       const url =
> 38 |         /api/receipts?code= +
     |         ^^^^^^^^^^^^^
  39 |         (operatorToken ? &token= : "");
  40 |
  41 |       const res = await fetch(url, {

Unknown regular expression flags.

Import trace:
  Server Component:
    ./src/app/recibo/[code]/recibo-client.tsx
    ./src/app/recibo/[code]/page.tsx


./src/app/eco/mural-acoes/page.tsx:2:1
Module not found: Can't resolve './_components/MuralTopBarClient'
  1 | import { MuralAcoesClient } from "./MuralAcoesClient";
> 2 | import MuralTopBarClient from "./_components/MuralTopBarClient";
    | ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  3 |
  4 | export const dynamic = "force-dynamic";
  5 |



https://nextjs.org/docs/messages/module-not-found


    at <unknown> (./src/app/eco/mural-acoes/MuralAcoesClient.tsx:17:1)
    at <unknown> (./src/app/eco/mural-acoes/MuralAcoesClient.tsx:29:10)
    at <unknown> (./src/app/api/eco/mutirao/finish/route.ts:148:82)
    at <unknown> (./src/app/api/eco/points/confirm/route.ts:128:25)
    at <unknown> (./src/app/api/eco/points/replicar/route.ts:128:25)
    at <unknown> (./src/app/api/eco/points/support/route.ts:128:25)
    at <unknown> (./src/app/api/share/receipt-card/route.ts:38:10)
    at <unknown> (./src/app/chamar/sucesso/page.tsx:60:1)
    at <unknown> (./src/app/eco/mutiroes/[id]/page.tsx:7:9)
    at <unknown> (./src/app/pedidos/page.tsx:52:74)
    at <unknown> (./src/app/recibo/[code]/recibo-client.tsx:39:32)
    at <unknown> (./src/app/recibo/[code]/recibo-client.tsx:39:26)
    at <unknown> (./src/app/recibo/[code]/recibo-client.tsx:38:9)
    at <unknown> (./src/app/eco/mural-acoes/page.tsx:2:1)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
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