# ECO — STEP 32 — ReceiptShareBar: WebShare com URL fallback + botões link

Data: 2025-12-25 21:00:35
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG
Arquivo: src/components/eco/ReceiptShareBar.tsx
Backup : tools/_patch_backup/20251225-210035-src_components_eco_ReceiptShareBar.tsx
codeVar: code

## PATCH
- OK: inseri helpers de link após STEP31_TOAST_STATE_END.
- WARN: não achei ecoShareCard(fmt) para atualizar (skip).
- INFO: botões de link já existem (skip).

## VERIFY
1) Reinicie o dev (CTRL+C): npm run dev
2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1
3) Abra /r/[code] e teste:
   - Copiar link (toast) + colar em outro lugar
   - Compartilhar link (abre share sheet quando suportado)
   - Compartilhar 3:4/1:1: se não suportar files, deve compartilhar URL do recibo
