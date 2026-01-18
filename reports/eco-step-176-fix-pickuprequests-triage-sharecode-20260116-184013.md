# eco-step-176 — triage shareCode->code — 20260116-184013

## DIAG
alvo: src\app\api\pickup-requests\triage\route.ts
antes: .shareCode = 0 | shareCode:true = 1

## PATCH LOG
~~~
[OK]   shareCode: true -> code: true (triage)
[OK]   .shareCode -> .code (triage)
       backup: C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\eco-step-176\20260116-184013\20260116-184013-C__Projetos_App_ECO_eluta-servicos_src_app_api_pickup-requests_triage_route.ts
~~~

## POS
depois: .shareCode = 0 | shareCode:true = 0

## VERIFY
- npm run build
