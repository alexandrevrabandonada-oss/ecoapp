# eco-step-146-estado-geral-roadmap-diag-v0_1 - 20260115-224034

## ambiente
- node: v22.19.0
- npm: 10.9.3

## git status --porcelain

## scripts (package.json)

## rotas UI (/eco)
- /eco/fechamento
- /eco/mapa
- /eco/mural
- /eco/mural-acoes
- /eco/mural/chamados
- /eco/mural/confirmados
- /eco/mutiroes
- /eco/mutiroes/[id]
- /eco/mutiroes/[id]/finalizar
- /eco/pontos
- /eco/pontos/[id]
- /eco/pontos/[id]/resolver
- /eco/recibos
- /eco/share
- /eco/share/dia/[day]
- /eco/share/mes/[month]
- /eco/share/mutirao/[id]
- /eco/share/ponto/[id]
- /eco/transparencia

## rotas API (/api/eco)
- /api/eco/critical/confirm
- /api/eco/critical/create
- /api/eco/critical/list
- /api/eco/day-close
- /api/eco/day-close/card
- /api/eco/day-close/compute
- /api/eco/day-close/list
- /api/eco/month-close
- /api/eco/month-close/card
- /api/eco/month-close/list
- /api/eco/mural/list
- /api/eco/mutirao/card
- /api/eco/mutirao/create
- /api/eco/mutirao/finish
- /api/eco/mutirao/get
- /api/eco/mutirao/list
- /api/eco/mutirao/proof
- /api/eco/mutirao/update
- /api/eco/point/detail
- /api/eco/point/reopen
- /api/eco/points
- /api/eco/points/action
- /api/eco/points/card
- /api/eco/points/confirm
- /api/eco/points/get
- /api/eco/points/list
- /api/eco/points/list2
- /api/eco/points/map
- /api/eco/points/react
- /api/eco/points/replicar
- /api/eco/points/report
- /api/eco/points/resolve
- /api/eco/points/stats
- /api/eco/points/support
- /api/eco/points2
- /api/eco/recibo/list
- /api/eco/upload

## Prisma models
- Delivery
- EcoCriticalPoint
- EcoCriticalPointConfirm
- EcoDayClose
- EcoMonthClose
- EcoMutirao
- EcoPointReplicate
- EcoPointSupport
- EcoReceipt
- PickupRequest
- Point
- Receipt
- Service
- Weighing

## proximo passo sugerido
- colar esse report aqui no chat para eu atualizar o roadmap oficial com status real (DONE/IN PROGRESS/NEXT).