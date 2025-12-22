# ECO — Step 04 (Recibo ECO v0) — RESCUE

- Data: 2025-12-22 19:56:08
- PWD : C:\Projetos\App ECO\eluta-servicos
- Node: v22.19.0
- npm : 10.9.3

## DIAG (antes)
### Rotas (pages)
```
/chamar
/chamar-coleta
/chamar-coleta/novo
/chamar/sucesso
/coleta
/coleta/novo
/coleta/p/[id]
/doacao
/entrega
/feira
/formacao
/formacao/cursos
/impacto
/mapa
/page.tsx
/painel
/pedidos
/recibo/[code]
/recibos
/reparo
/servicos
/servicos/novo
```

### Rotas (api)
```
/api/admin/weighing
/api/delivery
/api/pickup-requests
/api/points
/api/points/[id]
/api/receipts
/api/receipts/[code]
/api/requests/[id]
/api/seed
/api/services
/api/stats
```

### Prisma models
```
Delivery
PickupRequest
Point
Receipt
Service
Weighing
```

- Backup tools/eco-smoke.ps1: tools/_patch_backup/20251222-195608-tools_eco-smoke.ps1
- OK: tools/eco-smoke.ps1 (parse corrigido)
- OK: src/app/api/pickup-requests/[id]/route.ts (criado/ajustado)
- Backup src/app/api/pickup-requests/route.ts: tools/_patch_backup/20251222-195609-src_app_api_pickup-requests_route.ts
- OK: src/app/api/pickup-requests/route.ts
- Backup src/app/api/receipts/route.ts: tools/_patch_backup/20251222-195609-src_app_api_receipts_route.ts
- OK: src/app/api/receipts/route.ts
- OK: src/app/api/receipts/[code]/route.ts
- Backup src/app/chamar-coleta/page.tsx: tools/_patch_backup/20251222-195609-src_app_chamar-coleta_page.tsx
- OK: src/app/chamar-coleta/page.tsx
- Backup src/app/chamar-coleta/novo/page.tsx: tools/_patch_backup/20251222-195609-src_app_chamar-coleta_novo_page.tsx
- OK: src/app/chamar-coleta/novo/page.tsx
- Backup src/app/recibos/page.tsx: tools/_patch_backup/20251222-195609-src_app_recibos_page.tsx
- OK: src/app/recibos/page.tsx
- OK: src/app/recibo/[code]/page.tsx

## VERIFY
- Prisma: generate + db push OK
- Arquivos obrigatórios: OK
- eco-smoke.ps1: parse OK (AST)

## DIAG (depois)
### Rotas (pages)
```
/chamar
/chamar-coleta
/chamar-coleta/novo
/chamar/sucesso
/coleta
/coleta/novo
/coleta/p/[id]
/doacao
/entrega
/feira
/formacao
/formacao/cursos
/impacto
/mapa
/page.tsx
/painel
/pedidos
/recibo/[code]
/recibos
/reparo
/servicos
/servicos/novo
```

### Rotas (api)
```
/api/admin/weighing
/api/delivery
/api/pickup-requests
/api/pickup-requests/[id]
/api/points
/api/points/[id]
/api/receipts
/api/receipts/[code]
/api/requests/[id]
/api/seed
/api/services
/api/stats
```

### Prisma models
```
Delivery
PickupRequest
Point
Receipt
Service
Weighing
```
