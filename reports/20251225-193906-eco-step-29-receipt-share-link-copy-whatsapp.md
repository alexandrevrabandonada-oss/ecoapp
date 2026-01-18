# ECO — STEP 29 — ReceiptShareBar: copiar link + WhatsApp + Web Share (link)

Data: 2025-12-25 19:39:06
PWD : C:\Projetos\App ECO\eluta-servicos

## DIAG
Arquivo: src/components/eco/ReceiptShareBar.tsx
Backup : tools/_patch_backup/20251225-193906-src_components_eco_ReceiptShareBar.tsx
codeVar: code

## PATCH
- OK: injetei helpers do STEP 29 (top-level).
- OK: inseri botões do STEP 29 após ECO_STEP28_BUTTONS_END.

## VERIFY
1) Reinicie o dev (CTRL+C): npm run dev
2) Rode o smoke: pwsh -NoProfile -ExecutionPolicy Bypass -File .\\tools\\eco-smoke.ps1
3) Abra /r/[code] e teste:
   - Copiar link
   - Copiar texto + link
   - WhatsApp (abre wa.me com texto)
   - Compartilhar link (no celular/PWA: share sheet; no desktop: copia tudo)
