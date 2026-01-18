# ECO — STEP 21c2 — Fix UI /pedidos token patch (sem crash)

Data: 2025-12-24 16:28:24
PWD : C:\Projetos\App ECO\eluta-servicos

ui file: C:\Projetos\App ECO\eluta-servicos\src\app\chamar-coleta\page.tsx

Backup ui: tools/_patch_backup/20251224-162824-C__Projetos_App ECO_eluta-servicos_src_app_chamar-coleta_page.tsx
- OK: helper ecoAuthHeaders injetado após imports.
- OK: inseri headers: ecoAuthHeaders() no options.

## Próximos passos
1) Reinicie o dev (CTRL+C): npm run dev
2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1
3) Abra /pedidos: com token salvo em localStorage('eco_operator_token') deve mandar header x-eco-token
