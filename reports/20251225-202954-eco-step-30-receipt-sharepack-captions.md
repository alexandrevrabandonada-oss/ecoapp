# ECO — STEP 30 — ReceiptShareBar: share pack (legendas prontas p/ copiar)

Data: 2025-12-25 20:29:54
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG
Arquivo: src/components/eco/ReceiptShareBar.tsx
Backup : tools/_patch_backup/20251225-202954-src_components_eco_ReceiptShareBar.tsx
codeVar: code

## PATCH
- OK: injetei helpers do STEP 30 (top-level).
- OK: inseri botões do STEP 30 após ECO_STEP29_LINK_BUTTONS_END.

## VERIFY
1) Reinicie o dev (CTRL+C): npm run dev
2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1
3) Abra /r/[code] e teste botões:
   - Copiar legenda (curta / longa / zap pronta)
   - Compartilhar texto (no celular/PWA: share sheet; no desktop: copia tudo)
