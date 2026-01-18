# ECO — STEP 28c — ReceiptShareBar: Web Share (PNG) + botão 1:1 (hardening/idempotente)

Data: 2025-12-25 19:24:12
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG
Arquivo: src/components/eco/ReceiptShareBar.tsx

## PATCH
Backup: tools/_patch_backup/20251225-192412-src_components_eco_ReceiptShareBar.tsx
- OK: removi bloco antigo ECO_STEP28_SHARE_HELPERS.
- OK: injetei helpers ECO_STEP28_SHARE_HELPERS (top-level).
- OK: inseri botões (1:1 + compartilhar 3:4/1:1) após 'Baixar card 3:4'.

## VERIFY
1) Reinicie o dev (CTRL+C): npm run dev
2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1
3) Abra um recibo /r/[code] e teste:
   - Baixar card 3:4
   - Baixar card 1:1
   - Compartilhar 3:4 / 1:1 (no celular/PWA deve abrir share sheet; senão baixa)
