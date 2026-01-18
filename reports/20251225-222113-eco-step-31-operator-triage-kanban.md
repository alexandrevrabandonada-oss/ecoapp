# ECO — STEP 31 — /operador/triagem (kanban de triagem + contadores por bairro)

Data: 2025-12-25 22:21:13
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG
schema: prisma/schema.prisma
statusField: status (type PickupRequestStatus)
enum: OPEN, SCHEDULED, DONE, CANCELED
columns: novos=[OPEN] rota=[OPEN] done=[DONE] cancel=[CANCELED]

- OK: criei/atualizei src/components/eco/OperatorTriageBoard.tsx
- OK: criei src/app/operador/triagem/page.tsx

## VERIFY
1) Reinicie o dev (CTRL+C): npm run dev
2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1
3) Abra: /operador/triagem
   - Atualizar (carrega /api/pickup-requests)
   - Ver colunas (Novos/Em rota/Concluídos/Cancelados)
   - Clicar Em rota / Concluir (PATCH) e ver mover de coluna
