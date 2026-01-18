# ECO STEP 201r — ESLint 9 estável + TS exclude + dep clean

Stamp: 20260117-115018
Root: C:\Projetos\App ECO\eluta-servicos

## PATCH A — remover __DEP__ (quebra TS build)
- ok: sem ocorrencias de __DEP__ em src/

## PATCH B — eslint.config.mjs (minimal + ignores)
- backup: C:\Projetos\App ECO\eluta-servicos\eslint.config.mjs -> C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\eco-step-201r\20260117-115018\eslint.config.mjs--20260117-115018
- wrote: C:\Projetos\App ECO\eluta-servicos\eslint.config.mjs

## PATCH C — package.json scripts.lint
- backup: C:\Projetos\App ECO\eluta-servicos\package.json -> C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\eco-step-201r\20260117-115018\package.json--20260117-115018
- ok: scripts.lint = eslint . --no-error-on-unmatched-pattern

## PATCH D — tsconfig.json exclude (backups/reports)
- backup: C:\Projetos\App ECO\eluta-servicos\tsconfig.json -> C:\Projetos\App ECO\eluta-servicos\tools\_patch_backup\eco-step-201r\20260117-115018\tsconfig.json--20260117-115018
- ok: updated exclude in tsconfig.json

## VERIFY
### npm --version
~~~
10.9.3

~~~

### npm run lint
~~~

> eluta-servicos@0.1.0 lint
> eslint . --no-error-on-unmatched-pattern


exit: 0
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
 Ô£ô Generating static pages using 11 workers (44/44) in 881.1ms
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


exit: 0
~~~

## NEXT
- Se o terminal continuar estranho com npm, rode: Set-Alias npm npm.cmd