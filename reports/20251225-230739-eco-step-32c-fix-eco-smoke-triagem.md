# ECO — STEP 32c — Fix eco-smoke (/operador/triagem) sem vírgula

Data: 2025-12-25 23:07:39
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG
Arquivo: tools/eco-smoke.ps1
Backup : tools/_patch_backup/20251225-230739-tools_eco-smoke.ps1

- INFO: /operador/triagem já existia (só normalizei vírgula se tinha).
- OK: eco-smoke.ps1 atualizado.

## VERIFY
Rode: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1
