# ECO — STEP 30 — /operador v0.2 (filtros + seleção + copiar rota + WhatsApp)

Data: 2025-12-25 22:10:40
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG
schema: prisma/schema.prisma
statusField: status (type PickupRequestStatus)
statusOptions: OPEN, SCHEDULED, DONE, CANCELED

## PATCH
Arquivo: src/components/eco/OperatorPanel.tsx
Backup : tools/_patch_backup/20251225-221040-src_components_eco_OperatorPanel.tsx
- OK: OperatorPanel.tsx atualizado (/operador v0.2).

## VERIFY
1) Reinicie o dev (CTRL+C): npm run dev
2) Rode: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1
3) Abra /operador e teste:
   - Filtrar por status
   - Buscar por bairro/endereço
   - Selecionar alguns e 'Copiar rota' / 'WhatsApp'
