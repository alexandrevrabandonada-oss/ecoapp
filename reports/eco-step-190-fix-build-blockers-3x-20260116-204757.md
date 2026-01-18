# eco-step-190 — fix build blockers (ReceiptPublishButton + r/[code] + eco/pontos/[id]) — 20260116-204757

## PATCH LOG
~~~
[OK]   C:\Projetos\App ECO\eluta-servicos\src\components\eco\ReceiptPublishButton.tsx
       backup: 
[OK]   C:\Projetos\App ECO\eluta-servicos\src\components\eco\ReceiptPublishButton.tsx
       backup: 
[SKIP] C:\Projetos\App ECO\eluta-servicos\src\app\r\[code]\page.tsx (no change)
[SKIP] C:\Projetos\App ECO\eluta-servicos\src\app\r\[code]\page.tsx (no change)
[SKIP] C:\Projetos\App ECO\eluta-servicos\src\app\r\[code]\page.tsx (no change)
[SKIP] C:\Projetos\App ECO\eluta-servicos\src\app\eco\pontos\[id]\page.tsx (no change)
~~~

## VERIFY
Rode (em linhas separadas):
- npm run build
- (se passar) dir tools\eco-step-148b*
- (depois) rode o smoke que aparecer: pwsh -NoProfile -ExecutionPolicy Bypass -File tools\<arquivo>.ps1 -OpenReport