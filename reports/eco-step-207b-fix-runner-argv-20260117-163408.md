# eco-step-207b - fix runner argv - 20260117-163408

Root: C:\Projetos\App ECO\eluta-servicos

## PATCH - write tools\eco-runner.ps1
- [SKIP] missing: C:\Projetos\App ECO\eluta-servicos\tools\eco-runner.ps1
- wrote: C:\Projetos\App ECO\eluta-servicos\tools\eco-runner.ps1

## VERIFY - run eco-runner (lint+build)
~~~
[REPORT] C:\Projetos\App ECO\eluta-servicos\reports\eco-runner-20260117-163409.md
Exception: C:\Projetos\App ECO\eluta-servicos\tools\eco-runner.ps1:59
Line |
  59 |  . cript:failed){ throw ("Runner failed (see report): " + $reportPath) }
     |                   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Runner failed (see report): C:\Projetos\App ECO\eluta-servicos\reports\eco-runner-20260117-163409.md
~~~
