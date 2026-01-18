# eco-step-210 — fix eco-runner Tasks argv — 20260117-171949

Root: C:\Projetos\App ECO\eluta-servicos

[BACKUP] C:\Projetos\App ECO\eluta-servicos\tools\eco-runner.ps1 -> C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\eco-step-210\20260117-171949\eco-runner.ps1

## PATCH
- wrote: C:\Projetos\App ECO\eluta-servicos\tools\eco-runner.ps1

## VERIFY
### -Tasks lint build (2 tokens)
~~~
Exception: C:\Projetos\App ECO\eluta-servicos\tools\eco-runner.ps1:30
Line |
  30 |  . $ec -ne 0){ throw ("command failed: " + $title + " (exit " + $ec + ") .
     |                ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | command failed: npm run lint (exit 1)
~~~

### -Tasks lint,build (1 token com vírgula)
~~~
Exception: C:\Projetos\App ECO\eluta-servicos\tools\eco-runner.ps1:30
Line |
  30 |  . $ec -ne 0){ throw ("command failed: " + $title + " (exit " + $ec + ") .
     |                ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | command failed: npm run lint (exit 1)
~~~
