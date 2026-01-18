# ECO — STEP 36c — Card do dia (PNG 3:4) + Baixar/Compartilhar no /operador/triagem (SAFE)

Data: 2025-12-26 14:22:21
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG
schema: prisma/schema.prisma
pickup delegate: pickupRequest
route field   : routeDay
status field  : status

## PATCH
- OK: API /api/share/route-day-card criada. Backup: (nenhum)
- UI alvo: src/app/operador/triagem/OperatorTriageV2.tsx
- Backup UI: tools/_patch_backup/20251226-142221-src_app_operador_triagem_OperatorTriageV2.tsx
- OK: helpers inseridos após STEP35.
- OK: botões inseridos ao lado do WhatsApp do boletim.
- OK: UI escrita.

## VERIFY
1) Reinicie o dev (CTRL+C): npm run dev
2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1
3) Teste manual:
   - /api/share/route-day-card?day=YYYY-MM-DD&format=3x4 (abre PNG)
   - /operador/triagem -> Fechamento do dia -> Baixar/Compartilhar card (3:4)