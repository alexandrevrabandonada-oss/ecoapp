# ECO — STEP 19 — /pedidos: mostrar 'Ver recibo' quando houver receipt

Data: 2025-12-24 14:47:04
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG
arquivo: C:\Projetos\App ECO\eluta-servicos\src\app\chamar\sucesso\page.tsx

## PATCH
Backup: tools/_patch_backup/20251224-144704-C__Projetos_App ECO_eluta-servicos_src_app_chamar_sucesso_page.tsx
- INFO: import Link já existe.
- OK: helper receiptCodeFromItem inserido após imports.
- INFO: var detectada no map: item
- OK: inserido link 'Ver recibo' condicional após 'Fechar / Emitir recibo'.

## Próximos passos
1) Reinicie o dev (CTRL+C): npm run dev
2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\eco-smoke.ps1
3) Abra /pedidos: se a linha tiver receipt, deve aparecer 'Ver recibo'.
