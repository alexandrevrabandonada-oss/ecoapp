# ECO — STEP 32b — Rota do dia SAFE no /operador/triagem (sem aspas curvas)

Data: 2025-12-25 23:01:36
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG
Arquivo: src/components/eco/OperatorTriageBoard.tsx
Backup : tools/_patch_backup/20251225-230136-src_components_eco_OperatorTriageBoard.tsx

## PATCH
- OK: helpers inseridos após eco31Status.
- OK: state routeBairro/routeOnlyNew inserido.
- OK: derivados/handlers de rota inseridos.
- OK: UI 'Rota do dia' inserida no return.
- OK: OperatorTriageBoard atualizado.

## PATCH (smoke)
Arquivo: tools/eco-smoke.ps1
Backup : tools/_patch_backup/20251225-230136-tools_eco-smoke.ps1
- OK: inseri /operador/triagem no eco-smoke.

## VERIFY
1) Reinicie o dev (CTRL+C): npm run dev
2) Rode: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1
3) Abra /operador/triagem e teste Rota do dia (bairro + so NOVOS + copiar + WhatsApp)
