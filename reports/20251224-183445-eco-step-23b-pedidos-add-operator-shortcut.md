# ECO — STEP 23b — Atalho /operador dentro de /pedidos

Data: 2025-12-24 18:34:45
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG
Arquivo: src/app/pedidos/page.tsx
Já tem /operador? NÃO

## PATCH
Backup: tools/_patch_backup/20251224-183445-src_app_pedidos_page.tsx
- OK: atalho inserido.

## VERIFY
1) Reinicie o dev (CTRL+C): npm run dev
2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1
3) Abra /pedidos -> deve aparecer link 'Modo Operador'
4) Clique e confirme /operador funcionando

## COMMIT (recomendado)
git status
git add -A
git commit -m "eco: atalhos operador em /pedidos"